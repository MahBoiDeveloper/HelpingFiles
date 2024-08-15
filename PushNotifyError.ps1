Add-Type -AssemblyName System.Windows.Forms
$global:balmsg          = New-Object System.Windows.Forms.NotifyIcon
$path                   = (Get-Process -id $pid).Path
$balmsg.Icon            = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
$balmsg.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Error
$balmsg.BalloonTipTitle = $args[0]
$balmsg.BalloonTipText  = $args[1]
$balmsg.Visible         = $true
$balmsg.ShowBalloonTip(10000)