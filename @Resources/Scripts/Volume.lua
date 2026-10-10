-- Control-Plaine | Volume
-- Scroll rules and click-on-the-ring. The plugin (mAudio) does the audio work:
-- its value is 0-100, or -1 while muted. SetVolume and ChangeVolume unmute.

local audio

function Initialize()
	audio = SKIN:GetMeasure('mAudio')
end

local function num(name, default)
	return tonumber(SKIN:ParseFormula('(' .. SKIN:ReplaceVariables('#' .. name .. '#') .. ')')) or default
end

local function refresh()
	SKIN:Bang('!UpdateMeasureGroup', 'Volume')
	SKIN:Bang('!UpdateMeterGroup', 'Volume')
	SKIN:Bang('!Redraw')
end

-- dir: 1 = up, -1 = down.
function Scroll(dir)
	local step = math.max(1, math.floor(num('VolumeStep', 2)))
	if audio:GetValue() < 0 then
		-- Muted: down does nothing (ChangeVolume would unmute); up unmutes
		-- only when VolumeScrollUnmutes is on.
		if dir < 0 or num('VolumeScrollUnmutes', 1) == 0 then return end
	end
	SKIN:Bang('!CommandMeasure', 'mAudio', 'ChangeVolume ' .. (dir > 0 and '+' or '-') .. step)
	refresh()
end

-- x, y: mouse position inside RingHit (same box as the Ring meter).
function RingClick(x, y)
	local scale = num('Scale', 1)
	local r = num('RingRadius', 22) * scale
	local w = num('RingWidth', 5) * scale
	local c = r + w / 2 + scale
	local dx, dy = x - c, y - c
	-- Only the ring band counts, with a little slack either side.
	local d = math.sqrt(dx * dx + dy * dy)
	local slack = w / 2 + 6 * scale
	if d < r - slack or d > r + slack then return end
	-- 0 at 12 o'clock, clockwise (screen y grows downward).
	local a = math.atan2(dx, -dy)
	if a < 0 then a = a + 2 * math.pi end
	local p = math.floor(a / (2 * math.pi) * 100 + 0.5)
	-- Just left of the top means full; a click never silences the output.
	if p >= 98 then p = 100 end
	if p < 1 then p = 1 end
	SKIN:Bang('!CommandMeasure', 'mAudio', 'SetVolume ' .. p)
	refresh()
end
