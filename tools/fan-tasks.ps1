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
# It also creates the Max config if it does not exist yet: a copy of the normal
# config with every enabled fan on manual control at 100%.
# Run it again after changing the program path or profile names.
#Requires -RunAsAdministrator
param(
    [string]$FanControlPath = 'C:\Program Files (x86)\FanControl\FanControl.exe',
    [string]$Normal = 'userConfig.json',
    [string]$Max = 'Max.json'
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $FanControlPath)) { throw "Fan Control not found at $FanControlPath (pass -FanControlPath)." }
$dir = Split-Path -Parent $FanControlPath
$configs = Join-Path $dir 'Configurations'

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

$tasks = [ordered]@{
    FanMax    = "-c $Max"
    FanNormal = "-c $Normal"
    FanOpen   = '-w'
}
foreach ($name in $tasks.Keys) {
    # Fan Control looks config names up in its Configurations folder.
    $action = New-ScheduledTaskAction -Execute $FanControlPath -Argument $tasks[$name] -WorkingDirectory $configs
    Register-ScheduledTask -TaskPath '\ControlPlaine\' -TaskName $name -Action $action -Principal $principal `
        -Settings $settings -Description 'Control-Plaine Fan Control skin' -Force | Out-Null
    Write-Host "Task \ControlPlaine\$name -> FanControl.exe $($tasks[$name])"
}
Write-Host 'Done. Refresh the Fan Control skin.'
