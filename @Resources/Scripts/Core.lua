-- Control-Plaine | Core
-- Resolves the suite's shared layout variables once per skin load (Core.inc
-- runs this as mCore), so skins never branch on their own settings:
--
--   Side Mir TA TAT Lead Trail   left/right arrangement (specs/alignment.md)
--   RevealMin Reveal             details at rest: 0 = hover only, 1 = always
--   HoverTint                    colour of a hovered icon: Accent or Ink
--   Mode Ink InkContrast Warn Accent
--                                dark or light, and the colours for it
--   RestEff HoverEff             rest and hover brightness (%), light boost applied
--
-- Input is read from variables the skin sets before it includes Core.inc:
--   SkinSide     left or right   (the skin's <Skin>Align)
--   SkinDetails  hover or always (the skin's <Skin>Details)
--   SkinTheme    auto, dark or light (the skin's <Skin>Theme)
-- plus the global AlignAll, DetailsAll, HoverAccent, Theme, ThemeLock,
-- AccentLight, AccentLightK, RestBrightness, HoverBrightness and LightBoost
-- settings (specs/alignment.md, specs/theme.md).
-- A wrong or missing value falls back to left / hover / accent, never to an
-- error, so a typo in User.inc can't take a skin down.

local SIDES = {
	left  = { Mir = 0, TA = 'LeftCenter',  TAT = 'Left',  Lead = 0, Trail = 1 },
	right = { Mir = 1, TA = 'RightCenter', TAT = 'Right', Lead = 1, Trail = 0 },
}

local function norm(value)
	return (tostring(value or ''):lower():gsub('^%s+', ''):gsub('%s+$', ''))
end

-- AlignAll = left or right wins; anything else (skin) defers to the skin.
function PickSide(all, skin)
	all, skin = norm(all), norm(skin)
	if all == 'left' or all == 'right' then return all end
	if skin == 'right' then return 'right' end
	return 'left'
end

-- DetailsAll = hover or always wins; anything else (skin) defers to the skin.
function PickDetails(all, skin)
	all, skin = norm(all), norm(skin)
	if all == 'hover' or all == 'always' then return all end
	if skin == 'always' then return 'always' end
	return 'hover'
end

-- Dark = for dark wallpapers (white skins, today). Light = for light wallpapers
-- (black skins). Theme: auto follows Windows, dark and light force it.
-- SkinTheme: auto follows Theme, dark and light override it for one skin.
-- A locked skin (the Settings window) is always dark.
function PickMode(lock, skin, global, winLight)
	if lock then return 'dark' end
	skin, global = norm(skin), norm(global)
	if skin == 'dark' or skin == 'light' then return skin end
	if global == 'dark' or global == 'light' then return global end
	if global == 'auto' then return winLight and 'light' or 'dark' end
	return 'dark'
end

local function parseRGB(text)
	local r, g, b = tostring(text):match('^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$')
	if r then return tonumber(r), tonumber(g), tonumber(b) end
end

-- "r,g,b" with every channel multiplied by k; unreadable input is returned as is.
function Darken(rgb, k)
	local r, g, b = parseRGB(rgb)
	k = tonumber(k)
	if not r or not k then return rgb end
	local function ch(c) return math.max(0, math.min(255, math.floor(c * k + 0.5))) end
	return ch(r) .. ',' .. ch(g) .. ',' .. ch(b)
end

local function pct(value, default)
	return math.max(0, math.min(100, tonumber(value) or default))
end

-- Rest and hover brightness in percent. In light mode the boost is added to
-- rest; hover is never below rest. Both are capped at 100.
function Brightness(rest, hover, boost, light)
	rest = pct(rest, 60)
	hover = pct(hover, 98)
	if light then rest = math.min(100, rest + (tonumber(boost) or 0)) end
	return rest, math.min(100, math.max(hover, rest))
end

-- ReplaceVariables, so a value like Accent=#AccentColor# comes back resolved.
local function get(name, default)
	return SKIN:ReplaceVariables(SKIN:GetVariable(name, default))
end

local cache = {}

-- Sets a variable only when its value changed, so the 5 second Update is cheap.
-- True when it changed.
local function set(name, value)
	value = tostring(value)
	if cache[name] ~= value then
		cache[name] = value
		SKIN:Bang('!SetVariable', name, value)
		return true
	end
	return false
end

local inkDark, inkContrastDark, warnDark

-- Windows' own light or dark setting, read by the mWinTheme registry measure.
-- Missing or unreadable counts as dark.
local function windowsIsLight()
	local ok, value = pcall(function() return SKIN:GetMeasure('mWinTheme'):GetValue() end)
	return ok and tonumber(value) == 1
end

-- The accent before any light-mode darkening: the Windows accent (mAccent)
-- while AccentFollowWindows is on and it answers, else the custom AccentColor.
local function accentBase()
	if get('AccentFollowWindows', '1') ~= '0' then
		local ok, text = pcall(function() return SKIN:GetMeasure('mAccent'):GetStringValue() end)
		if ok and type(text) == 'string' and text:match('^%d+,%d+,%d+$') and text ~= '0,0,0' then
			return text
		end
	end
	return get('AccentColor', '0,229,255')
end

-- The Settings window is always dark: it names its page in Tab, and a skin can
-- also set ThemeLock=1.
local function locked()
	return get('ThemeLock', '0') == '1' or get('Tab', '') ~= ''
end

-- Colours, brightness and the hover tint. Runs at load and every 5 seconds,
-- so a change of Windows theme or accent shows without a refresh.
local function resolveTheme()
	local mode = PickMode(locked(), get('SkinTheme', 'auto'), get('Theme', 'dark'), windowsIsLight())
	local light = mode == 'light'
	local ink = light and get('InkLight', '0,0,0') or inkDark
	local accent = accentBase()
	if light and get('AccentLight', '1') ~= '0' then
		accent = Darken(accent, get('AccentLightK', '0.7'))
	end
	set('Mode', mode)
	set('Ink', ink)
	set('InkContrast', light and get('InkContrastLight', '255,255,255') or inkContrastDark)
	set('Warn', light and get('WarnLight', '214,110,0') or warnDark)
	set('Accent', accent)
	local rest, hover = Brightness(get('RestBrightness', '60'), get('HoverBrightness', '98'),
		get('LightBoost', '10'), light)
	set('RestEff', string.format('%g', rest))
	set('HoverEff', string.format('%g', hover))
	set('HoverTint', norm(get('HoverAccent', '1')) == '0' and ink or accent)
end

-- ---------- Needs ----------
-- Each skin checks its own needs (Setup\NeedsList.lua, Scripts\Needs.lua) and
-- sets <Skin>Has<Feature>, <Skin>NeedState and <Skin>NeedBlocked on itself, so
-- the gating in the skin works with the Settings window closed. This is the
-- one place that does it: skin scripts and measures only read the flags.
-- File-exists and registry reads only. Any failure (no list, no entry, an
-- error) leaves the defaults, which mean "present".

local NEED_EVERY = 60
local needs, needList, needName
local needAt = 0

local function loadNeeds()
	needs, needList, needName = nil, nil, nil
	local config = tostring(SKIN:GetVariable('CURRENTCONFIG', ''))
	local name = config:match('([^\\/]+)$')
	if not name or name == '' then return end
	local at = SKIN:ReplaceVariables('#@#')
	local okLib, lib = pcall(dofile, at .. 'Scripts\\Needs.lua')
	local okList, list = pcall(dofile, at .. 'Setup\\NeedsList.lua')
	if okLib and okList and type(lib) == 'table' and type(list) == 'table'
		and type(list[name]) == 'table' then
		needs, needList, needName = lib, list, name
	end
end

-- True when any needs variable changed.
local function resolveNeeds()
	needAt = os.time()
	if not needs then return false end
	local ok, changed = pcall(function()
		local res = needs.evaluate(needName, needList[needName], needs.rainmeterEnv(SKIN))
		local any = false
		needs.apply(res, function(name, value)
			if set(name, value) then any = true end
		end)
		return any
	end)
	return ok and changed
end

function Initialize()
	cache = {}
	loadNeeds()
	resolveNeeds()
	inkDark = get('Ink', '255,255,255')
	inkContrastDark = get('InkContrast', '0,0,0')
	warnDark = get('Warn', '255,170,60')

	local side = PickSide(get('AlignAll', 'skin'), get('SkinSide', 'left'))
	set('Side', side)
	for name, value in pairs(SIDES[side]) do set(name, value) end

	local details = PickDetails(get('DetailsAll', 'skin'), get('SkinDetails', 'hover'))
	local min = details == 'always' and 1 or 0
	set('RevealMin', min)
	set('Reveal', min)

	resolveTheme()
end

function Update()
	resolveTheme()
	if needs and os.time() - needAt >= NEED_EVERY and resolveNeeds() then
		-- A gate flipped (an item was installed or removed): redraw once.
		SKIN:Bang('!UpdateMeter', '*')
		SKIN:Bang('!Redraw')
	end
	return 0
end
