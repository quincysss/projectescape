Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $root "assets\map\_concept"
$outPng = Join-Path $outDir "town_level_concept_v01_annotated.png"
$outJson = Join-Path $outDir "town_level_concept_v01_layout.json"

$scale = 6
$mapW = 300
$mapH = 240
$margin = 48
$legendW = 600
$canvasW = $margin * 2 + $mapW * $scale + $legendW
$canvasH = $margin * 2 + $mapH * $scale

function PX([double]$u) { return [int][Math]::Round($margin + $u * $scale) }
function PY([double]$u) { return [int][Math]::Round($margin + $u * $scale) }
function SZ([double]$u) { return [int][Math]::Round($u * $scale) }

function New-Brush([int]$a, [int]$r, [int]$g, [int]$b) {
    return New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, $r, $g, $b))
}
function New-Pen([int]$a, [int]$r, [int]$g, [int]$b, [float]$w) {
    return New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb($a, $r, $g, $b)), $w
}

$bmp = New-Object System.Drawing.Bitmap $canvasW, $canvasH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

$font = New-Object System.Drawing.Font("Microsoft YaHei", 13, [System.Drawing.FontStyle]::Regular)
$fontSmall = New-Object System.Drawing.Font("Microsoft YaHei", 10, [System.Drawing.FontStyle]::Regular)
$fontTiny = New-Object System.Drawing.Font("Microsoft YaHei", 8, [System.Drawing.FontStyle]::Regular)
$fontBold = New-Object System.Drawing.Font("Microsoft YaHei", 15, [System.Drawing.FontStyle]::Bold)
$fontTitle = New-Object System.Drawing.Font("Microsoft YaHei", 24, [System.Drawing.FontStyle]::Bold)

$bg = New-Brush 255 21 22 24
$mapBg = New-Brush 255 42 42 41
$gridPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(30, 210, 210, 210)), 1
$gridMajorPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70, 220, 220, 220)), 1
$borderPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230, 235, 235, 220)), 3
$roadBrush = New-Brush 255 85 85 83
$roadEdgePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(210, 150, 150, 142)), 2
$roadCenterPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(110, 230, 220, 150)), 1
$walkBrush = New-Brush 110 130 130 122
$buildingBrush = New-Brush 245 59 61 65
$buildingRoofBrush = New-Brush 245 77 78 82
$buildingPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(235, 17, 17, 18)), 2
$collisionPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230, 255, 90, 90)), 2
$homeBrush = New-Brush 245 120 105 78
$homeSafeBrush = New-Brush 70 255 215 95
$outpostBrush = New-Brush 245 80 92 106
$outpostSafeBrush = New-Brush 55 120 170 255
$whiteBrush = New-Brush 255 235 235 225
$mutedBrush = New-Brush 255 178 178 165
$blueBrush = New-Brush 255 90 150 230
$purpleBrush = New-Brush 255 160 110 230
$redBrush = New-Brush 255 220 80 80
$yellowBrush = New-Brush 255 238 200 100

$g.FillRectangle($bg, 0, 0, $canvasW, $canvasH)
$g.FillRectangle($mapBg, $margin, $margin, $mapW * $scale, $mapH * $scale)

for ($x = 0; $x -le $mapW; $x += 10) {
    $g.DrawLine($(if ($x % 50 -eq 0) { $gridMajorPen } else { $gridPen }), (PX $x), (PY 0), (PX $x), (PY $mapH))
}
for ($y = 0; $y -le $mapH; $y += 10) {
    $g.DrawLine($(if ($y % 50 -eq 0) { $gridMajorPen } else { $gridPen }), (PX 0), (PY $y), (PX $mapW), (PY $y))
}

$homeCenter = @{ x = 142; y = 118 }
foreach ($r in @(20, 60, 100, 130)) {
    $ringPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(60, 160, 130, 230)), 2
    $g.DrawEllipse($ringPen, (PX ($homeCenter.x - $r)), (PY ($homeCenter.y - $r)), (SZ ($r * 2)), (SZ ($r * 2)))
    $ringPen.Dispose()
}

