Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class NativeWin {
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int n);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
'@

Start-Process -FilePath "$PSScriptRoot\dist\DefenderToggle.exe"
$h = [IntPtr]::Zero
for ($i = 0; $i -lt 30; $i++) {
  Start-Sleep -Seconds 1
  $p = Get-Process -Name DefenderToggle -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -eq $p) { Write-Output "PROCESS_NOT_RUNNING (iter $i)"; exit 1 }
  $p.Refresh()
  if ($p.MainWindowHandle -ne [IntPtr]::Zero) { $h = $p.MainWindowHandle; Write-Output "handle=$h title=$($p.MainWindowTitle) iter=$i"; break }
}
if ($h -eq [IntPtr]::Zero) { Write-Output "WINDOW_NOT_FOUND"; exit 1 }
Start-Sleep -Seconds 4
[NativeWin]::ShowWindow($h, 9) | Out-Null
[NativeWin]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 600
$r = New-Object NativeWin+RECT
[NativeWin]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Right - $r.Left
$ht = $r.Bottom - $r.Top
Write-Output "rect=$($r.Left),$($r.Top) ${w}x${ht}"
$bmp = New-Object System.Drawing.Bitmap($w, $ht)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, (New-Object System.Drawing.Size($w, $ht)))
$bmp.Save("$PSScriptRoot\gui.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "SAVED"
Get-Process -Name DefenderToggle -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Output "CLOSED"
