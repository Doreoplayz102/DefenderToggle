$out = New-Object System.Collections.Generic.List[string]
function P($m) { $script:out.Add($m) }

function Snap($tag) {
  $live = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection' 'DisableRealtimeMonitoring' -ErrorAction SilentlyContinue
  $s = Get-MpComputerStatus
  P ($tag + ': live reg=' + $live + ' RTP=' + $s.RealTimeProtectionEnabled + ' Behavior=' + $s.BehaviorMonitorEnabled + ' Ioav=' + $s.IoavProtectionEnabled + ' OnAccess=' + $s.OnAccessProtectionEnabled)
}

Snap 'before'
P '--- Set-MpPreference -DisableRealtimeMonitoring $false ---'
try {
  Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
  P 'Set-MpPreference: OK returned'
} catch {
  P ('Set-MpPreference FAILED: ' + $_.Exception.Message)
}

for ($i = 1; $i -le 8; $i++) {
  Start-Sleep -Seconds 2
  Snap ('t+' + $i)
}

P '--- full messages of events in last 6 min ---'
try {
  Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Defender/Operational'; StartTime=(Get-Date).AddMinutes(-6)} -ErrorAction SilentlyContinue |
    Where-Object { $_.Id -in 5013,5007,5001,5008 } |
    Sort-Object TimeCreated | ForEach-Object {
      P ('### ' + $_.TimeCreated.ToString('HH:mm:ss') + ' id=' + $_.Id)
      P (($_.Message -replace '\s+', ' '))
    }
} catch { P ('events failed: ' + $_.Exception.Message) }

P ''
P '--- TamperProtection related feature values ---'
$tp = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Features' -ErrorAction SilentlyContinue
$tp.PSObject.Properties | Where-Object { $_.Name -like '*amper*' } | ForEach-Object { P ($_.Name + ' = ' + $_.Value) }

$out | Set-Content -Path (Join-Path $PSScriptRoot 'restore2-result.txt')
$out | ForEach-Object { Write-Output $_ }
