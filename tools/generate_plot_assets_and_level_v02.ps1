Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$plotDir = Join-Path $root "assets\map\plots"
$conceptDir = Join-Path $root "assets\map\_concept"
$layoutPath = Join-Path $conceptDir "town_level_concept_v01_layout.json"
$outPng = Join-Path $conceptDir "town_level_art_concept_v02_plots_annotated.png"
$outJson = Join-Path $conceptDir "town_level_concept_v02_plots_layout.json"

New-Item -ItemType Directory -Force -Path $plotDir | Out-Null

function C([int]$a, [int]$r, [int]$g, [int]$b) { return [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }
function Brush([int]$a, [int]$r, [int]$g, [int]$b) { return New-Object System.Drawing.SolidBrush (C $a $r $g $b) }
function PenC([int]$a, [int]$r, [int]$g, [int]$b, [float]$w) { return New-Object System.Drawing.Pen (C $a $r $g $b), $w }

function Save-PlotTile([string]$name, [int]$w, [int]$h, [string]$variant) {
    $path = Join-Path $plotDir $name
    $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $base = Brush 255 171 174 169
    $alt = Brush 255 186 188 183
    $line = PenC 95 230 232 226 1
    $edge = PenC 245 20 22 24 4
    $inner = PenC 120 245 245 238 2
    $g.FillRectangle($base, 0, 0, $w, $h)
    for ($x=0; $x -le $w; $x += 32) { $g.DrawLine($line, $x, 0, $x, $h) }
    for ($y=0; $y -le $h; $y += 32) { $g.DrawLine($line, 0, $y, $w, $y) }
    if ($variant -eq "corner") {
        $g.FillRectangle($alt, [int]($w*0.58), 0, [int]($w*0.42), [int]($h*0.42))
        $g.DrawLine($inner, [int]($w*0.58), 0, [int]($w*0.58), [int]($h*0.42))
        $g.DrawLine($inner, [int]($w*0.58), [int]($h*0.42), $w, [int]($h*0.42))
    } elseif ($variant -eq "lot_lines") {
        $g.DrawLine($inner, [int]($w*0.5), 0, [int]($w*0.5), $h)
        $g.DrawLine($inner, 0, [int]($h*0.5), $w, [int]($h*0.5))
    } elseif ($variant -eq "yard") {
        $yard = Brush 255 145 154 144
        $g.FillRectangle($yard, 12, 12, [Math]::Max(4, $w-24), [Math]::Max(4, $h-24))
        $g.DrawRectangle($inner, 12, 12, [Math]::Max(4, $w-24), [Math]::Max(4, $h-24))
    }
    $g.DrawRectangle($edge, 2, 2, $w - 4, $h - 4)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

Save-PlotTile "plot_block_gray_rect_16x12_01.png" 512 384 "lot_lines"
Save-PlotTile "plot_block_gray_rect_22x16_01.png" 704 512 "lot_lines"
Save-PlotTile "plot_block_gray_rect_28x18_01.png" 896 576 "corner"
Save-PlotTile "plot_block_gray_square_14x14_01.png" 448 448 "yard"
Save-PlotTile "plot_block_gray_large_36x24_01.png" 1152 768 "lot_lines"
Save-PlotTile "plot_block_gray_strip_28x10_01.png" 896 320 "corner"

if (!(Test-Path $layoutPath)) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root "tools\generate_level_concept_v01.ps1") | Out-Null
}
$layout = Get-Content $layoutPath -Raw | ConvertFrom-Json

$scale = 6
$mapW = [int]$layout.map_units.width
$mapH = [int]$layout.map_units.height
$margin = 48
$legendW = 620
$canvasW = $margin * 2 + $mapW * $scale + $legendW
$canvasH = $margin * 2 + $mapH * $scale

function PX([double]$u) { return [int][Math]::Round($margin + $u * $scale) }
function PY([double]$u) { return [int][Math]::Round($margin + $u * $scale) }
function SZ([double]$u) { return [int][Math]::Round($u * $scale) }

