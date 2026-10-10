-- Control-Plaine | Media
-- Slides long titles and artists inside their boxes when MediaScrollTitles=1.
-- Each line moves left 1px per tick (40 ms), waits at both ends, and starts
-- over when the song changes. Nothing runs unless something is playing.

local LINES = { { meter = 'Title', box = 'TitleBox' }, { meter = 'Artist', box = 'ArtistBox' } }
local PAUSE = 40 -- ticks to wait at each end (1.6 s)

local state, enabled
local lastTitle

function Initialize()
	state = SKIN:GetMeasure('mState')
	enabled = SKIN:GetVariable('MediaScrollTitles', '0') == '1'
	for _, l in ipairs(LINES) do
		l.offset, l.wait = 0, PAUSE
	end
end

function Start()
	if enabled then
		SKIN:Bang('!CommandMeasure', 'mScroll', 'Stop 1')
		SKIN:Bang('!CommandMeasure', 'mScroll', 'Execute 1')
	end
end

local function place(l)
	SKIN:Bang('!SetOption', l.meter, 'X', -l.offset)
	SKIN:Bang('!UpdateMeter', l.meter)
end

function Tick()
	if not enabled then return end
	local title = SKIN:GetMeasure('mTitle'):GetStringValue()
	local changed = title ~= lastTitle
	lastTitle = title
	local moved = false
	for _, l in ipairs(LINES) do
		local over = SKIN:GetMeter(l.meter):GetW() - SKIN:GetMeter(l.box):GetW()
		if changed or over <= 0 then
			if l.offset ~= 0 then l.offset = 0; place(l); moved = true end
			l.wait = PAUSE
		elseif state:GetValue() == 1 then
			if l.wait > 0 then
				l.wait = l.wait - 1
			elseif l.offset < over then
				l.offset = l.offset + 1
				place(l)
				moved = true
				if l.offset >= over then l.wait = PAUSE end
			else
				l.offset = 0
				l.wait = PAUSE
				place(l)
				moved = true
			end
		end
	end
	if moved then SKIN:Bang('!Redraw') end
end
