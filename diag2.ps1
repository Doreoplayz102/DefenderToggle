Write-Host '--- Get-MpPreference disable flags ---'
$p = Get-MpPreference
'DisableRealtimeMonitoring  = ' + $p.DisableRealtimeMonitoring
'DisableBehaviorMonitoring  = ' + $p.DisableBehaviorMonitoring
'DisableIOAVProtection      = ' + $p.DisableIOAVProtection
'DisableScriptScanning      = ' + $p.DisableScriptScanning
'DisableArchiveScanning     = ' + $p.DisableArchiveScanning
'MAPSReporting              = ' + [int]$p.MAPSReporting
'SubmitSamplesConsent       = ' + [int]$p.SubmitSamplesConsent

Write-Host '--- policy keys present ---'
$k = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
if (Test-Path $k) {
  Get-ChildItem $k -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
  Get-ItemProperty $k -ErrorAction SilentlyContinue | Out-Null
  $rtp = Join-Path $k 'Real-Time Protection'
  if (Test-Path $rtp) { Write-Host 'RTP policy values:'; (Get-Item $rtp).GetValueNames() | ForEach-Object { '  ' + $_ + ' = ' + (Get-ItemPropertyValue $rtp $_) } }
  $spy = Join-Path $k 'Spynet'
  if (Test-Path $spy) { Write-Host 'Spynet policy values:'; (Get-Item $spy).GetValueNames() | ForEach-Object { '  ' + $_ + ' = ' + (Get-ItemPropertyValue $spy $_) } }
} else { Write-Host 'no policy key' }

Write-Host '--- last 5001 / 1116 / 1117 full messages ---'
Get-WinEvent -LogName 'Microsoft-Windows-Windows Defender/Operational' -MaxEvents 40 |
  Where-Object { $_.Id -in 5001,1116,1117 -and $_.TimeCreated -gt (Get-Date).AddHours(-1) } |
  ForEach-Object {
    Write-Host ('### id=' + $_.Id + ' at ' + $_.TimeCreated.ToString('HH:mm:ss'))
    Write-Host ($_.Message -replace '\s+', ' ')
  }