$images = @{}
function Img([string]$rel) {
    $path = Join-Path $root $rel
    if (!$images.ContainsKey($path)) {
        if (!(Test-Path $path)) { throw "Missing image asset: $rel" }
        $images[$path] = [System.Drawing.Image]::FromFile((Resolve-Path $path))
    }
    return $images[$path]
}
function Draw-Asset($g, $img, [double]$x, [double]$y, [double]$w, [double]$h) {
    $rect = New-Object System.Drawing.Rectangle (PX $x), (PY $y), (SZ $w), (SZ $h)
    $g.DrawImage($img, $rect)
}
function Draw-Asset-Centered($g, $img, [double]$cx, [double]$cy, [double]$w, [double]$h) {
    Draw-Asset $g $img ($cx - $w / 2.0) ($cy - $h / 2.0) $w $h
}
function Draw-Label($g, [string]$text, [double]$x, [double]$y, $font, $fg) {
    $px = PX $x
    $py = PY $y
    $bg = Brush 190 8 9 10
    $size = $g.MeasureString($text, $font)
    $g.FillRectangle($bg, $px - 2, $py - 1, [int]$size.Width + 5, [int]$size.Height + 3)
    $g.DrawString($text, $font, $fg, $px, $py)
}

$bmp = New-Object System.Drawing.Bitmap $canvasW, $canvasH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

$fontTiny = New-Object System.Drawing.Font("Microsoft YaHei", 7, [System.Drawing.FontStyle]::Regular)
$fontSmall = New-Object System.Drawing.Font("Microsoft YaHei", 10, [System.Drawing.FontStyle]::Regular)
$fontBold = New-Object System.Drawing.Font("Microsoft YaHei", 15, [System.Drawing.FontStyle]::Bold)
$fontTitle = New-Object System.Drawing.Font("Microsoft YaHei", 24, [System.Drawing.FontStyle]::Bold)

$bg = Brush 255 34 35 33
$ground = Brush 255 152 154 149
$white = Brush 255 246 244 228
$muted = Brush 255 205 203 190
$yellow = Brush 255 247 210 95
$blue = Brush 255 94 166 246
$purple = Brush 255 178 108 244
$red = Brush 255 238 76 76
$safeFill = Brush 70 255 220 92
$outpostFill = Brush 55 95 170 255
$roadPen = PenC 160 238 236 220 1
$plotPen = PenC 245 20 22 24 3
$buildingPen = PenC 235 255 72 72 2
$homePen = PenC 235 255 218 75 2
$outpostPen = PenC 235 95 170 255 2
$gridPen = PenC 34 80 82 80 1
$gridMajorPen = PenC 58 90 92 90 1
$borderPen = PenC 230 235 235 220 3

$g.FillRectangle($bg, 0, 0, $canvasW, $canvasH)
$mapRect = New-Object System.Drawing.Rectangle $margin, $margin, ($mapW * $scale), ($mapH * $scale)
$g.FillRectangle($ground, $mapRect)
for ($x = 0; $x -le $mapW; $x += 10) {
    $g.DrawLine($(if ($x % 50 -eq 0) { $gridMajorPen } else { $gridPen }), (PX $x), (PY 0), (PX $x), (PY $mapH))
}
for ($y = 0; $y -le $mapH; $y += 10) {
    $g.DrawLine($(if ($y % 50 -eq 0) { $gridMajorPen } else { $gridPen }), (PX 0), (PY $y), (PX $mapW), (PY $y))
}

$homeCenter = $layout.home_center_units
foreach ($r in @(20, 60, 100, 130)) {
    $ringPen = PenC 42 90 70 150 2
    $g.DrawEllipse($ringPen, (PX ($homeCenter.x - $r)), (PY ($homeCenter.y - $r)), (SZ ($r * 2)), (SZ ($r * 2)))
}

