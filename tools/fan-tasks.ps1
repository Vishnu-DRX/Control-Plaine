# Control-Plaine: one-time setup for the Fan Control skin. Run as admin:
#   powershell -ExecutionPolicy Bypass -File tools\fan-tasks.ps1
#
# Fan Control needs admin, so starting FanControl.exe from Rainmeter would show
# a UAC prompt every time. This script makes three scheduled tasks that run it
# with highest privileges; the skin starts them with `schtasks /run`, which
# needs no prompt:
#   \ControlPlaine\FanMax     FanControl.exe -c <Max config>
#   \ControlPlaine\FanNormal  FanControl.exe -c <Normal config>
#   \ControlPlaine\FanOpen    FanControl.exe -w   (show the window)
#   \ControlPlaine\FanSensors pwsh.exe FanControlSensors.ps1 (live fan speeds)
# The last one needs PowerShell 7 from Program Files (winget install Microsoft.PowerShell): Fan
# Control's sensor feed only answers admin programs, and its DLLs are .NET 10.
# It writes %ProgramData%\ControlPlaine\FanControl\fans.txt for the skin and
# stops by itself once Rainmeter has been closed for 30 s.
# Because that task runs elevated, it runs a COPY of FanControlSensors.ps1 kept
# in %ProgramData%\ControlPlaine\FanControl, a folder only administrators can
# write. The copy in the Skins folder is never run elevated, so editing it (or
# a git pull) cannot gain admin rights. Run this script again after the
# script is updated. It also refuses a Fan Control folder that normal users
# can write to (a portable copy in Downloads): move it to Program Files, or
# pass -IgnoreFolderPermissions to accept the risk.
# It also creates the Max config if it does not exist yet: a copy of the normal
# config with every enabled fan on manual control at 100%.
# Run it again after changing the program path or profile names.
#Requires -RunAsAdministrator
param(
    [string]$FanControlPath = 'C:\Program Files (x86)\FanControl\FanControl.exe',
    [string]$Normal = 'userConfig.json',
    [string]$Max = 'Max.json',
    [switch]$IgnoreFolderPermissions
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $FanControlPath)) { throw "Fan Control not found at $FanControlPath (pass -FanControlPath)." }
$dir = Split-Path -Parent $FanControlPath
$configs = Join-Path $dir 'Configurations'

# ---- Trust checks ----
# SIDs, so this works in any language: SYSTEM, Administrators, TrustedInstaller, CREATOR OWNER.
$trusted = @('S-1-5-18', 'S-1-5-32-544', 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464', 'S-1-3-0')
$writeRights = [System.Security.AccessControl.FileSystemRights]'WriteData, AppendData, WriteExtendedAttributes, WriteAttributes, Delete, DeleteSubdirectoriesAndFiles, ChangePermissions, TakeOwnership'
function Test-AdminOnly([string]$Path) {
    $acl = Get-Acl -LiteralPath $Path
    $owner = $acl.GetOwner([System.Security.Principal.SecurityIdentifier]).Value
    if ($owner -notin $trusted) { return $false }
    foreach ($rule in $acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])) {
        if ($rule.AccessControlType -ne 'Allow') { continue }
        # A rule that only passes down to children does not apply to this item.
        if ($rule.PropagationFlags -band [System.Security.AccessControl.PropagationFlags]::InheritOnly) { continue }
        if ($rule.IdentityReference.Value -in $trusted) { continue }
        if (($rule.FileSystemRights -band $writeRights) -ne 0) { return $false }
    }
    $true
}
# The item and every folder above it (up to, not including, the drive root)
# must be admin-only: a user who can rename a parent folder can swap the item.
function Test-TrustedPath([string]$Path) {
    $p = (Resolve-Path -LiteralPath $Path).Path
    while ($p) {
        if (-not (Test-AdminOnly $p)) { return $false }
        $parent = Split-Path -Parent $p
        if (-not $parent -or -not (Split-Path -Parent $parent)) { break }
        $p = $parent
    }
    $true
}
# Fan Control runs elevated and the tasks start its exe, so a folder a normal
# user can write to would hand that user admin rights.
foreach ($p in @($dir, $FanControlPath)) {
    if (-not (Test-TrustedPath $p)) {
        $msg = "$p can be changed by non-administrators. Move Fan Control to C:\Program Files and pass -FanControlPath, or fix its permissions (or pass -IgnoreFolderPermissions if you accept the risk)."
        if ($IgnoreFolderPermissions) { Write-Warning $msg } else { throw $msg }
    }
}

