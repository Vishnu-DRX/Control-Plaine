-- Control-Plaine | Power
-- Hover labels, two-click confirm for restart and shut down, and the uptime line.

local LABEL = { lock = 'Lock', sleep = 'Sleep', restart = 'Restart', shutdown = 'Shut down' }
local CONFIRM = { restart = 'Click again to restart', shutdown = 'Click again to shut down' }
local METER = { lock = 'Lock', sleep = 'Sleep', restart = 'Restart', shutdown = 'Shutdown' }
local RUN = { lock = 'mDoLock', sleep = 'mDoSleep', restart = 'mDoRestart', shutdown = 'mDoShutdown' }

local armed, hovered

function Initialize()
	rest = SKIN:GetVariable('AlphaRest')
	lit = SKIN:GetVariable('AlphaHover')
	ink = SKIN:GetVariable('Ink')
	warn = SKIN:GetVariable('Warn')
	warnDays = tonumber(SKIN:GetVariable('UptimeWarnDays', '5')) or 5
	uptime = SKIN:GetMeasure('mUptime')
end

local function paint(key)
	local meter = METER[key]
	local on = (key == hovered) or (key == armed)
	SKIN:Bang('!SetOption', meter, 'ImageAlpha', on and lit or rest)
	SKIN:Bang('!SetOption', meter, 'ImageTint', key == armed and warn or ink)
	SKIN:Bang('!UpdateMeter', meter)
end

local function label()
	local text, color
	if armed then
		text, color = CONFIRM[armed], warn
	elseif hovered then
		text, color = LABEL[hovered], ink
	end
	if text then
		SKIN:Bang('!SetOption', 'Name', 'Text', text)
		SKIN:Bang('!SetOption', 'Name', 'FontColor', color .. ',' .. lit)
		SKIN:Bang('!ShowMeter', 'Name')
		SKIN:Bang('!HideMeter', 'Uptime')
	else
		SKIN:Bang('!HideMeter', 'Name')
		SKIN:Bang('!ShowMeter', 'Uptime')
	end
	SKIN:Bang('!UpdateMeter', 'Name')
	SKIN:Bang('!UpdateMeter', 'Uptime')
	SKIN:Bang('!Redraw')
end

function Hover(key)
	hovered = key
	paint(key)
	label()
end

function Leave(key)
	if hovered == key then hovered = nil end
	paint(key)
	label()
end

function Disarm()
	if not armed then return end
	local was = armed
	armed = nil
	paint(was)
	label()
end

function Click(key)
	-- Restart and shut down need a second click within a few seconds.
	if CONFIRM[key] and armed ~= key then
		local was = armed
		armed = key
		if was then paint(was) end
		paint(key)
		label()
		SKIN:Bang('!CommandMeasure', 'mDisarm', 'Stop 1')
		SKIN:Bang('!CommandMeasure', 'mDisarm', 'Execute 1')
		return
	end
	Disarm()
	SKIN:Bang('!CommandMeasure', RUN[key], 'Run')
end

function Update()
	local seconds = uptime:GetValue()
	local hours = math.floor(seconds / 3600)
	local days = math.floor(seconds / 86400)
	local text
	if hours < 1 then
		text = 'Up less than an hour'
	elseif hours == 1 then
		text = 'Up 1 hour'
	elseif hours < 48 then
		text = 'Up ' .. hours .. ' hours'
	else
		text = 'Up ' .. days .. ' days'
	end
	local due = days >= warnDays
	if due then text = text .. ', restart recommended' end
	SKIN:Bang('!SetOption', 'Uptime', 'Text', text)
	SKIN:Bang('!SetVariable', 'UpWarn', due and '1' or '0')
	SKIN:Bang('!SetVariable', 'UpColor', due and warn or ink)
	SKIN:Bang('!UpdateMeter', 'Uptime')
	SKIN:Bang('!Redraw')
	return text
end
