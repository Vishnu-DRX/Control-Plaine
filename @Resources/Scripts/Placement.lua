-- Control-Plaine | Placement (pure maths, no Rainmeter calls)
-- Where the first-run setup puts the skins: one column on a screen edge, in a
-- fixed order, at the user's Scale, with fixed gaps. Onboarding.lua loads this
-- with dofile and does the !Move; tools/test_placement.py runs it offline.
--
-- Skin sizes are not readable from another skin at runtime (Rainmeter gives a
-- script only its own skin), so this table holds each skin's size at Scale 1,
-- worked out from the skin files (BoxW, IconBox, ring size, SkinW/SkinH). Icon
-- row skins also take the SizeBoost factor (their Sz = Scale * SizeBoost). Sizes
-- are rounded up, so a small error leaves a slightly larger gap, never an
-- overlap. DayDate, Playnite and SettingsButton have text-wide windows: their
-- widths are estimates.

local P = {}

P.GAP = 16      -- between skins, pixels, not scaled
P.MARGIN = 24   -- from the screen's work area edge, pixels, not scaled

-- Top to bottom. Skins whose window can grow downward come last (Controllers
-- shows one row per controller).
P.ORDER = {
	'DayDate', 'Uptime', 'Power', 'Volume', 'Media', 'RecycleBin', 'WiFi',
	'FanControl', 'DeepCool', 'SignalRGB', 'Playnite', 'SettingsButton', 'Controllers',
}

-- w, h at Scale 1; boost = also multiplied by SizeBoost.
P.SIZES = {
	DayDate = { w = 330, h = 90 },
	Uptime = { w = 200, h = 44 },
	Power = { w = 176, h = 72 },
	Volume = { w = 233, h = 52 },
	Media = { w = 233, h = 52 },
	RecycleBin = { w = 236, h = 56 },
	WiFi = { w = 298, h = 32, boost = true },
	FanControl = { w = 300, h = 32, boost = true },
	DeepCool = { w = 230, h = 32, boost = true },
	SignalRGB = { w = 230, h = 32, boost = true },
	Playnite = { w = 120, h = 33 },
	SettingsButton = { w = 86, h = 32, boost = true },
	Controllers = { w = 230, h = 152, boost = true },
}

-- Pixel size of a skin at the given Scale and SizeBoost.
function P.size(name, scale, boost)
	local s = P.SIZES[name]
	if not s then return nil end
	local k = scale * (s.boost and boost or 1)
	return math.ceil(s.w * k - 1e-9), math.ceil(s.h * k - 1e-9)
end

-- Screens from a getter(name) -> string, the way Rainmeter exposes them:
-- NUMOFMONITORS and SCREENAREAX/Y/WIDTH/HEIGHT@n (work area, taskbar left out),
-- or without @n for the primary screen. Returns { {x,y,w,h}, ... } and the
-- index of the primary screen. Always at least one screen.
function P.screens(get)
	local out = {}
	local n = math.floor(tonumber(get('NUMOFMONITORS')) or 1)
	for i = 1, math.max(1, n) do
		local x, y = tonumber(get('SCREENAREAX@' .. i)), tonumber(get('SCREENAREAY@' .. i))
		local w, h = tonumber(get('SCREENAREAWIDTH@' .. i)), tonumber(get('SCREENAREAHEIGHT@' .. i))
		if x and y and w and h and w > 0 and h > 0 then
			out[#out + 1] = { x = x, y = y, w = w, h = h, index = i }
		end
	end
	local px, py = tonumber(get('SCREENAREAX')), tonumber(get('SCREENAREAY'))
	local pw, ph = tonumber(get('SCREENAREAWIDTH')), tonumber(get('SCREENAREAHEIGHT'))
	local primary = 1
	if px and py and pw and ph then
		local found
		for i, s in ipairs(out) do
			if s.x == px and s.y == py and s.w == pw and s.h == ph then
				found = i
				break
			end
		end
		if found then
			primary = found
		elseif #out == 0 then
			out[1] = { x = px, y = py, w = pw, h = ph, index = 1 }
		end
	end
	if #out == 0 then out[1] = { x = 0, y = 0, w = 1920, h = 1040, index = 1 } end
	return out, primary
end

-- Stack the given skins (names, any order; only known ones are placed) in a
-- column on the left or right edge of area {x,y,w,h}. When the next skin would
-- run below the area, a new column starts further in. Returns a list of
-- { name, x, y, w, h } with x,y the window's top-left corner (pixels on the
-- virtual desktop, what !Move takes).
function P.stack(names, area, edge, scale, boost)
	local want = {}
	for _, n in ipairs(names) do want[n] = true end
	local top = area.y + P.MARGIN
	local bottom = area.y + area.h - P.MARGIN
	local out = {}
	local y = top
	local offset = 0       -- distance of the current column from the edge
	local colW = 0         -- widest skin of the current column
	local count = 0
	for _, name in ipairs(P.ORDER) do
		if want[name] then
			local w, h = P.size(name, scale, boost)
			if count > 0 and y + h > bottom then
				offset = offset + colW + P.GAP
				colW, y, count = 0, top, 0
			end
			local x
			if edge == 'right' then
				x = area.x + area.w - P.MARGIN - offset - w
			else
				x = area.x + P.MARGIN + offset
			end
			-- Too many columns for a narrow or portrait screen: keep the skin on
			-- screen (it may overlap the previous column) and say so.
			local clamped = false
			local lo, hi = area.x + P.MARGIN, area.x + area.w - P.MARGIN - w
			if hi < lo then hi = lo end
			if x > hi then x, clamped = hi, true end
			if x < lo then x, clamped = lo, true end
			out[#out + 1] = { name = name, x = x, y = y, w = w, h = h, clamped = clamped or nil }
			y = y + h + P.GAP
			colW = math.max(colW, w)
			count = count + 1
		end
	end
	return out
end

return P
