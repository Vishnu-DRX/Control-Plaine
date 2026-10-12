# Control-Plaine: open a signalrgb:// link without the SignalRGB window
# staying on screen.
# SignalRGB brings its window up for every application URL. If the window was
# not visible when this started, this opens the link and hides the window (the
# tray icon stays and still opens it) the moment it shows. If you already have
# the window open it is left alone.
#   powershell -File SignalRGBApply.ps1 -Url "signalrgb://effect/apply/Solid%20Color?color=%2300FFFF"
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [string]$Name = 'SignalRgb',
    [int]$Seconds = 8
)

Add-Type -Namespace ControlPlaine -Name SgWin -MemberDefinition @'
public delegate bool EnumProc(System.IntPtr hWnd, System.IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, System.IntPtr lParam);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(System.IntPtr hWnd, out uint pid);
[DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(System.IntPtr hWnd);
[DllImport("user32.dll")] public static extern bool IsIconic(System.IntPtr hWnd);
[DllImport("user32.dll")] public static extern System.IntPtr GetWindow(System.IntPtr hWnd, uint cmd);
'@

$script:pids = @()
$script:hide = $false
$script:seen = 0
$cb = [ControlPlaine.SgWin+EnumProc]{
    param($h, $l)
    $wpid = [uint32]0
    [void][ControlPlaine.SgWin]::GetWindowThreadProcessId($h, [ref]$wpid)
    if ($script:pids -contains $wpid -and [ControlPlaine.SgWin]::IsWindowVisible($h) -and
        [ControlPlaine.SgWin]::GetWindow($h, 4) -eq [System.IntPtr]::Zero -and
        -not [ControlPlaine.SgWin]::IsIconic($h)) {
        if ($script:hide) { [void][ControlPlaine.SgWin]::ShowWindow($h, 0) }
        $script:seen++
    }
    return $true
}

$script:pids = @(Get-Process -Name $Name -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
[void][ControlPlaine.SgWin]::EnumWindows($cb, [System.IntPtr]::Zero)
$alreadyOpen = $script:seen -gt 0
$script:hide = -not $alreadyOpen
$script:seen = 0

Start-Process $Url
if ($alreadyOpen) { exit 0 }

# Poll every 10 ms; keep watching a little after the last window was hidden,
# because the app can show it more than once while it loads the dashboard.
$deadline = (Get-Date).AddSeconds($Seconds)
$lastPids = Get-Date
while ((Get-Date) -lt $deadline) {
    if ($script:pids.Count -eq 0 -or ((Get-Date) - $lastPids).TotalMilliseconds -gt 250) {
        $script:pids = @(Get-Process -Name $Name -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
        $lastPids = Get-Date
    }
    if ($script:pids.Count -gt 0) {
        $before = $script:seen
        [void][ControlPlaine.SgWin]::EnumWindows($cb, [System.IntPtr]::Zero)
        if ($script:seen -gt $before -and $deadline -gt (Get-Date).AddSeconds(3)) {
            $deadline = (Get-Date).AddSeconds(3)
        }
    }
    Start-Sleep -Milliseconds 10
}
exit 0
