-- Control-Plaine | DeepCool
-- Follows whether the DeepCool app runs and starts or closes it on click.

local running = false
local holdUntil = 0     -- after a click, trust the click until the app catches up
local proc

local function show()
	local accent, ink = SKIN:GetVariable('Accent'), SKIN:GetVariable('Ink')
	local label = SKIN:GetVariable('DeepCoolLabel', 'app'):lower() == 'screen' and 'Case screen' or 'DeepCool'
	SKIN:Bang('!SetVariable', 'IconTint', running and accent or ink)
	SKIN:Bang('!SetVariable', 'StateText', label .. (running and ' on' or ' off'))
	SKIN:Bang('!SetOption', 'Icon', 'ToolTipText', running and 'Close DeepCool' or 'Start DeepCool')
	SKIN:Bang('!UpdateMeter', 'Icon')
	SKIN:Bang('!UpdateMeter', 'State')
	SKIN:Bang('!Redraw')
end

function Initialize()
	proc = SKIN:GetMeasure('mProcess')
	show()
end

function Update()
	if os.time() >= holdUntil then
		running = proc:GetValue() == 1
	end
	show()
	return running and 1 or 0
end

function Toggle()
	if running then
		SKIN:Bang('!CommandMeasure', 'mStop', 'Run')
	elseif SKIN:GetVariable('DeepCoolStartHidden', '1') == '1' then
		SKIN:Bang('!CommandMeasure', 'mStart', 'Run')
	else
		SKIN:Bang('!CommandMeasure', 'mStartShown', 'Run')
	end
	running = not running
	holdUntil = os.time() + 6
	show()
end
