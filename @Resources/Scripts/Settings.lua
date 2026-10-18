-- Control-Plaine | Settings
-- Reads and writes settings for the Settings skin pages.
-- Every change is written to @Resources\User.inc (git-ignored), set as a
-- variable here, and the affected skins are refreshed so they pick it up.
-- Meters ask for state with inline Lua: [&mSettings:Fill('Key')].

local TABS = {
	'General', 'Advanced', 'DayDate', 'Power', 'Uptime', 'Volume', 'RecycleBin', 'Playnite',
	'Media', 'WiFi', 'FanControl', 'SignalRGB', 'DeepCool', 'Controllers',
}

local root, userInc
local active = {}      -- skin name -> true when loaded
local pending = {}     -- key -> value, written by Commit()
local pendingTargets = {}
local editKey, editTargets

-- ---------- helpers ----------

local function val(key)
	return SKIN:ReplaceVariables('#' .. key .. '#')
end

local function num(key)
	return tonumber(SKIN:ParseFormula('(' .. val(key) .. ')')) or 0
end

local function redraw()
	SKIN:Bang('!UpdateMeter', '*')
	SKIN:Bang('!Redraw')
end

-- Rainmeter.ini is UTF-16; the parts we read are ASCII, so dropping the
-- zero bytes is enough.
local function readActive()
	local f = io.open(SKIN:GetVariable('SETTINGSPATH') .. 'Rainmeter.ini', 'rb')
	if not f then return end
	local text = f:read('*a'):gsub('%z', '')
	f:close()
	local section
	for line in text:gmatch('[^\r\n]+') do
		local s = line:match('^%[(.-)%]')
		if s then
			section = s
		else
			local a = line:match('^Active=(%d+)')
			if a and section then
				local name = section:match('^' .. root:gsub('%p', '%%%0') .. '\\(.+)$')
				if name then active[name] = tonumber(a) > 0 end
			end
		end
	end
end

local function apply(targets)
	local self = false
	for t in (targets or ''):gmatch('[^,%s]+') do
		if t == 'all' then
			SKIN:Bang('!RefreshGroup', 'ControlPlaine')
			self = true
		elseif t ~= 'none' and active[t] then
			SKIN:Bang('!Refresh', root .. '\\' .. t)
		end
	end
	-- General settings (scale, accent, brightness) change this window too.
	if self then SKIN:Bang('!Refresh') end
end

-- ---------- lifecycle ----------

function Initialize()
	root = SKIN:GetVariable('ROOTCONFIG')
	userInc = SKIN:GetVariable('@') .. 'User.inc'
	readActive()
	-- Light the current tab and move the accent bar to it.
	local tab = SKIN:GetVariable('Tab', 'General')
	for _, name in ipairs(TABS) do
		if name == tab then
			SKIN:Bang('!SetOption', 'Tab' .. name, 'FontColor', '#Ink#,255')
			SKIN:Bang('!SetOption', 'TabBar', 'Y', '([Tab' .. name .. ':Y]-4*#PS#)')
		end
	end
	redraw()
end

function Update()
	return 0
end

-- ---------- state for meters (inline Lua) ----------

function On(key)
	return num(key) ~= 0
end

-- Toggle track colour.
function Fill(key)
	return On(key) and (val('Accent') .. ',255') or (val('Ink') .. ',46')
end

-- Toggle knob centre x at scale 1.
function Knob(key)
	return On(key) and 22 or 8
end

function ChoiceAlpha(key, value)
	return val(key):lower() == value:lower() and 255 or 115
end

function ChoiceLine(key, value)
	return val(key):lower() == value:lower() and 255 or 0
end

-- Text for value and path boxes.
function Show(key, format)
	local v = val(key)
	if format == 'plain' or format == nil then
		return v ~= '' and v or 'NOT SET'
	end
	local n = tonumber(v) or num(key)
	if format == 'pct' and n then
		return string.format('%d%%', math.floor(n + 0.5))
	elseif format == 'scale' and n then
		return string.format('%d%%', math.floor(n * 100 + 0.5))
	elseif format == 'ms' and n then
		return string.format('%d MS', math.floor(n + 0.5))
	elseif format == 'px' and n then
		return string.format('%g PX', n)
	elseif format == 'days' and n then
		return n == 1 and '1 DAY' or string.format('%d DAYS', n)
	elseif format == 'hm' and n then
		local h, m = math.floor(n / 60), math.floor(n % 60)
		if h == 0 then return m .. ' M' end
		if m == 0 then return h .. ' H' end
		return h .. ' H ' .. m .. ' M'
	end
	return v ~= '' and v or 'NOT SET'
