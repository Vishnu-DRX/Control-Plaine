# Control-Plaine | Controllers helper
#
# Started hidden by Controllers.ini (RunCommand, State=Hide), which makes
# Rainmeter kill it when the skin refreshes or unloads. It finds connected
# game controllers and their battery, and writes them to
# %TEMP%\ControlPlaine-controllers.txt for Controllers.lua:
#
#   v1|<unix time of this write>
#   <kind>|<name>|<battery 0-100 or -1>|<charging 0/1>
#
# kind is xbox, dualsense, moza or other. The first line is rewritten every
# scan, so Lua can tell a dead helper from "nothing connected".
#
# Read-only: it never changes a device. Sources:
#   - PnP (CIM) for what is plugged in or paired.
#   - Bluetooth "is connected" property, because paired pads that are off
#     stay present in Windows.
#   - Bluetooth battery property for Xbox over Bluetooth.
#   - DSX's UDP status reply for a DualSense while DSX runs (DSX hides the
#     pad from other apps with HidHide).
#   - One HID input report for a DualSense when DSX is not running.

param(
	[ValidateRange(1, 300)][int]$Poll = 3,
	[ValidateRange(1, 3600)][int]$BatteryPoll = 60,
	[ValidateRange(1, 65535)][int]$DsxPort = 6969
)

$ErrorActionPreference = 'SilentlyContinue'
$OutFile = Join-Path $env:TEMP 'ControlPlaine-controllers.txt'

# ---------- one copy only ----------

$mutex = New-Object System.Threading.Mutex($false, 'Local\ControlPlaineControllers')
$owned = $false
for ($i = 0; $i -lt 10 -and -not $owned; $i++) {
	# A killed previous copy leaves the mutex abandoned, which throws but
	# still hands it to us.
	try { $owned = $mutex.WaitOne(500) } catch { $owned = $true }
}
if (-not $owned) { exit }

# Exit with Rainmeter even if it crashed and could not kill us.
$parentId = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId

# ---------- DualSense HID read ----------

