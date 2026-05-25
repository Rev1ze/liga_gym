Add-Type -AssemblyName System.Drawing

$primary = [System.Drawing.Color]::FromArgb(255, 29, 78, 216)
$secondary = [System.Drawing.Color]::FromArgb(255, 132, 204, 22)
$tertiary = [System.Drawing.Color]::FromArgb(255, 20, 184, 166)
$deep = [System.Drawing.Color]::FromArgb(255, 15, 23, 42)

function New-LigaIconBitmap([int]$size) {
  $bitmap = New-Object System.Drawing.Bitmap $size, $size
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

  $bounds = New-Object System.Drawing.Rectangle 0, 0, $size, $size
  $background = New-Object System.Drawing.Drawing2D.LinearGradientBrush $bounds, $primary, $tertiary, 45
  $graphics.FillRectangle($background, $bounds)
  $background.Dispose()

  $glow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(36, 255, 255, 255))
  $graphics.FillEllipse($glow, $size * 0.12, $size * 0.10, $size * 0.76, $size * 0.76)
  $glow.Dispose()

  $ring = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(238, 255, 255, 255)), ($size * 0.066)
  $ring.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $ring.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawArc($ring, $size * 0.18, $size * 0.18, $size * 0.64, $size * 0.64, -225, 310)
  $ring.Dispose()

  $accent = New-Object System.Drawing.Pen $secondary, ($size * 0.053)
  $accent.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $accent.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $graphics.DrawArc($accent, $size * 0.18, $size * 0.18, $size * 0.64, $size * 0.64, 30, 72)
  $accent.Dispose()

  $barBrush = New-Object System.Drawing.SolidBrush $deep
  $barY = $size * 0.512
  $weightSize = $size * 0.19
  $graphics.FillEllipse($barBrush, $size * 0.18, $barY - $weightSize / 2, $weightSize, $weightSize)
  $graphics.FillEllipse($barBrush, $size * 0.63, $barY - $weightSize / 2, $weightSize, $weightSize)

  $bar = New-Object System.Drawing.Pen $deep, ($size * 0.074)
  $bar.StartCap = [System.Drawing.Drawing2D.LineCap]::Square
  $bar.EndCap = [System.Drawing.Drawing2D.LineCap]::Square
  $graphics.DrawLine($bar, $size * 0.27, $barY, $size * 0.73, $barY)
  $bar.Dispose()
  $barBrush.Dispose()

  $spark = New-Object System.Drawing.SolidBrush $secondary
  $graphics.FillEllipse($spark, $size * 0.64, $size * 0.22, $size * 0.11, $size * 0.11)
  $spark.Dispose()

  $graphics.Dispose()
  return $bitmap
}

function Save-LigaIcon([string]$relativePath, [int]$size) {
  $path = Join-Path (Get-Location) $relativePath
  $bitmap = New-LigaIconBitmap $size
  $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bitmap.Dispose()
}

$icons = @{
  'android\app\src\main\res\mipmap-mdpi\ic_launcher.png' = 48
  'android\app\src\main\res\mipmap-hdpi\ic_launcher.png' = 72
  'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png' = 96
  'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png' = 144
  'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png' = 192
  'web\favicon.png' = 32
  'web\icons\Icon-192.png' = 192
  'web\icons\Icon-maskable-192.png' = 192
  'web\icons\Icon-512.png' = 512
  'web\icons\Icon-maskable-512.png' = 512
  'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_16.png' = 16
  'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_32.png' = 32
  'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_64.png' = 64
  'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_128.png' = 128
  'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_256.png' = 256
  'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_512.png' = 512
  'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_1024.png' = 1024
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png' = 20
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png' = 40
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png' = 60
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png' = 29
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png' = 58
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png' = 87
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png' = 40
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png' = 80
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png' = 120
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png' = 120
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png' = 180
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png' = 76
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png' = 152
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png' = 167
  'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png' = 1024
}

foreach ($entry in $icons.GetEnumerator()) {
  Save-LigaIcon $entry.Key $entry.Value
}

$iconBitmap = New-LigaIconBitmap 256
$handle = $iconBitmap.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($handle)
$stream = [System.IO.File]::Create((Join-Path (Get-Location) 'windows\runner\resources\app_icon.ico'))
$icon.Save($stream)
$stream.Dispose()
$icon.Dispose()
$iconBitmap.Dispose()

Write-Host 'App icons generated.'