end

-- ---------- changes ----------

function Set(key, value, targets)
	value = tostring(value)
	SKIN:Bang('!WriteKeyValue', 'Variables', key, value, userInc)
	SKIN:Bang('!SetVariable', key, value)
	redraw()
	apply(targets)
end

function Toggle(key, targets)
	Set(key, On(key) and 0 or 1, targets)
end

-- Scroll: show the new value now, write it once scrolling stops.
function Step(key, delta, min, max, targets)
	local v = num(key) + delta
	v = math.max(min, math.min(max, v))
	v = math.floor(v * 100 + 0.5) / 100
	SKIN:Bang('!SetVariable', key, tostring(v))
	pending[key] = tostring(v)
	pendingTargets[targets or 'none'] = true
	redraw()
	SKIN:Bang('!CommandMeasure', 'mCommit', 'Stop 1')
	SKIN:Bang('!CommandMeasure', 'mCommit', 'Execute 1')
end

function Commit()
	for key, value in pairs(pending) do
		SKIN:Bang('!WriteKeyValue', 'Variables', key, value, userInc)
	end
	local targets = {}
	for t in pairs(pendingTargets) do targets[#targets + 1] = t end
	pending, pendingTargets = {}, {}
	apply(table.concat(targets, ','))
end

-- Click on a path box: open a text field over it.
function EditPath(key, targets, meterName)
	editKey, editTargets = key, targets
	local m = SKIN:GetMeter(meterName)
	local w = math.max(m:GetW(), math.floor(280 * num('PS')))
	SKIN:Bang('!SetOption', 'mInput', 'X', m:GetX() + m:GetW() - w)
	SKIN:Bang('!SetOption', 'mInput', 'Y', m:GetY() - 2)
	SKIN:Bang('!SetOption', 'mInput', 'W', w)
	SKIN:Bang('!SetOption', 'mInput', 'H', m:GetH() + 4)
	SKIN:Bang('!SetOption', 'mInput', 'DefaultValue', val(key))
	SKIN:Bang('!UpdateMeasure', 'mInput')
	SKIN:Bang('!CommandMeasure', 'mInput', 'ExecuteBatch 1')
end

-- Colours are stored R,G,B; accept hex too (00E5FF or #00E5FF).
local function toRGB(text)
	local hex = text:match('^%s*#?(%x%x%x%x%x%x)%s*$')
	if hex then
		return string.format('%d,%d,%d', tonumber(hex:sub(1, 2), 16),
			tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
	end
	local r, g, b = text:match('^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$')
	if r then return r .. ',' .. g .. ',' .. b end
end

function InputDone(text)
	if not editKey then return end
	local key, targets = editKey, editTargets
	editKey, editTargets = nil, nil
	if key == 'AccentColor' then
		text = toRGB(text)
		if not text then return end
	end
	-- Values may not contain # (Rainmeter would read it as a variable).
	text = text:gsub('#', '')
	Set(key, text, targets)
end

-- ---------- GENERAL ----------

function SkinFill(name)
	return active[name] and (val('Accent') .. ',255') or (val('Ink') .. ',46')
end

function SkinKnob(name)
	return active[name] and 22 or 8
end

function SkinOn(name)
	if active[name] then
		SKIN:Bang('!DeactivateConfig', root .. '\\' .. name)
		active[name] = false
	else
		SKIN:Bang('!ActivateConfig', root .. '\\' .. name, name .. '.ini')
		active[name] = true
	end
	redraw()
end

function Lock()
	local on = not On('LockPositions')
	SKIN:Bang('!DraggableGroup', on and '0' or '1', 'ControlPlaine')
	Set('LockPositions', on and 1 or 0, 'none')
end

-- ---------- RESET AND CLEAN UP (Advanced page) ----------
-- User.inc is written by Rainmeter (!WriteKeyValue) and may be UTF-16 with a
-- byte order mark. Read it either way and write it back the way it was.

local resetAsking = false
local unknownCache

local function readFile(path)
	local f = io.open(path, 'rb')
	if not f then return nil, false end
	local raw = f:read('*a')
	f:close()
	local wide = raw:sub(1, 2) == '\255\254'
	if wide then raw = raw:sub(3) end
	if raw:sub(1, 3) == '\239\187\191' then raw = raw:sub(4) end
	return (raw:gsub('%z', '')), wide
end

local function writeFile(path, text, wide)
	local f = io.open(path, 'wb')
	if not f then return false end
	text = text:gsub('\r?\n', '\r\n')
	if wide then
		f:write('\255\254', (text:gsub('.', '%0\0')))
	else
		f:write(text)
	end
	f:close()
	return true
end

-- Key names set in a file's [Variables] (every key=value line).
local function keysOf(text, into)
	for line in (text or ''):gmatch('[^\r\n]+') do
		local k = line:match('^%s*([%w_]+)%s*=')
		if k then into[k:lower()] = true end
	end
	return into
end

local function definedKeys()
	local defined = {}
	local at = SKIN:GetVariable('@')
	local base = SKIN:GetVariable('ROOTCONFIGPATH')
	keysOf(readFile(at .. 'Defaults.inc'), defined)
	keysOf(readFile(at .. 'Theme.inc'), defined)
	for _, name in ipairs(TABS) do
		keysOf(readFile(base .. name .. '\\Defaults.inc'), defined)
	end
	keysOf(readFile(base .. 'SettingsButton\\Defaults.inc'), defined)
	return defined
end

-- Keys in User.inc that no Defaults.inc defines (for example a setting that
-- was renamed or removed). Sorted, original spelling.
local function unknownKeys()
	if unknownCache then return unknownCache end
	local list = {}
	local text = readFile(userInc)
	if text then
		local defined = definedKeys()
		local seen = {}
		for line in text:gmatch('[^\r\n]+') do
			local k = line:match('^%s*([%w_]+)%s*=')
			if k and not defined[k:lower()] and not seen[k:lower()] then
				seen[k:lower()] = true
				list[#list + 1] = k
			end
		end
		table.sort(list)
	end
	unknownCache = list
	return list
end

-- General page notice, empty when everything in User.inc is known.
function UnknownNotice()
	local n = #unknownKeys()
	if n == 0 then return '' end
	return string.format('%d UNKNOWN SETTING%s IN USER.INC. CLEAN UP', n, n == 1 and '' or 'S')
end

-- Advanced page description of the clean-up row.
function UnknownDesc()
	local list = unknownKeys()
	if #list == 0 then return 'No leftover settings found.' end
	local shown = {}
	for i = 1, math.min(3, #list) do shown[i] = list[i] end
	local more = #list > 3 and string.format(' +%d more', #list - 3) or ''
	return 'No skin uses: ' .. table.concat(shown, ', ') .. more .. '.'
end

function CleanLabel()
	return #unknownKeys() > 0 and 'CLEAN' or 'NOTHING TO CLEAN'
end

function CleanUnknown()
	local list = unknownKeys()
	if #list == 0 then return end
	local drop = {}
	for _, k in ipairs(list) do drop[k:lower()] = true end
	local text, wide = readFile(userInc)
	if not text then return end
	local out = {}
	for line in (text .. '\n'):gmatch('([^\r\n]*)\r?\n') do
		local k = line:match('^%s*([%w_]+)%s*=')
		if not (k and drop[k:lower()]) then out[#out + 1] = line end
	end
	while #out > 0 and out[#out] == '' do out[#out] = nil end
	writeFile(userInc, table.concat(out, '\n') .. '\n', wide)
	unknownCache = nil
	SKIN:Bang('!Refresh')
end

function ResetLabel()
	return resetAsking and 'CLICK TO CONFIRM' or 'RESET'
end

function ResetCancelLabel()
	return resetAsking and 'CANCEL' or ''
end

-- First click asks, second click empties User.inc and refreshes everything.
function Reset()
	if not resetAsking then
		resetAsking = true
		redraw()
		return
	end
	resetAsking = false
	local _, wide = readFile(userInc)
	writeFile(userInc, '[Variables]\n', wide)
	SKIN:Bang('!DraggableGroup', '1', 'ControlPlaine')
	unknownCache = nil
	apply('all')
end

function ResetCancel()
	resetAsking = false
	redraw()
end
