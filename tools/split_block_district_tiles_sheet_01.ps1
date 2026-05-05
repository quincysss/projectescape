Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$source = "C:\Users\Administrator\.codex\generated_images\019de737-3b52-74d0-8b05-5c7ee6e3db26\ig_0599fd167dd062d70169f9c32cef0c8190a1e92a0a3981c5dd.png"

$blocksRoot = Join-Path $root "assets\map\blocks"
$sheetDir = Join-Path $blocksRoot "sheets"
$fillDir = Join-Path $blocksRoot "fill"
$edgeDir = Join-Path $blocksRoot "edge"
$cutDir = Join-Path $blocksRoot "cut"
$overlayDir = Join-Path $blocksRoot "overlay"
$guideDir = Join-Path $blocksRoot "guides"

foreach ($dir in @($blocksRoot, $sheetDir, $fillDir, $edgeDir, $cutDir, $overlayDir, $guideDir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$sheetPath = Join-Path $sheetDir "block_district_tiles_sheet_01.png"
$previewPath = Join-Path $guideDir "block_district_tiles_sheet_01_split_preview.png"
$manifestPath = Join-Path $blocksRoot "block_district_tiles_sheet_01_manifest.json"

Copy-Item -LiteralPath $source -Destination $sheetPath -Force

function New-Rect([int]$x, [int]$y, [int]$w, [int]$h) {
    return New-Object System.Drawing.Rectangle $x, $y, $w, $h
}

function Resize-Crop([System.Drawing.Image]$image, [System.Drawing.Rectangle]$srcRect, [string]$outPath, [bool]$transparentOverlay) {
    $tile = New-Object System.Drawing.Bitmap 256, 256, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($tile)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.DrawImage($image, (New-Rect 0 0 256 256), $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()

    if ($transparentOverlay) {
        # The generated overlay tile uses a dark preview plate. Convert that plate
        # to alpha while preserving high-contrast crack, stain, weed and drain marks.
        $bgR = 38; $bgG = 38; $bgB = 36
        for ($y = 0; $y -lt 256; $y++) {
            for ($x = 0; $x -lt 256; $x++) {
                $p = $tile.GetPixel($x, $y)
                $dist = [Math]::Abs($p.R - $bgR) + [Math]::Abs($p.G - $bgG) + [Math]::Abs($p.B - $bgB)
                $alpha = [Math]::Max(0, [Math]::Min(255, ($dist - 24) * 5))
                if ($alpha -lt 18) { $alpha = 0 }
                $tile.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $p.R, $p.G, $p.B))
            }
        }
    }

    $tile.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $tile.Dispose()
}

$sourceImage = [System.Drawing.Image]::FromFile($sheetPath)

$cellW = [Math]::Floor($sourceImage.Width / 3)
$cellH = [Math]::Floor($sourceImage.Height / 3)
$padX = [Math]::Max(6, [Math]::Floor($cellW * 0.045))
$padY = [Math]::Max(6, [Math]::Floor($cellH * 0.045))

$tiles = @(
    @{ id="block_fill_clean_01"; file="fill\block_fill_clean_01.png"; row=0; col=0; category="fill"; role="seamless clean concrete block fill"; alpha=$false },
    @{ id="block_fill_cracked_01"; file="fill\block_fill_cracked_01.png"; row=0; col=1; category="fill"; role="seamless cracked concrete block fill"; alpha=$false },
    @{ id="block_fill_dirty_01"; file="fill\block_fill_dirty_01.png"; row=0; col=2; category="fill"; role="seamless dirty concrete block fill"; alpha=$false },
    @{ id="block_edge_straight_01"; file="edge\block_edge_straight_01.png"; row=1; col=0; category="edge"; role="straight curb edge"; alpha=$false },
    @{ id="block_corner_outer_01"; file="edge\block_corner_outer_01.png"; row=1; col=1; category="edge"; role="outer curb corner"; alpha=$false },
    @{ id="block_corner_inner_01"; file="edge\block_corner_inner_01.png"; row=1; col=2; category="edge"; role="inner concave curb corner"; alpha=$false },
    @{ id="block_alley_cut_01"; file="cut\block_alley_cut_01.png"; row=2; col=0; category="cut"; role="alley cut or notch"; alpha=$false },
    @{ id="block_driveway_cut_01"; file="cut\block_driveway_cut_01.png"; row=2; col=1; category="cut"; role="driveway or entrance cut"; alpha=$false },
    @{ id="block_decal_cracks_01"; file="overlay\block_decal_cracks_01.png"; row=2; col=2; category="overlay"; role="transparent crack stain weed drain overlay"; alpha=$true }
)

$manifestAssets = @()
foreach ($t in $tiles) {
    $x = [int]($t.col * $cellW + $padX)
    $y = [int]($t.row * $cellH + $padY)
    $w = [int]($cellW - 2 * $padX)
    $h = [int]($cellH - 2 * $padY)
    $srcRect = New-Rect $x $y $w $h
    $outPath = Join-Path $blocksRoot $t.file
    Resize-Crop $sourceImage $srcRect $outPath ([bool]$t.alpha)
    $manifestAssets += [ordered]@{
        id = $t.id
        file = ("assets/map/blocks/" + $t.file.Replace("\", "/"))
        category = $t.category
        role = $t.role
        tile_size_px = 256
        source_box_xywh = @($x, $y, $w, $h)
        output_has_alpha = [bool]$t.alpha
    }
}

# Build a visual audit preview from the final sliced tiles.
$preview = New-Object System.Drawing.Bitmap 816, 876, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$pg = [System.Drawing.Graphics]::FromImage($preview)
$pg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$pg.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$bg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 30, 31, 31))
$fg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 235, 235, 225))
$font = New-Object System.Drawing.Font("Microsoft YaHei", 13, [System.Drawing.FontStyle]::Bold)
$pg.FillRectangle($bg, 0, 0, 816, 876)

foreach ($t in $tiles) {
    $img = [System.Drawing.Image]::FromFile((Join-Path $blocksRoot $t.file))
    $dx = 20 + $t.col * 268
    $dy = 20 + $t.row * 286
    $pg.DrawImage($img, $dx, $dy, 256, 256)
    $pg.DrawRectangle((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 210, 210, 190)), 2), $dx, $dy, 256, 256)
    $pg.DrawString($t.id, $font, $fg, $dx, $dy + 260)
    $img.Dispose()
}

$preview.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
$pg.Dispose()
$preview.Dispose()
$sourceImage.Dispose()

$manifest = [ordered]@{
    source_sheet = "assets/map/blocks/sheets/block_district_tiles_sheet_01.png"
    generated_source = $source
    spec_doc = "Doc/17_美术资源规格与GPT生图提示词规范_修订版_废土生存法则.md section 5.1.1"
    note = "Block district foundation tiles. Fill tiles and edge/corner/cut tiles are 256x256. Overlay tile is exported with alpha."
    assets = $manifestAssets
}

$manifest | ConvertTo-Json -Depth 8 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Output $sheetPath
Write-Output $previewPath
Write-Output $manifestPath
