-- Control-Plaine | FanControl
-- Averages the fan duty (%) Fan Control reports, runs the MAX / normal profile
-- switch, and keeps the MAX state in step with the config Fan Control is
-- actually using (Configurations\CACHE). After a switch the shown % climbs (or
-- falls) while SPEEDING UP / SLOWING DOWN and a spinner show, until the fans
-- have got there.
-- The numbers come from %TEMP%\ControlPlaine-fans.txt, written every 2 s by
-- Scripts\FanControlSensors.ps1, which runs as the \ControlPlaine\FanSensors
-- task (Fan Control's sensor feed only answers admin programs). The file is
--   ts|<unix seconds>
--   <id>|Fan|<RPM>   and   <id>|Control|<percent>
-- or error|<message>.

local ignoreStopped, useTasks
local exe, configDir, cacheFile, sensorFile
local lastStart = 0    -- when the reader task was last started
local STALE = 15       -- s without a new ts before the reader is started again
local RETRY = 30       -- s between starts
local maxOn = 0
local holdUntil = 0    -- ignore CACHE until then (a switch is in flight)
local ticks = 0
local spin             -- loader while the fans change speed (Spinner.lua)
local lastAvg          -- latest average duty from the sensor file
local shown = 0        -- the % on screen while ramping
local busy = false
local switchedAt = 0
local STEP = 1.5       -- % per 200 ms tick: 50% to 100% takes about 7 s
local GIVE_UP = 25     -- s before a switch counts as done anyway

local function var(name, default)
	return SKIN:GetVariable(name, default or '')
end

local function split(text)
	local list = {}
	for item in (text or ''):gmatch('[^,%s]+') do list[#list + 1] = item end
	return list
end

local function setVar(name, value)
	SKIN:Bang('!SetVariable', name, tostring(value))
end

local function showMax()
	setVar('MaxOn', maxOn)
	local tint = maxOn == 1 and var('Accent') or var('Ink')
	setVar('IconTint', tint)
	setVar('SnowTint', tint)
	setVar('SnowTip', maxOn == 1 and 'Back to normal' or 'All fans to 100%')
	SKIN:Bang('!UpdateMeter', 'Icon')
	SKIN:Bang('!UpdateMeter', 'Snow')
	SKIN:Bang('!Redraw')
end

local function saveMax()
	SKIN:Bang('!WriteKeyValue', 'Variables', 'FanControlMaxOn', tostring(maxOn), var('@') .. 'State.inc')
end

-- Fan Control writes the active config name to Configurations\CACHE.
local function readCache()
	local f = io.open(cacheFile, 'r')
	if not f then return nil end
	local text = f:read('*a')
	f:close()
	return text:match('"CurrentConfigFileName"%s*:%s*"([^"]+)"')
end

local function syncMax()
	if os.time() < holdUntil then return end
	local current = readCache()
	if not current then return end
	local on = (current:lower() == var('FanControlMax'):lower()) and 1 or 0
	if on ~= maxOn then
		maxOn = on
		saveMax()
		showMax()
	end
end

-- task: name under \ControlPlaine\ ; args: what FanControl.exe gets without tasks.
local function run(task, args)
	if useTasks then
		SKIN:Bang('!SetOption', 'mRun', 'Program', 'schtasks.exe')
		SKIN:Bang('!SetOption', 'mRun', 'Parameter', '/run /tn ControlPlaine\\' .. task)
		SKIN:Bang('!SetOption', 'mRun', 'StartInFolder', '')
	else
		-- Fan Control looks the config name up in its Configurations folder.
		SKIN:Bang('!SetOption', 'mRun', 'Program', exe)
		SKIN:Bang('!SetOption', 'mRun', 'Parameter', args)
		SKIN:Bang('!SetOption', 'mRun', 'StartInFolder', configDir)
	end
	SKIN:Bang('!UpdateMeasure', 'mRun')
	SKIN:Bang('!CommandMeasure', 'mRun', 'Run')
end

function Initialize()
	ignoreStopped = tonumber(var('FanControlIgnoreStopped', '1')) == 1
	useTasks = tonumber(var('FanControlUseTasks', '1')) == 1
	exe = var('FanControlPath')
	local dir = exe:match('^(.*\\)') or ''
	configDir = dir .. 'Configurations'
	cacheFile = configDir .. '\\CACHE'

	spin = dofile(var('@') .. 'Scripts\\Spinner.lua').new('Spinner', 'mSpin')
	sensorFile = (os.getenv('TEMP') or '') .. '\\ControlPlaine-fans.txt'
	startReader()

	maxOn = tonumber(var('FanControlMaxOn', '0')) == 1 and 1 or 0
	syncMax()
	showMax()
end

-- Start the reader task when it is not producing a fresh file.
function startReader()
	if not useTasks then return end
	local now = os.time()
	if now - lastStart < RETRY then return end
	lastStart = now
	SKIN:Bang('!UpdateMeasure', 'mSensors')
	SKIN:Bang('!CommandMeasure', 'mSensors', 'Run')
end

-- Parses the sensor file. Returns the average duty (%) of the fans that are
-- turning, or nil plus a reason.
local function average()
	local f = io.open(sensorFile, 'rb')
	if not f then
		startReader()
		return nil, 'No fan data yet. Run tools\\fan-tasks.ps1 as admin (needs PowerShell 7).'
	end
	local text = f:read('*a')
	f:close()
	local err = text:match('^error|([^\r\n]*)')
	if err then
		startReader()
		return nil, err
	end
	local ts = tonumber(text:match('ts|(%d+)'))
	if not ts or os.time() - ts > STALE then startReader() end
	local rpm, duty = {}, {}
	for id, kind, value in text:gmatch('([^|\r\n]+)|(%a+)|([^\r\n]*)') do
		local v = tonumber(value)
		if kind == 'Fan' then rpm[id] = v
		elseif kind == 'Control' and v then duty[id] = v end
	end
	local sum, count = 0, 0
	for id, pct in pairs(duty) do
		-- A control and its fan share an id apart from /control vs /fan.
		local spinning = rpm[(id:gsub('/control', '/fan'))]
		if not (ignoreStopped and spinning == 0) then
			sum = sum + math.min(pct, 100)
			count = count + 1
		end
	end
	if count == 0 then return nil, 'Fan Control reports no fan speeds.' end
	return sum / count
end

local function showText(text, tip)
	setVar('FanText', text)
	setVar('FanTip', tip)
	SKIN:Bang('!UpdateMeter', 'Value')
	SKIN:Bang('!Redraw')
end

function Update()
	local avg, why = average()
	lastAvg = avg
	if busy then
		-- Ramp() owns the text until the switch is done.
	elseif maxOn == 1 then
		setVar('FanText', '100%')
		setVar('FanTip', 'All fans at 100%')
	elseif avg then
		setVar('FanText', string.format('%d%%', math.floor(avg + 0.5)))
		setVar('FanTip', 'Average fan speed')
	else
		setVar('FanText', '--')
		setVar('FanTip', why or 'No fan data')
	end
	-- Every 10 s, follow config changes made in the Fan Control window.
	ticks = ticks + 1
	if ticks % 5 == 0 and not busy then syncMax() end
	return avg or -1
end

local function finish()
	busy = false
	spin:stop()
	SKIN:Bang('!CommandMeasure', 'mRamp', 'Stop 1')
	setVar('Busy', 0)
	setVar('StatusText', '')
	SKIN:Bang('!UpdateMeter', 'Status')
	SKIN:Bang('!UpdateMeter', 'Snow')
	if maxOn == 1 then
		showText('100%', 'All fans at 100%')
	elseif lastAvg then
		showText(string.format('%d%%', math.floor(lastAvg + 0.5)), 'Average fan speed')
	else
		showText('--', 'No fan data')
	end
end

-- Every 200 ms while the fans change speed: move the shown % toward its
-- target (100, or the normal curve's value) and finish once Fan Control has
-- switched config and the sensors agree.
function Ramp()
	if not busy then return end
	local elapsed = os.time() - switchedAt
	local target = maxOn == 1 and 100 or lastAvg
	if target then
		if shown < target then shown = math.min(shown + STEP, target)
		elseif shown > target then shown = math.max(shown - STEP, target) end
	end
	showText(string.format('%d%%', math.floor(shown + 0.5)),
		maxOn == 1 and 'Fans speeding up' or 'Fans slowing down')
	local settled
	if maxOn == 1 then
		settled = shown >= 100
	else
		local cfg = readCache()
		settled = target and math.abs(shown - target) < 1 and elapsed >= 4
			and cfg and cfg:lower() == var('FanControlNormal'):lower()
	end
	if settled or elapsed >= GIVE_UP then finish() end
end

function Spin()
	spin:step()
end

function ToggleMax()
	if busy then return end
	maxOn = 1 - maxOn
	if maxOn == 1 then
		run('FanMax', '-c ' .. var('FanControlMax'))
	else
		run('FanNormal', '-c ' .. var('FanControlNormal'))
	end
	-- Give Fan Control time to switch before trusting CACHE again.
	holdUntil = os.time() + 15
	saveMax()
	showMax()
	busy = true
	switchedAt = os.time()
	shown = maxOn == 1 and (lastAvg or 0) or 100
	setVar('Busy', 1)
	setVar('StatusText', maxOn == 1 and 'Speeding up' or 'Slowing down')
	SKIN:Bang('!UpdateMeter', 'Status')
	SKIN:Bang('!UpdateMeter', 'Snow')
	spin:start()
	SKIN:Bang('!CommandMeasure', 'mRamp', 'Stop 1')
	SKIN:Bang('!CommandMeasure', 'mRamp', 'Execute 1')
	Ramp()
end

function Open()
	run('FanOpen', '-w')
end
