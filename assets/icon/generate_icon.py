"""Generates the app launcher icon: a network-splitting into three motif
(one node branching into three), representing subnetting/VLSM.
Produces:
  - icon.png            : full icon (background + glyph), for iOS/web/legacy Android
  - icon_foreground.png : glyph only, transparent bg, sized for Android adaptive icons
"""

from PIL import Image, ImageDraw

CANVAS = 1024
INDIGO = (63, 81, 181, 255)  # Material Colors.indigo
WHITE = (255, 255, 255, 255)


def draw_tree(draw, top, children, line_width, node_radius):
    tx, ty = top
    # Lines first so node circles cleanly cover the joints.
    for cx, cy in children:
        draw.line([tx, ty, cx, cy], fill=WHITE, width=line_width)
    for cx, cy in children:
        draw.ellipse(
            [cx - node_radius, cy - node_radius, cx + node_radius, cy + node_radius],
            fill=WHITE,
        )
    draw.ellipse(
        [tx - node_radius * 1.15, ty - node_radius * 1.15, tx + node_radius * 1.15, ty + node_radius * 1.15],
        fill=WHITE,
    )


def make_full_icon():
    img = Image.new("RGBA", (CANVAS, CANVAS), INDIGO)
    draw = ImageDraw.Draw(img)
    top = (CANVAS / 2, 300)
    children = [(266, 760), (512, 810), (758, 760)]
    draw_tree(draw, top, children, line_width=46, node_radius=82)
    img.save("icon.png")


def make_adaptive_foreground():
    img = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Adaptive icon safe zone is the center ~66% of the canvas; keep the glyph
    # inside that so it survives circle/squircle/square masks.
    top = (CANVAS / 2, 360)
    children = [(340, 700), (512, 740), (684, 700)]
    draw_tree(draw, top, children, line_width=34, node_radius=60)
    img.save("icon_foreground.png")


if __name__ == "__main__":
    make_full_icon()
    make_adaptive_foreground()
    print("done")
