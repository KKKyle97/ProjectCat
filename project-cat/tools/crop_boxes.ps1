# Crops each detected box to its own PNG for visual verification.
# Boxes are hard-coded from detect_sprites.ps1 output so we can eyeball each
# frame and decide which are real animation frames vs. detached FX (fish,
# splash, z-bubbles, dangling bobber).

Add-Type -AssemblyName System.Drawing

$Src = "E:\ProjectCat\project-cat\sprites\sprites_cat.png"
$OutDir = "E:\ProjectCat\project-cat\tools\boxes"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# box: x, y, w, h   (from detector output)
$boxes = @(
    @(253, 59, 132, 164),    # 0  band0 IDLE
    @(472, 59, 130, 164),    # 1
    @(692, 59, 131, 164),    # 2
    @(911, 59, 131, 164),    # 3
    @(247, 302, 159, 193),   # 4  band1 CAST
    @(448, 320, 215, 149),   # 5
    @(692, 305, 215, 164),   # 6
    @(911, 306, 243, 190),   # 7
    @(247, 523, 204, 181),   # 8  band2 TUG
    @(534, 536, 164, 171),   # 9
    @(775, 527, 176, 185),   # 10
    @(247, 731, 204, 193),   # 11 band3 CATCH
    @(472, 744, 131, 180),   # 12
    @(704, 744, 204, 180),   # 13
    @(964, 752, 78, 139),    # 14
    @(1117, 775, 37, 53),    # 15
    @(247, 968, 205, 110),   # 16 band4 SLEEP
    @(534, 1008, 170, 185),  # 17
    @(534, 968, 145, 40),    # 18
    @(775, 968, 205, 110),   # 19
    @(775, 968, 205, 110)    # 20 (dup-ish; will inspect)
)

$src = [System.Drawing.Bitmap]::FromFile($Src)
$i = 0
foreach ($b in $boxes) {
    $rect = New-Object System.Drawing.Rectangle $b[0], $b[1], $b[2], $b[3]
    $crop = $src.Clone($rect, $src.PixelFormat)
    $crop.Save((Join-Path $OutDir ("box_{0:D2}.png" -f $i)), [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
    $i++
}
$src.Dispose()
Write-Output "Wrote $i crops to $OutDir"
