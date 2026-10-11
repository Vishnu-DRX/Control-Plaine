# Control-Plaine: what a Day-Date click opens.
#   -Target calendar  the Windows calendar (notification centre with the month
#                     view), by pressing Win+N like the taskbar clock does
#   -Target <other>   any program, file or URI, opened with the shell
param([string]$Target = 'calendar')

if ($Target -ne '' -and $Target -ne 'calendar') {
    Start-Process $Target
    exit
}
Add-Type -Namespace ControlPlaine -Name Keys -MemberDefinition @'
[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, System.UIntPtr extra);
'@
$up = 2
[ControlPlaine.Keys]::keybd_event(0x5B, 0, 0, [System.UIntPtr]::Zero)   # Win down
[ControlPlaine.Keys]::keybd_event(0x4E, 0, 0, [System.UIntPtr]::Zero)   # N down
[ControlPlaine.Keys]::keybd_event(0x4E, 0, $up, [System.UIntPtr]::Zero) # N up
[ControlPlaine.Keys]::keybd_event(0x5B, 0, $up, [System.UIntPtr]::Zero) # Win up
