-- Control-Plaine | Uptime
-- Runs every 15 s (and when the mouse enters) and always rewrites the text,
-- the colour and the visibility, so nothing depends on a value changing.
-- Visibility at rest comes from the reminder (Shown) and, when UptimeDetails
-- is always, from #RevealMin# in Core.inc; there is no separate always key.

local uptime

function Initialize()
	uptime = SKIN:GetMeasure('mUptime')
end

local function num(name)
	return tonumber(SKIN:ParseFormula('(' .. SKIN:ReplaceVariables('#' .. name .. '#') .. ')')) or 0
end

-- 45 M / 14 H 32 M / 1 DAY 3 H / 6 DAYS 3 H
function Format(seconds)
	local minutes = math.floor(seconds / 60)
	local days = math.floor(minutes / 1440)
	local hours = math.floor(minutes / 60) % 24
	if days >= 1 then
		return days .. (days == 1 and ' DAY ' or ' DAYS ') .. hours .. ' H'
	elseif hours >= 1 then
		return hours .. ' H ' .. (minutes % 60) .. ' M'
	end
	return minutes .. ' M'
end

function Update()
	local seconds = uptime:GetValue()
	local due = seconds >= num('UptimeWarnDays') * 86400
	local shown = due
	SKIN:Bang('!SetOption', 'UpLabel', 'Text', due and 'RESTART RECOMMENDED' or 'UPTIME')
	SKIN:Bang('!SetOption', 'UpValue', 'Text', Format(seconds))
	SKIN:Bang('!SetVariable', 'UpRGB', SKIN:ReplaceVariables(due and '#Warn#' or '#Ink#'))
	SKIN:Bang('!SetVariable', 'Shown', shown and '1' or '0')
	SKIN:Bang('!UpdateMeter', '*')
	SKIN:Bang('!Redraw')
	return seconds
end
