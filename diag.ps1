Write-Host '--- Defender Operational (last 40 min) ---'
try {
  Get-WinEvent -LogName 'Microsoft-Windows-Windows Defender/Operational' -MaxEvents 60 -ErrorAction Stop |
    Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-40) } |
    ForEach-Object {
      $m = ($_.Message -replace '\s+', ' ')
      if ($m.Length -gt 240) { $m = $m.Substring(0, 240) }
      '{0} id={1} {2}' -f $_.TimeCreated.ToString('HH:mm:ss'), $_.Id, $m
    }
} catch { Write-Host ('none: ' + $_.Exception.Message) }

Write-Host '--- AppLocker EXE ---'
try {
  Get-WinEvent -LogName 'Microsoft-Windows-AppLocker/EXE and DLL' -MaxEvents 30 -ErrorAction Stop |
    Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-40) } |
    ForEach-Object {
      $m = ($_.Message -replace '\s+', ' ')
      if ($m.Length -gt 240) { $m = $m.Substring(0, 240) }
      '{0} id={1} {2}' -f $_.TimeCreated.ToString('HH:mm:ss'), $_.Id, $m
    }
} catch { Write-Host ('none: ' + $_.Exception.Message) }
