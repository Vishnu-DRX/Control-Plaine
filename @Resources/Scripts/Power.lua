-- Control-Plaine | Power
-- Owns every piece of state in the Power skin: which icon is hovered, the
-- armed second click, the schedule picker and the scheduled action.
-- Commands run through RunCommand measures in Power.ini (mShut for
-- shutdown.exe, mPS for Power.ps1, mLock); each one calls Done() when it ends.
-- The schedule is stored in @Resources\State.inc so it survives a refresh.

local NAME = { hibernate = 'HIBERNATE', sleep = 'SLEEP', shutdown = 'SHUT DOWN', restart = 'RESTART', lock = 'LOCK' }
local TASK = { hibernate = true, sleep = true }
local PICK_MIN, PICK_MAX, PICK_STEP = 15, 1440, 15

local slots          -- slot number -> action key
local over = {}      -- hovered elements ('c1', 'i2', 'link') -> true
local last           -- element entered most recently
local hovered, armed, linkKey
local picking, pickMinutes
local errorText
local sched = { action = '', at = 0, boot = 0 }
local checked = false
local queue = {}     -- commands waiting to run: { measure, args, ok, after, failText }
local running

-- ---------- helpers ----------

local function var(name)
	return SKIN:ReplaceVariables('#' .. name .. '#')
end

local function num(name)
	return tonumber(SKIN:ParseFormula('(' .. var(name) .. ')')) or 0
end

local function scale()
	return num('Scale')
end

local function slotOf(key)
	for i, k in pairs(slots) do
		if k == key then return i end
	end
end

local function hm(minutes)
	local h, m = math.floor(minutes / 60), minutes % 60
	if h == 0 then return m .. ' M' end
	if m == 0 then return h .. ' H' end
	return h .. ' H ' .. m .. ' M'
end

local function countdown()
	local left = sched.at - os.time()
	if left < 60 then return math.max(0, left) .. ' S' end
	return hm(math.ceil(left / 60))
end

local function bootTime()
	return os.time() - math.floor(SKIN:GetMeasure('mUptime'):GetValue())
end

-- Centre a left-aligned meter on x (pixels), kept inside the skin.
local function place(meter, x)
	SKIN:Bang('!UpdateMeter', meter)
	local w = SKIN:GetMeter(meter):GetW()
	local maxX = num('SkinW') * scale() - w
	SKIN:Bang('!SetOption', meter, 'X', math.floor(math.max(0, math.min(maxX, x - w / 2))))
	SKIN:Bang('!UpdateMeter', meter)
end

local function iconCentre(slot)
	return (num('Margin') + (slot - 1) * num('Pitch') + num('IconSize') / 2) * scale()
end

-- ---------- state file ----------

local function saveState()
	local file = SKIN:GetVariable('@') .. 'State.inc'
	SKIN:Bang('!WriteKeyValue', 'Variables', 'PowerScheduledAction', sched.action, file)
	SKIN:Bang('!WriteKeyValue', 'Variables', 'PowerScheduledAt', tostring(sched.at), file)
	SKIN:Bang('!WriteKeyValue', 'Variables', 'PowerScheduledBoot', tostring(sched.boot), file)
end

local function clearState()
	sched = { action = '', at = 0, boot = 0 }
	saveState()
end

-- ---------- drawing ----------

