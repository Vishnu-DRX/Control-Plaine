-- Control-Plaine | RecycleBin
-- Shows the bin size ("3.2 GB", orange above RecycleBinWarnGB), swaps the
-- full/empty icon and shows or hides the EMPTY link beside the size (it stays
-- hidden while RecycleBinHasEmpty is 0, see Needs.lua). Runs on every update (no IfConditions: they only fire on
-- a change, which is how older skins went stale).

local mCount, mSize
local last, lastInk

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
	local bytes = mSize:GetValue()
	local warnGB = tonumber(SKIN:GetVariable('RecycleBinWarnGB')) or 10
	local text, icon, warn
	if n <= 0 then
		text, icon, warn = 'EMPTY', 'trash-empty.png', false
	else
		text, icon = size(bytes), 'trash.png'
		warn = bytes > warnGB * 1024 ^ 3
	end

	-- Ink and Warn change with the light/dark mode, so they are read on every
	-- run and a change of either counts as a new state.
	local ink = SKIN:GetVariable('Ink')
	local sizeInk = SKIN:GetVariable(warn and 'Warn' or 'Ink')
	local canEmpty = on('RecycleBinHasEmpty')
	local state = text .. '|' .. sizeInk .. '|' .. ink .. '|' .. tostring(canEmpty)
	if state ~= last then
		SKIN:Bang('!SetOption', 'Detail', 'Text', text)
		SKIN:Bang('!SetVariable', 'SizeInk', sizeInk)
		if ink ~= lastInk then SKIN:Bang('!SetVariable', 'EmptyInk', ink) end
		lastInk = ink
		SKIN:Bang('!SetOption', 'Icon', 'ImageName', '#@#Icons\\' .. icon)
		SKIN:Bang((n > 0 and canEmpty) and '!ShowMeter' or '!HideMeter', 'LinkEmpty')
		SKIN:Bang('!UpdateMeter', '*')
		SKIN:Bang('!Redraw')
		last = state
	end
	return n
end

-- EMPTY link. EmptyBin shows Windows' confirm dialog; EmptyBinSilent does not.
function Empty()
	if not on('RecycleBinHasEmpty') then return end
	-- The link may hide under the mouse, so no leave event: reset its colour.
	SKIN:Bang('!SetVariable', 'EmptyInk', SKIN:GetVariable('Ink'))
	SKIN:Bang('!CommandMeasure', 'mCount',
		on('RecycleBinConfirm') and 'EmptyBin' or 'EmptyBinSilent')
	SKIN:Bang('!UpdateMeasure', 'mCount')
	SKIN:Bang('!UpdateMeasure', 'mSize')
	SKIN:Bang('!UpdateMeasure', 'mScript')
end
