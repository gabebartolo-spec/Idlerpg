"""Low-poly modelling helpers for the Blender art build.

Models are built in Blender axes: Z up, facing -Y, the character's right at -X.
Sizes are metres. A model is a list of Parts; a Part is one mesh (or an empty
attach point) with its pivot at a joint, so the game can swing it.
"""

import math
import random

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

from palette import GLOWS, PALETTE


def _linear(channel):
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


COLOUR_LAYER = "Color"


def colour_rgb(name):
    """Palette colour as linear RGB."""
    hex_colour = PALETTE[name]
    return [_linear(int(hex_colour[i:i + 2], 16) / 255.0) for i in (1, 3, 5)]


def material_name(colour):
    return "pal_" + colour if colour in GLOWS else "pal_matte"


def material(colour):
    """The shared matte material, coloured per face, or a glow colour's own material."""
    name = material_name(colour)
    mat = bpy.data.materials.get(name)
    if mat is not None:
        return mat
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Roughness"].default_value = 0.85
    face_colour = nodes.new("ShaderNodeVertexColor")
    face_colour.layer_name = COLOUR_LAYER
    mat.node_tree.links.new(face_colour.outputs["Color"], bsdf.inputs["Base Color"])
    if colour in GLOWS:
        bsdf.inputs["Emission Color"].default_value = (*colour_rgb(colour), 1.0)
        bsdf.inputs["Emission Strength"].default_value = GLOWS[colour]
    return mat


def _matrix(at, rot, scale=(1.0, 1.0, 1.0)):
    euler = Euler([math.radians(a) for a in rot], "XYZ")
    return Matrix.Translation(at) @ euler.to_matrix().to_4x4() @ Matrix.Diagonal((*scale, 1.0))


class Part:
    def __init__(self, name, pivot=(0.0, 0.0, 0.0), parent=None, rot=(0.0, 0.0, 0.0)):
        self.name = name
        self.pivot = Vector(pivot)
        self.parent = parent
        self.rot = rot
        self.bm = bmesh.new()
        self.colours = []
        self.points = []

    def _add(self, verts, faces, colour, matrix):
        if colour not in self.colours:
            self.colours.append(colour)
        index = self.colours.index(colour)
        made = [self.bm.verts.new(matrix @ Vector(v)) for v in verts]
        self.points.extend(v.co.copy() for v in made)
        for face in faces:
            self.bm.faces.new([made[i] for i in face]).material_index = index
        return made

    def _soften(self, made, bevel):
        """Chamfer every edge of the shape just made."""
        if bevel > 0.0:
            edges = list({edge for vert in made for edge in vert.link_edges})
            bmesh.ops.bevel(self.bm, geom=edges, offset=bevel, segments=1, profile=0.5, affect="EDGES")

    def box(self, size, at, colour, rot=(0, 0, 0), taper=1.0, bevel=0.0):
        """Box centred on `at`. `taper` scales the top face in X and Y; `bevel` chamfers the edges."""
        x, y, z = (s / 2.0 for s in size)
        verts = [(-x, -y, -z), (x, -y, -z), (x, y, -z), (-x, y, -z)]
        verts += [(-x * taper, -y * taper, z), (x * taper, -y * taper, z), (x * taper, y * taper, z), (-x * taper, y * taper, z)]
        faces = [(0, 1, 2, 3), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        self._soften(self._add(verts, faces, colour, _matrix(at, rot)), bevel)
        return self

    def cyl(self, radius, height, at, colour, sides=6, top=None, rot=(0, 0, 0), scale=(1, 1), bevel=0.0):
        """Cylinder along Z centred on `at`. `top` is the top radius; 0 makes a cone.
        `scale` squashes the cross-section in X and Y."""
        top = radius if top is None else top
        ring = [(math.cos(math.tau * i / sides), math.sin(math.tau * i / sides)) for i in range(sides)]
        verts = [(radius * c, radius * s, -height / 2.0) for c, s in ring]
        faces = [tuple(range(sides))]
        if top <= 0.0:
            verts.append((0.0, 0.0, height / 2.0))
            faces += [(i, (i + 1) % sides, sides) for i in range(sides)]
        else:
            verts += [(top * c, top * s, height / 2.0) for c, s in ring]
            faces.append(tuple(range(sides, sides * 2)))
            faces += [(i, (i + 1) % sides, sides + (i + 1) % sides, sides + i) for i in range(sides)]
        self._soften(self._add(verts, faces, colour, _matrix(at, rot, (scale[0], scale[1], 1.0))), bevel)
        return self

    def ball(self, radius, at, colour, scale=(1, 1, 1), detail=1, rot=(0, 0, 0), jitter=0.0, seed=0, floor=None):
        """Icosphere. `jitter` roughens it (rocks); `floor` flattens everything below that height."""
        if colour not in self.colours:
            self.colours.append(colour)
        index = self.colours.index(colour)
        made = bmesh.ops.create_icosphere(self.bm, subdivisions=detail, radius=radius, matrix=_matrix(at, rot, scale))["verts"]
        rng = random.Random(seed)
        centre = Vector(at)
        for vert in made:
            if jitter > 0.0:
                vert.co = centre + (vert.co - centre) * (1.0 + rng.uniform(-jitter, jitter))
            if floor is not None and vert.co.z < floor:
                vert.co.z = floor
            self.points.append(vert.co.copy())
        for face in {f for v in made for f in v.link_faces}:
            face.material_index = index
        return self

    def prism(self, outline, depth, at, colour, rot=(0, 0, 0)):
        """Extrude an (x, z) outline along Y by `depth`, centred on `at`."""
        n = len(outline)
        verts = [(x, -depth / 2.0, z) for x, z in outline] + [(x, depth / 2.0, z) for x, z in outline]
        faces = [tuple(range(n)), tuple(range(n * 2 - 1, n - 1, -1))]
        faces += [(i, (i + 1) % n, n + (i + 1) % n, n + i) for i in range(n)]
        self._add(verts, faces, colour, _matrix(at, rot))
        return self

    def finish(self, objects):
        """Create the Blender object with its origin at the pivot."""
        if self.bm.faces:
            bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
            bmesh.ops.translate(self.bm, verts=self.bm.verts[:], vec=-self.pivot)
            mesh = bpy.data.meshes.new(self.name)
            self.bm.to_mesh(mesh)
            # Faces carry their palette colour; only glow colours need a material of their own.
            slots = []
            layer = mesh.color_attributes.new(COLOUR_LAYER, "BYTE_COLOR", "CORNER")
            for polygon in mesh.polygons:
                colour = self.colours[polygon.material_index]
                if material_name(colour) not in slots:
                    slots.append(material_name(colour))
                    mesh.materials.append(material(colour))
                polygon.material_index = slots.index(material_name(colour))
                for loop in polygon.loop_indices:
                    layer.data[loop].color = (*colour_rgb(colour), 1.0)
            obj = bpy.data.objects.new(self.name, mesh)
        else:
            obj = bpy.data.objects.new(self.name, None)
            obj.empty_display_size = 0.1
        self.bm.free()
        bpy.context.scene.collection.objects.link(obj)
        if self.parent is not None:
            obj.parent = objects[self.parent.name]
            obj.location = self.pivot - self.parent.pivot
        else:
            obj.location = self.pivot
        obj.rotation_euler = Euler([math.radians(a) for a in self.rot], "XYZ")
        objects[self.name] = obj
        return obj
