# Control-Plaine | Power helper, run by the Power skin (mPS measure).
#   Power.ps1 sleep                       sleep now (even with hibernation on)
#   Power.ps1 schedule hibernate|sleep|lock N  one-time task N seconds from now
#   Power.ps1 cancel hibernate|sleep|lock      delete that task (0 also when absent)
#   Power.ps1 query hibernate|sleep|lock       exit 0 if the task exists, 1 if not
# Exit code 2 = something failed. The code is also printed, because the
# skin's RunCommand measure can only read output, not exit codes.
# Needs no admin rights: the task runs as you.
param([string]$Do, [string]$Action = 'hibernate', [int]$Seconds = 0)

function Finish([int]$Code) { Write-Output $Code; exit $Code }

$names = @{ hibernate = 'ControlPlaineHibernate'; sleep = 'ControlPlaineSleep'; lock = 'ControlPlaineLock' }
$name = $names[$Action]
if (-not $name -and $Do -ne 'sleep') { Finish 2 }

try {
    switch ($Do) {
        'sleep' {
            Add-Type -AssemblyName System.Windows.Forms
            [void][System.Windows.Forms.Application]::SetSuspendState('Suspend', $false, $false)
            Finish 0
        }
        'schedule' {
            if ($Seconds -lt 60) { Finish 2 }
            if ($Action -eq 'hibernate') {
                $run = New-ScheduledTaskAction -Execute 'shutdown.exe' -Argument '/h'
            } elseif ($Action -eq 'lock') {
                $run = New-ScheduledTaskAction -Execute 'rundll32.exe' -Argument 'user32.dll,LockWorkStation'
            } else {
                $run = New-ScheduledTaskAction -Execute 'powershell.exe' `
                    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" sleep"
            }
            $when = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($Seconds)
            # StartWhenAvailable stays off: a time missed while asleep or off is skipped.
            $opts = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            Register-ScheduledTask -TaskName $name -Action $run -Trigger $when -Settings $opts -Force -ErrorAction Stop | Out-Null
            Finish 0
        }
        'cancel' {
            & schtasks.exe /query /tn $name *> $null
            if ($LASTEXITCODE -ne 0) { Finish 0 }
            & schtasks.exe /delete /tn $name /f *> $null
            if ($LASTEXITCODE -eq 0) { Finish 0 } else { Finish 2 }
        }
        'query' {
            & schtasks.exe /query /tn $name *> $null
            if ($LASTEXITCODE -eq 0) { Finish 0 } else { Finish 1 }
        }
        default { Finish 2 }
    }
} catch {
    Finish 2
}
