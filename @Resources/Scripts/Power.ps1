# Control-Plaine | Power helper, run by the Power skin (mPS measure).
#   Power.ps1 sleep                       sleep now (even with hibernation on)
#   Power.ps1 schedule hibernate|sleep N  one-time task N seconds from now
#   Power.ps1 cancel hibernate|sleep      delete that task (0 also when absent)
#   Power.ps1 query hibernate|sleep       exit 0 if the task exists, 1 if not
# Exit code 2 = something failed. Needs no admin rights: the task runs as you.
param([string]$Do, [string]$Action = 'hibernate', [int]$Seconds = 0)

$names = @{ hibernate = 'ControlPlaineHibernate'; sleep = 'ControlPlaineSleep' }
$name = $names[$Action]
if (-not $name -and $Do -ne 'sleep') { exit 2 }

try {
    switch ($Do) {
        'sleep' {
            Add-Type -AssemblyName System.Windows.Forms
            [void][System.Windows.Forms.Application]::SetSuspendState('Suspend', $false, $false)
            exit 0
        }
        'schedule' {
            if ($Seconds -lt 60) { exit 2 }
            if ($Action -eq 'hibernate') {
                $run = New-ScheduledTaskAction -Execute 'shutdown.exe' -Argument '/h'
            } else {
                $run = New-ScheduledTaskAction -Execute 'powershell.exe' `
                    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" sleep"
            }
            $when = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds($Seconds)
            # StartWhenAvailable stays off: a time missed while asleep or off is skipped.
            $opts = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            Register-ScheduledTask -TaskName $name -Action $run -Trigger $when -Settings $opts -Force -ErrorAction Stop | Out-Null
            exit 0
        }
        'cancel' {
            & schtasks.exe /query /tn $name *> $null
            if ($LASTEXITCODE -ne 0) { exit 0 }
            & schtasks.exe /delete /tn $name /f *> $null
            if ($LASTEXITCODE -eq 0) { exit 0 } else { exit 2 }
        }
        'query' {
            & schtasks.exe /query /tn $name *> $null
            if ($LASTEXITCODE -eq 0) { exit 0 } else { exit 1 }
        }
        default { exit 2 }
    }
} catch {
    exit 2
}
