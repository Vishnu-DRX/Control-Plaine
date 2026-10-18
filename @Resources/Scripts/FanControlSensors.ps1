#Requires -Version 7.4
# Control-Plaine: read Fan Control's live fan speeds and control percentages
# over its local IPC pipe, for the FanControl skin. Read-only: it only calls
# SensorsRPC GetAllSensors (Fan Control does not implement ReadSensorValues).
#   pwsh -NoProfile -WindowStyle Hidden -File FanControlSensors.ps1 [-Poll 2]
#        [-Out "%ProgramData%\ControlPlaine\FanControl\fans.txt"]
# Output, rewritten atomically every poll:
#   ts|<unix seconds>
#   <Identifier>|Fan|<RPM>          one line per fan sensor
#   <Identifier>|Control|<percent>  one line per control (empty if no value)
# or "error|<message>" while Fan Control is not reachable (retried every 5 s).
# Fan Control runs elevated and its pipe only admits elevated clients, so this
# runs from the \ControlPlaine\FanSensors task (tools\fan-tasks.ps1), which
# runs a copy of this script from a folder only administrators can write. Needs
# PowerShell 7 (Fan Control's DLLs are .NET 10). One instance at a time; exits
# once no Rainmeter.exe has been running for 30 s.
param(
    [double]$Poll = 2,
    [string]$Out = (Join-Path $env:ProgramData 'ControlPlaine\FanControl\fans.txt'),
    [string]$Pipe = 'FanControl',
    [string]$FanControlDir = 'C:\Program Files (x86)\FanControl',
    [int]$RainmeterGrace = 30
)
$ErrorActionPreference = 'Stop'
$inv = [Globalization.CultureInfo]::InvariantCulture

$created = $false
$mutex = [Threading.Mutex]::new($true, 'Local\ControlPlaine.FanControlSensors', [ref]$created)
if (-not $created) { exit 0 }

$tmp = "$Out.tmp"
function Write-Out([string[]]$Lines) {
    [IO.File]::WriteAllLines($tmp, $Lines)
    # Replace in one step; retry briefly if a reader has the file open.
    for ($i = 0; ; $i++) {
        try { [IO.File]::Move($tmp, $Out, $true); return }
        catch [IO.IOException] { if ($i -ge 10) { throw }; [Threading.Thread]::Sleep(20) }
        catch [UnauthorizedAccessException] { if ($i -ge 10) { throw }; [Threading.Thread]::Sleep(20) }
    }
}
function Write-Fail([string]$Message) {
    try { Write-Out @("error|$(($Message -replace '[\r\n|]+', ' ').Trim())") } catch { }
}
# Rainmeter is looked for every 10 s, not every poll.
$lastSeen = [datetime]::UtcNow
$lastCheck = [datetime]::MinValue
function Test-Rainmeter {
    $now = [datetime]::UtcNow
    if (($now - $script:lastCheck).TotalSeconds -ge 10) {
        $script:lastCheck = $now
        if ([Diagnostics.Process]::GetProcessesByName('Rainmeter').Length -gt 0) { $script:lastSeen = $now }
    }
    ($now - $script:lastSeen).TotalSeconds -lt $RainmeterGrace
}
$pipePath = "\\.\pipe\$Pipe"

# Fan Control's own IPC client and its gRPC dependencies, from its folder.
try {
    foreach ($dll in 'Google.Protobuf', 'Grpc.Core.Api', 'GrpcDotNetNamedPipes', 'FanControl.IPC') {
        [void][Reflection.Assembly]::LoadFrom((Join-Path $FanControlDir "$dll.dll"))
    }
} catch {
    Write-Fail "Cannot load Fan Control from ${FanControlDir}: $($_.Exception.GetBaseException().Message)"
    exit 1
}

$client = $null
while (Test-Rainmeter) {
    try {
        if (-not $client) {
            if ([IO.Directory]::GetFiles('\\.\pipe\') -notcontains $pipePath) { throw "Fan Control is not running ($pipePath not found)." }
            $client = [SensorsRPC+SensorsRPCClient]::new([GrpcDotNetNamedPipes.NamedPipeChannel]::new('.', $Pipe))
        }
        $opts = [Grpc.Core.CallOptions]::new().WithDeadline([datetime]::UtcNow.AddSeconds(3))
        $all = $client.GetAllSensors([GetAllSensorsRequest]::new(), $opts)
        $lines = [Collections.Generic.List[string]]::new()
        $lines.Add("ts|$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())")
        foreach ($s in $all.Sensors) {
            if ($s.Type -eq [SensorMessageType]::Rpm) { $type = 'Fan' }
            elseif ($s.Type -eq [SensorMessageType]::Control) { $type = 'Control' }
            else { continue }
            $value = $s.HasValue ? $s.Value.ToString('0.#', $inv) : ''
            $lines.Add("$($s.Identifier)|$type|$value")
        }
        if ($lines.Count -eq 1) { throw 'Fan Control reported no fan or control sensors.' }
        Write-Out $lines
        Start-Sleep -Milliseconds ([int]($Poll * 1000))
    } catch {
        $e = $_.Exception.GetBaseException()
        $msg = switch ($e.GetType().Name) {
            'RpcException' { "Fan Control did not answer ($($e.StatusCode))." }
            'UnauthorizedAccessException' { 'Fan Control only answers elevated programs. Run this from the FanSensors task.' }
            default { $e.Message }
        }
        Write-Fail $msg
        $client = $null
        Start-Sleep -Seconds 5
    }
}
$mutex.ReleaseMutex()