local function paint()
	local ink, accent, warn = var('Ink'), var('Accent'), var('Warn')
	local rest, lit = num('AlphaDetail'), num('AlphaHover')

	SKIN:Bang(picking and '!HideMeterGroup' or '!ShowMeterGroup', 'Main')
	SKIN:Bang(picking and '!ShowMeterGroup' or '!HideMeterGroup', 'Pick')

	if picking then
		local s = scale()
		local cx = num('SkinW') * s / 2
		SKIN:Bang('!SetOption', 'PickTitle', 'Text', NAME[picking] .. ' IN')
		SKIN:Bang('!SetOption', 'PickValue', 'Text', hm(pickMinutes))
		place('PickTitle', cx)
		place('PickValue', cx)
		place('PickSet', cx)
		local v = SKIN:GetMeter('PickValue')
		SKIN:Bang('!SetVariable', 'PickBoxW', math.floor(v:GetW() + 20 * s))
		SKIN:Bang('!SetVariable', 'PickBoxH', math.floor(v:GetH() + 4 * s))
		SKIN:Bang('!SetOption', 'PickBox', 'X', math.floor(v:GetX() - 10 * s))
		SKIN:Bang('!UpdateMeterGroup', 'Pick')
		SKIN:Bang('!Redraw')
		return
	end

	-- Icons.
	for i, key in pairs(slots) do
		local tint, alpha = ink, rest
		if key == armed then
			tint, alpha = warn, lit
		elseif key == sched.action then
			tint, alpha = accent, lit
		elseif key == hovered then
			alpha = lit
		end
		SKIN:Bang('!SetVariable', 'Tint' .. i, tint)
		SKIN:Bang('!SetVariable', 'Alpha' .. i, alpha)
	end

	-- Label row: error, then CLICK AGAIN, then the hovered name, then the countdown.
	local text, rgb, keep, slot = '', ink, 0, nil
	local focus = hovered or (sched.action ~= '' and sched.action) or nil
	if errorText then
		text, rgb, keep, slot = errorText, warn, 1, slotOf(focus or slots[1]) or 1
	elseif armed then
		text, rgb, keep, slot = 'CLICK AGAIN', warn, 1, slotOf(armed)
	elseif focus and focus == sched.action then
		text, rgb, keep, slot = NAME[focus] .. ' IN ' .. countdown(), accent, 1, slotOf(focus)
	elseif focus then
		text, slot = NAME[focus], slotOf(focus)
	end
	SKIN:Bang('!SetVariable', 'LabelRGB', rgb)
	SKIN:Bang('!SetVariable', 'LabelKeep', keep)
	SKIN:Bang('!SetOption', 'Label', 'Text', text)
	if slot then place('Label', iconCentre(slot)) end

	-- Link row: CANCEL under the scheduled icon, SCHEDULE under any other (not lock).
	-- CANCEL stays visible at rest, like the countdown above it.
	local linkKeep = 0
	if focus and focus == sched.action then
		linkKey = focus
		linkKeep = 1
		SKIN:Bang('!SetOption', 'Link', 'Text', 'CANCEL')
	elseif focus and focus ~= 'lock' then
		linkKey = focus
		SKIN:Bang('!SetOption', 'Link', 'Text', 'SCHEDULE')
	else
		linkKey = nil
	end
	SKIN:Bang('!SetVariable', 'LinkKeep', linkKeep)
	if linkKey and slotOf(linkKey) then
		SKIN:Bang('!ShowMeter', 'Link')
		place('Link', iconCentre(slotOf(linkKey)))
	else
		SKIN:Bang('!HideMeter', 'Link')
	end

	SKIN:Bang('!UpdateMeterGroup', 'Main')
	SKIN:Bang('!Redraw')
end

-- ---------- commands ----------

local function runNext()
	if running or #queue == 0 then return end
	running = table.remove(queue, 1)
	if running.measure == 'mShut' then
		SKIN:Bang('!SetVariable', 'ShutArgs', running.args)
	elseif running.measure == 'mPS' then
		SKIN:Bang('!SetVariable', 'PSArgs', running.args)
	end
	SKIN:Bang('!UpdateMeasure', running.measure)
	SKIN:Bang('!CommandMeasure', running.measure, 'Run')
end

-- opts: ok = exit codes that count as success (default {0}),
-- after = function(code, good), failText = error to show on failure.
local function run(measure, args, opts)
	opts = opts or {}
	table.insert(queue, { measure = measure, args = args, ok = opts.ok or { 0 },
		after = opts.after, failText = opts.failText })
	runNext()
end

local function showError(text)
	errorText = text
	queue = {}
	SKIN:Bang('!CommandMeasure', 'mTimer', 'Stop 3')
	SKIN:Bang('!CommandMeasure', 'mTimer', 'Execute 3')
	paint()
end

-- Called by the RunCommand measures when their program exits.
function Done()
	local step = running
	running = nil
	if not step then return end
	SKIN:Bang('!UpdateMeasure', step.measure)
	-- RunCommand's number value is 1 once the program ends, whatever its exit
	-- code, so both commands print the code and we read it from the output.
	local out = SKIN:GetMeasure(step.measure):GetStringValue() or ''
	local code = tonumber(out:match('(%-?%d+)%s*$')) or -1
	local good = false
	for _, c in ipairs(step.ok) do
		if c == code then good = true end
	end
	if step.after then step.after(code, good) end
	if good then
		runNext()
	elseif step.failText then
		showError(step.failText)
	else
		queue = {}
	end
end

-- Queue whatever undoes the current schedule. shutdown /a returns 1116 when
-- nothing was scheduled, which is fine.
local function queueCancel(failText)
	local a = sched.action
	if a == '' then return end
	local opts = { failText = failText, after = function(code, good)
		if good then clearState() end
	end }
	if TASK[a] then
		run('mPS', 'cancel ' .. a, opts)
	else
		opts.ok = { 0, 1116 }
		run('mShut', '/a', opts)
	end
end

local function runNow(key)
	if key == 'lock' then
		SKIN:Bang('!CommandMeasure', 'mLock', 'Run')
		return
	end
	queueCancel('COULD NOT CANCEL')
	local opts = { failText = 'COULD NOT ' .. NAME[key] }
	if key == 'hibernate' then
		run('mShut', '/h', opts)
	elseif key == 'sleep' then
		run('mPS', 'sleep', opts)
	elseif key == 'shutdown' then
		run('mShut', '/s /t 0', opts)
	elseif key == 'restart' then
		run('mShut', '/r /t 0', opts)
	end
