-- Control-Plaine | Media
-- 1. Long titles and artists (wider than the line between the chevrons):
--    at rest they are cut with an ellipsis. When the song changes they slide
--    once to show the rest, then go back; while hovered they keep sliding.
--    MediaScrollTitles=0 turns sliding off (ellipsis only).
-- 2. Click on the ring jumps to that point in the song.

local LINES = { { meter = 'Title', box = 'TitleBox' }, { meter = 'Artist', box = 'ArtistBox' } }
local WAIT = 30 -- ticks (40 ms each) before sliding and at the end: 1.2 s
local STEP = 1  -- px per tick, times Scale

local enabled, hovering = false, false
local running = false

local function num(name, default)
	return tonumber(SKIN:ParseFormula('(' .. SKIN:ReplaceVariables('#' .. name .. '#') .. ')')) or default
end

function Initialize()
	enabled = num('MediaScrollTitles', 1) ~= 0
	for _, l in ipairs(LINES) do
		l.phase, l.offset, l.count, l.over = 'idle', 0, 0, 0
	end
end

-- Cut back to the ellipsis at the start of the line.
local function rest(l)
	l.phase, l.offset, l.count = 'idle', 0, 0
	SKIN:Bang('!SetOption', l.meter, 'X', 0)
	SKIN:Bang('!SetOption', l.meter, 'ClipStringW', '(#TextW#*#Scale#)')
	SKIN:Bang('!UpdateMeter', l.meter)
end

-- Unclip to measure the full text; slide only if it doesn't fit.
local function begin(l)
	SKIN:Bang('!SetOption', l.meter, 'ClipStringW', 4000)
	SKIN:Bang('!UpdateMeter', l.meter)
	l.over = SKIN:GetMeter(l.meter):GetW() - SKIN:GetMeter(l.box):GetW()
	if l.over <= 0 then
		rest(l)
		return false
	end
	l.phase, l.offset, l.count = 'wait', 0, WAIT
	return true
end

local function run()
	local any = false
	for _, l in ipairs(LINES) do
		if l.phase ~= 'idle' then any = true end
	end
	if any and not running then
		SKIN:Bang('!CommandMeasure', 'mScroll', 'Execute 1')
		running = true
	elseif not any and running then
		SKIN:Bang('!CommandMeasure', 'mScroll', 'Stop 1')
		running = false
	end
	SKIN:Bang('!Redraw')
end

local function startAll()
	for _, l in ipairs(LINES) do
		if l.phase == 'idle' then begin(l) end
	end
	run()
end

function TrackChanged()
	if not enabled then return end
	for _, l in ipairs(LINES) do rest(l) end
	startAll()
end

function Hover(on)
	if not enabled then return end
	hovering = on == 1
	if hovering then
		startAll()
	else
		for _, l in ipairs(LINES) do rest(l) end
		run()
	end
end

function Tick()
	local step = STEP * num('Scale', 1)
	for _, l in ipairs(LINES) do
		if l.phase == 'wait' then
			l.count = l.count - 1
			if l.count <= 0 then l.phase = 'slide' end
		elseif l.phase == 'slide' then
			l.offset = math.min(l.over, l.offset + step)
			SKIN:Bang('!SetOption', l.meter, 'X', -l.offset)
			SKIN:Bang('!UpdateMeter', l.meter)
			if l.offset >= l.over then l.phase, l.count = 'hold', WAIT end
		elseif l.phase == 'hold' then
			l.count = l.count - 1
			if l.count <= 0 then
				rest(l)
				-- Keep going while the mouse is on the skin.
				if hovering then begin(l) end
			end
		end
	end
	run()
end

-- x, y: mouse position inside RingHit (same box as the Ring meter).
function Seek(x, y)
	if SKIN:GetMeasure('mDuration'):GetValue() <= 0 then return end
	local scale = num('Scale', 1)
	local r = num('RingRadius', 22) * scale
	local w = num('RingWidth', 5) * scale
	local c = r + w / 2 + scale
	local dx, dy = x - c, y - c
	-- Only the ring band counts; the centre is play/pause.
	local d = math.sqrt(dx * dx + dy * dy)
	local slack = w / 2 + 6 * scale
	if d < r - slack or d > r + slack then return end
	-- 0 at 12 o'clock, clockwise (screen y grows downward).
	local a = math.atan2(dx, -dy)
	if a < 0 then a = a + 2 * math.pi end
	local p = math.floor(a / (2 * math.pi) * 100)
	SKIN:Bang('!CommandMeasure', 'mProgress', 'SetPosition ' .. math.min(99, math.max(0, p)))
	SKIN:Bang('!UpdateMeasureGroup', 'Media')
	SKIN:Bang('!UpdateMeterGroup', 'Media')
	SKIN:Bang('!Redraw')
end
