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

from palette import PALETTE


def _linear(channel):
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4


def material(name):
    mat = bpy.data.materials.get("pal_" + name)
    if mat is not None:
        return mat
    hex_colour, metallic, roughness, emission = PALETTE[name]
    rgb = [_linear(int(hex_colour[i:i + 2], 16) / 255.0) for i in (1, 3, 5)]
    mat = bpy.data.materials.new("pal_" + name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
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
        return self

    def box(self, size, at, colour, rot=(0, 0, 0), taper=1.0):
        """Box centred on `at`. `taper` scales the top face in X and Y."""
        x, y, z = (s / 2.0 for s in size)
        verts = [(-x, -y, -z), (x, -y, -z), (x, y, -z), (-x, y, -z)]
        verts += [(-x * taper, -y * taper, z), (x * taper, -y * taper, z), (x * taper, y * taper, z), (-x * taper, y * taper, z)]
        faces = [(0, 1, 2, 3), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
        return self._add(verts, faces, colour, _matrix(at, rot))

    def cyl(self, radius, height, at, colour, sides=6, top=None, rot=(0, 0, 0)):
        """Cylinder along Z centred on `at`. `top` is the top radius; 0 makes a cone."""
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
        return self._add(verts, faces, colour, _matrix(at, rot))

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
        return self._add(verts, faces, colour, _matrix(at, rot))

    def finish(self, objects):
        """Create the Blender object with its origin at the pivot."""
        if self.bm.faces:
            bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces[:])
            bmesh.ops.translate(self.bm, verts=self.bm.verts[:], vec=-self.pivot)
            mesh = bpy.data.meshes.new(self.name)
            self.bm.to_mesh(mesh)
            for colour in self.colours:
                mesh.materials.append(material(colour))
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
