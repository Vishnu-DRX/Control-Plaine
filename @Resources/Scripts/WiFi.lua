-- Control-Plaine | WiFi
-- Picks the taskbar-style state from the network measures, and runs the
-- manual speed test (Ookla speedtest.exe) through mSpeedRun.
-- Update() returns the text for the Name meter (MeasureName=mWiFi), so an
-- SSID with [ or # in it is shown as is, never parsed.

local OUT_NAME = 'ControlPlaine-speedtest.json'
-- Tried in order when WiFiSpeedtestPath is empty or not found.
local FALLBACKS = {
	'%LOCALAPPDATA%\\Microsoft\\WinGet\\Links\\speedtest.exe',
	-- winget only makes the Links entry when it may create symlinks (Developer
	-- Mode); otherwise it adds the package folder to PATH, which Rainmeter
	-- doesn't see until it restarts.
	'%LOCALAPPDATA%\\Microsoft\\WinGet\\Packages\\Ookla.Speedtest.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe\\speedtest.exe',
	'%LOCALAPPDATA%\\Programs\\Ookla\\speedtest.exe',
	'%ProgramFiles%\\Ookla\\Speedtest CLI\\speedtest.exe',
}
local INSTALL_URL = 'https://www.speedtest.net/apps/cli'

local spin              -- loader while a test runs (Spinner.lua)

local m = {}
local shown = {}         -- what the meters show now, to skip needless redraws
local testing = false
local exe, out

-- ---------- helpers ----------

local function expand(path)
	return (path:gsub('%%([%w_%(%)]+)%%', function(v) return os.getenv(v) or ('%' .. v .. '%') end))
end

local function exists(path)
	local f = path ~= '' and io.open(path, 'rb')
	if f then f:close() return true end
	return false
end

local function findExe()
	local set = expand(SKIN:GetVariable('WiFiSpeedtestPath', ''))
	if exists(set) then return set end
	for _, p in ipairs(FALLBACKS) do
		p = expand(p)
		if exists(p) then return p end
	end
end

-- Colour of a text meter: a token name (Ink, Accent, Warn) and an alpha
-- formula. #*Var*# keeps the variables live in the option.
local function color(meter, token, alpha)
	local value = '#*' .. token .. '*#,' .. alpha
	if shown[meter] == value then return end
	shown[meter] = value
	SKIN:Bang('!SetOption', meter, 'FontColor', value)
end

-- The name shows on hover and is hidden while a speed test runs or its result
-- shows (Hold), then comes back as Hold fades.
local NAME_REST = '(#*AlphaHover*#*#*Reveal*#*(1-#*Hold*#))'
local NAME_WARN = '(#*AlphaValue*#+(#*AlphaHover*#-#*AlphaValue*#)*#*Reveal*#)'
-- The name and the speed test icon beside it must fit in the skin's fixed width
-- (LineW, which already holds the longest speed test result): name + 8 gap + 24
-- icon. Width is estimated per letter (the name is shown in capitals, 7.25 pt
-- semibold plus 2.4 tracking; EM is calibrated so "SAVARI GIRI GIRI" comes to the
-- ~122 px it measured at on a real screenshot) so that
-- narrow and wide letters count fairly.
local NAME_BUDGET = 226  -- design px for the name (LineW 262 - 8 - 24, a little spare)
local EM, TRACK = 11.1, 2.4
local function nameWidth(text)
	local w = 0
	for c in text:upper():gmatch('.') do
		local em = 0.62
		if c:find('[I%.,:;\'!|]') then em = 0.28
		elseif c == ' ' then em = 0.27
		elseif c:find('[%d]') then em = 0.55
		elseif c:find('[JLT1]') then em = 0.52
		elseif c:find('[M@%%]') then em = 0.85
		elseif c == 'W' then em = 0.92 end
		w = w + em * EM + TRACK
	end
	return w
end

-- Cut a long name to the budget, with an ellipsis. ASCII only (other scripts
-- are left as WiFiStatus gives them).
local function fitName(text)
	if text:find('[\128-\255]') or nameWidth(text) <= NAME_BUDGET then return text end
	local dots = nameWidth('...')
	for n = #text - 1, 1, -1 do
		if nameWidth(text:sub(1, n)) + dots <= NAME_BUDGET then
			return text:sub(1, n):gsub('%s+$', '') .. '...'
		end
	end
	return text
end

local hold = 0           -- mirrors the Hold variable while it fades

local function setText(meter, text)
	SKIN:Bang('!SetOption', meter, 'Text', text)
	SKIN:Bang('!UpdateMeter', meter)
end

local function setHold(v)
	hold = v
	SKIN:Bang('!SetVariable', 'Hold', tostring(v))
	SKIN:Bang('!UpdateMeterGroup', 'Reveal')
	SKIN:Bang('!Redraw')
end

local function restTip()
	exe = findExe()
	SKIN:Bang('!SetOption', 'Gauge', 'ToolTipText', exe and 'Speed test' or 'Install speedtest')
end

-- ---------- lifecycle ----------

function Initialize()
	for _, name in ipairs({ 'mSSID', 'mQuality', 'mType', 'mState', 'mInternet', 'mAirplane' }) do
		m[name] = SKIN:GetMeasure(name)
	end
	spin = dofile(SKIN:GetVariable('@') .. 'Scripts\\Spinner.lua').new('Spinner', 'mSpin')
	out = (os.getenv('TEMP') or SKIN:GetVariable('CURRENTPATH')) .. '\\' .. OUT_NAME

	local click = SKIN:GetVariable('WiFiClick', 'settings')
	if click == '' or click:lower() == 'settings' then click = 'ms-settings:network-wifi' end
	SKIN:Bang('!SetVariable', 'OpenTarget', click)

	restTip()
end

-- Same order as the taskbar: a live connection wins, then airplane mode.
function Update()
	local kind = m.mType:GetValue()
	local up = m.mState:GetValue() == 1
	local noNet = m.mInternet:GetValue() == -1
	local icon, text, warn

	if up and kind == 6 then
		if noNet then
			icon, text, warn = 'globe-disconnected', 'No internet', true
		else
			icon, text = 'ethernet', 'Ethernet'
		end
	elseif up and kind == 71 then
		if noNet then
			icon, text, warn = 'wifi-no-internet-badge', 'No internet', true
		else
			local q = m.mQuality:GetValue()
			-- Quality 0 with a live link means WiFiStatus can't read it.
			icon = (q >= 67 or q <= 0) and 'wifi' or (q >= 34 and 'wifi-2' or 'wifi-1')
			text = m.mSSID:GetStringValue()
			if text == '' or text == '-1' then text = 'Wi-Fi' end
			text = fitName(text)
		end
	elseif m.mAirplane:GetValue() == 1 then
		icon, text = 'airplane', 'Airplane mode'
	else
		icon, text, warn = 'globe-disconnected', 'Not connected', true
	end

	if shown.icon ~= icon then
		shown.icon = icon
		SKIN:Bang('!SetOption', 'Icon', 'ImageName', '#@#Icons\\' .. icon .. '.png')
		SKIN:Bang('!UpdateMeter', 'Icon')
	end
	color('Name', warn and 'Warn' or 'Ink', warn and NAME_WARN or NAME_REST)
	return text
end

-- ---------- speed test ----------

-- Ookla prints one JSON object per line: testStart, ping, download, upload,
-- result, and log lines (errors). bandwidth is bytes per second.
local function mbps(line, key)
	local b = line:match('"' .. key .. '":{[^}]-"bandwidth":(%d+)')
	return b and math.floor(tonumber(b) * 8 / 1e6 + 0.5)
end

local function readLines()
	local f = io.open(out, 'rb')
	if not f then return {} end
	local lines = {}
	for line in f:read('*a'):gmatch('[^\r\n]+') do
		if line:sub(1, 1) == '{' then lines[#lines + 1] = line end
	end
	f:close()
	return lines
end

function LinkClick()
	if testing then return end
	restTip()
	if not exe then
		SKIN:Bang('["' .. INSTALL_URL .. '"]')
		return
	end
	testing = true
	os.remove(out)
	-- "call" keeps cmd from stripping the quotes around the paths.
	SKIN:Bang('!SetOption', 'mSpeedRun', 'Parameter', 'call "' .. exe ..
		'" --format=json --progress=yes --accept-license --accept-gdpr > "' .. out .. '" 2>&1')
	SKIN:Bang('!UpdateMeasure', 'mSpeedRun')
	SKIN:Bang('!SetVariable', 'Result', '0')
	SKIN:Bang('!SetOption', 'Live', 'FontColor', '#*Accent*#,(#*AlphaHover*#*(1-#*Result*#)*Max(#*Reveal*#,#*Hold*#))')
	setText('Live', '-- Mbps')
	setHold(1)
	spin:start()
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Stop 2')
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Stop 3')
	SKIN:Bang('!CommandMeasure', 'mSpeedRun', 'Run')
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Execute 1')
end

function Poll()
	if not testing then return end
	local lines = readLines()
	for i = #lines, 1, -1 do
		local kind = lines[i]:match('"type":"(%a+)"')
		if kind == 'download' or kind == 'upload' then
			local v = mbps(lines[i], kind)
			if v then
				setText('Live', v .. ' Mbps')
				SKIN:Bang('!Redraw')
			end
			return
		elseif kind == 'ping' or kind == 'testStart' then
			return
		end
	end
end

function Finished()
	if not testing then return end
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Stop 1')
	spin:stop()
	local down, up, ping
	for _, line in ipairs(readLines()) do
		if line:match('"type":"(%a+)"') == 'result' then
			down, up = mbps(line, 'download'), mbps(line, 'upload')
			ping = line:match('"ping":{[^}]-"latency":([%d%.]+)')
		end
	end
	if down and up and ping then
		setText('Live', '')
		setText('Down', tostring(down))
		setText('Up', up .. ' Mbps')
		setText('Ping', 'Ping ' .. math.floor(tonumber(ping) + 0.5) .. ' ms')
		SKIN:Bang('!SetVariable', 'Result', '1')
	else
		SKIN:Bang('!SetOption', 'Live', 'FontColor', '#*Warn*#,(#*AlphaHover*#*Max(#*Reveal*#,#*Hold*#))')
		setText('Live', 'Test failed')
	end
	SKIN:Bang('!UpdateMeterGroup', 'Reveal')
	SKIN:Bang('!Redraw')
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Execute 2')
end

function Spin()
	spin:step()
end

-- After ResultHold: fade the result (and the name that was held) out.
function Clear()
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Stop 3')
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Execute 3')
end

function HoldStep()
	local v = hold - 1 / tonumber(SKIN:GetVariable('FadeSteps', '12'))
	if v > 0.001 then
		setHold(v)
		return
	end
	testing = false
	spin:stop()
	SKIN:Bang('!SetVariable', 'Result', '0')
	setText('Live', '')
	setText('Down', '')
	setText('Up', '')
	setText('Ping', '')
	setHold(0)
	restTip()
end
