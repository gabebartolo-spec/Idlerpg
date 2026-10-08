"""Build Mossgate from original centreline drawings, not from an existing font.

Requires fonttools and shapely. All coordinates below were drawn for Idle RPG.
Rounded outlines are constructed from these strokes at two optical weights.
Run from any directory; output is always art/fonts next to this repository.
"""
from pathlib import Path
import math
import re
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from shapely.geometry import LineString, Point
from shapely.ops import unary_union
from shapely.geometry.polygon import orient

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "fonts"
UPM = 1000
# 700 cap height, 510 x height. Each glyph has its own width and drawing.
# A lifted shoulder, soft terminals and slightly asymmetric bowls keep the
# letters friendly without putting decorative flourishes in reading text.
DRAWINGS = {
    "A": (650, "M65 0 L300 695 Q310 720 320 695 L585 0 M150 240 L495 240"),
    "B": (610, "M85 0 L85 700 L295 700 C610 700 610 360 300 360 L85 360 M300 360 C645 360 645 0 295 0 L85 0"),
    "C": (650, "M570 600 C480 760 75 775 75 350 C75 -60 470 -65 580 100"),
    "D": (650, "M85 0 L85 700 L260 700 C680 700 680 0 260 0 L85 0"),
    "E": (550, "M475 700 L85 700 L85 0 L485 0 M85 365 L405 365"),
    "F": (535, "M85 0 L85 700 L470 700 M85 365 L395 365"),
    "G": (680, "M585 590 C485 770 75 770 75 350 C75 -65 495 -55 595 95 L595 320 L390 320"),
    "H": (660, "M85 0 L85 700 M575 0 L575 700 M85 350 L575 350"),
    "I": (340, "M70 700 L270 700 M170 700 L170 0 M70 0 L270 0"),
    "J": (490, "M415 700 L415 175 C415 -60 85 -65 75 160"),
    "K": (610, "M85 0 L85 700 M530 700 L85 285 M255 440 L565 0"),
    "L": (525, "M85 700 L85 0 L465 0"),
    "M": (810, "M85 0 L85 700 L405 225 L725 700 L725 0"),
    "N": (675, "M85 0 L85 700 L590 0 L590 700"),
    "O": (700, "M350 705 C-15 705 -15 -5 350 -5 C715 -5 715 705 350 705"),
    "P": (600, "M85 0 L85 700 L290 700 C635 700 635 335 290 335 L85 335"),
    "Q": (700, "M350 705 C-15 705 -15 -5 350 -5 C715 -5 715 705 350 705 M405 155 L650 -95"),
    "R": (625, "M85 0 L85 700 L290 700 C635 700 635 350 290 350 L85 350 M310 350 L570 0"),
    "S": (590, "M510 595 C435 760 80 745 85 545 C90 320 515 410 515 180 C515 -60 145 -65 70 115"),
    "T": (590, "M60 700 L530 700 M295 700 L295 0"),
    "U": (660, "M85 700 L85 210 C85 -75 575 -75 575 210 L575 700"),
    "V": (640, "M65 700 L305 0 Q320 -20 335 0 L575 700"),
    "W": (900, "M65 700 L235 0 L450 480 L665 0 L835 700"),
    "X": (615, "M70 700 L545 0 M545 700 L70 0"),
    "Y": (620, "M65 700 L310 355 L555 700 M310 355 L310 0"),
    "Z": (585, "M75 700 L510 700 L75 0 L510 0"),
    "a": (555, "M465 490 L465 0 M465 255 C465 600 80 595 80 255 C80 -90 465 -85 465 255"),
    "b": (565, "M85 0 L85 740 M85 255 C85 590 485 595 485 255 C485 -90 85 -85 85 255"),
    "c": (515, "M440 440 C320 595 75 535 75 255 C75 -35 335 -70 445 80"),
    "d": (565, "M480 0 L480 740 M480 255 C480 590 80 595 80 255 C80 -90 480 -85 480 255"),
    "e": (540, "M85 265 L460 265 C470 580 75 610 75 255 C75 -55 350 -70 455 85"),
    "f": (355, "M155 0 L155 590 C155 745 230 785 310 735 M65 480 L295 480"),
    "g": (565, "M480 490 L480 -65 C480 -240 225 -260 100 -150 M480 255 C480 590 80 595 80 255 C80 -90 480 -85 480 255"),
    "h": (555, "M85 0 L85 740 M85 325 C120 585 470 590 470 325 L470 0"),
    "i": (235, "M118 0 L118 490 M118 675 L118 676"),
    "j": (270, "M180 490 L180 -60 C180 -185 100 -220 35 -175 M180 675 L180 676"),
    "k": (510, "M85 0 L85 740 M440 500 L85 190 M230 315 L465 0"),
    "l": (280, "M95 740 L95 95 Q95 -5 205 10"),
    "m": (800, "M85 0 L85 490 M85 340 C105 570 400 565 400 340 L400 0 M400 340 C430 570 715 565 715 340 L715 0"),
    "n": (555, "M85 0 L85 490 M85 325 C120 585 470 590 470 325 L470 0"),
    "o": (570, "M285 515 C5 515 5 -5 285 -5 C565 -5 565 515 285 515"),
    "p": (565, "M85 -210 L85 490 M85 255 C85 590 485 595 485 255 C485 -90 85 -85 85 255"),
    "q": (565, "M480 -210 L480 490 M480 255 C480 590 80 595 80 255 C80 -90 480 -85 480 255"),
    "r": (380, "M85 0 L85 490 M85 305 C115 510 255 540 325 495"),
    "s": (475, "M400 435 C305 565 80 540 80 395 C80 235 390 290 390 115 C390 -45 155 -70 70 75"),
    "t": (360, "M150 665 L150 130 C150 -10 235 -20 305 35 M60 490 L300 490"),
    "u": (555, "M85 500 L85 175 C85 -85 430 -70 470 175 M470 500 L470 0"),
    "v": (505, "M65 500 L240 0 Q253 -20 265 0 L440 500"),
    "w": (735, "M65 500 L190 0 L368 360 L545 0 L670 500"),
    "x": (500, "M70 500 L430 0 M430 500 L70 0"),
    "y": (515, "M65 500 L260 0 M450 500 L220 -100 Q185 -210 90 -195"),
    "z": (475, "M75 490 L400 490 L75 10 L400 10"),
    "0": (560, "M280 705 C-10 705 -10 -5 280 -5 C570 -5 570 705 280 705 M220 285 L340 415"),
    "1": (560, "M135 555 L290 700 L290 0 M130 0 L455 0"),
    "2": (560, "M80 555 C80 765 480 765 480 550 C480 380 230 220 80 0 L490 0"),
    "3": (560, "M85 610 C190 760 480 740 480 545 C480 405 365 350 245 350 C580 385 570 -40 275 -5 Q130 -5 75 100"),
    "4": (560, "M410 0 L410 700 L70 225 L495 225"),
    "5": (560, "M465 700 L110 700 L85 380 C500 560 640 -5 270 -5 Q130 -5 75 100"),
    "6": (560, "M435 645 C110 820 -35 -5 280 -5 C565 -5 565 395 280 395 Q110 395 85 245"),
    "7": (560, "M70 700 L490 700 L195 0"),
    "8": (560, "M280 350 C-5 350 -5 705 280 705 C565 705 565 350 280 350 C-35 350 -35 -5 280 -5 C595 -5 595 350 280 350"),
    "9": (560, "M125 60 C450 -115 595 705 280 705 C-5 705 -5 305 280 305 Q450 305 475 455"),
    ".": (230, "M115 10 L115 11"),
    ",": (230, "M130 40 Q145 -70 75 -115"),
    ":": (230, "M115 370 L115 371 M115 10 L115 11"),
    ";": (230, "M115 370 L115 371 M130 40 Q145 -70 75 -115"),
    "!": (250, "M125 700 L125 205 M125 10 L125 11"),
    "?": (510, "M75 550 C75 765 450 765 450 550 C450 405 255 400 255 205 M255 10 L255 11"),
    "-": (360, "M65 285 L295 285"),
    "–": (540, "M65 285 L475 285"),
    "—": (790, "M65 285 L725 285"),
    "_": (540, "M65 -105 L475 -105"),
    "+": (550, "M75 300 L475 300 M275 100 L275 500"),
    "=": (550, "M75 200 L475 200 M75 400 L475 400"),
    "/": (450, "M65 -70 L385 740"),
    "\\": (450, "M65 740 L385 -70"),
    "(": (300, "M230 760 C40 570 40 130 230 -60"),
    ")": (300, "M70 760 C260 570 260 130 70 -60"),
    "[": (300, "M240 740 L100 740 L100 -50 L240 -50"),
    "]": (300, "M60 740 L200 740 L200 -50 L60 -50"),
    "{": (340, "M275 740 Q135 740 160 500 Q180 355 70 345 Q180 335 160 190 Q135 -50 275 -50"),
    "}": (340, "M65 740 Q205 740 180 500 Q160 355 270 345 Q160 335 180 190 Q205 -50 65 -50"),
    "'": (210, "M105 735 L95 565"),
    '"': (330, "M100 735 L90 565 M240 735 L230 565"),
    "‘": (210, "M135 760 Q65 705 95 610"),
    "’": (210, "M105 750 Q135 665 65 610"),
    "“": (340, "M135 760 Q65 705 95 610 M265 760 Q195 705 225 610"),
    "”": (340, "M105 750 Q135 665 65 610 M235 750 Q265 665 195 610"),
    "`": (250, "M85 765 L175 635"),
    "~": (550, "M70 295 C210 470 340 140 480 315"),
    "^": (500, "M80 470 L250 690 L420 470"),
    "<": (520, "M430 540 L80 300 L430 60"),
    ">": (520, "M90 540 L440 300 L90 60"),
    "|": (240, "M120 760 L120 -80"),
    "*": (430, "M215 650 L215 350 M75 560 L355 430 M75 430 L355 560"),
    "#": (620, "M220 720 L135 -20 M490 720 L405 -20 M75 225 L535 225 M105 485 L565 485"),
    "%": (730, "M115 0 L615 700 M190 700 C35 700 35 430 190 430 C345 430 345 700 190 700 M540 270 C385 270 385 0 540 0 C695 0 695 270 540 270"),
    "$": (590, "M510 595 C435 760 80 745 85 545 C90 320 515 410 515 180 C515 -60 145 -65 70 115 M295 790 L295 -95"),
    "&": (700, "M615 0 L170 475 C-60 775 510 800 390 555 C300 385 80 375 80 185 C80 -95 500 -85 620 310"),
    "@": (880, "M555 220 L555 480 M555 350 C555 590 280 565 280 340 C280 100 555 105 555 350 M555 480 L555 255 C555 70 790 150 790 390 C790 850 85 820 85 345 C85 -65 570 -145 735 20"),
    "·": (230, "M115 285 L115 286"),
    "•": (270, "M135 285 L135 286"),
    "…": (650, "M105 10 L105 11 M325 10 L325 11 M545 10 L545 11"),
    "×": (500, "M100 470 L400 120 M400 470 L100 120"),
    "÷": (500, "M65 295 L435 295 M250 490 L250 491 M250 100 L250 101"),
    "→": (750, "M70 310 L680 310 M485 505 L680 310 L485 115"),
    "←": (750, "M680 310 L70 310 M265 505 L70 310 L265 115"),
    "↑": (600, "M300 20 L300 650 M100 450 L300 650 L500 450"),
    "↓": (600, "M300 650 L300 20 M100 220 L300 20 L500 220"),
    "∞": (800, "M400 290 C85 720 -120 -100 400 290 C920 680 715 -140 400 290"),
    "✓": (600, "M70 295 L225 70 L535 550"),
    "★": (720, "M360 700 L445 435 L665 435 L495 280 L550 20 L360 170 L170 20 L225 280 L55 435 L275 435 L360 700"),
    "ß": (580, "M85 0 L85 535 C85 770 435 815 435 590 C435 475 335 425 300 385 C600 370 565 -45 300 10"),
    "æ": (830, "M420 490 L420 0 M420 255 C420 600 80 595 80 255 C80 -90 420 -85 420 255 M420 265 L750 265 C765 590 420 595 420 255 C420 -55 655 -70 755 85"),
    "Æ": (850, "M55 0 L345 700 L755 700 M345 700 L345 0 L770 0 M150 240 L345 240 M345 365 L680 365"),
    "ø": (570, "M285 515 C5 515 5 -5 285 -5 C565 -5 565 515 285 515 M75 -30 L490 545"),
    "Ø": (700, "M350 705 C-15 705 -15 -5 350 -5 C715 -5 715 705 350 705 M85 -30 L615 735"),
}


