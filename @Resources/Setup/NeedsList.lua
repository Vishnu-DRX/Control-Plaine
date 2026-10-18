-- Control-Plaine | what each skin needs (single source).
-- Read by Scripts\Needs.lua (detection, runs nothing), Scripts\Onboarding.lua
-- (first-run steps) and Scripts\Settings.lua (amber marks). tools\lint.py
-- checks it against the skin list, the Defaults files and Helpers.txt.
--
-- One entry per skin folder (plus General). Each entry is a list of needs:
--   id        short name, unique inside the skin
--   label     spaced-capitals text shown in Settings
--   level     'mandatory' (missing: the skin is BLOCKED) or 'optional'
--             (missing: the skin is DEGRADED and the feature is hidden)
--   feature   optional needs only: the skin gates the function on the
--             variable <Skin>Has<feature> (0/1) set from this check
--   check     what to look for, see Needs.lua (file and registry reads only)
--   key       the Settings key the user can change to fix it (a path), if any
--   helper    id in Helpers.txt that can install it, if any
--   why       one line: what is missing or hidden without it
--   when      only counts while {var=<key>, eq=<value>} holds
--   onboard   true: first-run setup shows this item
-- A skin with no needs has an empty list. Detection caveat: Rainmeter's own
-- plugins cannot be found by a file check, so they are 'bundled' (present);
-- things that need a process or the network to check are 'assume'.

local PLUGINS = '%APPDATA%\\Rainmeter\\Plugins\\'

