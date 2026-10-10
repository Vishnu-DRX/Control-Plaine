-- Control-Plaine | WiFi
-- Picks the taskbar-style state from the network measures, and runs the
-- manual speed test (Ookla speedtest.exe) through mSpeedRun.
-- Update() returns the text for the Name meter (MeasureName=mWiFi), so an
-- SSID with [ or # in it is shown as is, never parsed.

local OUT_NAME = 'ControlPlaine-speedtest.json'
-- Tried in order when WiFiSpeedtestPath is empty or not found.
local FALLBACKS = {
	'%LOCALAPPDATA%\\Microsoft\\WinGet\\Links\\speedtest.exe',
	'%LOCALAPPDATA%\\Programs\\Ookla\\speedtest.exe',
	'%ProgramFiles%\\Ookla\\Speedtest CLI\\speedtest.exe',
}
local INSTALL_URL = 'https://www.speedtest.net/apps/cli'

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

local NAME_REST = '(#*NameAlpha*#+(#*AlphaHover*#-#*NameAlpha*#)*#*Reveal*#)'
local NAME_WARN = '(#*AlphaValue*#+(#*AlphaHover*#-#*AlphaValue*#)*#*Reveal*#)'
local LINK_ALPHA = '(#*AlphaHover*#*Max(#*Reveal*#,#*Testing*#))'

local function setLink(text, token)
	SKIN:Bang('!SetOption', 'Link', 'Text', text)
	color('Link', token or 'Ink', LINK_ALPHA)
	SKIN:Bang('!UpdateMeter', 'Link')
	SKIN:Bang('!UpdateMeter', 'LinkLine')
	SKIN:Bang('!Redraw')
end

local function restLink()
	exe = findExe()
	setLink(exe and 'Speed test' or 'Install speedtest')
end

-- ---------- lifecycle ----------

function Initialize()
	for _, name in ipairs({ 'mSSID', 'mQuality', 'mType', 'mState', 'mInternet', 'mAirplane' }) do
		m[name] = SKIN:GetMeasure(name)
	end
	out = (os.getenv('TEMP') or SKIN:GetVariable('CURRENTPATH')) .. '\\' .. OUT_NAME

	local click = SKIN:GetVariable('WiFiClick', 'settings')
	if click == '' or click:lower() == 'settings' then click = 'ms-settings:network-wifi' end
	SKIN:Bang('!SetVariable', 'OpenTarget', click)

	restLink()
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
	restLink()
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
	SKIN:Bang('!SetVariable', 'Testing', '1')
	setLink('Testing', 'Accent')
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Stop 2')
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
			if v then setLink('Testing  ' .. v .. ' Mbps', 'Accent') end
			return
		elseif kind == 'ping' or kind == 'testStart' then
			return
		end
	end
end

function Finished()
	if not testing then return end
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Stop 1')
	local down, up, ping
	for _, line in ipairs(readLines()) do
		if line:match('"type":"(%a+)"') == 'result' then
			down, up = mbps(line, 'download'), mbps(line, 'upload')
			ping = line:match('"ping":{[^}]-"latency":([%d%.]+)')
		end
	end
	if down and up and ping then
		setLink(string.format('%d / %d Mbps   Ping %d ms', down, up, math.floor(tonumber(ping) + 0.5)))
	else
		setLink('Test failed', 'Warn')
	end
	SKIN:Bang('!CommandMeasure', 'mSpeedTimer', 'Execute 2')
end

function Clear()
	testing = false
	SKIN:Bang('!SetVariable', 'Testing', '0')
	restLink()
end
