# Control-Plaine: start a tray app with its window hidden.
# For apps with no "start minimized" option (DeepCool). Starts the program
# with a hidden show state, then watches every top-level window the app owns
# and hides it with ShowWindow(SW_HIDE) the moment it becomes visible. The
# app keeps running and its tray icon still opens the window.
#   powershell -File HideWindow.ps1 -Path "C:\DeepCool\DeepCool.exe" [-Arguments "..."] [-Seconds 20]
# Exit code 0 once the app runs and its window was hidden (or never showed),
# 1 if the app is not running at the end.
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Arguments = '',
    [int]$Seconds = 20
)

Add-Type -Namespace ControlPlaine -Name Win -MemberDefinition @'
public delegate bool EnumProc(System.IntPtr hWnd, System.IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, System.IntPtr lParam);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(System.IntPtr hWnd, out uint pid);
[DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(System.IntPtr hWnd);
[DllImport("user32.dll")] public static extern System.IntPtr GetWindow(System.IntPtr hWnd, uint cmd);
'@

$name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
$dir = Split-Path -Parent $Path

# Start through the shell, like a shortcut does (DeepCool exits on its own when
# started from some consoles). Hidden asks the app to start with SW_HIDE; apps
# that honour it never show a window at all.
$start = @{ FilePath = $Path; WorkingDirectory = $dir; WindowStyle = 'Hidden' }
if ($Arguments) { $start.ArgumentList = $Arguments }
Start-Process @start

# Hide each visible, unowned top-level window of the app as soon as it shows
# (Electron apps can show their window more than once while loading). Polls
# every 10 ms so a window is gone before it is drawn on screen.
$script:hidden = $false
$cb = [ControlPlaine.Win+EnumProc]{
    param($h, $l)
    $wpid = [uint32]0
    [void][ControlPlaine.Win]::GetWindowThreadProcessId($h, [ref]$wpid)
    if ($script:pids -contains $wpid -and [ControlPlaine.Win]::IsWindowVisible($h) -and
        [ControlPlaine.Win]::GetWindow($h, 4) -eq [System.IntPtr]::Zero) {
        [void][ControlPlaine.Win]::ShowWindow($h, 0)
        $script:hidden = $true
    }
    return $true
}
$deadline = (Get-Date).AddSeconds($Seconds)
$lastPids = (Get-Date)
$script:pids = @()
while ((Get-Date) -lt $deadline) {
    if ($script:pids.Count -eq 0 -or ((Get-Date) - $lastPids).TotalMilliseconds -gt 250) {
        $script:pids = @(Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
        $lastPids = Get-Date
    }
    if ($script:pids.Count -gt 0) { [void][ControlPlaine.Win]::EnumWindows($cb, [System.IntPtr]::Zero) }
    if ($script:hidden -and $deadline -gt (Get-Date).AddSeconds(4)) {
        # Keep watching a little longer, then stop.
        $deadline = (Get-Date).AddSeconds(4)
    }
    Start-Sleep -Milliseconds 10
}
if (Get-Process -Name $name -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }
