-- Control-Plaine | FanControl
-- Averages the fan sensors HWiNFO reports to the registry (Gadget reporting),
-- runs the MAX / normal profile switch, and keeps the MAX state in step with
-- the config Fan Control is actually using (Configurations\CACHE).

local MAXFANS = 8
local fans = {}        -- { measure, maxRPM }
local mode, ignoreStopped, useTasks
local exe, configDir, cacheFile
local maxOn = 0
local holdUntil = 0    -- ignore CACHE until then (a switch is in flight)
local ticks = 0

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
	setVar('BubbleInk', maxOn == 1 and var('Dark') or var('Ink'))
	SKIN:Bang('!UpdateMeter', 'Bubble')
	SKIN:Bang('!UpdateMeter', 'BubbleText')
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
	mode = var('FanControlMode', 'rpm'):lower()
	ignoreStopped = tonumber(var('FanControlIgnoreStopped', '1')) == 1
	useTasks = tonumber(var('FanControlUseTasks', '1')) == 1
	exe = var('FanControlPath')
	local dir = exe:match('^(.*\\)') or ''
	configDir = dir .. 'Configurations'
	cacheFile = configDir .. '\\CACHE'

	local indexes = split(var('FanControlIndexes'))
	local rpms = split(var('FanControlMaxRPM'))
	for i = 1, MAXFANS do
		local name = 'mFan' .. i
		local idx = tonumber(indexes[i])
		if idx then
			SKIN:Bang('!SetOption', name, 'RegValue', 'ValueRaw' .. idx)
			SKIN:Bang('!EnableMeasure', name)
			fans[#fans + 1] = { measure = SKIN:GetMeasure(name), maxRPM = tonumber(rpms[i]) }
		else
			SKIN:Bang('!DisableMeasure', name)
		end
	end

	maxOn = tonumber(var('FanControlMaxOn', '0')) == 1 and 1 or 0
	syncMax()
	showMax()
end

-- Average % of the reported fans, or nil when no sensor has a value.
local function average()
	local sum, count = 0, 0
	for _, fan in ipairs(fans) do
		-- HWiNFO stores values as text; a missing value reads as ''.
		local v = tonumber((fan.measure:GetStringValue() or ''):match('[%d%.]+') or '')
		if v and not (ignoreStopped and v == 0) then
			local pct
			if mode == 'duty' then
				pct = v
			elseif fan.maxRPM and fan.maxRPM > 0 then
				pct = v / fan.maxRPM * 100
			end
			if pct then
				sum = sum + math.min(pct, 100)
				count = count + 1
			end
		end
	end
	if count == 0 then return nil end
	return sum / count
end

function Update()
	local avg = average()
	if maxOn == 1 then
		setVar('FanText', '100%')
		setVar('FanTip', 'All fans at 100%')
	elseif avg then
		setVar('FanText', string.format('%d%%', math.floor(avg + 0.5)))
		setVar('FanTip', 'Average fan speed')
	else
		setVar('FanText', '--')
		setVar('FanTip', 'No fan sensor. In HWiNFO, turn on Gadget reporting for the fans and set FanControlIndexes.')
	end
	-- Every 10 s, follow config changes made in the Fan Control window.
	ticks = ticks + 1
	if ticks % 5 == 0 then syncMax() end
	return avg or -1
end

function ToggleMax()
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
	SKIN:Bang('!UpdateMeasure', 'mFanControl')
	SKIN:Bang('!UpdateMeter', 'Value')
	SKIN:Bang('!Redraw')
end

function Open()
	run('FanOpen', '-w')
end
