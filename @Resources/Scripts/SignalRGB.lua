-- Control-Plaine | SignalRGB
-- Reads lighting state from SignalRGB's local API and sends brightness and
-- on/off changes with curl. The API is SignalRGB Pro only: anything that is not
-- a lighting state (403 "Missing Permission", an error, no answer) drops the
-- skin to free mode, and it keeps checking so it recovers on its own.
--
-- Free mode (no Pro): the application URL signalrgb://effect/apply/<effect>
-- is open to everyone. Solid Color takes a color, so brightness is the color
-- scaled toward black and 0 is black. The skin remembers what it sent (the
-- free tier cannot be read back). SignalRGBEffect= (empty) means launcher only.

local api = false          -- true while the API answers with a lighting state
local effectMode = false   -- free mode drives an effect with URLs
local mode = 'solid'       -- free mode: solid (SignalRGBEffect) or move (SignalRGBMoveEffect)
local enabled = false
local bright = 0           -- 0 to 100
local lastBright = 50      -- brightness to come back to after OFF
local holdUntil = 0        -- ignore reads until then (a change is in flight)
local misses = 0
local sentBright, sentEnabled
local step, port, apiAllowed, effect, moveEffect

local function setVar(name, value)
	SKIN:Bang('!SetVariable', name, tostring(value))
end

local function scale()
	return tonumber(SKIN:ParseFormula('(' .. SKIN:GetVariable('Scale', '1') .. ')')) or 1
end

-- Ring, scroll and brightness text are live with the API or in free mode.
local function active()
	return api or effectMode
end

local function show()
	setVar('ApiMode', active() and 1 or 0)
	-- Accent while the lights are on; in free mode only while the move effect runs.
	local lit = active() and enabled and bright > 0
	if effectMode and not api then lit = lit and mode == 'move' end
	setVar('IconTint', lit and SKIN:GetVariable('Accent') or SKIN:GetVariable('Ink'))
	local name = SKIN:GetVariable('SignalRGBLabel', 'Case lights')
	if not active() then
		setVar('BrightText', 'SignalRGB')
	else
		setVar('BrightText', name .. ' ' .. ((enabled and bright > 0) and (bright .. '%') or 'OFF'))
	end
	setVar('MoveOn', moveEffect ~= '' and 1 or 0)
	SKIN:Bang('!UpdateMeter', '*')
	SKIN:Bang('!Redraw')
end

function Initialize()
	step = tonumber(SKIN:GetVariable('SignalRGBStep', '5')) or 5
	port = SKIN:GetVariable('SignalRGBPort', '16038')
	apiAllowed = SKIN:GetVariable('SignalRGBApi', 'auto') ~= '0'
	if not apiAllowed then
		SKIN:Bang('!DisableMeasure', 'mApi')
	end
	effect = SKIN:GetVariable('SignalRGBEffect', 'Solid Color')
	moveEffect = SKIN:GetVariable('SignalRGBMoveEffect', '')
	effectMode = effect ~= ''
	if moveEffect ~= '' and SKIN:GetVariable('SignalRGBMode', 'solid') == 'move' then mode = 'move' end
	if effectMode then
		bright = math.max(0, math.min(100, tonumber(SKIN:GetVariable('SignalRGBBright', '100')) or 100))
		enabled = bright > 0
		if bright > 0 then lastBright = bright end
	end
	show()
end

function Update()
	-- The accent can change while running (Core.inc follows Windows).
	if active() then show() end
	return active() and (enabled and bright or 0) or -1
end

-- Without Pro the answer never changes, so check less often.
local function setPoll(seconds)
	SKIN:Bang('!SetOption', 'mApi', 'UpdateRate', tostring(seconds))
end

function Parsed()
	local text = SKIN:GetMeasure('mApiText'):GetStringValue() or ''
	local b = text:match('"global_brightness"%s*:%s*(%d+)')
	local e = text:match('"enabled"%s*:%s*(%a+)')
	if not b then
		Offline()
		return
	end
	if not api then setPoll(2) end
	api, misses = true, 0
	if os.time() < holdUntil then return end
	bright = math.max(0, math.min(100, tonumber(b)))
	enabled = (e == 'true')
	if bright > 0 then lastBright = bright end
	show()
end

function Offline()
	misses = misses + 1
	if api then
		api = false
		show()
	end
	if misses == 15 then setPoll(30) end
end

function Scroll(dir)
	if not active() then return end
	if not enabled or bright == 0 then
		if dir < 0 then return end
		enabled = true
		bright = step
	else
		bright = bright + dir * step
		if bright <= 0 then
			bright = 0
			enabled = false
		end
	end
	bright = math.min(100, bright)
	if bright > 0 then lastBright = bright end
	holdUntil = os.time() + 3
	show()
	SKIN:Bang('!CommandMeasure', 'mDebounce', 'Stop 1')
	SKIN:Bang('!CommandMeasure', 'mDebounce', 'Execute 1')
end