$roads = @(
    @{id="R01"; type="main"; x=28; y=117; w=246; h=6; label="main road 6u"},
    @{id="R02"; type="main"; x=144; y=28; w=6; h=186; label="main road 6u"},
    @{id="R03"; type="main"; x=52; y=42; w=198; h=5; label="outer ring 5u"},
    @{id="R04"; type="main"; x=42; y=194; w=224; h=5; label="outer ring 5u"},
    @{id="R05"; type="main"; x=42; y=42; w=5; h=157; label="outer ring 5u"},
    @{id="R06"; type="main"; x=250; y=42; w=5; h=157; label="outer ring 5u"},
    @{id="R07"; type="secondary"; x=60; y=76; w=170; h=4; label="secondary 4u"},
    @{id="R08"; type="secondary"; x=60; y=160; w=176; h=4; label="secondary 4u"},
    @{id="R09"; type="secondary"; x=82; y=60; w=4; h=130; label="secondary 4u"},
    @{id="R10"; type="secondary"; x=210; y=62; w=4; h=136; label="secondary 4u"},
    @{id="R11"; type="alley"; x=105; y=78; w=3; h=39; label="alley 3u"},
    @{id="R12"; type="alley"; x=180; y=123; w=3; h=37; label="alley 3u"},
    @{id="R13"; type="alley"; x=47; y=100; w=69; h=3; label="alley 3u"},
    @{id="R14"; type="alley"; x=148; y=182; w=100; h=3; label="alley 3u"},
    @{id="R15"; type="inner_ring"; x=116; y=94; w=58; h=5; label="inner ring 5u"},
    @{id="R16"; type="inner_ring"; x=116; y=138; w=58; h=5; label="inner ring 5u"},
    @{id="R17"; type="inner_ring"; x=116; y=94; w=5; h=49; label="inner ring 5u"},
    @{id="R18"; type="inner_ring"; x=169; y=94; w=5; h=49; label="inner ring 5u"}
)

foreach ($r in $roads) {
    $rect = New-Object System.Drawing.Rectangle (PX $r.x), (PY $r.y), (SZ $r.w), (SZ $r.h)
    $g.FillRectangle($roadBrush, $rect)
    $g.DrawRectangle($roadEdgePen, $rect)
    if ($r.type -eq "main") {
        if ($r.w -gt $r.h) {
            $cy = PY ($r.y + $r.h / 2)
            $g.DrawLine($roadCenterPen, (PX $r.x), $cy, (PX ($r.x + $r.w)), $cy)
        } else {
            $cx = PX ($r.x + $r.w / 2)
            $g.DrawLine($roadCenterPen, $cx, (PY $r.y), $cx, (PY ($r.y + $r.h)))
        }
    }
}

$plazas = @(
    @{id="P_HOME"; x=132; y=110; w=22; h=18; label="home plaza 22x18"},
    @{id="P_CROSS"; x=136; y=111; w=18; h=18; label="central cross"},
    @{id="P_N"; x=138; y=72; w=18; h=12; label="north node"},
    @{id="P_S"; x=136; y=156; w=20; h=12; label="south node"},
    @{id="P_E"; x=205; y=112; w=16; h=14; label="east node"},
    @{id="P_W"; x=76; y=112; w=16; h=14; label="west node"}
)
foreach ($p in $plazas) {
    $rect = New-Object System.Drawing.Rectangle (PX $p.x), (PY $p.y), (SZ $p.w), (SZ $p.h)
    $g.FillRectangle($walkBrush, $rect)
    $g.DrawRectangle($roadEdgePen, $rect)
}

function Draw-Label($text, $x, $y, $brush, $fontObj) {
    $g.DrawString($text, $fontObj, $brush, (PX $x), (PY $y))
}

