param(
  [string]$SourceDir = "src/assets/images",
  [string]$OutputDir = "src/assets/images-optimized",
  [int]$MaxWidth = 720,
  [int]$MaxHeight = 720,
  [int]$Quality = 72
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object { $_.MimeType -eq "image/jpeg" } |
  Select-Object -First 1

$encoderParams = [System.Drawing.Imaging.EncoderParameters]::new(1)
$encoderParams.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new(
  [System.Drawing.Imaging.Encoder]::Quality,
  [long]$Quality
)

Get-ChildItem -Path $SourceDir -File -Filter "*.jpg" | ForEach-Object {
  $sourcePath = $_.FullName
  $outputPath = Join-Path $OutputDir $_.Name
  $image = $null
  $bitmap = $null
  $graphics = $null

  try {
    $image = [System.Drawing.Image]::FromFile($sourcePath)
    $scale = [Math]::Min(
      1,
      [Math]::Min($MaxWidth / $image.Width, $MaxHeight / $image.Height)
    )
    $width = [Math]::Max(1, [Math]::Round($image.Width * $scale))
    $height = [Math]::Max(1, [Math]::Round($image.Height * $scale))

    $bitmap = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($image, 0, 0, $width, $height)
    $bitmap.Save($outputPath, $jpegCodec, $encoderParams)
  }
  finally {
    if ($graphics) { $graphics.Dispose() }
    if ($bitmap) { $bitmap.Dispose() }
    if ($image) { $image.Dispose() }
  }
}

$sourceBytes = (Get-ChildItem -Path $SourceDir -File -Filter "*.jpg" |
  Measure-Object -Property Length -Sum).Sum
$outputBytes = (Get-ChildItem -Path $OutputDir -File -Filter "*.jpg" |
  Measure-Object -Property Length -Sum).Sum

Write-Output "Optimized menu images: $([Math]::Round($sourceBytes / 1MB, 2)) MB -> $([Math]::Round($outputBytes / 1MB, 2)) MB"
