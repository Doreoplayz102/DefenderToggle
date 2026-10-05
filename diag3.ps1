$rp = 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection'
$out = @()

function Log($m) { Write-Output $m; $script:out += $m }

$before = Get-ItemPropertyValue $rp 'DisableRealtimeMonitoring' -ErrorAction SilentlyContinue
Log "before: reg=$before"

# Direct registry write
& reg.exe add 'HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection' /v DisableRealtimeMonitoring /t REG_DWORD /d 0 /f | Out-Null
Log ("reg.exe add exit: " + $LASTEXITCODE)

for ($i = 1; $i -le 6; $i++) {
  Start-Sleep -Seconds 1
  $v = Get-ItemPropertyValue $rp 'DisableRealtimeMonitoring' -ErrorAction SilentlyContinue
  $rtp = (Get-MpComputerStatus).RealTimeProtectionEnabled
  Log "t+$i`: reg=$v RTP=$rtp"
}

# Official API again
try { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop; Log 'Set-MpPreference: OK' }
catch { Log ('Set-MpPreference FAILED: ' + $_.Exception.Message) }
Start-Sleep -Seconds 3
$v = Get-ItemPropertyValue $rp 'DisableRealtimeMonitoring' -ErrorAction SilentlyContinue
$rtp = (Get-MpComputerStatus).RealTimeProtectionEnabled
Log "final: reg=$v RTP=$rtp"

# Recent events that might show who touched it
Log '--- events last 3 min mentioning Realtime ---'
Get-WinEvent -LogName 'Microsoft-Windows-Windows Defender/Operational' -MaxEvents 30 -ErrorAction SilentlyContinue |
  Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-3) -and $_.Message -match 'Realtime|Real-time|5001' } |
  ForEach-Object {
    $m = ($_.Message -replace '\s+', ' ')
    if ($m.Length -gt 200) { $m = $m.Substring(0, 200) }
    Log ('  ' + $_.TimeCreated.ToString('HH:mm:ss') + ' id=' + $_.Id + ' ' + $m)
  }

$out | Set-Content -Path (Join-Path $PSScriptRoot 'diag3-result.txt')
