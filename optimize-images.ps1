Add-Type -AssemblyName System.Drawing

$srcDir = "E:\ClaudeCode\Ajeesh-Wedding\images"
$dstDir = "E:\ClaudeCode\Ajeesh-Wedding\images\web"
$maxDim = 1800
$quality = 78L

if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir | Out-Null }

$files = @("1.jpeg","2.jpeg","3.jpeg","4.JPG","5.JPG","6.JPG","7.JPG")

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $quality)

foreach ($f in $files) {
    $srcPath = Join-Path $srcDir $f
    if (-not (Test-Path $srcPath)) { Write-Host "MISSING: $f"; continue }

    $img = [System.Drawing.Image]::FromFile($srcPath)

    # Respect EXIF orientation tag (274) so rotated phone/camera photos come out upright
    if ($img.PropertyIdList -contains 274) {
        $orientation = $img.GetPropertyItem(274).Value[0]
        switch ($orientation) {
            2 { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
            3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
            4 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipX) }
            5 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
            6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
            7 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
            8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
        }
    }

    $w = $img.Width
    $h = $img.Height
    $scale = [Math]::Min(1.0, $maxDim / [Math]::Max($w, $h))
    $newW = [int]($w * $scale)
    $newH = [int]($h * $scale)

    $bmp = New-Object System.Drawing.Bitmap($newW, $newH)
    $bmp.SetResolution($img.HorizontalResolution, $img.VerticalResolution)
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $gfx.DrawImage($img, 0, 0, $newW, $newH)

    $outName = [System.IO.Path]::GetFileNameWithoutExtension($f) + ".jpg"
    $outPath = Join-Path $dstDir $outName
    $bmp.Save($outPath, $jpegCodec, $encParams)

    $gfx.Dispose()
    $bmp.Dispose()
    $img.Dispose()

    $srcSize = (Get-Item $srcPath).Length
    $dstSize = (Get-Item $outPath).Length
    Write-Host "$f -> $outName : $([Math]::Round($srcSize/1MB,2))MB -> $([Math]::Round($dstSize/1MB,2))MB ($($newW)x$($newH))"
}
