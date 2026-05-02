Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$conceptDir = Join-Path $root "assets\map\_concept"
$layoutPath = Join-Path $conceptDir "town_level_concept_v01_layout.json"
$outPng = Join-Path $conceptDir "town_level_art_concept_v01_annotated.png"

if (!(Test-Path $layoutPath)) {
    throw "Missing layout json: $layoutPath. Run tools/generate_level_concept_v01.ps1 first."
}

$layout = Get-Content $layoutPath -Raw | ConvertFrom-Json
$scale = 6
$mapW = [int]$layout.map_units.width
$mapH = [int]$layout.map_units.height
$margin = 48
$legendW = 600
$canvasW = $margin * 2 + $mapW * $scale + $legendW
$canvasH = $margin * 2 + $mapH * $scale

function PX([double]$u) { return [int][Math]::Round($margin + $u * $scale) }
function PY([double]$u) { return [int][Math]::Round($margin + $u * $scale) }
function SZ([double]$u) { return [int][Math]::Round($u * $scale) }
function C([int]$a, [int]$r, [int]$g, [int]$b) { return [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }
function Brush([int]$a, [int]$r, [int]$g, [int]$b) { return New-Object System.Drawing.SolidBrush (C $a $r $g $b) }
function PenC([int]$a, [int]$r, [int]$g, [int]$b, [float]$w) { return New-Object System.Drawing.Pen (C $a $r $g $b), $w }

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
    $bg = Brush 185 10 10 12
    $size = $g.MeasureString($text, $font)
    $g.FillRectangle($bg, $px - 2, $py - 1, [int]$size.Width + 5, [int]$size.Height + 3)
    $g.DrawString($text, $font, $fg, $px, $py)
}

function Draw-BoxLabel($g, $item, $font, $fg, $pen) {
    $rect = New-Object System.Drawing.Rectangle (PX $item.x), (PY $item.y), (SZ $item.w), (SZ $item.h)
    $g.DrawRectangle($pen, $rect)
    Draw-Label $g "$($item.id) $($item.type) $($item.w)x$($item.h)u" $item.x $item.y $font $fg
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

$bg = Brush 255 14 15 17
$ground = Brush 255 37 38 37
$white = Brush 255 238 236 220
$muted = Brush 255 188 187 172
$yellow = Brush 255 242 205 96
$blue = Brush 255 94 164 238
$purple = Brush 255 170 104 235
$red = Brush 255 235 82 82
$safeFill = Brush 65 255 220 92
$outpostFill = Brush 50 95 170 255
$roadPen = PenC 145 210 205 180 1
$buildingPen = PenC 235 255 70 70 2
$homePen = PenC 235 255 218 75 2
$outpostPen = PenC 235 95 170 255 2
$gridPen = PenC 24 210 210 210 1
$gridMajorPen = PenC 55 220 220 220 1
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
    $ringPen = PenC 50 160 130 230 2
    $g.DrawEllipse($ringPen, (PX ($homeCenter.x - $r)), (PY ($homeCenter.y - $r)), (SZ ($r * 2)), (SZ ($r * 2)))
}

$roadStraight = Img "assets\map\roads\tiles\road_straight_main_01.png"
$roadCross = Img "assets\map\roads\tiles\road_cross_intersection_01.png"
$plazaTile = Img "assets\map\roads\tiles\plaza_concrete_01.png"
$alleyTile = Img "assets\map\roads\tiles\alley_path_01.png"
$sidewalkTile = Img "assets\map\roads\tiles\sidewalk_tile_01.png"

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
    "assets\map\decals\overlays\ground_decal_overlay_006.png",
    "assets\map\decals\overlays\ground_decal_overlay_007.png",
    "assets\map\decals\overlays\ground_decal_overlay_008.png"
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
    $path = $buildingByType[$b.type]
    if ($null -eq $path) { $path = "assets\map\buildings\building_small_residential_block_01.png" }
    Draw-Asset $g (Img $path) $b.x $b.y $b.w $b.h
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

