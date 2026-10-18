-- Control-Plaine | Core
-- Resolves the suite's shared layout variables once per skin load (Core.inc
-- runs this as mCore), so skins never branch on their own settings:
--
--   Side Mir TA TAT Lead Trail   left/right arrangement (specs/alignment.md)
--   RevealMin Reveal             details at rest: 0 = hover only, 1 = always
--   HoverTint                    colour of a hovered icon: Accent or Ink
--
-- Input is read from variables the skin sets before it includes Core.inc:
--   SkinSide     left or right   (the skin's <Skin>Align)
--   SkinDetails  hover or always (the skin's <Skin>Details)
-- plus the global AlignAll, DetailsAll and HoverAccent settings.
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

-- ReplaceVariables, so a value like Accent=#AccentColor# comes back resolved.
local function get(name, default)
	return SKIN:ReplaceVariables(SKIN:GetVariable(name, default))
end

local function set(name, value)
	SKIN:Bang('!SetVariable', name, tostring(value))
end

local lastTint

-- Accent can change while running (Core.inc follows Windows), so HoverTint
-- is refreshed on every Update, not only at load.
local function hoverTint()
	local tint
	if norm(get('HoverAccent', '1')) == '0' then
		tint = get('Ink', '255,255,255')
	else
		tint = get('Accent', '0,229,255')
	end
	if tint ~= lastTint then
		lastTint = tint
		set('HoverTint', tint)
	end
end

function Initialize()
	local side = PickSide(get('AlignAll', 'skin'), get('SkinSide', 'left'))
	set('Side', side)
	for name, value in pairs(SIDES[side]) do set(name, value) end

	local details = PickDetails(get('DetailsAll', 'skin'), get('SkinDetails', 'hover'))
	local min = details == 'always' and 1 or 0
	set('RevealMin', min)
	set('Reveal', min)

	lastTint = nil
	hoverTint()
end

function Update()
	hoverTint()
	return 0
end