function Draw-UnitBox($item, $brush, $roofBrush, $pen, $labelBrush, $fontObj) {
    $rect = New-Object System.Drawing.Rectangle (PX $item.x), (PY $item.y), (SZ $item.w), (SZ $item.h)
    $g.FillRectangle($brush, $rect)
    $inset = [Math]::Max(2, [int](2 * $scale / 3))
    $inner = New-Object System.Drawing.Rectangle ($rect.X + $inset), ($rect.Y + $inset), ([Math]::Max(2, $rect.Width - 2*$inset)), ([Math]::Max(2, $rect.Height - 2*$inset))
    $g.FillRectangle($roofBrush, $inner)
    $g.DrawRectangle($pen, $rect)
    $g.DrawRectangle($collisionPen, $rect)
    $g.DrawString("$($item.id) $($item.type)`n$($item.w)x$($item.h)u", $fontObj, $labelBrush, $rect.X + 4, $rect.Y + 3)
}

$buildings = @(
    @{id="B01"; type="long_shop"; x=64; y=30; w=16; h=6},
    @{id="B02"; type="apartment"; x=92; y=28; w=12; h=12},
    @{id="B03"; type="warehouse"; x=118; y=28; w=18; h=12},
    @{id="B04"; type="standard_house"; x=158; y=30; w=10; h=8},
    @{id="B05"; type="long_shop"; x=176; y=30; w=16; h=6},
    @{id="B06"; type="apartment"; x=214; y=28; w=12; h=12},
    @{id="B07"; type="apartment"; x=27; y=60; w=12; h=12},
    @{id="B08"; type="small_house"; x=50; y=84; w=8; h=6},
    @{id="B09"; type="long_shop"; x=55; y=104; w=16; h=6},
    @{id="B10"; type="standard_house"; x=88; y=104; w=10; h=8},
    @{id="B11"; type="apartment"; x=156; y=102; w=12; h=12},
    @{id="B12"; type="long_shop"; x=190; y=104; w=16; h=6},
    @{id="B13"; type="standard_house"; x=225; y=103; w=10; h=8},
    @{id="B14"; type="standard_house"; x=55; y=130; w=10; h=8},
    @{id="B15"; type="long_shop"; x=88; y=129; w=16; h=6},
    @{id="B16"; type="standard_house"; x=156; y=130; w=10; h=8},
    @{id="B17"; type="apartment"; x=190; y=128; w=12; h=12},
    @{id="B18"; type="long_shop"; x=226; y=130; w=16; h=6},
    @{id="B19"; type="warehouse"; x=26; y=145; w=18; h=12},
    @{id="B20"; type="standard_house"; x=50; y=166; w=10; h=8},
    @{id="B21"; type="apartment"; x=260; y=60; w=12; h=12},
    @{id="B22"; type="warehouse"; x=228; y=86; w=18; h=12},
    @{id="B23"; type="apartment"; x=260; y=145; w=12; h=12},
    @{id="B24"; type="long_shop"; x=232; y=166; w=16; h=6},
    @{id="B25"; type="ruined_market"; x=102; y=172; w=18; h=12},
    @{id="B26"; type="construction"; x=184; y=174; w=16; h=16}
)
foreach ($b in $buildings) {
    Draw-UnitBox $b $buildingBrush $buildingRoofBrush $buildingPen $whiteBrush $fontTiny
}

$safe = @{id="HOME"; type="home_safe"; x=137; y=114; w=10; h=8}
$safeArea = New-Object System.Drawing.Rectangle (PX 136), (PY 113), (SZ 12), (SZ 10)
$g.FillRectangle($homeSafeBrush, $safeArea)
$g.DrawRectangle((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(220,255,220,90)),2), $safeArea)
Draw-UnitBox $safe $homeBrush (New-Brush 245 157 125 75) $buildingPen $whiteBrush $fontTiny
$doorBuffer = New-Object System.Drawing.Rectangle (PX 137), (PY 122), (SZ 10), (SZ 3)
$g.FillRectangle((New-Brush 95 255 220 100), $doorBuffer)
$g.DrawString("door buffer 10x3u", $fontTiny, $yellowBrush, $doorBuffer.X + 2, $doorBuffer.Y + 2)