foreach ($b in $layout.buildings) {
    Draw-BoxLabel $g $b $fontTiny $white $buildingPen
}
Draw-BoxLabel $g $homeNode $fontTiny $yellow $homePen
foreach ($o in $layout.outpost_candidates) {
    Draw-BoxLabel $g $o $fontTiny $blue $outpostPen
    Draw-Label $g $o.t $o.x ($o.y + $o.h + 0.4) $fontTiny $blue
}
foreach ($p in $layout.points) {
    $fg = if ($p.kind -eq "container") { $purple } elseif ($p.kind -eq "outpost_material") { $yellow } elseif ($p.kind -like "extract*") { $blue } else { $red }
    Draw-Label $g $p.id ($p.x + 1.8) ($p.y - 1.5) $fontTiny $fg
}

$g.DrawRectangle($borderPen, $mapRect)
$g.DrawString("Project Escape - V0.1 Town Level ART Concept v01", $fontTitle, $white, $margin, 10)
$g.DrawString("Composited from assets/map resources; 300x240 units; top-down / slightly top-down", $fontSmall, $muted, $margin + 720, 22)

$lx = $margin + $mapW * $scale + 35
$ly = $margin
$g.DrawString("Art Source Layout", $fontBold, $white, $lx, $ly)
$ly += 38
$notes = @(
    "This image uses existing PNG assets under assets/map.",
    "Roads: assets/map/roads/tiles",
    "Buildings: assets/map/buildings root/assembled",
    "Home: assets/map/safe/safe_house_active_01.png",
    "Outposts: assets/map/outposts/outpost_broken_01.png",
    "Props, containers, decals: props/interactables/decals",
    "All labels preserve the whitebox unit sizes from layout JSON.",
    "Buildings are still blockers; players walk only roads/plazas/safe zones.",
    "Red outlines mark collision footprints, not final render bounds."
)
foreach ($line in $notes) {
    $g.DrawString($line, $fontSmall, $muted, $lx, $ly)
    $ly += 30
}

$ly += 18
$g.DrawString("Key Dimensions", $fontBold, $white, $lx, $ly)
$ly += 36
$dims = @(
    "Map: 300 x 240 units, 1 unit = 1 tile = 64px",
    "HOME: 10x8u, SafeArea: 12x10u, door buffer: 10x3u",
    "Roads: main 6u, rings 5u, secondary 4u, alley 3u",
    "Outpost T1: 10x8u; Outpost T2: 12x8u",
    "Building sizes follow Doc/03 rules: 8x6, 10x8, 12x12, 16x6, 18x12, 16x16"
)
foreach ($line in $dims) {
    $g.DrawString($line, $fontSmall, $white, $lx, $ly)
    $ly += 30
}

$ly += 18
$g.DrawString("Whitebox Handoff", $fontBold, $white, $lx, $ly)
$ly += 36
$handoff = @(
    "Use town_level_concept_v01_layout.json for exact rectangles.",
    "Use this PNG for visual placement, street wall rhythm, and mood.",
    "Top-left = (0,0), bottom-right = (300,240).",
    "Home center = (142,118). Ring radii = 20/60/100/130."
)
foreach ($line in $handoff) {
    $g.DrawString($line, $fontSmall, $muted, $lx, $ly)
    $ly += 30
}

$g.DrawString("N", $fontBold, $white, (PX 288), (PY 8))
$arrowPen = PenC 240 235 235 225 3
$g.DrawLine($arrowPen, (PX 292), (PY 28), (PX 292), (PY 12))
$g.DrawLine($arrowPen, (PX 292), (PY 12), (PX 288), (PY 18))
$g.DrawLine($arrowPen, (PX 292), (PY 12), (PX 296), (PY 18))

$bmp.Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
foreach ($img in $images.Values) { $img.Dispose() }

Write-Output $outPng
