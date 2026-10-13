-- Control-Plaine | Controllers
-- Reads the state file written by Controllers.ps1 and fills the rows.
-- File: %TEMP%\ControlPlaine-controllers.txt
--   v1|<unix time>
--   <kind>|<name>|<battery 0-100 or -1>|<charging 0/1>
-- Each row's look comes from variables Row<N>Icon, Row<N>Bat, Row<N>Name,
-- Row<N>Color, Row<N>Chg, Row<N>Target, Row<N>Tip; the meters use them.

local MAX_ROWS = 4
local ICONS = { xbox = 'controller-xbox', dualsense = 'controller-dualsense', moza = 'wheel-moza', other = 'controller-xbox' }

local file
local staleAfter
local lastBody, lastLook
local lastKick = 0
local count = 0

local function var(name)
	return SKIN:ReplaceVariables('#' .. name .. '#')
end

local function num(name)
	return tonumber(SKIN:ParseFormula('(' .. var(name) .. ')')) or 0
end

function Initialize()
	file = os.getenv('TEMP') .. '\\ControlPlaine-controllers.txt'
	-- A file left by an earlier run would show controllers that may be gone.
	os.remove(file)
	-- The helper rewrites the file every scan; older than this means it died.
	staleAfter = math.max(15, num('ControllersPoll') * 4)
	lastKick = os.time()
end

-- Where a row's click goes, and its tooltip.
local function target(kind)
	local other = var('ControllersOther')
	if kind == 'dualsense' and var('ControllersDualSenseApp') ~= '' then
		return var('ControllersDualSenseApp'), ''
	elseif kind == 'moza' and var('ControllersWheelApp') ~= '' then
		return var('ControllersWheelApp'), ''
	end
	if other:lower() == 'ms-settings:bluetooth' then
		return other, 'Open Bluetooth settings'
	end
	return other, 'Open controller settings'
end

local function apply(devices, look)
	local low = num('ControllersBatteryLow')
	for i = 1, MAX_ROWS do
		local d = devices[i]
		if d then
			local p = 'Row' .. i
			local color = look.ink
			if d.chg == 1 then
				color = look.accent
			elseif d.bat >= 0 and d.bat < low then
				color = look.warn
			end
			local click, tip = target(d.kind)
			SKIN:Bang('!SetVariable', p .. 'Icon', ICONS[d.kind] or ICONS.other)
			SKIN:Bang('!SetVariable', p .. 'Bat', tostring(d.bat))
			SKIN:Bang('!SetVariable', p .. 'Chg', tostring(d.chg))
			SKIN:Bang('!SetVariable', p .. 'Name', d.name)
			SKIN:Bang('!SetVariable', p .. 'Color', color)
			SKIN:Bang('!SetVariable', p .. 'Target', click)
			SKIN:Bang('!SetVariable', p .. 'Tip', tip)
		end
	end
	count = math.min(#devices, MAX_ROWS)
	for i = 1, MAX_ROWS do
		SKIN:Bang(i <= count and '!ShowMeterGroup' or '!HideMeterGroup', 'Row' .. i)
	end
	SKIN:Bang('!SetVariable', 'Count', tostring(count))
	SKIN:Bang('!SetVariable', 'SelfHidden', count == 0 and '1' or '0')
	SKIN:Bang('!UpdateMeasure', 'mVisible')
	SKIN:Bang('!UpdateMeter', '*')
	SKIN:Bang('!Redraw')
end

function Update()
	local text = ''
	local f = io.open(file, 'r')
	if f then
		text = f:read('*a') or ''
		f:close()
	end

	local stamp, body = text:match('^v1|(%d+)\r?\n(.*)$')
	if not stamp or os.time() - tonumber(stamp) > staleAfter then
		body = ''
		-- Helper missing or dead: start it again (at most every 30 s).
		if os.time() - lastKick > 30 then
			lastKick = os.time()
			SKIN:Bang('!CommandMeasure', 'mHelper', 'Run')
		end
	end

	-- Colours are resolved here, so re-apply when the accent changes.
	local look = { ink = var('Ink'), warn = var('Warn'), accent = var('Accent') }
	local lookKey = look.ink .. '/' .. look.warn .. '/' .. look.accent
	if body == lastBody and lookKey == lastLook then return count end
	lastBody, lastLook = body, lookKey

	local devices = {}
	for line in body:gmatch('[^\r\n]+') do
		local kind, name, bat, chg = line:match('^(%w+)|([^|]*)|(%-?%d+)|(%d)$')
		if kind then
			devices[#devices + 1] = { kind = kind, name = name, bat = tonumber(bat), chg = tonumber(chg) }
		end
	end
	apply(devices, look)
	return count
end
