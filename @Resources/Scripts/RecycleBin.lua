-- Control-Plaine | RecycleBin
-- Formats "35 FILES   3.2 GB", swaps the full/empty icon and shows or hides
-- the EMPTY link. Runs on every update (no IfConditions: they only fire on
-- a change, which is how older skins went stale).

local mCount, mSize
local last

local UNITS = { 'B', 'KB', 'MB', 'GB', 'TB' }

local function size(bytes)
	local i = 1
	while bytes >= 1024 and i < #UNITS do
		bytes = bytes / 1024
		i = i + 1
	end
	if i == 1 then return string.format('%d B', bytes) end
	if bytes < 100 then return string.format('%.1f %s', bytes, UNITS[i]) end
	return string.format('%d %s', math.floor(bytes + 0.5), UNITS[i])
end

local function on(name)
	return tonumber(SKIN:GetVariable(name)) == 1
end

function Initialize()
	mCount = SKIN:GetMeasure('mCount')
	mSize = SKIN:GetMeasure('mSize')
end

function Update()
	local n = math.floor(mCount:GetValue() + 0.5)
	local text, icon
	if n <= 0 then
		text, icon = 'EMPTY', 'trash-empty.png'
	else
		text = n == 1 and '1 FILE' or (n .. ' FILES')
		if on('RecycleBinShowSize') then
			text = text .. '   ' .. size(mSize:GetValue())
		end
		icon = 'trash.png'
	end

	if text ~= last then
		local full = n > 0
		SKIN:Bang('!SetOption', 'Detail', 'Text', text)
		SKIN:Bang('!SetOption', 'Icon', 'ImageName', '#@#Icons\\' .. icon)
		local show = full and '!ShowMeter' or '!HideMeter'
		SKIN:Bang(show, 'LinkEmpty')
		SKIN:Bang(show, 'LinkEmptyLine')
		-- With EMPTY gone, OPEN takes the right edge.
		SKIN:Bang('!SetOption', 'LinkOpen', 'X',
			full and '([LinkEmpty:X]-16*#Scale#)' or '#ColW#')
		SKIN:Bang('!UpdateMeter', '*')
		SKIN:Bang('!Redraw')
		last = text
	end
	return n
end

-- EMPTY link. EmptyBin shows Windows' confirm dialog; EmptyBinSilent does not.
function Empty()
	SKIN:Bang('!CommandMeasure', 'mCount',
		on('RecycleBinConfirm') and 'EmptyBin' or 'EmptyBinSilent')
	SKIN:Bang('!UpdateMeasure', 'mCount')
	SKIN:Bang('!UpdateMeasure', 'mSize')
	SKIN:Bang('!UpdateMeasure', 'mScript')
end