$outposts = @(
    @{id="O1A"; type="outpost_t1_candidate"; x=82; y=70; w=10; h=8; t="T1 ~14s"},
    @{id="O1B"; type="outpost_t1_candidate"; x=206; y=70; w=10; h=8; t="T1 ~16s"},
    @{id="O1C"; type="outpost_t1_candidate"; x=118; y=154; w=10; h=8; t="T1 ~12s"},
    @{id="O2A"; type="outpost_t2_candidate"; x=54; y=48; w=12; h=8; t="T2 ~32s"},
    @{id="O2B"; type="outpost_t2_candidate"; x=236; y=48; w=12; h=8; t="T2 ~34s"},
    @{id="O2C"; type="outpost_t2_candidate"; x=56; y=184; w=12; h=8; t="T2 ~30s"},
    @{id="O2D"; type="outpost_t2_candidate"; x=236; y=184; w=12; h=8; t="T2 ~36s"}
)
foreach ($o in $outposts) {
    $sa = New-Object System.Drawing.Rectangle (PX ($o.x - 1)), (PY ($o.y - 1)), (SZ ($o.w + 2)), (SZ ($o.h + 2))
    $g.FillRectangle($outpostSafeBrush, $sa)
    Draw-UnitBox $o $outpostBrush (New-Brush 245 103 118 134) $buildingPen $whiteBrush $fontTiny
    $g.DrawString($o.t, $fontTiny, $blueBrush, (PX $o.x), (PY ($o.y + $o.h + 0.5)))
}

$points = @(
    @{id="C01"; x=78; y=116; kind="container"}, @{id="C02"; x=99; y=78; kind="container"},
    @{id="C03"; x=160; y=78; kind="container"}, @{id="C04"; x=218; y=118; kind="container"},
    @{id="C05"; x=132; y=160; kind="container"}, @{id="C06"; x=207; y=162; kind="container"},
    @{id="M01"; x=45; y=102; kind="outpost_material"}, @{id="M02"; x=182; y=125; kind="outpost_material"},
    @{id="M03"; x=246; y=184; kind="outpost_material"}, @{id="M04"; x=105; y=185; kind="outpost_material"},
    @{id="E01"; x=145; y=204; kind="extract_or_event"}, @{id="A01"; x=236; y=77; kind="anomaly"}
)
foreach ($p in $points) {
    $brush = if ($p.kind -eq "container") { $purpleBrush } elseif ($p.kind -eq "outpost_material") { $yellowBrush } elseif ($p.kind -like "extract*") { $blueBrush } else { $redBrush }
    $cx = PX $p.x
    $cy = PY $p.y
    $g.FillEllipse($brush, $cx - 5, $cy - 5, 10, 10)
    $g.DrawString($p.id, $fontTiny, $whiteBrush, $cx + 5, $cy - 8)
}

foreach ($lamp in @(@(71,121),@(117,96),@(173,141),@(211,123),@(145,47),@(85,164),@(251,119),@(44,194),@(210,77),@(145,183))) {
    $x = PX $lamp[0]; $y = PY $lamp[1]
    $g.FillEllipse((New-Brush 80 255 210 90), $x - 14, $y - 14, 28, 28)
    $g.FillEllipse($yellowBrush, $x - 3, $y - 3, 6, 6)
}

$g.DrawRectangle($borderPen, $margin, $margin, $mapW * $scale, $mapH * $scale)
$g.DrawString("Project Escape - V0.1 Town Level Concept v01", $fontTitle, $whiteBrush, $margin, 10)
$g.DrawString("View: top-down / slightly top-down; 1 unit = 1 Tile = 64px; concept map = 300x240 units", $fontSmall, $mutedBrush, $margin + 620, 22)

