# Repacks the messy AI cat sheet into clean, individual, transparent frame PNGs.
#
# For each kept box: crop from source, make near-white transparent, trim to the
# content bbox, then center it (horizontally centered, bottom-aligned) on a
# uniform transparent canvas. Output goes to sprites/cat/<anim>_<i>.png so the
# frames can be dragged straight into a Godot SpriteFrames resource -- no grid
# slicing required.
#
# EDIT THIS MAPPING to correct any mis-detected frame: each entry is the box
# index from detect_sprites.ps1. Drop FX boxes (fish/splash/z-bubbles) here.

$Anim = @{
    idle  = @(0, 1, 2, 3)
    cast  = @(4, 5, 6, 7)
    tug   = @(8, 9, 10)
    catch = @(11, 12, 13)      # 14=fish, 15=splash dropped
    sleep = @(16, 19)          # 17/18=z-bubble noise, 20=dup dropped
}

# Box table (x, y, w, h) from detect_sprites.ps1 output.
$Boxes = @(
    @(253, 59, 132, 164),   @(472, 59, 130, 164),   @(692, 59, 131, 164),   @(911, 59, 131, 164),
    @(247, 302, 159, 193),  @(448, 320, 215, 149),  @(692, 305, 215, 164),  @(911, 306, 243, 190),
    @(247, 523, 204, 181),  @(534, 536, 164, 171),  @(775, 527, 176, 185),
    @(247, 731, 204, 193),  @(472, 744, 131, 180),  @(704, 744, 204, 180),  @(964, 752, 78, 139),  @(1117, 775, 37, 53),
    @(247, 968, 205, 110),  @(534, 1008, 170, 185), @(534, 968, 145, 40),   @(775, 968, 205, 110), @(775, 968, 205, 110)
)

$Src = "E:\ProjectCat\project-cat\sprites\sprites_cat.png"
$OutDir = "E:\ProjectCat\project-cat\sprites\cat"
$WhiteThreshold = 236
$CanvasW = 256
$CanvasH = 208
$PadBottom = 8

Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$src = [System.Drawing.Bitmap]::FromFile($Src)

function Export-Frame($box, $outPath) {
    $bx = $box[0]; $by = $box[1]; $bw = $box[2]; $bh = $box[3]

    # 1. Crop the box region into a 32bpp ARGB working bitmap.
    $work = New-Object System.Drawing.Bitmap $bw, $bh, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($work)
    $dst = New-Object System.Drawing.Rectangle 0, 0, $bw, $bh
    $srcR = New-Object System.Drawing.Rectangle $bx, $by, $bw, $bh
    $g.DrawImage($src, $dst, $srcR, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()

    # 2. White -> transparent + find tight content bbox (LockBits for speed).
    $rect = New-Object System.Drawing.Rectangle 0, 0, $bw, $bh
    $d = $work.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $d.Stride
    $buf = New-Object byte[] ($stride * $bh)
    [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $buf, 0, $buf.Length)
    $minX = $bw; $minY = $bh; $maxX = -1; $maxY = -1
    for ($y = 0; $y -lt $bh; $y++) {
        $rb = $y * $stride
        for ($x = 0; $x -lt $bw; $x++) {
            $i = $rb + $x * 4
            $bl = $buf[$i]; $gr = $buf[$i + 1]; $re = $buf[$i + 2]
            if ($re -ge $WhiteThreshold -and $gr -ge $WhiteThreshold -and $bl -ge $WhiteThreshold) {
                $buf[$i + 3] = 0   # make white transparent
            } else {
                if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $d.Scan0, $buf.Length)
    $work.UnlockBits($d)

    if ($maxX -lt 0) { $work.Dispose(); return }  # nothing left
    $cw = $maxX - $minX + 1; $ch = $maxY - $minY + 1

    # 3. Compose onto the uniform canvas: h-centered, bottom-aligned.
    $canvas = New-Object System.Drawing.Bitmap $CanvasW, $CanvasH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $cg = [System.Drawing.Graphics]::FromImage($canvas)
    $cg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $cg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $px = [int](($CanvasW - $cw) / 2)
    $py = $CanvasH - $PadBottom - $ch
    if ($py -lt 0) { $py = 0 }
    $srcTrim = New-Object System.Drawing.Rectangle $minX, $minY, $cw, $ch
    $dstTrim = New-Object System.Drawing.Rectangle $px, $py, $cw, $ch
    $cg.DrawImage($work, $dstTrim, $srcTrim, [System.Drawing.GraphicsUnit]::Pixel)
    $cg.Dispose()
    $work.Dispose()

    $canvas.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
}

$total = 0
foreach ($anim in $Anim.Keys) {
    $i = 0
    foreach ($boxIdx in $Anim[$anim]) {
        $out = Join-Path $OutDir ("{0}_{1}.png" -f $anim, $i)
        Export-Frame $Boxes[$boxIdx] $out
        Write-Output ("  {0}_{1}.png  <- box {2}" -f $anim, $i, $boxIdx)
        $i++; $total++
    }
}
$src.Dispose()
Write-Output "Done. $total frames written to $OutDir (canvas ${CanvasW}x${CanvasH})."
