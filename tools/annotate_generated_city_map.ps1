Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$source = "C:\Users\Administrator\.codex\generated_images\019de737-3b52-74d0-8b05-5c7ee6e3db26\ig_0599fd167dd062d70169f59592548081908af5e46fab385a35.png"
$conceptDir = Join-Path $root "assets\map\_concept"
$baseOut = Join-Path $conceptDir "town_level_art_fullmap_v01.png"
$annotatedOut = Join-Path $conceptDir "town_level_art_fullmap_v01_roles_collision_annotated.png"

New-Item -ItemType Directory -Force -Path $conceptDir | Out-Null
Copy-Item -LiteralPath $source -Destination $baseOut -Force

function C([int]$a, [int]$r, [int]$g, [int]$b) { return [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }
function Brush([int]$a, [int]$r, [int]$g, [int]$b) { return New-Object System.Drawing.SolidBrush (C $a $r $g $b) }
function PenC([int]$a, [int]$r, [int]$g, [int]$b, [float]$w) { return New-Object System.Drawing.Pen (C $a $r $g $b), $w }

function Draw-Tag($g, [string]$text, [int]$x, [int]$y, $font, $fg, $bg) {
    $size = $g.MeasureString($text, $font)
    $padX = 8
    $padY = 5
    $rect = New-Object System.Drawing.Rectangle ($x), ($y), ([int]$size.Width + $padX * 2), ([int]$size.Height + $padY * 2)
    $g.FillRectangle($bg, $rect)
    $g.DrawRectangle((PenC 235 245 245 235 2), $rect)
    $g.DrawString($text, $font, $fg, $x + $padX, $y + $padY)
}

function Draw-Callout($g, [string]$text, [int]$x, [int]$y, [int]$tx, [int]$ty, $font, $fg, $bg, $pen) {
    Draw-Tag $g $text $tx $ty $font $fg $bg
    $g.DrawLine($pen, $tx + 12, $ty + 24, $x, $y)
    $g.FillEllipse((New-Object System.Drawing.SolidBrush $pen.Color), $x - 5, $y - 5, 10, 10)
}

$bmp = [System.Drawing.Image]::FromFile($baseOut)
$canvas = New-Object System.Drawing.Bitmap $bmp.Width, $bmp.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.DrawImage($bmp, 0, 0, $bmp.Width, $bmp.Height)

$font = New-Object System.Drawing.Font("Microsoft YaHei", 22, [System.Drawing.FontStyle]::Bold)
$fontSmall = New-Object System.Drawing.Font("Microsoft YaHei", 17, [System.Drawing.FontStyle]::Bold)
$fontLegend = New-Object System.Drawing.Font("Microsoft YaHei", 18, [System.Drawing.FontStyle]::Regular)

$homePen = PenC 245 255 220 70 6
$homeFill = Brush 38 255 220 70
$outpostPen = PenC 245 70 165 255 5
$outpostFill = Brush 35 70 165 255
$collisionPen = PenC 230 255 70 70 4
$collisionFill = Brush 26 255 70 70
$labelBg = Brush 220 8 9 10
$homeText = Brush 255 255 235 105
$outpostText = Brush 255 115 190 255
$collisionText = Brush 255 255 115 115
$white = Brush 255 245 245 230

# Building collision footprints. These are intentionally broad block/building roof footprints,
# not road or sidewalk areas.
$collisions = @(
    @{id="C01"; x=12; y=2; w=160; h=127},
    @{id="C02"; x=190; y=9; w=162; h=132},
    @{id="C03"; x=400; y=5; w=181; h=131},
    @{id="C04"; x=610; y=2; w=178; h=134},
    @{id="C05"; x=871; y=5; w=159; h=135},
    @{id="C06"; x=1112; y=4; w=161; h=128},
    @{id="C07"; x=1312; y=4; w=141; h=132},
    @{id="C08"; x=88; y=181; w=146; h=119},
    @{id="C09"; x=308; y=214; w=171; h=116},
    @{id="C10"; x=592; y=228; w=211; h=178},
    @{id="C11"; x=883; y=244; w=203; h=159},
    @{id="C12"; x=1135; y=229; w=226; h=150},
    @{id="C13"; x=2; y=362; w=143; h=143},
    @{id="C14"; x=198; y=368; w=172; h=147},
    @{id="C15"; x=405; y=363; w=156; h=141},
    @{id="C16"; x=604; y=421; w=178; h=145},
    @{id="C17"; x=928; y=417; w=170; h=150},
    @{id="C18"; x=1205; y=417; w=133; h=140},
    @{id="C19"; x=1372; y=378; w=112; h=148},
    @{id="C20"; x=9; y=574; w=146; h=139},
    @{id="C21"; x=207; y=566; w=182; h=153},
    @{id="C22"; x=404; y=567; w=165; h=143},
    @{id="C23"; x=602; y=579; w=176; h=134},
    @{id="C24"; x=904; y=578; w=203; h=144},
    @{id="C25"; x=1182; y=604; w=177; h=126},
    @{id="C26"; x=1378; y=594; w=123; h=126},
    @{id="C27"; x=0; y=768; w=168; h=125},
    @{id="C28"; x=188; y=765; w=168; h=126},
    @{id="C29"; x=394; y=751; w=162; h=128},
    @{id="C30"; x=618; y=738; w=171; h=133},
    @{id="C31"; x=894; y=756; w=204; h=127},
    @{id="C32"; x=1184; y=763; w=226; h=115}
)

foreach ($c in $collisions) {
    $rect = New-Object System.Drawing.Rectangle $c.x, $c.y, $c.w, $c.h
    $g.FillRectangle($collisionFill, $rect)
    $g.DrawRectangle($collisionPen, $rect)
}

# Home and outpost roles are selected from visually readable landmark-like buildings.
$homeRect = New-Object System.Drawing.Rectangle 586, 425, 220, 170
$g.FillRectangle($homeFill, $homeRect)
$g.DrawRectangle($homePen, $homeRect)

$outposts = @(
    @{id="OUTPOST A"; x=210; y=370; w=180; h=145; tx=245; ty=327},
    @{id="OUTPOST B"; x=895; y=425; w=205; h=150; tx=927; ty=386},
    @{id="OUTPOST C"; x=1186; y=605; w=175; h=124; tx=1198; ty=562},
    @{id="OUTPOST D"; x=405; y=747; w=160; h=128; tx=425; ty=706}
)
foreach ($o in $outposts) {
    $rect = New-Object System.Drawing.Rectangle $o.x, $o.y, $o.w, $o.h
    $g.FillRectangle($outpostFill, $rect)
    $g.DrawRectangle($outpostPen, $rect)
}

Draw-Callout $g "HOME" 696 510 620 384 $font $homeText $labelBg $homePen
foreach ($o in $outposts) {
    Draw-Callout $g $o.id ($o.x + [int]($o.w / 2)) ($o.y + [int]($o.h / 2)) $o.tx $o.ty $fontSmall $outpostText $labelBg $outpostPen
}

Draw-Tag $g "RED translucent = BUILDING COLLISION / BLOCKED" 24 22 $fontLegend $collisionText $labelBg
Draw-Tag $g "YELLOW = HOME    BLUE = OUTPOST" 24 72 $fontLegend $white $labelBg

$bmp.Dispose()
$canvas.Save($annotatedOut, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$canvas.Dispose()

Write-Output $baseOut
Write-Output $annotatedOut