$lx = $margin + $mapW * $scale + 35
$ly = $margin
$g.DrawString("Whitebox Build Notes", $fontBold, $whiteBrush, $lx, $ly)
$ly += 38
$legendLines = @(
    "Map: 300 x 240 units; Tile size: 64px",
    "HOME: 10x8u; SafeArea: 12x10u; Door buffer: 10x3u",
    "Roads: main 6u; outer/inner ring 5u; secondary 4u; alley 3u",
    "Buildings: B01-B26 are non-enterable blockers; red outline = collision",
    "Outposts: O1A-O1C tier-1 candidates; O2A-O2D tier-2 candidates",
    "Outpost size: tier-1 10x8u; tier-2 12x8u; repaired safe zone < home",
    "Points: C=container; M=outpost material; E=extract/event; A=anomaly",
    "Walkable: roads, plazas, home, and repaired outpost safe zones only",
    "Layout: buildings form street walls on both sides of roads",
    "Routes: home connects N/E/W/S; outer layer has a loop route"
)
foreach ($line in $legendLines) {
    $g.DrawString($line, $fontSmall, $mutedBrush, $lx, $ly)
    $ly += 30
}

$ly += 16
$g.DrawString("Legend", $fontBold, $whiteBrush, $lx, $ly)
$ly += 36
$legendItems = @(
    @($roadBrush, "Road / plaza: walkable"),
    @($buildingBrush, "Building blocker: not enterable"),
    @($homeBrush, "HOME building"),
    @($homeSafeBrush, "Yellow alpha: home safe area"),
    @($outpostBrush, "Outpost candidate building"),
    @($outpostSafeBrush, "Blue alpha: outpost safe area"),
    @($purpleBrush, "C: container point"),
    @($yellowBrush, "M: material / warm streetlight"),
    @($redBrush, "A: anomaly warning")
)
foreach ($li in $legendItems) {
    $g.FillRectangle($li[0], $lx, $ly + 4, 22, 16)
    $g.DrawRectangle($borderPen, $lx, $ly + 4, 22, 16)
    $g.DrawString($li[1], $fontSmall, $whiteBrush, $lx + 34, $ly)
    $ly += 30
}

$ly += 16
$g.DrawString("Whitebox Coordinates", $fontBold, $whiteBrush, $lx, $ly)
$ly += 35
$coordLines = @(
    "Top-left is (0,0); bottom-right is (300,240)",
    "Home center = (142,118)",
    "Ring radius = 20 / 60 / 100 / 130",
    "All rectangle x,y values are top-left; w,h are unit sizes"
)
foreach ($line in $coordLines) {
    $g.DrawString($line, $fontSmall, $mutedBrush, $lx, $ly)
    $ly += 28
}

$g.DrawString("N", $fontBold, $whiteBrush, (PX 288), (PY 8))
$arrowPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(240,235,235,225)), 3
$g.DrawLine($arrowPen, (PX 292), (PY 28), (PX 292), (PY 12))
$g.DrawLine($arrowPen, (PX 292), (PY 12), (PX 288), (PY 18))
$g.DrawLine($arrowPen, (PX 292), (PY 12), (PX 296), (PY 18))

$layout = [ordered]@{
    version = "v01"
    map_units = @{ width = $mapW; height = $mapH; tile_size_px = 64; source_scale_px_per_unit_in_concept = $scale }
    view = "top-down / slightly top-down, matching assets/map art direction"
    home_center_units = $homeCenter
    home = @{ id = "HOME"; x = 137; y = 114; w = 10; h = 8; safe_area = @{ x = 136; y = 113; w = 12; h = 10 }; door_buffer = @{ x = 137; y = 122; w = 10; h = 3 } }
    roads = $roads
    plazas = $plazas
    buildings = $buildings
    outpost_candidates = $outposts
    points = $points
    notes = @(
        "Ordinary buildings are non-enterable blockers and should become StaticBody2D + CollisionShape2D.",
        "Player movement should be constrained to roads, plazas, home, and repaired outpost safe areas.",
        "Main corridors deliberately have buildings on both sides to read as streets, not open fields."
    )
}
$layout | ConvertTo-Json -Depth 8 | Set-Content -Path $outJson -Encoding UTF8

$bmp.Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
Write-Output $outPng
Write-Output $outJson