$plots = @(
    @{id="LOT01"; x=62; y=27; w=19; h=11; asset="plot_block_gray_strip_28x10_01.png"; contains=@("B01")},
    @{id="LOT02"; x=88; y=24; w=18; h=18; asset="plot_block_gray_square_14x14_01.png"; contains=@("B02")},
    @{id="LOT03"; x=115; y=24; w=24; h=17; asset="plot_block_gray_rect_22x16_01.png"; contains=@("B03")},
    @{id="LOT04"; x=155; y=27; w=39; h=13; asset="plot_block_gray_rect_28x18_01.png"; contains=@("B04","B05")},
    @{id="LOT05"; x=211; y=24; w=18; h=18; asset="plot_block_gray_square_14x14_01.png"; contains=@("B06")},
    @{id="LOT06"; x=24; y=57; w=18; h=18; asset="plot_block_gray_square_14x14_01.png"; contains=@("B07")},
    @{id="LOT07"; x=48; y=82; w=52; h=32; asset="plot_block_gray_large_36x24_01.png"; contains=@("B08","B09","B10")},
    @{id="LOT08"; x=153; y=99; w=17; h=17; asset="plot_block_gray_square_14x14_01.png"; contains=@("B11")},
    @{id="LOT09"; x=187; y=101; w=51; h=13; asset="plot_block_gray_rect_28x18_01.png"; contains=@("B12","B13")},
    @{id="LOT10"; x=52; y=127; w=53; h=14; asset="plot_block_gray_rect_28x18_01.png"; contains=@("B14","B15")},
    @{id="LOT11"; x=153; y=127; w=51; h=16; asset="plot_block_gray_rect_28x18_01.png"; contains=@("B16","B17")},
    @{id="LOT12"; x=223; y=127; w=22; h=12; asset="plot_block_gray_strip_28x10_01.png"; contains=@("B18")},
    @{id="LOT13"; x=23; y=142; w=24; h=18; asset="plot_block_gray_rect_22x16_01.png"; contains=@("B19")},
    @{id="LOT14"; x=47; y=164; w=16; h=13; asset="plot_block_gray_rect_16x12_01.png"; contains=@("B20")},
    @{id="LOT15"; x=257; y=57; w=18; h=18; asset="plot_block_gray_square_14x14_01.png"; contains=@("B21")},
    @{id="LOT16"; x=225; y=83; w=24; h=18; asset="plot_block_gray_rect_22x16_01.png"; contains=@("B22")},
    @{id="LOT17"; x=257; y=142; w=18; h=18; asset="plot_block_gray_square_14x14_01.png"; contains=@("B23")},
    @{id="LOT18"; x=229; y=163; w=22; h=13; asset="plot_block_gray_strip_28x10_01.png"; contains=@("B24")},
    @{id="LOT19"; x=99; y=169; w=24; h=18; asset="plot_block_gray_rect_22x16_01.png"; contains=@("B25")},
    @{id="LOT20"; x=181; y=171; w=22; h=22; asset="plot_block_gray_square_14x14_01.png"; contains=@("B26")},
    @{id="LOT21"; x=134; y=111; w=16; h=14; asset="plot_block_gray_square_14x14_01.png"; contains=@("HOME")},
    @{id="LOT22"; x=80; y=68; w=14; h=12; asset="plot_block_gray_rect_16x12_01.png"; contains=@("O1A")},
    @{id="LOT23"; x=204; y=68; w=14; h=12; asset="plot_block_gray_rect_16x12_01.png"; contains=@("O1B")},
    @{id="LOT24"; x=116; y=152; w=14; h=12; asset="plot_block_gray_rect_16x12_01.png"; contains=@("O1C")},
    @{id="LOT25"; x=51; y=46; w=18; h=12; asset="plot_block_gray_rect_16x12_01.png"; contains=@("O2A")},
    @{id="LOT26"; x=233; y=46; w=18; h=12; asset="plot_block_gray_rect_16x12_01.png"; contains=@("O2B")},
    @{id="LOT27"; x=53; y=182; w=18; h=12; asset="plot_block_gray_rect_16x12_01.png"; contains=@("O2C")},
    @{id="LOT28"; x=233; y=182; w=18; h=12; asset="plot_block_gray_rect_16x12_01.png"; contains=@("O2D")}
)

