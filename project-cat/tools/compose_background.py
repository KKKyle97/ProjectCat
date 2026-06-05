"""
Composes a 360x480 pond backdrop for the Backyard Pond level from the
prototype env tileset. Layout (top -> bottom):
  rows 0-1 : grass bank   (cat sits here)
  row  2   : shoreline     (grass top / water bottom)
  row  3   : open water    (bobber drops to y~300)
Output: sprites/background_backyard_pond.png
"""
from PIL import Image
import numpy as np

SRC = r"E:\ProjectCat\project-cat\sprites\sprites_prototype_env.png"
OUT = r"E:\ProjectCat\project-cat\sprites\background_backyard_pond.png"

img = Image.open(SRC).convert("RGBA")
arr = np.array(img)

cols = {"C0": (72, 263)}
rows = {"R0": (100, 258), "R1": (316, 476), "R2": (538, 711)}

INSET = 10  # crop dark cell border for seamless tiling

def tile(rkey, ckey):
    y0, y1 = rows[rkey]; x0, x1 = cols[ckey]
    cell = arr[y0+INSET:y1+1-INSET, x0+INSET:x1+1-INSET]
    return Image.fromarray(cell)

grass     = tile("R0", "C0")
water     = tile("R1", "C0")
shoreline = tile("R2", "C0")  # grass top, water bottom

W, H = 360, 480

# Full-width horizontal bands -> no vertical seams. (y_start, height, tile)
bands = [
    (0,   225, grass),      # grassy bank
    (225,  90, shoreline),  # waterline (grass top / water bottom)
    (315, 165, water),      # open pond (bobber rests at y~300)
]

canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for y0, bh, src in bands:
    strip = src.resize((W, bh), Image.NEAREST)
    canvas.paste(strip, (0, y0))

canvas.save(OUT)
print(f"Saved {OUT}  ({W}x{H})")