end

-- ---------- lifecycle ----------

function Initialize()
	checked = false
	slots = { (var('PowerFirst'):lower() == 'sleep') and 'sleep' or 'hibernate', 'shutdown', 'restart', 'lock' }
	if slots[1] == 'sleep' then
		SKIN:Bang('!SetOption', 'Icon1', 'ImageName', '#@#Icons\\power-sleep.png')
	end
	sched.action = var('PowerScheduledAction'):lower()
	sched.at = num('PowerScheduledAt')
	sched.boot = num('PowerScheduledBoot')
	if not NAME[sched.action] or sched.at <= 0 then
		sched = { action = '', at = 0, boot = 0 }
	end
	pickMinutes = math.max(PICK_MIN, math.min(PICK_MAX, num('PowerPickerStart')))
end

-- Throw away a schedule that can no longer be true.
local function check()
	checked = true
	if sched.action == '' then return end
	if os.time() > sched.at + 60 then
		if TASK[sched.action] then run('mPS', 'cancel ' .. sched.action, { ok = { 0, 1, 2 } }) end
		clearState()
	elseif not TASK[sched.action] and math.abs(bootTime() - sched.boot) > 120 then
		-- The PC restarted, which drops a pending shut down or restart.
		clearState()
	elseif TASK[sched.action] then
		-- Is the Windows task still there? (0 = yes, 1 = no)
		run('mPS', 'query ' .. sched.action, { ok = { 0, 1 }, after = function(code)
			if code == 1 then
				clearState()
				paint()
			end
		end })
	end
end

function Update()
	if not checked then check() end
	if sched.action ~= '' and os.time() > sched.at + 60 then
		if TASK[sched.action] then run('mPS', 'cancel ' .. sched.action, { ok = { 0, 1, 2 } }) end
		clearState()
	end
	paint()
	return sched.action ~= '' and (sched.at - os.time()) or 0
end

-- ---------- mouse ----------

local function keyOf(el)
	if el == 'link' then return linkKey end
	return slots[tonumber(el:sub(2))]
end

local function refreshHover()
	local h
	if last and over[last] then
		h = keyOf(last)
	else
		for el in pairs(over) do h = keyOf(el) break end
	end
	if h ~= hovered then
		hovered = h
		paint()
	end
end

function Over(el)
	over[el] = true
	last = el
	refreshHover()
end

function Out(el)
	over[el] = nil
	refreshHover()
end

function Enter()
	SKIN:Bang('!CommandMeasure', 'mTimer', 'Stop 2')
end

function Exit()
	over, last = {}, nil
	hovered = nil
	if picking then
		SKIN:Bang('!CommandMeasure', 'mTimer', 'Stop 2')
		SKIN:Bang('!CommandMeasure', 'mTimer', 'Execute 2')
	end
	paint()
end

-- ---------- clicks ----------

function Disarm()
	if not armed then return end
	armed = nil
	paint()
end

function ClearError()
	errorText = nil
	paint()
end

function Click(slot)
	local key = slots[slot]
	if not key or picking then return end
	local confirm = (key == 'shutdown' or key == 'restart') and num('PowerConfirm') ~= 0
	if confirm and armed ~= key then
		armed = key
		SKIN:Bang('!CommandMeasure', 'mTimer', 'Stop 1')
		SKIN:Bang('!CommandMeasure', 'mTimer', 'Execute 1')
		paint()
		return
	end
	armed = nil
	SKIN:Bang('!CommandMeasure', 'mTimer', 'Stop 1')
	runNow(key)
	paint()
end

function LinkClick()
	local key = linkKey
	if not key then return end
	if key == sched.action then
		queueCancel('COULD NOT CANCEL')
	else
		picking = key
		pickMinutes = math.max(PICK_MIN, math.min(PICK_MAX, num('PowerPickerStart')))
	end
	armed = nil
	paint()
end

-- ---------- picker ----------

function PickStep(delta)
	if not picking then return end
	pickMinutes = math.max(PICK_MIN, math.min(PICK_MAX, pickMinutes + delta))
	paint()
end

function ClosePicker()
	picking = nil
	paint()
end

function SetSchedule()
	local key = picking
	if not key then return end
	picking = nil
	local seconds = pickMinutes * 60
	-- One schedule at a time: undo the old one first.
	queueCancel('COULD NOT SCHEDULE')
	local opts = { failText = 'COULD NOT SCHEDULE', after = function(code, good)
		if not good then return end
		sched = { action = key, at = os.time() + seconds, boot = bootTime() }
		saveState()
		paint()
	end }
	if TASK[key] then
		run('mPS', 'schedule ' .. key .. ' ' .. seconds, opts)
	else
		run('mShut', (key == 'restart' and '/r' or '/s') .. ' /t ' .. seconds, opts)
	end
	paint()
end