$hidSource = @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public static class CpDualSense
{
	[DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
	static extern SafeFileHandle CreateFile(string name, uint access, uint share, IntPtr security,
		uint disposition, uint flags, IntPtr template);
	[DllImport("kernel32.dll")]
	static extern bool CancelIoEx(SafeFileHandle handle, IntPtr overlapped);
	[DllImport("hid.dll")]
	static extern bool HidD_GetPreparsedData(SafeFileHandle handle, out IntPtr data);
	[DllImport("hid.dll")]
	static extern bool HidD_FreePreparsedData(IntPtr data);
	[DllImport("hid.dll")]
	static extern int HidP_GetCaps(IntPtr data, byte[] caps);

	const string HidInterface = "#{4d1e55b2-f16f-11cf-88cb-001111000030}";

	// Battery of the DualSense whose HID node is instanceId.
	// Returns -1 when unknown, else percent, plus 1000 while charging.
	public static int Read(string instanceId, int timeoutMs)
	{
		string path = @"\\?\" + instanceId.Replace('\\', '#') + HidInterface;
		// GENERIC_READ, shared read/write (DSX or a game keeps its own copy of
		// every report), OPEN_EXISTING, FILE_FLAG_OVERLAPPED.
		SafeFileHandle handle = CreateFile(path, 0x80000000, 3, IntPtr.Zero, 3, 0x40000000, IntPtr.Zero);
		if (handle.IsInvalid) return -1;
		try
		{
			IntPtr data;
			if (!HidD_GetPreparsedData(handle, out data)) return -1;
			byte[] caps = new byte[64];
			int length;
			try
			{
				HidP_GetCaps(data, caps);
				length = BitConverter.ToUInt16(caps, 4);
			}
			finally { HidD_FreePreparsedData(data); }
			if (length < 64) return -1;

			using (FileStream stream = new FileStream(handle, FileAccess.Read, 1, true))
			{
				byte[] report = new byte[length];
				IAsyncResult pending = stream.BeginRead(report, 0, length, null, null);
				if (!pending.AsyncWaitHandle.WaitOne(timeoutMs))
				{
					CancelIoEx(handle, IntPtr.Zero);
					try { stream.EndRead(pending); } catch { }
					return -1;
				}
				int read = stream.EndRead(pending);
				// USB: report 0x01, 64 bytes, status at 53.
				// Bluetooth full report: 0x31, 78 bytes, status at 54.
				// Bluetooth short report (0x01 on a 78 byte device) has no battery.
				int at;
				if (report[0] == 0x01 && length == 64 && read > 53) at = 53;
				else if (report[0] == 0x31 && read > 54) at = 54;
				else return -1;
				return Decode(report[at]);
			}
		}
		catch { return -1; }
		finally { handle.Dispose(); }
	}

	// Status byte, as in the Linux hid-playstation driver: low nibble is
	// capacity in tens, high nibble 0 discharging, 1 charging, 2 full.
	public static int Decode(byte status)
	{
		int level = status & 0x0F;
		int state = status >> 4;
		int percent = Math.Min(level * 10 + 5, 100);
		if (state == 0) return percent;
		if (state == 1) return percent + 1000;
		if (state == 2) return 100 + 1000;
		return -1;
	}
}
'@

$hidReady = $false
try { Add-Type -TypeDefinition $hidSource -ErrorAction Stop; $hidReady = $true } catch { }

# ---------- PnP helpers ----------

$KeyParent = '{4340a6c5-93fa-4706-972c-7b648008a5a7} 8'
$KeyConnected = '{83DA6326-97A6-4088-9453-A1923F573B29} 15'
$KeyBattery = '{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2'

function Get-Prop([string]$id, [string]$key) {
	$p = Get-PnpDeviceProperty -InstanceId $id -KeyName $key -ErrorAction SilentlyContinue
	if ($p -and $p.Type -ne 'Empty') { return $p.Data }
	return $null
}

# Parents up to the first real bus node (a root hub plus its parent), cached per device.
$chains = @{}
function Get-Chain([string]$id) {
	if ($chains.ContainsKey($id)) { return $chains[$id] }
	$chain = @()
	$current = $id
	for ($i = 0; $i -lt 8; $i++) {
		$parent = Get-Prop $current $KeyParent
		if (-not $parent) { break }
		$chain += $parent
		# A root hub is followed one more hop: a real one sits under PCI, DSX's ViGEm
		# virtual pad's under ROOT\USB (which the caller drops).
		if ($parent -match '^USB\\ROOT_HUB') {
			$up = Get-Prop $parent $KeyParent
			if ($up) { $chain += $up }
			break
		}
		if ($parent -match '^(PCI|ACPI|BTH|HTREE)') { break }
		$current = $parent
	}
	$chains[$id] = $chain
	return $chain
}

# Bluetooth address (12 hex digits) in a device or its parents.
function Get-Mac([string[]]$ids) {
	foreach ($x in $ids) {
		if ($x -match '(?:DEV_|&|_)([0-9A-F]{12})(?=[_\\&]|$)') { return $Matches[1] }
	}
	return $null
}

# BTHLE\DEV_<mac> or BTHENUM\DEV_<mac>, cached.
$btNodes = @{}
function Get-BtNode([string]$mac) {
	if ($btNodes.ContainsKey($mac)) { return $btNodes[$mac] }
	$node = Get-CimInstance Win32_PnPEntity -Filter "DeviceID LIKE 'BTHLE\\DEV_$mac%' OR DeviceID LIKE 'BTHENUM\\DEV_$mac%'" |
		Select-Object -First 1 -ExpandProperty DeviceID
	if ($node) { $btNodes[$mac] = $node }
	return $node
}

# ---------- DSX ----------

# DualSense entries from DSX's status reply (empty when DSX is not running).
function Get-DsxPads {
	$pads = @()
	$udp = New-Object System.Net.Sockets.UdpClient
	try {
		$udp.Client.ReceiveTimeout = 300
		$udp.Connect('127.0.0.1', $DsxPort)
		$bytes = [Text.Encoding]::ASCII.GetBytes('{"instructions":[{"type":0,"parameters":[]}]}')
		[void]$udp.Send($bytes, $bytes.Length)
		$from = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
		$reply = [Text.Encoding]::UTF8.GetString($udp.Receive([ref]$from))
		$status = $reply | ConvertFrom-Json
		foreach ($d in @($status.Devices)) {
			# DeviceType 0 = DualSense in DSX's list.
			if ($d -and $d.DeviceType -eq 0) {
				$pads += [pscustomobject]@{
					Battery = [int]$d.BatteryLevel
					# ConnectionType 0 = USB: the pad is on a cable, so it charges.
					Usb = ($d.ConnectionType -eq 0)
				}
			}
		}
	} catch { } finally { $udp.Close() }
	return $pads
}

# ---------- scan ----------

$Order = @{ xbox = 0; dualsense = 1; moza = 2; other = 3 }
$batteries = @{}
$nextBattery = @{}

function Get-Controllers {
	$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
	$filter = "PNPClass='HIDClass' OR PNPClass='XnaComposite' OR PNPClass='XboxComposite' OR DeviceID LIKE 'USB\\VID_346E%'"
	$found = @{}

	foreach ($d in Get-CimInstance Win32_PnPEntity -Filter $filter) {
		$id = $d.DeviceID
		if ($d.Present -eq $false -or $id -like 'SWD\*' -or $d.PNPClass -eq 'Ports') { continue }
		$vid = $null; $prod = $null
		if ($id -match 'VID[_&](?:0002|02)?([0-9A-F]{4})[&_]PID[_&]([0-9A-F]{4})') { $vid = $Matches[1]; $prod = $Matches[2] }
		$compat = ($d.CompatibleID -join ' ')
		$isPad = $compat -match 'HID_DEVICE_UP:0001_U:000[45]'

		$kind = $null
		if ($vid -eq '346E') { $kind = 'moza' }
		elseif ($d.PNPClass -in 'XnaComposite', 'XboxComposite' -or $d.Name -like '*Xbox*Controller*' -or
			($vid -eq '045E' -and $d.Name -like '*XINPUT*')) {
			if ($d.Name -notlike '*Adapter*') { $kind = 'xbox' }
		}
		elseif ($isPad) {
			if ($vid -eq '045E') { $kind = 'xbox' }
			elseif ($vid -eq '054C' -and $prod -in '0CE6', '0DF2') { $kind = 'dualsense' }
			elseif ($vid -ne '054C') { $kind = 'other' }
		}
		if (-not $kind) { continue }

		$chain = @()
		$key = $id
		if ($kind -eq 'moza') {
			# Base, pedals and handbrake all count as the one wheel row.
			$key = 'moza'
		} else {
			$chain = Get-Chain $id
			# Virtual pads (DSX / ViGEm) hang off a root-enumerated bus.
			if (@($chain | Where-Object { $_ -like 'ROOT\*' }).Count -gt 0) { continue }
			$all = @($id) + $chain
			$bluetooth = @($all | Where-Object { $_ -like 'BTH*' -or $_ -like '*{00001124-*' -or $_ -like '*{00001812-*' }).Count -gt 0
			if ($bluetooth) {
				$mac = Get-Mac $all
				if (-not $mac) { continue }
				$node = Get-BtNode $mac
				# Paired pads that are switched off stay present; skip them.
				if (-not $node -or (Get-Prop $node $KeyConnected) -ne $true) { continue }
				$key = "bt:$mac"
			} else {
				# One row per physical USB device, not per HID collection.
				$usb = $all | Where-Object { $_ -match '^USB\\VID_[^\\]+\\' -and $_ -notmatch '&MI_' } | Select-Object -First 1
				if ($usb) { $key = $usb }
			}
		}
		if ($found.ContainsKey($key)) { continue }

		$name = switch ($kind) {
			'xbox' { 'XBOX' }
			'dualsense' { if ($prod -eq '0DF2') { 'DUALSENSE EDGE' } else { 'DUALSENSE' } }
			'moza' { 'MOZA R3' }
			default { 'CONTROLLER' }
		}
		$found[$key] = [pscustomobject]@{
			Kind = $kind; Name = $name; Id = $id; Key = $key
			Bluetooth = $key -like 'bt:*'; Node = $(if ($key -like 'bt:*') { Get-BtNode $key.Substring(3) })
			Battery = -1; Charging = 0
		}
	}

	$list = @($found.Values | Sort-Object { $Order[$_.Kind] }, Key)

	# DSX answers only while it runs; with DSX on, its numbers win for DualSense.
	$dsx = @(Get-DsxPads)
	$pads = @($list | Where-Object { $_.Kind -eq 'dualsense' })
	# If DSX's HidHide also hides the pad from PnP, trust DSX's list.
	for ($i = $pads.Count; $i -lt $dsx.Count; $i++) {
		$extra = [pscustomobject]@{ Kind = 'dualsense'; Name = 'DUALSENSE'; Id = $null; Key = "dsx:$i";
			Bluetooth = $false; Node = $null; Battery = -1; Charging = 0 }
		$list += $extra
		$pads += $extra
	}

	for ($i = 0; $i -lt $list.Count; $i++) {
		$c = $list[$i]
		$padIndex = [array]::IndexOf($pads, $c)
		if ($c.Kind -eq 'dualsense' -and $padIndex -ge 0 -and $padIndex -lt $dsx.Count) {
			$p = $dsx[$padIndex]
			$c.Battery = [Math]::Max(0, [Math]::Min(100, $p.Battery))
			$c.Charging = [int]($p.Usb -and $p.Battery -lt 100)
			continue
		}
		# Slow sources: once on arrival, then every BatteryPoll seconds.
		if ($nextBattery.ContainsKey($c.Key) -and $now -lt $nextBattery[$c.Key]) {
			$c.Battery = $batteries[$c.Key][0]
			$c.Charging = $batteries[$c.Key][1]
			continue
		}
		$value = @(-1, 0)
		if ($c.Kind -eq 'xbox' -and $c.Node) {
			$b = Get-Prop $c.Node $KeyBattery
			if ($b -ne $null) { $value = @([int]$b, 0) }
		} elseif ($c.Kind -eq 'dualsense' -and $c.Id -and $hidReady) {
			$r = [CpDualSense]::Read($c.Id, 500)
			if ($r -ge 1000) { $value = @(($r - 1000), 1) } elseif ($r -ge 0) { $value = @($r, 0) }
		}
		$batteries[$c.Key] = $value
		# An unknown value is retried sooner than a good one.
		$nextBattery[$c.Key] = $now + $(if ($value[0] -lt 0) { [Math]::Min(15, $BatteryPoll) } else { $BatteryPoll })
		$c.Battery = $value[0]
		$c.Charging = $value[1]
	}

	# Forget battery timers for devices that left, so a reconnect reads at once.
	foreach ($k in @($nextBattery.Keys)) {
		if (-not ($list | Where-Object { $_.Key -eq $k })) { $nextBattery.Remove($k); $batteries.Remove($k) }
	}

	return ($list | Sort-Object { $Order[$_.Kind] }, Key | ForEach-Object { "$($_.Kind)|$($_.Name)|$($_.Battery)|$($_.Charging)" }) -join "`r`n"
}

# ---------- loop ----------

$body = ''
while ($true) {
	if ($parentId -and -not (Get-Process -Id $parentId -ErrorAction SilentlyContinue)) { break }
	try { $body = Get-Controllers } catch { }
	$stamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
	$text = "v1|$stamp`r`n$body`r`n"
	try {
		$tmp = "$OutFile.tmp"
		[IO.File]::WriteAllText($tmp, $text, [Text.Encoding]::ASCII)
		Move-Item -LiteralPath $tmp -Destination $OutFile -Force
	} catch { }
	Start-Sleep -Seconds $Poll
}
