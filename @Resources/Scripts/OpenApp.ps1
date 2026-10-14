# Control-Plaine | Controllers
# Opens the app a controller row points at, but never starts a second copy.
#   powershell -File OpenApp.ps1 -Target "steam://rungameid/1812620" -Process DSX
# If a process named -Process already has a window, that window is brought to
# the front. If it runs without a window (in the tray) nothing is started, as
# Steam would refuse a game that is already running. Otherwise -Target is
# opened. With no -Process the target is simply opened. -DryRun only prints
# what it would do.
param(
    [Parameter(Mandatory = $true)][string]$Target,
    [string]$Process = '',
    [switch]$DryRun
)

if ($Process) {
    $running = @(Get-Process -Name $Process -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        $proc = $running | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
        if ($DryRun) { Write-Output "running; would focus window: $(if ($proc) { $proc.MainWindowTitle } else { '(none, do nothing)' })"; exit 0 }
        if ($proc) {
            Add-Type -Namespace CP -Name Win -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr h, int cmd);
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
'@
            $h = $proc.MainWindowHandle
            # SW_RESTORE if minimised, else SW_SHOW.
            $null = [CP.Win]::ShowWindowAsync($h, $(if ([CP.Win]::IsIconic($h)) { 9 } else { 5 }))
            # A tap of Alt lets a background process take the foreground.
            [CP.Win]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)
            [CP.Win]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
            $null = [CP.Win]::SetForegroundWindow($h)
        }
        exit 0
    }
}
if ($DryRun) { Write-Output "not running; would start: $Target"; exit 0 }
Start-Process -FilePath $Target
