"""
Extracts clean, uniform-padded animation frames from sprites_cat.png.
Outputs individual PNGs to sprites/frames/<anim>/<anim>_<NN>.png
"""
from PIL import Image
import numpy as np
import os, math

SHEET = r"E:\ProjectCat\project-cat\sprites\sprites_cat.png"
OUT_ROOT = r"E:\ProjectCat\project-cat\sprites\frames"

# (x0, y0, x1, y1) cell regions in the full 1254x1254 sheet
FRAMES = {
    "idle": [
        (249,  54, 402, 212),
        (472,  54, 624, 212),
        (695,  54, 847, 212),
        (914,  54,1065, 212),
    ],
    "cast": [
        (234, 276, 406, 437),
        (446, 276, 690, 437),
        (691, 276, 935, 437),
        (936, 276,1182, 437),
    ],
    "tug": [
        (247, 500, 473, 655),
        (507, 500, 703, 655),
        (750, 500, 957, 655),
    ],
    "catch": [
        (250, 706, 456, 896),
        (480, 706, 611, 896),
        (662, 706, 899, 896),  # cat + flying fish in same frame
        (921, 706,1068, 896),
    ],
    "sleep": [
        (250, 955, 386,1119),
        (457, 950, 597,1119),
        (659, 950, 821,1122),
    ],
}

ITEMS = {
    "bucket": (985,1076,1089,1191),
    "bobber": (1138,1111,1174,1169),
}

PADDING = 8  # pixels added to each side beyond tight content bounds


def make_transparent(arr):
    """Remove near-pure-white background pixels. R,G,B all >=248 -> alpha=0."""
    result = arr.copy()
    bg = (arr[:,:,0] >= 248) & (arr[:,:,1] >= 248) & (arr[:,:,2] >= 248)
    result[bg, 3] = 0
    return result


def tight_crop(arr):
    """Return (x0,y0,x1,y1) bounding box of non-transparent pixels."""
    alpha = arr[:,:,3]
    rows = np.where(alpha.any(axis=1))[0]
    cols = np.where(alpha.any(axis=0))[0]
    if not len(rows) or not len(cols):
        return None
    return int(cols.min()), int(rows.min()), int(cols.max()), int(rows.max())


def extract_cell(sheet_arr, x0, y0, x1, y1):
    """Crop cell, make transparent, return tight-cropped array."""
    cell = sheet_arr[y0:y1+1, x0:x1+1].copy()
    cell = make_transparent(cell)
    bounds = tight_crop(cell)
    if bounds is None:
        return None, (0, 0, x1-x0, y1-y0)
    cx0, cy0, cx1, cy1 = bounds
    return cell[cy0:cy1+1, cx0:cx1+1], bounds


def pad_to_size(arr, target_w, target_h):
    """Center horizontally, bottom-align vertically onto transparent canvas."""
    canvas = np.zeros((target_h, target_w, 4), dtype=np.uint8)
    h, w = arr.shape[:2]
    x_off = (target_w - w) // 2
    y_off = target_h - h  # bottom-align
    canvas[y_off:y_off+h, x_off:x_off+w] = arr
    return canvas


def next_multiple(n, m):
    return int(math.ceil(n / m)) * m


# ── Load sheet ──────────────────────────────────────────────────────────────
sheet = Image.open(SHEET).convert("RGBA")
sheet_arr = np.array(sheet)

summary = []

# ── Extract animation frames ─────────────────────────────────────────────────
for anim, cells in FRAMES.items():
    out_dir = os.path.join(OUT_ROOT, anim)
    os.makedirs(out_dir, exist_ok=True)

    crops = []
    for (x0, y0, x1, y1) in cells:
        cropped, _ = extract_cell(sheet_arr, x0, y0, x1, y1)
        crops.append(cropped)

    # Uniform padded size for this animation (multiple of 4, plus padding)
    max_w = max(c.shape[1] for c in crops if c is not None)
    max_h = max(c.shape[0] for c in crops if c is not None)
    pad_w = next_multiple(max_w + PADDING * 2, 4)
    pad_h = next_multiple(max_h + PADDING * 2, 4)

    for i, crop in enumerate(crops):
        if crop is None:
            print(f"  WARNING: {anim}_{i:02d} had no content")
            continue
        padded = pad_to_size(crop, pad_w, pad_h)
        out_path = os.path.join(out_dir, f"{anim}_{i:02d}.png")
        Image.fromarray(padded).save(out_path)
        summary.append(f"  {anim}_{i:02d}.png  {pad_w}x{pad_h}")

    print(f"{anim}: {len(crops)} frames  cell={pad_w}x{pad_h}  -> {out_dir}")

# ── Extract items ────────────────────────────────────────────────────────────
items_dir = os.path.join(OUT_ROOT, "items")
os.makedirs(items_dir, exist_ok=True)

for name, (x0, y0, x1, y1) in ITEMS.items():
    crop, _ = extract_cell(sheet_arr, x0, y0, x1, y1)
    if crop is None:
        print(f"  WARNING: item {name} had no content")
        continue
    out_path = os.path.join(items_dir, f"{name}.png")
    Image.fromarray(crop).save(out_path)
    h, w = crop.shape[:2]
    print(f"item {name}: {w}x{h}  -> {out_path}")

print("\nDone.")