foreach ($lot in $plots) {
    Draw-Asset $g (Img ("assets\map\plots\" + $lot.asset)) $lot.x $lot.y $lot.w $lot.h
    $rect = New-Object System.Drawing.Rectangle (PX $lot.x), (PY $lot.y), (SZ $lot.w), (SZ $lot.h)
    $g.DrawRectangle($plotPen, $rect)
}

$roadStraight = Img "assets\map\roads\tiles\road_straight_main_01.png"
$roadCross = Img "assets\map\roads\tiles\road_cross_intersection_01.png"
$plazaTile = Img "assets\map\roads\tiles\plaza_concrete_01.png"
$alleyTile = Img "assets\map\roads\tiles\alley_path_01.png"
foreach ($r in $layout.roads) {
    $img = if ($r.type -eq "alley") { $alleyTile } else { $roadStraight }
    Draw-Asset $g $img $r.x $r.y $r.w $r.h
    $rect = New-Object System.Drawing.Rectangle (PX $r.x), (PY $r.y), (SZ $r.w), (SZ $r.h)
    $g.DrawRectangle($roadPen, $rect)
}
foreach ($p in $layout.plazas) {
    $img = if ($p.id -eq "P_CROSS") { $roadCross } else { $plazaTile }
    Draw-Asset $g $img $p.x $p.y $p.w $p.h
    $rect = New-Object System.Drawing.Rectangle (PX $p.x), (PY $p.y), (SZ $p.w), (SZ $p.h)
    $g.DrawRectangle($roadPen, $rect)
}

$decalFiles = @(
    "assets\map\decals\overlays\ground_decal_overlay_001.png",
    "assets\map\decals\overlays\ground_decal_overlay_002.png",
    "assets\map\decals\overlays\ground_decal_overlay_003.png",
    "assets\map\decals\overlays\ground_decal_overlay_004.png",
    "assets\map\decals\overlays\ground_decal_overlay_005.png",
    "assets\map\decals\overlays\ground_decal_overlay_006.png"
)
$decalSpots = @(@(70,120,7,5),@(102,78,5,4),@(160,78,6,5),@(215,122,8,5),@(132,160,6,4),@(205,162,6,4),@(48,102,8,5),@(244,184,8,5),@(145,204,7,5),@(235,77,7,5))
for ($i=0; $i -lt $decalSpots.Count; $i++) {
    $d = $decalSpots[$i]
    Draw-Asset-Centered $g (Img $decalFiles[$i % $decalFiles.Count]) $d[0] $d[1] $d[2] $d[3]
}

$buildingByType = @{
    "long_shop" = "assets\map\buildings\building_medium_shop_blank_neon_01.png"
    "apartment" = "assets\map\buildings\building_medium_apartment_rooftop_01.png"
    "warehouse" = "assets\map\buildings\building_large_ruined_market_01.png"
    "standard_house" = "assets\map\buildings\building_small_residential_block_01.png"
    "small_house" = "assets\map\buildings\building_small_corner_shop_01.png"
    "ruined_market" = "assets\map\buildings\building_large_ruined_market_01.png"
    "construction" = "assets\map\buildings\assembled\building_tin_shed_variant_01.png"
}
foreach ($b in $layout.buildings) {
    Draw-Asset $g (Img $buildingByType[$b.type]) $b.x $b.y $b.w $b.h
}

$homeNode = $layout.home
$homeSafeRect = New-Object System.Drawing.Rectangle (PX $homeNode.safe_area.x), (PY $homeNode.safe_area.y), (SZ $homeNode.safe_area.w), (SZ $homeNode.safe_area.h)
$g.FillRectangle($safeFill, $homeSafeRect)
$g.DrawRectangle($homePen, $homeSafeRect)
Draw-Asset $g (Img "assets\map\safe\safe_house_active_01.png") $homeNode.x $homeNode.y $homeNode.w $homeNode.h

foreach ($o in $layout.outpost_candidates) {
    $sa = New-Object System.Drawing.Rectangle (PX ($o.x - 1)), (PY ($o.y - 1)), (SZ ($o.w + 2)), (SZ ($o.h + 2))
    $g.FillRectangle($outpostFill, $sa)
    $g.DrawRectangle($outpostPen, $sa)
    Draw-Asset $g (Img "assets\map\outposts\outpost_broken_01.png") $o.x $o.y $o.w $o.h
}

$propStreetLamp = Img "assets\map\props\placement\streetlamp_warm_01.png"
$propBrokenLamp = Img "assets\map\props\placement\streetlamp_broken_01.png"
$propBarrier = Img "assets\map\props\placement\barricade_wood_metal_01.png"
$propTrash = Img "assets\map\props\placement\trash_bin_overturned_01.png"
$propPole = Img "assets\map\props\placement\utility_pole_01.png"
$propBench = Img "assets\map\props\placement\bench_wood_01.png"
$propCone = Img "assets\map\props\placement\road_cone_cluster_01.png"
$container = Img "assets\map\interactables\containers\storage_crate_closed_01.png"
$safeContainer = Img "assets\map\interactables\containers\container_safe_closed.png"
$material = Img "assets\map\interactables\loot\scrap_pile_01.png"
$beacon = Img "assets\map\interactables\props\extraction_beacon_device_01.png"
$anomaly = Img "assets\map\interactables\barriers\rubble_barrier_stack_01.png"

foreach ($lamp in @(@(71,121),@(117,96),@(173,141),@(211,123),@(145,47),@(85,164),@(251,119),@(44,194),@(210,77),@(145,183))) {
    Draw-Asset-Centered $g $propStreetLamp $lamp[0] $lamp[1] 3 4
}
foreach ($p in @(@(95,116,$propTrash),@(136,111,$propBench),@(182,125,$propBarrier),@(235,118,$propCone),@(246,184,$propPole),@(54,48,$propBrokenLamp))) {
    Draw-Asset-Centered $g $p[2] $p[0] $p[1] 4 3
}
foreach ($p in $layout.points) {
    $img = if ($p.kind -eq "container") { if ($p.id -eq "C04") { $safeContainer } else { $container } } elseif ($p.kind -eq "outpost_material") { $material } elseif ($p.kind -like "extract*") { $beacon } else { $anomaly }
    Draw-Asset-Centered $g $img $p.x $p.y 4 4
}

foreach ($lot in $plots) {
    Draw-Label $g "$($lot.id) plot $($lot.w)x$($lot.h)u" $lot.x ($lot.y - 1.8) $fontTiny $muted
}
foreach ($b in $layout.buildings) {
    $rect = New-Object System.Drawing.Rectangle (PX $b.x), (PY $b.y), (SZ $b.w), (SZ $b.h)
    $g.DrawRectangle($buildingPen, $rect)
    Draw-Label $g "$($b.id) $($b.type) $($b.w)x$($b.h)u" $b.x $b.y $fontTiny $white
}
$homeRect = New-Object System.Drawing.Rectangle (PX $homeNode.x), (PY $homeNode.y), (SZ $homeNode.w), (SZ $homeNode.h)
$g.DrawRectangle($homePen, $homeRect)
Draw-Label $g "HOME 10x8u" $homeNode.x $homeNode.y $fontTiny $yellow
foreach ($o in $layout.outpost_candidates) {
    $rect = New-Object System.Drawing.Rectangle (PX $o.x), (PY $o.y), (SZ $o.w), (SZ $o.h)
    $g.DrawRectangle($outpostPen, $rect)
    Draw-Label $g "$($o.id) $($o.type) $($o.w)x$($o.h)u" $o.x $o.y $fontTiny $blue
}
foreach ($p in $layout.points) {
    $fg = if ($p.kind -eq "container") { $purple } elseif ($p.kind -eq "outpost_material") { $yellow } elseif ($p.kind -like "extract*") { $blue } else { $red }
    Draw-Label $g $p.id ($p.x + 1.8) ($p.y - 1.5) $fontTiny $fg
}

$g.DrawRectangle($borderPen, $mapRect)
$g.DrawString("Project Escape - V0.1 Town Level ART Concept v02 / Plot Blocks", $fontTitle, $white, $margin, 10)
$g.DrawString("Layer order: gray plot blocks -> roads -> buildings/props -> labels", $fontSmall, $muted, $margin + 860, 22)

$lx = $margin + $mapW * $scale + 35
$ly = $margin
$g.DrawString("v02 Layer Logic", $fontBold, $white, $lx, $ly)
$ly += 38
$notes = @(
    "Black no longer has level meaning.",
    "Gray plot blocks are the buildable city lots.",
    "Roads are the gaps enclosed by plot blocks.",
    "Buildings sit on plots and remain collision blockers.",
    "Players walk roads/plazas/home/repaired outpost zones only.",
    "LOT labels define block extents for whitebox handoff."
)
foreach ($line in $notes) { $g.DrawString($line, $fontSmall, $muted, $lx, $ly); $ly += 30 }

$ly += 18
$g.DrawString("New Plot Resources", $fontBold, $white, $lx, $ly)
$ly += 36
$plotNames = @(
    "assets/map/plots/plot_block_gray_rect_16x12_01.png",
    "assets/map/plots/plot_block_gray_rect_22x16_01.png",
    "assets/map/plots/plot_block_gray_rect_28x18_01.png",
    "assets/map/plots/plot_block_gray_square_14x14_01.png",
    "assets/map/plots/plot_block_gray_large_36x24_01.png",
    "assets/map/plots/plot_block_gray_strip_28x10_01.png"
)
foreach ($line in $plotNames) { $g.DrawString($line, $fontSmall, $white, $lx, $ly); $ly += 28 }

$ly += 18
$g.DrawString("Handoff", $fontBold, $white, $lx, $ly)
$ly += 36
$handoff = @(
    "Use town_level_concept_v02_plots_layout.json for LOT rectangles.",
    "Use town_level_concept_v01_layout.json for road/building coordinates.",
    "Home center = (142,118). Ring radii = 20/60/100/130.",
    "Map remains 300x240 units, 1 unit = 1 tile = 64px."
)
foreach ($line in $handoff) { $g.DrawString($line, $fontSmall, $muted, $lx, $ly); $ly += 30 }

$g.DrawString("N", $fontBold, $white, (PX 288), (PY 8))
$arrowPen = PenC 240 235 235 225 3
$g.DrawLine($arrowPen, (PX 292), (PY 28), (PX 292), (PY 12))
$g.DrawLine($arrowPen, (PX 292), (PY 12), (PX 288), (PY 18))
$g.DrawLine($arrowPen, (PX 292), (PY 12), (PX 296), (PY 18))

$v02 = [ordered]@{
    version = "v02_plots"
    map_units = $layout.map_units
    plot_assets_path = "assets/map/plots"
    plots = $plots
    base_layout = "assets/map/_concept/town_level_concept_v01_layout.json"
    layer_order = @("gray_plot_blocks", "roads_and_plazas", "buildings_home_outposts", "props_points", "labels")
    notes = @(
        "Gray plot blocks are intentionally added to remove meaningless black voids.",
        "Roads are enclosed negative space between lots.",
        "Buildings are placed on lots, not directly on background."
    )
}
$v02 | ConvertTo-Json -Depth 8 | Set-Content -Path $outJson -Encoding UTF8

$bmp.Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
foreach ($img in $images.Values) { $img.Dispose() }

Write-Output $outPng
Write-Output $outJson
