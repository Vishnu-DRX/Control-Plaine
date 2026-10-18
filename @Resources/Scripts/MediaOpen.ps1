# Control-Plaine | Media
# Brings the app that is playing to the front (click on the title or artist).
# Reads the current Windows media session's app id (the same session the
# skin shows), then focuses that app's window, or starts/activates the app.
#   Spotify.exe, foobar2000.exe ...   win32 app: focus its window
#   Chrome, MSEdge, 308046B0AF4A39CB  browsers: focus the browser window
#   Publisher.App_xyz!App             Store app: activate it via shell:AppsFolder
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
    $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
} | Select-Object -First 1
function Await($op, [Type]$type) {
    $task = $asTask.MakeGenericMethod($type).Invoke($null, @($op))
    $null = $task.Wait(5000)
    $task.Result
}

$mgrType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType = WindowsRuntime]
$session = (Await ($mgrType::RequestAsync()) $mgrType).GetCurrentSession()
if (-not $session) { exit 1 }
$aumid = $session.SourceAppUserModelId
if (-not $aumid) { exit 1 }

# Browser and app ids that are not exe names, mapped to their process name.
$known = @{
    'Chrome'           = 'chrome'
    'MSEdge'           = 'msedge'
    '308046B0AF4A39CB' = 'firefox'
    'Brave'            = 'brave'
    'Opera'            = 'opera'
    'Vivaldi'          = 'vivaldi'
}
$name = $null
if ($aumid -match '\.exe$') { $name = [IO.Path]::GetFileNameWithoutExtension($aumid) }
elseif ($known.ContainsKey($aumid)) { $name = $known[$aumid] }

if ($name) {
    $proc = Get-Process -Name $name -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
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
        exit 0
    }
    # Running with no window (minimised to the tray): starting the same exe
    # again makes most apps show the existing window. A Win32 exe id is not
    # a Store app id, so there is nothing else to try.
    $any = Get-Process -Name $name -ErrorAction SilentlyContinue | Where-Object { $_.Path } | Select-Object -First 1
    if ($any) { Start-Process -FilePath $any.Path; exit 0 }
    if ($aumid -match '\.exe$') { exit 1 }
}

# Store apps (and anything else registered by app id): activating focuses a
# running instance.
Start-Process "shell:AppsFolder\$aumid"
