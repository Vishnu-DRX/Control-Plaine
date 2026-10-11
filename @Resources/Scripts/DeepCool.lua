-- Control-Plaine | DeepCool
-- Follows whether the DeepCool app runs and starts or closes it on click.
-- Starting and closing take a few seconds, so a click shows STARTING or
-- CLOSING with a spinner, and the on/off state changes only once the
-- process list confirms it (or after a timeout, back to what is true).

local TIMEOUT = 30      -- s before a start or close that never lands is given up
local SETTLE = 3        -- s the process must run before a start counts as done
-- s CLOSING stays after the process is gone: DeepCoolOffDelay (the case
-- screen goes dark a few seconds after the app exits).

local running = false
local pending           -- nil, 'start' or 'stop'
local since = 0         -- when pending began
local seenAt            -- when the process was first seen during a start
local goneAt            -- when the process was first missing during a close
local proc, spin

local function label()
	return SKIN:GetVariable('DeepCoolLabel', 'screen'):lower() == 'screen' and 'Case screen' or 'DeepCool'
end

local function show()
	local accent, ink = SKIN:GetVariable('Accent'), SKIN:GetVariable('Ink')
	local text, tip
	if pending == 'start' then
		text, tip = 'Starting', 'Starting DeepCool'
	elseif pending == 'stop' then
		text, tip = 'Closing', 'Closing DeepCool'
	else
		text = label() .. (running and ' on' or ' off')
		tip = running and 'Close DeepCool' or 'Start DeepCool'
	end
	SKIN:Bang('!SetVariable', 'IconTint', (running and not pending) and accent or ink)
	SKIN:Bang('!SetVariable', 'Busy', pending and 1 or 0)
	SKIN:Bang('!SetVariable', 'StateText', text)
	SKIN:Bang('!SetOption', 'Icon', 'ToolTipText', tip)
	SKIN:Bang('!UpdateMeter', 'Icon')
	SKIN:Bang('!UpdateMeter', 'State')
	SKIN:Bang('!UpdateMeter', 'Spinner')
	SKIN:Bang('!Redraw')
	if pending then spin:start() else spin:stop() end
end

function Initialize()
	proc = SKIN:GetMeasure('mProcess')
	spin = dofile(SKIN:GetVariable('@') .. 'Scripts\\Spinner.lua').new('Spinner', 'mSpin')
	show()
end

function Update()
	running = proc:GetValue() == 1
	local now = os.time()
	if pending == 'start' and running then
		seenAt = seenAt or now
		if now - seenAt >= SETTLE then pending = nil end
	elseif pending == 'stop' and not running then
		goneAt = goneAt or now
		local delay = tonumber(SKIN:GetVariable('DeepCoolOffDelay', '5')) or 5
		if now - goneAt >= delay then pending = nil end
	end
	if pending and now - since > TIMEOUT then pending = nil end
	show()
	return running and 1 or 0
end

function Toggle()
	if pending then return end
	if running then
		pending = 'stop'
		goneAt = nil
		SKIN:Bang('!CommandMeasure', 'mStop', 'Run')
	else
		pending = 'start'
		seenAt = nil
		if SKIN:GetVariable('DeepCoolStartHidden', '1') == '1' then
			SKIN:Bang('!CommandMeasure', 'mStart', 'Run')
		else
			SKIN:Bang('!CommandMeasure', 'mStartShown', 'Run')
		end
	end
	since = os.time()
	show()
end

function Spin()
	spin:step()
end
