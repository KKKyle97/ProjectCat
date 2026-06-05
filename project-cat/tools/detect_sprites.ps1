# Sprite-sheet frame detector for Cat & Hook.
# Reads sprites_cat.png, finds frame bounding boxes via white-gap projection,
# and writes a debug overlay (boxes drawn in red) so detection can be verified
# before any repack. No destructive changes to the source.
#
# Method:
#   1. LockBits -> byte[] (fast whole-image read).
#   2. Build a per-pixel "is content" mask (non-near-white, opaque).
#   3. Horizontal projection -> row bands (gaps of >= ROW_GAP empty rows split).
#   4. Per band, vertical projection -> frame columns (gaps of >= COL_GAP split).
#   5. Drop the left label column and tiny specks via MIN_W / MIN_H / LEFT_MARGIN.
#   6. Draw boxes onto a copy and save *_debug.png; also dump boxes to console.

param(
    [string]$Src = "E:\ProjectCat\project-cat\sprites\sprites_cat.png",
    [int]$WhiteThreshold = 236,  # R,G,B all above this = background
    [int]$RowGap = 16,           # blank rows needed to end a row band
    [int]$ColGap = 14,           # blank cols needed to split frames in a band
    [int]$MinW = 24,             # discard boxes narrower than this (specks/text)
    [int]$MinH = 24,             # discard boxes shorter than this
    [int]$LeftMargin = 200       # ignore content left of this x (row labels)
)

Add-Type -AssemblyName System.Drawing

$bmp = [System.Drawing.Bitmap]::FromFile($Src)
$W = $bmp.Width
$H = $bmp.Height

# --- Fast read: lock all pixels into a byte array (BGRA, 4 bytes/px) ---
$rect = New-Object System.Drawing.Rectangle 0, 0, $W, $H
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$bytes = New-Object byte[] ($stride * $H)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
$bmp.UnlockBits($data)

# --- Build content mask as a 2D bool via flat array ---
# mask[y*W + x] = $true when pixel is opaque and not near-white.
$mask = New-Object bool[] ($W * $H)
for ($y = 0; $y -lt $H; $y++) {
    $rowBase = $y * $stride
    $mBase = $y * $W
    for ($x = 0; $x -lt $W; $x++) {
        $i = $rowBase + $x * 4
        $b = $bytes[$i]; $g = $bytes[$i + 1]; $r = $bytes[$i + 2]; $a = $bytes[$i + 3]
        if ($a -gt 16 -and -not ($r -ge $WhiteThreshold -and $g -ge $WhiteThreshold -and $b -ge $WhiteThreshold)) {
            $mask[$mBase + $x] = $true
        }
    }
}

# --- Horizontal projection: rows that contain any content (x >= LeftMargin) ---
$rowHas = New-Object bool[] $H
for ($y = 0; $y -lt $H; $y++) {
    $mBase = $y * $W
    for ($x = $LeftMargin; $x -lt $W; $x++) {
        if ($mask[$mBase + $x]) { $rowHas[$y] = $true; break }
    }
}

# Collapse into row bands separated by >= RowGap empty rows.
$bands = @()
$inBand = $false; $bandStart = 0; $gap = 0
for ($y = 0; $y -lt $H; $y++) {
    if ($rowHas[$y]) {
        if (-not $inBand) { $bandStart = $y; $inBand = $true }
        $gap = 0
    } else {
        if ($inBand) {
            $gap++
            if ($gap -ge $RowGap) {
                $bands += , @($bandStart, ($y - $gap))
                $inBand = $false
            }
        }
    }
}
if ($inBand) { $bands += , @($bandStart, ($H - 1)) }

# --- Per band: vertical projection -> frame column clusters ---
$boxes = @()
foreach ($band in $bands) {
    $by0 = $band[0]; $by1 = $band[1]
    $colHas = New-Object bool[] $W
    for ($x = $LeftMargin; $x -lt $W; $x++) {
        for ($y = $by0; $y -le $by1; $y++) {
            if ($mask[$y * $W + $x]) { $colHas[$x] = $true; break }
        }
    }
    $inCol = $false; $cStart = 0; $cgap = 0
    $cols = @()
    for ($x = $LeftMargin; $x -lt $W; $x++) {
        if ($colHas[$x]) {
            if (-not $inCol) { $cStart = $x; $inCol = $true }
            $cgap = 0
        } else {
            if ($inCol) {
                $cgap++
                if ($cgap -ge $ColGap) { $cols += , @($cStart, ($x - $cgap)); $inCol = $false }
            }
        }
    }
    if ($inCol) { $cols += , @($cStart, ($W - 1)) }

    # Tighten each column cluster to its exact content bbox (top/bottom within band).
    foreach ($c in $cols) {
        $cx0 = $c[0]; $cx1 = $c[1]
        $ty = $by1; $by = $by0; $lx = $cx1; $rx = $cx0
        for ($y = $by0; $y -le $by1; $y++) {
            for ($x = $cx0; $x -le $cx1; $x++) {
                if ($mask[$y * $W + $x]) {
                    if ($y -lt $ty) { $ty = $y }
                    if ($y -gt $by) { $by = $y }
                    if ($x -lt $lx) { $lx = $x }
                    if ($x -gt $rx) { $rx = $x }
                }
            }
        }
        $bw = $rx - $lx + 1; $bh = $by - $ty + 1
        if ($bw -ge $MinW -and $bh -ge $MinH) {
            $boxes += , @($lx, $ty, $bw, $bh)
        }
    }
}

# --- Report ---
Write-Output "Sheet: $W x $H"
Write-Output "Row bands found: $($bands.Count)"
$bi = 0
foreach ($band in $bands) { Write-Output ("  band {0}: y {1}..{2}" -f $bi++, $band[0], $band[1]) }
Write-Output "Boxes found: $($boxes.Count)"
$idx = 0
foreach ($bx in $boxes) {
    Write-Output ("  box {0}: x={1} y={2} w={3} h={4}" -f $idx++, $bx[0], $bx[1], $bx[2], $bx[3])
}

# --- Debug overlay ---
$dbg = [System.Drawing.Bitmap]::FromFile($Src)
$gfx = [System.Drawing.Graphics]::FromImage($dbg)
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Red), 3
$font = New-Object System.Drawing.Font "Arial", 18
$brush = [System.Drawing.Brushes]::Red
$idx = 0
foreach ($bx in $boxes) {
    $gfx.DrawRectangle($pen, $bx[0], $bx[1], $bx[2], $bx[3])
    $gfx.DrawString("$idx", $font, $brush, $bx[0], [Math]::Max(0, $bx[1] - 24))
    $idx++
}
$gfx.Dispose()
$out = "E:\ProjectCat\project-cat\tools\sprites_cat_debug.png"
$dbg.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$dbg.Dispose()
Write-Output "Debug overlay written: $out"