local function patch(path, body)
	-- curl.exe parses its command line the C way: \" is a literal quote, and
	-- the body has no spaces, so it needs no outer quotes.
	local escaped = body:gsub('"', '\\"')
	return '-s -m 3 -X PATCH -H Content-Type:application/json -d ' .. escaped .. ' http://localhost:' .. port .. '/api/v1/lighting/' .. path
end

-- Opens signalrgb://effect/apply/<name>?<params> and hides SignalRGB's window
-- again (SignalRGBApply.ps1). Spaces and the like in the name are %-escaped.
local function apply(name, params)
	local escaped = name:gsub('[^%w]', function(c) return string.format('%%%02X', c:byte()) end)
	local url = 'signalrgb://effect/apply/' .. escaped
	if params and params ~= '' then url = url .. '?' .. params end
	local script = SKIN:GetVariable('@') .. 'Scripts\\SignalRGBApply.ps1'
	SKIN:Bang('!SetOption', 'mApply', 'Parameter',
		'-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' .. script .. '" -Url "' .. url .. '"')
	SKIN:Bang('!UpdateMeasure', 'mApply')
	SKIN:Bang('!CommandMeasure', 'mApply', 'Run')
end

-- "RRGGBB" scaled by k (0 to 1), same format.
local function scaled(hex, k)
	local out = ''
	for i = 1, 5, 2 do
		local v = tonumber(hex:sub(i, i + 1), 16)
		out = out .. string.format('%02X', math.floor(v * k + 0.5))
	end
	return out
end

-- Free mode: apply the current effect (solid, or the move effect when it was
-- chosen) with its color scaled to the brightness, so scrolling never changes
-- which effect runs.
local function sendEffect()
	local k = (enabled and bright > 0) and bright / 100 or 0
	local state = SKIN:GetVariable('@') .. 'State.inc'
	SKIN:Bang('!WriteKeyValue', 'Variables', 'SignalRGBBright', tostring(enabled and bright or 0), state)
	SKIN:Bang('!WriteKeyValue', 'Variables', 'SignalRGBMode', mode, state)
	if mode == 'move' and moveEffect ~= '' then
		local params = SKIN:GetVariable('SignalRGBMoveParams', '')
		local base = params:match('color1=%%23(%x%x%x%x%x%x)')
		if base then
			params = params:gsub('color1=%%23%x%x%x%x%x%x', function() return 'color1=%23' .. scaled(base, k) end)
		else
			local hex = SKIN:GetVariable('SignalRGBColor', '00BBFF'):gsub('^#', '')
			if not hex:match('^%x%x%x%x%x%x$') then hex = '00BBFF' end
			params = (params ~= '' and (params .. '&') or '') .. 'color1=%23' .. scaled(hex, k)
		end
		apply(moveEffect, params)
		return
	end
	local hex = SKIN:GetVariable('SignalRGBColor', '00BBFF'):gsub('^#', '')
	if not hex:match('^%x%x%x%x%x%x$') then hex = '00BBFF' end
	apply(effect, 'color=%23' .. scaled(hex, k) .. '&breathe=false')
end

function Send()
	if not api and effectMode then
		sendEffect()
		return
	end
	local parts = {}
	if enabled and bright > 0 and bright ~= sentBright then
		parts[#parts + 1] = patch('global_brightness', '{"global_brightness":' .. bright .. '}')
		sentBright = bright
	end
	local on = enabled and bright > 0
	if on ~= sentEnabled then
		parts[#parts + 1] = patch('enabled', '{"enabled":' .. tostring(on) .. '}')
		sentEnabled = on
	end
	if #parts == 0 then return end
	SKIN:Bang('!SetOption', 'mSend', 'Parameter', table.concat(parts, ' --next '))
	SKIN:Bang('!UpdateMeasure', 'mSend')
	SKIN:Bang('!CommandMeasure', 'mSend', 'Run')
	holdUntil = os.time() + 3
end

-- Click: SignalRGBPath, or with auto the launcher from the signalrgb:// registration.
function Open()
	local target = SKIN:GetVariable('SignalRGBPath', 'auto')
	if target == '' or target:lower() == 'auto' then
		local cmd = SKIN:GetMeasure('mProtocol'):GetStringValue() or ''
		target = cmd:match('^"([^"]+)"') or cmd:match('^(%S+)') or ''
	end
	if target == '' then return end
	if target:lower():match('%.exe$') then
		SKIN:Bang('!SetOption', 'mOpen', 'Program', target)
		SKIN:Bang('!UpdateMeasure', 'mOpen')
		SKIN:Bang('!CommandMeasure', 'mOpen', 'Run')
	else
		SKIN:Bang('"' .. target .. '"')
	end
end

-- The double arrow: switch between the solid color and the move effect
-- (SignalRGBMoveEffect / SignalRGBMoveParams). Lights come on if they were off.
function Move()
	if moveEffect == '' then return end
	if api or not effectMode then
		apply(moveEffect, SKIN:GetVariable('SignalRGBMoveParams', ''))
		return
	end
	mode = (mode == 'move') and 'solid' or 'move'
	if not enabled or bright == 0 then
		enabled = true
		bright = lastBright
	end
	show()
	sendEffect()
end