def paths(drawing):
    """Sample our small absolute M/L/Q/C drawing language into centrelines."""
    tokens = re.findall(r"[MLQC]|-?\d+(?:\.\d+)?", drawing)
    i, current, path = 0, (0, 0), []
    while i < len(tokens):
        command = tokens[i]
        count = {"M": 2, "L": 2, "Q": 4, "C": 6}[command]
        points = list(map(float, tokens[i + 1:i + 1 + count]))
        i += 1 + count
        end = tuple(points[-2:])
        if command == "M":
            if path:
                yield path
            path = [end]
        elif command == "L":
            path.append(end)
        else:
            start = current
            # 32 samples preserve soft curves even at heading sizes.
            for step in range(1, 33):
                t, u = step / 32, 1 - step / 32
                if command == "Q":
                    p = tuple(u*u*start[k] + 2*u*t*points[k] + t*t*end[k] for k in (0, 1))
                else:
                    p = tuple(u**3*start[k] + 3*u*u*t*points[k] + 3*u*t*t*points[k + 2] + t**3*end[k] for k in (0, 1))
                path.append(p)
        current = end
    if path:
        yield path


def glyph(drawing, weight):
    pen = TTGlyphPen(None)
    if not drawing:
        return pen.glyph()
    strokes = []
    for path in paths(drawing):
        radius = weight / 2
        if len(path) == 2 and math.dist(*path) <= 1.01:
            radius *= 1.16  # Dots stay visible at small screen sizes.
        strokes.append(LineString(path).buffer(radius, quad_segs=8))
    outline = unary_union(strokes).simplify(0.35, preserve_topology=True)
    polygons = [outline] if outline.geom_type == "Polygon" else list(outline.geoms)
    for polygon in polygons:
        # TrueType outer clockwise / counters anticlockwise.
        polygon = orient(polygon, sign=-1)
        for ring in [polygon.exterior, *polygon.interiors]:
            points = [(round(x), round(y)) for x, y in ring.coords[:-1]]
            pen.moveTo(points[0])
            for point in points[1:]:
                pen.lineTo(point)
            pen.closePath()
    return pen.glyph()


