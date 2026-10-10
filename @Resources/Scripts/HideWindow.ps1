# Control-Plaine: start a tray app with its window hidden.
# For apps with no "start minimized" option (DeepCool). Starts the program, waits
# for its main window, and hides it with ShowWindow(SW_HIDE). The app keeps
# running and its tray icon still opens the window.
#   powershell -File HideWindow.ps1 -Path "C:\DeepCool\DeepCool.exe" [-Arguments "..."] [-Seconds 20]
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Arguments = '',
    [int]$Seconds = 20
)

Add-Type -Namespace ControlPlaine -Name Win -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(System.IntPtr hWnd);
'@

$name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
$dir = Split-Path -Parent $Path

# Start through the shell, like a shortcut does (DeepCool exits on its own when
# started from some consoles).
$start = @{ FilePath = $Path; WorkingDirectory = $dir }
if ($Arguments) { $start.ArgumentList = $Arguments }
Start-Process @start

# Hide every visible main window the app shows during the first few seconds
# (Electron apps can show their window more than once while loading).
$hidden = $false
$deadline = (Get-Date).AddSeconds($Seconds)
while ((Get-Date) -lt $deadline) {
    foreach ($p in Get-Process -Name $name -ErrorAction SilentlyContinue) {
        $h = $p.MainWindowHandle
        if ($h -ne [System.IntPtr]::Zero -and [ControlPlaine.Win]::IsWindowVisible($h)) {
            [void][ControlPlaine.Win]::ShowWindow($h, 0)
            if (-not $hidden) {
                $hidden = $true
                # Keep watching a little longer, then stop.
                $deadline = (Get-Date).AddSeconds(4)
            }
        }
    }
    Start-Sleep -Milliseconds 150
}
