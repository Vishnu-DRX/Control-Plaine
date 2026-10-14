# Control-Plaine | Controllers
# Opens the app a controller row points at, but never starts a second copy.
#   powershell -File OpenApp.ps1 -Target "steam://rungameid/1812620" -Process DSX
# If a process named -Process already runs, its main window is brought to the
# front, also when the app keeps it hidden in the tray (minimised and not
# visible, which Process.MainWindowHandle does not report). If it runs without
# any window nothing is started, as Steam would refuse a game that is already
# running. Otherwise -Target is opened. With no -Process the target is simply
# opened. -DryRun only prints what it would do.
param(
    [Parameter(Mandatory = $true)][string]$Target,
    [string]$Process = '',
    [switch]$DryRun
)

if ($Process) {
    $script:pids = @(Get-Process -Name $Process -ErrorAction SilentlyContinue | ForEach-Object { [uint32]$_.Id })
    if ($script:pids.Count -gt 0) {
        Add-Type -Namespace CP -Name Win -MemberDefinition @'
public delegate bool EnumProc(System.IntPtr h, System.IntPtr l);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, System.IntPtr l);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(System.IntPtr h, out uint pid);
[DllImport("user32.dll")] public static extern System.IntPtr GetWindow(System.IntPtr h, uint cmd);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(System.IntPtr h, System.Text.StringBuilder s, int max);
[DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr h, int cmd);
[DllImport("user32.dll")] public static extern bool IsIconic(System.IntPtr h);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(System.IntPtr h);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(System.IntPtr h);
[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, System.UIntPtr extra);
'@
        # The app's main window: top level (no owner) and titled, whether or not it
        # is visible. Visible ones win over hidden ones.
        $script:found = New-Object System.Collections.ArrayList
        $cb = [CP.Win+EnumProc] {
            param($h, $l)
            $wpid = [uint32]0
            [void][CP.Win]::GetWindowThreadProcessId($h, [ref]$wpid)
            if ($script:pids -contains $wpid -and [CP.Win]::GetWindow($h, 4) -eq [System.IntPtr]::Zero) {
                $sb = New-Object System.Text.StringBuilder 256
                $null = [CP.Win]::GetWindowTextW($h, $sb, 256)
                if ($sb.Length -gt 0) {
                    [void]$script:found.Add([pscustomobject]@{ H = $h; Title = $sb.ToString(); Visible = [CP.Win]::IsWindowVisible($h) })
                }
            }
            return $true
        }
        [void][CP.Win]::EnumWindows($cb, [System.IntPtr]::Zero)
        $win = @($script:found | Sort-Object { -[int]$_.Visible })[0]
        if ($DryRun) {
            Write-Output "running; would focus window: $(if ($win) { '"' + $win.Title + '" visible=' + $win.Visible } else { '(none, do nothing)' })"
            exit 0
        }
        if ($win) {
            $h = $win.H
            # SW_RESTORE when minimised, else SW_SHOW.
            $null = [CP.Win]::ShowWindow($h, $(if ([CP.Win]::IsIconic($h)) { 9 } else { 5 }))
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