# ---- Max config ----
$normalFile = Join-Path $configs $Normal
$maxFile = Join-Path $configs $Max
if (Test-Path $maxFile) {
    Write-Host "Keeping existing $maxFile"
} elseif (-not (Test-Path $normalFile)) {
    Write-Warning "No $normalFile, so no $Max was made. Create it in Fan Control (every fan at 100%)."
} else {
    $cfg = Get-Content -Raw -Path $normalFile | ConvertFrom-Json
    # Controls live under "FanControl" in recent versions, "Main" in older ones.
    $root = if ($cfg.FanControl) { $cfg.FanControl } else { $cfg.Main }
    $count = 0
    foreach ($c in @($root.Controls)) {
        if ($c.Enable -eq $true -and $null -ne $c.PSObject.Properties['ManualControl']) {
            $c.ManualControl = $true
            $c.ManualControlValue = 100
            $count++
        }
    }
    if ($count -eq 0) {
        Write-Warning "Found no enabled fans in $Normal, so no $Max was made. Create it in Fan Control (every fan at 100%)."
    } else {
        $json = $cfg | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($maxFile, $json, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Made $maxFile ($count fans on manual 100%)"
    }
}

# ---- Tasks ----
$user = "$env:USERDOMAIN\$env:USERNAME"
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
# No time limit: if Fan Control was not running, the task's process is Fan Control itself.
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -MultipleInstances Parallel
# The sensor reader runs once; the skin asks for it every 30 s while it is missing.
$readerSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew

# The task runs as whoever runs this script. With a separate admin account the
# skin would read the wrong user's data.
$console = (Get-CimInstance Win32_ComputerSystem).UserName
if ($console -and $console -ne $user) {
    Write-Warning "Tasks are registered for $user but $console is signed in. Run this from $console's own elevated PowerShell."
}

$tasks = [ordered]@{
    FanMax    = "-c `"$Max`""
    FanNormal = "-c `"$Normal`""
    FanOpen   = '-w'
}
foreach ($name in $tasks.Keys) {
    # Fan Control looks config names up in its Configurations folder.
    $action = New-ScheduledTaskAction -Execute $FanControlPath -Argument $tasks[$name] -WorkingDirectory $configs
    Register-ScheduledTask -TaskPath '\ControlPlaine\' -TaskName $name -Action $action -Principal $principal `
        -Settings $settings -Description 'Control-Plaine Fan Control skin' -Force | Out-Null
    Write-Host "Task \ControlPlaine\$name -> FanControl.exe $($tasks[$name])"
}
# ---- Sensor reader (needs PowerShell 7) ----
$source = Join-Path (Split-Path -Parent $PSScriptRoot) '@Resources\Scripts\FanControlSensors.ps1'
# The task runs elevated, so pwsh.exe must sit where only administrators can
# write. The Store version is an alias in a user-writable folder and is not
# accepted; the MSI in Program Files (winget install Microsoft.PowerShell) is.
$pwshPath = $null
foreach ($c in @((Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'), (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source)) {
    if ($c -and (Test-Path -LiteralPath $c) -and (Test-TrustedPath $c)) { $pwshPath = $c; break }
}
if (-not $pwshPath) {
    Write-Warning 'PowerShell 7 (pwsh.exe) not found in an admin-only folder such as C:\Program Files\PowerShell\7 (the Store version is not accepted), so no FanSensors task was made. Install it (winget install Microsoft.PowerShell) and run this script again.'
} elseif (-not (Test-Path $source)) {
    Write-Warning "No $source, so no FanSensors task was made."
} else {
    # A folder only administrators can write: the elevated task runs the copy
    # and writes its output here. Refuse a folder someone else already made.
    $admins = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)
    $system = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)
    $users = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::BuiltinUsersSid, $null)
    $inherit = 'ContainerInherit, ObjectInherit'
    $parent = Join-Path $env:ProgramData 'ControlPlaine'
    $data = Join-Path $parent 'FanControl'
    foreach ($d in @($parent, $data)) {
        if (Test-Path -LiteralPath $d) {
            $item = Get-Item -LiteralPath $d -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "$d is a link. Delete it and run this script again." }
            if ((Get-Acl -LiteralPath $d).GetOwner([System.Security.Principal.SecurityIdentifier]).Value -notin $trusted) {
                throw "$d was created by a normal user. Delete it (as admin) and run this script again."
            }
        } else {
            New-Item -ItemType Directory -Path $d | Out-Null
        }
        $acl = New-Object System.Security.AccessControl.DirectorySecurity
        $acl.SetOwner($admins)
        $acl.SetAccessRuleProtection($true, $false)
        foreach ($rule in @(@($system, 'FullControl'), @($admins, 'FullControl'), @($users, 'ReadAndExecute'))) {
            $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($rule[0], $rule[1], $inherit, 'None', 'Allow')))
        }
        Set-Acl -LiteralPath $d -AclObject $acl
    }
    # Clear anything that was in the folder before it was locked down.
    foreach ($old in Get-ChildItem -LiteralPath $data -Force) {
        if ($old.PSIsContainer) { throw "$($old.FullName) is unexpected. Delete it (as admin) and run this script again." }
        Remove-Item -LiteralPath $old.FullName -Force
    }
    $script = Join-Path $data 'FanControlSensors.ps1'
    Copy-Item -LiteralPath $source -Destination $script -Force
    $out = Join-Path $data 'fans.txt'
    # Task Scheduler gets the full path of the trusted pwsh.exe.
    $arg = "-NoProfile -WindowStyle Hidden -File `"$script`" -Out `"$out`" -FanControlDir `"$dir`""
    $action = New-ScheduledTaskAction -Execute $pwshPath -Argument $arg
    Register-ScheduledTask -TaskPath '\ControlPlaine\' -TaskName 'FanSensors' -Action $action -Principal $principal `
        -Settings $readerSettings -Description 'Control-Plaine Fan Control skin: live fan speeds' -Force | Out-Null
    Write-Host "Task \ControlPlaine\FanSensors -> $pwshPath $arg"
}
Write-Host 'Done. Refresh the Fan Control skin.'
