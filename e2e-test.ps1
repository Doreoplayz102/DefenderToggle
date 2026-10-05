$log = Join-Path $PSScriptRoot 'e2e-result.txt'
if (Test-Path $log) { Remove-Item $log -Force }

function Step($header, $argList) {
  Add-Content -Path $log -Value ""
  Add-Content -Path $log -Value "=== $header ==="
  $out = "$log.out.tmp"
  $err = "$log.err.tmp"
  $p = Start-Process -FilePath (Join-Path $PSScriptRoot 'dist\DefenderToggle.exe') `
        -ArgumentList $argList -Wait -PassThru -NoNewWindow `
        -RedirectStandardOutput $out -RedirectStandardError $err
  Add-Content -Path $log -Value "exit=$($p.ExitCode)"
  if (Test-Path $out) { Get-Content $out | Add-Content -Path $log; Remove-Item $out -Force }
  if (Test-Path $err) {
    $e = Get-Content $err
    if ($e) { Add-Content -Path $log -Value ("stderr: " + ($e -join ' | ')) }
    Remove-Item $err -Force
  }
}

Step "status BEFORE" @('--cli','status')
Step "DISABLE"       @('--cli','disable','--yes')
Step "status DURING" @('--cli','status')
Step "ENABLE"        @('--cli','enable')
Step "status AFTER"  @('--cli','status')

Add-Content -Path $log -Value ""
Add-Content -Path $log -Value "=== snapshot still present (should be False) ==="
Add-Content -Path $log -Value (Test-Path (Join-Path $env:LOCALAPPDATA 'DefenderToggle\state.json'))
Add-Content -Path $log -Value "DONE"
