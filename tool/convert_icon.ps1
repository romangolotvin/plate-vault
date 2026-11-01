Add-Type -AssemblyName System.Drawing
$src = 'E:\dev\plate-vault\assets\app_icon_source.jpg'
$dst = 'E:\dev\plate-vault\assets\app_icon.png'
$img = [System.Drawing.Image]::FromFile($src)
$bmp = New-Object System.Drawing.Bitmap 1024, 1024
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(255, 10, 6, 18))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($img, 0, 0, 1024, 1024)
$g.Dispose()
$img.Dispose()
$bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "OK $dst"
