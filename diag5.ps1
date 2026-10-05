$out = New-Object System.Collections.Generic.List[string]
function P($m) { $script:out.Add($m) }

P '--- all Defender Operational events 14:40 -> now ---'
try {
  Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Defender/Operational'; StartTime=(Get-Date).Date.AddHours(14).AddMinutes(40)} -ErrorAction Stop |
    Sort-Object TimeCreated | ForEach-Object {
      $m = ($_.Message -replace '\s+', ' ')
      if ($m.Length -gt 400) { $m = $m.Substring(0, 400) }
      P ('{0} id={1} {2}' -f $_.TimeCreated.ToString('HH:mm:ss'), $_.Id, $m)
    }
} catch { P ('failed: ' + $_.Exception.Message) }

P ''
P '--- live value now ---'
$live = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection' 'DisableRealtimeMonitoring' -ErrorAction SilentlyContinue
P ('DisableRealtimeMonitoring = ' + $live)

$out | Set-Content -Path (Join-Path $PSScriptRoot 'diag5-result.txt')
$out | ForEach-Object { Write-Output $_ }