return {
	DayDate = {
		{ id = 'click', label = 'CLICK TARGET', level = 'optional', feature = 'Click',
		  check = { target = 'DayDateClick', builtin = { 'calendar' } }, key = 'DayDateClick',
		  why = 'The click that opens a calendar is off.' },
	},
	Power = {
		{ id = 'schedule', label = 'TASK SCHEDULER', level = 'optional', feature = 'Schedule',
		  check = { file = '%SystemRoot%\\System32\\schtasks.exe' },
		  why = 'SCHEDULE is hidden.' },
	},
	Uptime = {
		{ id = 'click', label = 'CLICK TARGET', level = 'optional', feature = 'Click',
		  check = { target = 'UptimeClick' }, key = 'UptimeClick',
		  why = 'The click that opens Task Manager is off.' },
	},
	Volume = {
		{ id = 'audio', label = 'AUDIO PLUGIN', level = 'mandatory',
		  check = { bundled = true },
		  why = 'Win7AudioPlugin (shipped with Rainmeter) is missing; the skin cannot read the volume.' },
		{ id = 'mixer', label = 'MIXER TARGET', level = 'optional', feature = 'Mixer',
		  check = { target = 'VolumeMixer' }, key = 'VolumeMixer', onboard = true,
		  why = 'The icon click that opens the mixer is off.' },
	},
	Media = {
		{ id = 'player', label = 'MEDIAPLAYER PLUGIN', level = 'mandatory',
		  when = { var = 'MediaPlugin', eq = 'MediaPlayer' },
		  check = { file = PLUGINS .. 'MediaPlayer.dll' }, helper = 'mediaplayer', onboard = true,
		  why = 'MediaPlayer.dll is missing; the skin cannot read what is playing.' },
		{ id = 'wnp', label = 'WEBNOWPLAYING PLUGIN', level = 'mandatory',
		  when = { var = 'MediaPlugin', eq = 'WebNowPlaying' },
		  check = { file = PLUGINS .. 'WebNowPlaying.dll' }, onboard = true,
		  why = 'WebNowPlaying.dll is missing; the skin cannot read what is playing.' },
	},
	RecycleBin = {
		{ id = 'plugin', label = 'RECYCLE BIN PLUGIN', level = 'mandatory',
		  check = { bundled = true },
		  why = 'RecycleManager (shipped with Rainmeter) is missing.' },
		{ id = 'empty', label = 'EMPTY ACTION', level = 'optional', feature = 'Empty',
		  check = { bundled = true },
		  why = 'EMPTY is hidden.' },
	},
	Playnite = {
		{ id = 'app', label = 'PLAYNITE', level = 'mandatory',
		  check = { path = 'PlaynitePath' }, key = 'PlaynitePath', onboard = true,
		  why = 'Playnite was not found at this path; the skin has nothing to open.' },
	},
	WiFi = {
		{ id = 'location', label = 'LOCATION SERVICES', level = 'optional', feature = 'NetName',
		  check = { assume = true },
		  why = 'The network name shows as plain Wi-Fi.' },
		{ id = 'speedtest', label = 'SPEEDTEST CLI', level = 'optional', feature = 'SpeedTest',
		  check = { path = 'WiFiSpeedtestPath', onpath = 'speedtest.exe', fallbacks = {
		      '%LOCALAPPDATA%\\Microsoft\\WinGet\\Links\\speedtest.exe',
		      '%LOCALAPPDATA%\\Microsoft\\WinGet\\Packages\\Ookla.Speedtest.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe\\speedtest.exe',
		      '%LOCALAPPDATA%\\Programs\\Ookla\\speedtest.exe',
		      '%ProgramFiles%\\Ookla\\Speedtest CLI\\speedtest.exe' } },
		  key = 'WiFiSpeedtestPath', helper = 'speedtest', onboard = true,
		  why = 'The speed test icon and row are hidden.' },
	},
	FanControl = {
		{ id = 'app', label = 'FAN CONTROL', level = 'mandatory',
		  check = { path = 'FanControlPath' }, key = 'FanControlPath', onboard = true,
		  why = 'Fan Control was not found at this path; the skin has nothing to control.' },
		{ id = 'tasks', label = 'NO-UAC TASKS', level = 'optional', feature = 'Tasks',
		  when = { var = 'FanControlUseTasks', eq = '1' },
		  check = { file = '%SystemRoot%\\System32\\Tasks\\ControlPlaine\\FanOpen' },
		  helper = 'fan-tasks', onboard = true,
		  why = 'Without the scheduled tasks the MAX switch asks for admin (UAC) every time.' },
		{ id = 'sensors', label = 'SENSOR FEED', level = 'optional', feature = 'Sensors',
		  when = { var = 'FanControlUseTasks', eq = '1' },
		  check = { file = '%SystemRoot%\\System32\\Tasks\\ControlPlaine\\FanSensors' },
		  helper = 'fan-tasks',
		  why = 'The live fan value is hidden; the icon and MAX switch stay.' },
		{ id = 'maxprofile', label = 'MAX PROFILE', level = 'optional', feature = 'Max',
		  check = { beside = 'FanControlPath', rel = 'Configurations\\', var = 'FanControlMax' },
		  key = 'FanControlMax', helper = 'fan-tasks',
		  why = 'The snowflake MAX switch is hidden.' },
	},
	SignalRGB = {
		{ id = 'launcher', label = 'SIGNALRGB', level = 'mandatory',
		  check = { path = 'SignalRGBPath', auto = { reg = 'mRegSignalRGB' } },
		  key = 'SignalRGBPath', onboard = true,
		  why = 'SignalRGB was not found; the skin has nothing to open.' },
		{ id = 'api', label = 'SIGNALRGB PRO API', level = 'optional', feature = 'Api',
		  check = { assume = true },
		  why = 'The brightness read-back is off.' },
		{ id = 'brightness', label = 'BRIGHTNESS EFFECT', level = 'optional', feature = 'Brightness',
		  check = { nonempty = { 'SignalRGBEffect', 'SignalRGBColor' } }, key = 'SignalRGBEffect',
		  why = 'The scroll control and percentage are hidden.' },
		{ id = 'move', label = 'MOVE EFFECT', level = 'optional', feature = 'Move',
		  check = { nonempty = { 'SignalRGBMoveEffect' } }, key = 'SignalRGBMoveEffect',
		  why = 'The double arrow is hidden.' },
	},
	DeepCool = {
		{ id = 'app', label = 'DEEPCOOL', level = 'mandatory',
		  check = { path = 'DeepCoolPath' }, key = 'DeepCoolPath', onboard = true,
		  why = 'The DeepCool app was not found at this path; the skin cannot drive the case screen.' },
		{ id = 'process', label = 'PROCESS CHECK', level = 'optional', feature = 'Bulb',
		  check = { nonempty = { 'DeepCoolProcess' } }, key = 'DeepCoolProcess',
		  why = 'The start/stop bulb is hidden.' },
	},
	Controllers = {
		{ id = 'helper', label = 'POWERSHELL HELPER', level = 'mandatory',
		  check = { file = '#@#Scripts\\Controllers.ps1' },
		  why = 'Scripts\\Controllers.ps1 is missing from the skin folder; reinstall.' },
		{ id = 'dsx', label = 'DUALSENSE APP', level = 'optional', feature = 'Dsx',
		  check = { target = 'ControllersDualSenseApp' }, key = 'ControllersDualSenseApp', onboard = true,
		  why = 'DualSense battery detail and the click are hidden.' },
		{ id = 'wheel', label = 'PIT HOUSE', level = 'optional', feature = 'Wheel',
		  check = { target = 'ControllersWheelApp' }, key = 'ControllersWheelApp', onboard = true,
		  why = 'The wheel click is off.' },
		{ id = 'other', label = 'OTHER CONTROLLERS', level = 'optional', feature = 'Other',
		  check = { target = 'ControllersOther' }, key = 'ControllersOther',
		  why = 'The click on other controllers is off.' },
	},
	SettingsButton = {},
	General = {
		{ id = 'fullscreen', label = 'ISFULLSCREEN PLUGIN', level = 'optional', feature = 'FullScreen',
		  check = { file = PLUGINS .. 'IsFullScreen.dll' }, helper = 'isfullscreen',
		  why = 'HIDE IN FULL SCREEN cannot work.' },
	},
}
