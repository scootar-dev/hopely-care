$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$source = [System.Drawing.Bitmap]::FromFile((Join-Path $root 'logo/logo hopelycare.jpg'))

function Export-BrandImage($Crop, [int]$Size, [double]$Occupancy, [string]$Path, [bool]$Transparent = $false) {
    $format = if ($Transparent) { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb } else { [System.Drawing.Imaging.PixelFormat]::Format24bppRgb }
    $bitmap = New-Object System.Drawing.Bitmap($Size, $Size, $format)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $scale = $Size * $Occupancy / [Math]::Max($Crop.Width, $Crop.Height)
    $width = [int]($Crop.Width * $scale)
    $height = [int]($Crop.Height * $scale)
    $destination = New-Object System.Drawing.Rectangle(([int](($Size - $width) / 2)), ([int](($Size - $height) / 2)), $width, $height)
    $graphics.DrawImage($source, $destination, $Crop, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    if ($Transparent) {
        # Remove the JPEG's white matte while retaining antialiased navy edges.
        for ($y = 0; $y -lt $Size; $y++) {
            for ($x = 0; $x -lt $Size; $x++) {
                $pixel = $bitmap.GetPixel($x, $y)
                $minimum = [Math]::Min($pixel.R, [Math]::Min($pixel.G, $pixel.B))
                $alpha = 255 - $minimum
                if ($alpha -lt 20) {
                    $bitmap.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                } else {
                    $red = [int](($pixel.R - $minimum) * 255 / $alpha)
                    $green = [int](($pixel.G - $minimum) * 255 / $alpha)
                    $blue = [int](($pixel.B - $minimum) * 255 / $alpha)
                    $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $red, $green, $blue))
                }
            }
        }
    }
    $target = Join-Path $root $Path
    [System.IO.Directory]::CreateDirectory((Split-Path $target -Parent)) | Out-Null
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

try {
    # Symbol bounds in the original 1148 x 928 artwork.
    $mark = New-Object System.Drawing.Rectangle(370, 145, 418, 430)
    Export-BrandImage $mark 512 0.94 'mobile/assets/branding/hopely-mark.png' $true
    $densities = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
    foreach ($density in $densities.Keys) {
        Export-BrandImage $mark $densities[$density] 0.66 "mobile/android/app/src/main/res/mipmap-$density/ic_launcher.png"
        Export-BrandImage $mark ($densities[$density] * 4) 0.66 "mobile/android/app/src/main/res/drawable-$density/brand_splash.png" $true
    }
    $catalog = Get-Content (Join-Path $root 'mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
    foreach ($icon in $catalog.images) {
        $size = [double]::Parse(($icon.size -split 'x')[0], [Globalization.CultureInfo]::InvariantCulture) * [int](($icon.scale -split 'x')[0])
        Export-BrandImage $mark $size 0.72 "mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/$($icon.filename)"
    }
    foreach ($scale in 1..3) {
        $suffix = if ($scale -eq 1) { '' } else { "@${scale}x" }
        Export-BrandImage $mark (192 * $scale) 0.66 "mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png"
    }
    foreach ($size in 192, 512) {
        Export-BrandImage $mark $size 0.72 "mobile/web/icons/Icon-$size.png"
        Export-BrandImage $mark $size 0.60 "mobile/web/icons/Icon-maskable-$size.png"
    }
    Export-BrandImage $mark 32 0.94 'mobile/web/favicon.png'
} finally {
    $source.Dispose()
}
