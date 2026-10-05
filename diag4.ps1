$out = New-Object System.Collections.Generic.List[string]
function P($m) { $script:out.Add($m) }

P '=== BEFORE ==='
$rtp = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection' -ErrorAction SilentlyContinue
P ('live DisableRealtimeMonitoring = ' + $rtp.DisableRealtimeMonitoring)
P ('live DisableBehaviorMonitoring  = ' + $rtp.DisableBehaviorMonitoring)
P ('live DisableIOAVProtection      = ' + $rtp.DisableIOAVProtection)
P ('live DisableOnAccessProtection  = ' + $rtp.DisableOnAccessProtection)
$pol = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' -ErrorAction SilentlyContinue
if ($pol) {
  P ('POLICY DisableRealtimeMonitoring = ' + $pol.DisableRealtimeMonitoring)
  P ('POLICY DisableBehaviorMonitoring  = ' + $pol.DisableBehaviorMonitoring)
  P ('POLICY DisableIOAVProtection      = ' + $pol.DisableIOAVProtection)
  P ('POLICY DisableOnAccessProtection  = ' + $pol.DisableOnAccessProtection)
  P ('POLICY DisableScanOnRealtimeEnable= ' + $pol.DisableScanOnRealtimeEnable)
} else { P 'POLICY RTP key: absent' }
$sp = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' -ErrorAction SilentlyContinue
if ($sp) { P ('POLICY SPYNETReporting = ' + $sp.SPYNETReporting + ' SubmitSamplesConsent = ' + $sp.SubmitSamplesConsent) } else { P 'POLICY Spynet key: absent' }
$tp = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Features' -ErrorAction SilentlyContinue
P ('Features TamperProtection = ' + $tp.TamperProtection)
$s = Get-MpComputerStatus
P ('RTP enabled = ' + $s.RealTimeProtectionEnabled + ' Behavior = ' + $s.BehaviorMonitorEnabled + ' Ioav = ' + $s.IoavProtectionEnabled + ' OnAccess = ' + $s.OnAccessProtectionEnabled)

P ''
P '=== STEP 1: gpupdate /target:computer /force ==='
try {
  $g = & gpupdate.exe /target:computer /force 2>&1 | Out-String
  P $g.Trim()
} catch { P ('gpupdate failed: ' + $_.Exception.Message) }
Start-Sleep -Seconds 3
$s = Get-MpComputerStatus
$rtp = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection' -ErrorAction SilentlyContinue
P ('after gpupdate: live reg = ' + $rtp.DisableRealtimeMonitoring + ' RTP = ' + $s.RealTimeProtectionEnabled)

P ''
P '=== STEP 2: Set-MpPreference re-enable ==='
try {
  Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
  Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction Stop
  Set-MpPreference -DisableIOAVProtection $false -ErrorAction Stop
  Set-MpPreference -DisableOnAccessProtection $false -ErrorAction Stop
  P 'Set-MpPreference: OK'
} catch { P ('Set-MpPreference FAILED: ' + $_.Exception.Message) }
Start-Sleep -Seconds 5
$s = Get-MpComputerStatus
$rtp = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection' -ErrorAction SilentlyContinue
P ('after Set-MpPreference: live reg = ' + $rtp.DisableRealtimeMonitoring + ' RTP = ' + $s.RealTimeProtectionEnabled + ' Behavior = ' + $s.BehaviorMonitorEnabled + ' Ioav = ' + $s.IoavProtectionEnabled + ' OnAccess = ' + $s.OnAccessProtectionEnabled)

P ''
P '=== STEP 3: Restart-Service WinDefend ==='
try {
  Restart-Service -Name WinDefend -Force -ErrorAction Stop
  P 'restart: OK'
} catch { P ('restart FAILED: ' + $_.Exception.Message) }
Start-Sleep -Seconds 8
$s = Get-MpComputerStatus
$rtp = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection' -ErrorAction SilentlyContinue
P ('after restart: live reg = ' + $rtp.DisableRealtimeMonitoring + ' RTP = ' + $s.RealTimeProtectionEnabled + ' Behavior = ' + $s.BehaviorMonitorEnabled + ' Ioav = ' + $s.IoavProtectionEnabled + ' OnAccess = ' + $s.OnAccessProtectionEnabled)

P ''
P '=== FINAL PREFS ==='
$p = Get-MpPreference
P ('DisableRealtimeMonitoring = ' + $p.DisableRealtimeMonitoring)
P ('DisableBehaviorMonitoring  = ' + $p.DisableBehaviorMonitoring)
P ('DisableIOAVProtection      = ' + $p.DisableIOAVProtection)
P ('MAPSReporting              = ' + [int]$p.MAPSReporting)
P ('SubmitSamplesConsent       = ' + [int]$p.SubmitSamplesConsent)

P ''
P '=== events last 15 min (5013/5007/5001/1116) ==='
try {
  Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Defender/Operational'; StartTime=(Get-Date).AddMinutes(-15)} -ErrorAction SilentlyContinue |
    Where-Object { $_.Id -in 5013,5007,5001,1116,1117 } |
    Sort-Object TimeCreated | ForEach-Object { P ('  ' + $_.TimeCreated.ToString('HH:mm:ss') + ' id=' + $_.Id + ' ' + $_.Message.Split("`n")[0]) }
} catch { P ('events failed: ' + $_.Exception.Message) }

$out | Set-Content -Path (Join-Path $PSScriptRoot 'diag4-result.txt')
$out | ForEach-Object { Write-Output $_ }
