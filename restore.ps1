# Restore the single flag left off by the test (real-time monitoring).
try {
  Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
  "Set DisableRealtimeMonitoring = False: OK"
} catch {
  "FAILED: " + $_.Exception.Message
}
Start-Sleep -Seconds 2

$s = Get-MpComputerStatus
$p = Get-MpPreference
$lines = @(
  '--- verification ---',
  'RealTimeProtectionEnabled = ' + $s.RealTimeProtectionEnabled,
  'BehaviorMonitorEnabled    = ' + $s.BehaviorMonitorEnabled,
  'IoavProtectionEnabled     = ' + $s.IoavProtectionEnabled,
  'OnAccessProtectionEnabled = ' + $s.OnAccessProtectionEnabled,
  'AntivirusEnabled          = ' + $s.AntivirusEnabled,
  'AMServiceEnabled          = ' + $s.AMServiceEnabled,
  'DisableRealtimeMonitoring = ' + $p.DisableRealtimeMonitoring,
  'MAPSReporting             = ' + [int]$p.MAPSReporting,
  'SubmitSamplesConsent      = ' + [int]$p.SubmitSamplesConsent
)
$lines | ForEach-Object { Write-Output $_ }
$lines | Set-Content -Path (Join-Path $PSScriptRoot 'restore-result.txt')