def build(style, weight):
    drawings = dict(DRAWINGS)
    drawings[" "] = (290, "")
    drawings["\u00a0"] = (290, "")
    # Original accent strokes over our original base letters, for common names.
    accents = {
        "acute": "M230 640 L345 770", "grave": "M205 770 L320 640",
        "circ": "M170 650 L275 765 L380 650", "dier": "M185 695 L185 696 M365 695 L365 696",
        "tilde": "M155 680 C235 800 315 620 395 725", "ring": "M275 640 C165 640 165 810 275 810 C385 810 385 640 275 640",
        "cedilla": "M275 -30 L235 -100 C405 -75 390 -215 225 -185",
    }
    import unicodedata
    for codepoint in range(0x00C0, 0x0250):
        character = chr(codepoint)
        decomposed = unicodedata.normalize("NFD", character)
        if len(decomposed) != 2 or decomposed[0] not in drawings:
            continue
        accent = {"\u0301": "acute", "\u0300": "grave", "\u0302": "circ", "\u0308": "dier", "\u0303": "tilde", "\u030a": "ring", "\u0327": "cedilla"}.get(decomposed[1])
        if accent:
            width, base = drawings[decomposed[0]]
            mark = accents[accent]
            # Uppercase accents sit above cap height, scaled ascender allows it.
            offset_y = 180 if decomposed[0].isupper() and accent != "cedilla" else 0
            offset_x = (width - 550) / 2
            mark_tokens = re.findall(r"[MLQC]|-?\d+", mark)
            coordinate_index = 0
            shifted = []
            for token in mark_tokens:
                if token in "MLQC":
                    shifted.append(token)
                    coordinate_index = 0
                else:
                    shifted.append(str(int(token) + round(offset_x if coordinate_index % 2 == 0 else offset_y)))
                    coordinate_index += 1
            drawings[character] = (width, base + " " + " ".join(shifted))
    names = {ord(c): "uni%04X" % ord(c) for c in drawings}
    order = [".notdef", *names.values()]
    glyphs = {".notdef": glyph("M80 0 L80 700 L490 700 L490 0 L80 0 M150 100 L420 600", weight)}
    metrics = {".notdef": (570, 40)}
    for c, (width, drawing) in drawings.items():
        name = names[ord(c)]
        glyphs[name] = glyph(drawing, weight)
        # Left bearing must match the actual outline origin for correct rasterising.
        metrics[name] = (width, glyphs[name].xMin if hasattr(glyphs[name], "xMin") else 0)
        if glyphs[name].numberOfContours:
            glyphs[name].recalcBounds(None)
            metrics[name] = (width, glyphs[name].xMin)
    builder = FontBuilder(UPM, isTTF=True)
    builder.setupGlyphOrder(order)
    builder.setupCharacterMap(names)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics(metrics)
    builder.setupHorizontalHeader(ascent=1040, descent=-270, lineGap=0)
    builder.setupNameTable({
        "familyName": "Mossgate", "styleName": style,
        "uniqueFontIdentifier": "IdleRPG:Mossgate:" + style + ":1.0",
        "fullName": "Mossgate " + style, "psName": "Mossgate-" + style,
        "version": "Version 1.000", "copyright": "Original letter drawings for Idle RPG, 2026. See FONT_LICENSE.md.",
        "description": "A warm rounded trail typeface drawn for Idle RPG. Original outlines, no source font.",
    })
    builder.setupOS2(sTypoAscender=1040, sTypoDescender=-270, sTypoLineGap=0,
                    usWinAscent=1040, usWinDescent=270, sxHeight=510, sCapHeight=700,
                    usWeightClass=400 if style == "Regular" else 600,
                    fsSelection=0x40 if style == "Regular" else 0)
    builder.setupPost()
    builder.setupMaxp()
    # Tabular figures keep health, currency and countdowns from wobbling.
    from fontTools.feaLib.builder import addOpenTypeFeaturesFromString
    pairs = {"AV": -40, "AW": -25, "AY": -35, "AT": -25, "TA": -25,
             "To": -35, "Ta": -35, "Te": -35, "Ty": -25, "Yo": -35,
             "Wa": -20, "Wo": -20, "Va": -30, "Vo": -30, "LT": -20}
    feature = "feature kern {\n" + "\n".join("pos %s %s %d;" % (names[ord(pair[0])], names[ord(pair[1])], amount) for pair, amount in pairs.items()) + "\n} kern;"
    addOpenTypeFeaturesFromString(builder.font, feature)
    # Fixed timestamps make rebuilds reproducible.
    builder.font["head"].created = builder.font["head"].modified = 3874262400
    builder.font.recalcTimestamp = False
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / ("Mossgate-" + style + ".ttf")
    builder.save(path)
    print("Built", path, "with", len(drawings), "characters")


if __name__ == "__main__":
    build("Regular", 76)
    build("Semibold", 94)
