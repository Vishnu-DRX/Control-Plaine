-- Control-Plaine | Onboarding
-- First-run setup inside the Settings window (Settings\Onboarding.ini, one
-- file; the step is the variable OnbStep). Steps: WELCOME, SKINS, SETUP (what
-- each chosen skin needs), LOOK, PLACEMENT (screen and edge), DONE.
--
-- Detection is Scripts\Needs.lua over Setup\NeedsList.lua: file-exists and
-- registry reads, nothing is run. Settings are written by Settings.lua (the
-- same Set / EditPath / SkinOn the skin pages use); this script only keeps its
-- own progress in State.inc (OnbStep, OnbOnly, OnbPre, OnbSkip, OnbSel,
-- OnbPage, OnbScreen, OnbEdge, OnbPlaced) and SetupDone.
--
-- PLACEMENT: Scripts\Placement.lua does the maths (one column on a screen
-- edge); this script reads the screens, and moves the loaded skins with !Move
-- (the same config names Settings.lua activates). Skins are only moved when the
-- user clicks a screen or an edge, never on entering the step.
--
-- Install helpers come from Setup\Helpers.txt only. Run() starts the one
-- helper of the selected item, after the click on RUN IT FOR ME, with the
-- program and arguments from that file; nothing typed by the user and nothing
-- read from User.inc is ever run. The command is shown in full first.

local SKINS = {
	'DayDate', 'Power', 'Uptime', 'Volume', 'RecycleBin', 'Playnite', 'Media', 'WiFi',
	'FanControl', 'SignalRGB', 'DeepCool', 'Controllers', 'SettingsButton',
}
local NAMES = {
	DayDate = 'DAY-DATE', Power = 'POWER', Uptime = 'UPTIME', Volume = 'VOLUME',
	RecycleBin = 'RECYCLE BIN', Playnite = 'PLAYNITE', Media = 'MEDIA', WiFi = 'WI-FI',
	FanControl = 'FAN CONTROL', SignalRGB = 'SIGNALRGB', DeepCool = 'DEEPCOOL',
	Controllers = 'CONTROLLERS', SettingsButton = 'SETTINGS BUTTON', General = 'GENERAL',
}

-- skip = true: the step exists but is not shown.
local STEPS = {
	{ id = 'welcome', title = 'WELCOME', group = 'OnbWelcome' },
	{ id = 'skins', title = 'SKINS', group = 'OnbSkins' },
	{ id = 'setup', title = 'SETUP', group = 'OnbSetup' },
	{ id = 'look', title = 'LOOK', group = 'OnbLook' },
	{ id = 'place', title = 'PLACEMENT', group = 'OnbPlace' },
	{ id = 'done', title = 'DONE', group = 'OnbDone' },
}
local GROUPS = { 'OnbWelcome', 'OnbSkins', 'OnbSetup', 'OnbLook', 'OnbPlace', 'OnbDone' }
local PER_PAGE = 5

local Needs, NEEDS, HELPERS, Place
local rootPath, statePath, env
local results = {}
local active = {}
local activeSig = ''
local needSig = ''
local running          -- helper id while its command runs
local outcome = {}     -- helper id -> { ok, tail }
local copied           -- helper id whose command was copied
local asking           -- 'Skin:id' while "turn the skin off?" is shown
local rendered = false
local KNOWN = {}
for _, name in ipairs(SKINS) do KNOWN[name] = true end

-- ---------- helpers ----------

local function var(key, default)
	return SKIN:GetVariable(key, default or '')
end

local function save(key, value)
	value = tostring(value)
	SKIN:Bang('!WriteKeyValue', 'Variables', key, value, statePath)
	SKIN:Bang('!SetVariable', key, value)
end

local function redraw()
	SKIN:Bang('!UpdateMeter', '*')
	SKIN:Bang('!Redraw')
end

local function fixMode()
	return var('OnbOnly') ~= ''
end

local function loadLibs()
	local at = SKIN:GetVariable('@')
	local okLib, lib = pcall(dofile, at .. 'Scripts\\Needs.lua')
	local okList, list = pcall(dofile, at .. 'Setup\\NeedsList.lua')
	if okLib and okList and type(lib) == 'table' and type(list) == 'table' then
		Needs, NEEDS = lib, list
	else
		SKIN:Bang('!Log', 'Control-Plaine onboarding: could not load Scripts\\Needs.lua or Setup\\NeedsList.lua', 'Error')
	end
	local okPlace, place = pcall(dofile, at .. 'Scripts\\Placement.lua')
	if okPlace and type(place) == 'table' then
		Place = place
	else
		SKIN:Bang('!Log', 'Control-Plaine onboarding: could not load Scripts\\Placement.lua', 'Error')
	end
	local f = io.open(at .. 'Setup\\Helpers.txt', 'rb')
	if f and Needs then
		HELPERS = Needs.parseHelpers(f:read('*a'))
		f:close()
	else
		HELPERS = { list = {}, byId = {} }
	end
end

-- Loaded skins, asked from Settings.lua (it reads Rainmeter.ini).
local function readActive()
	local text = SKIN:ReplaceVariables('[&mSettings:ActiveList()]')
	local sig = {}
	active = {}
	for name in text:gmatch('%w+') do
		if KNOWN[name] then
			active[name] = true
			sig[#sig + 1] = name
		end
	end
	local s = table.concat(sig, ',')
	local changed = s ~= activeSig
	activeSig = s
	return changed
end

local function detect()
	if not Needs then return false end
	env = env or Needs.rainmeterEnv(SKIN)
	local sig = {}
	results = {}
	for _, name in ipairs(SKINS) do
		results[name] = Needs.evaluate(name, NEEDS[name], env)
		for _, it in ipairs(results[name].items) do
			if not it.ok then sig[#sig + 1] = name .. it.id end
		end
	end
	results.General = Needs.evaluate('General', NEEDS.General, env)
	for _, it in ipairs(results.General.items) do
		if not it.ok then sig[#sig + 1] = 'General' .. it.id end
	end
	local s = table.concat(sig, ',')
	local changed = s ~= needSig
	needSig = s
	return changed
end

local function skipped(it)
	return (',' .. var('OnbSkip') .. ','):find(',' .. it.skin .. ':' .. it.id .. ',', 1, true) ~= nil
end

local function markSkipped(it)
	if skipped(it) then return end
	local list = var('OnbSkip')
	save('OnbSkip', (list ~= '' and list .. ',' or '') .. it.skin .. ':' .. it.id)
end

-- ---------- steps ----------

local function visibleSteps()
	local list = {}
	if fixMode() then
		list[1] = STEPS[3]
		return list
	end
	for _, s in ipairs(STEPS) do
		if not s.skip then list[#list + 1] = s end
	end
	return list
end

local function stepIndex()
	local id = var('OnbStep', 'welcome')
	if fixMode() then id = 'setup' end
	local list = visibleSteps()
	for i, s in ipairs(list) do
		if s.id == id then return i, list end
	end
	return 1, list
end

-- Items of the SETUP step: needs of the loaded skins that setup shows (all
-- the failing ones too when it was opened from a mark for one skin).
local function items()
	local list = {}
	local only = var('OnbOnly')
	local names = SKINS
	if only == 'General' then names = { 'General' } end
	for _, skin in ipairs(names) do
		local r = results[skin]
		if r and ((only == '' and active[skin]) or only == skin) then
			for _, it in ipairs(r.items) do
				if it.onboard or (only ~= '' and not it.ok) then list[#list + 1] = it end
			end
		end
	end
	return list
end

local function selected()
	local list = items()
	local key = var('OnbSel')
	for _, it in ipairs(list) do
		if it.skin .. ':' .. it.id == key then return it, list end
	end
	for _, it in ipairs(list) do
		if not it.ok then return it, list end
	end
	return list[1], list
end

local function pageItems()
	local list = items()
	local pages = math.max(1, math.ceil(#list / PER_PAGE))
	local page = math.max(0, math.min(pages - 1, tonumber(var('OnbPage', '0')) or 0))
	local out = {}
	for i = page * PER_PAGE + 1, math.min(#list, (page + 1) * PER_PAGE) do out[#out + 1] = list[i] end
	return out, pages, page
end

local function status(it)
	if it.ok then return 'FOUND' end
	if skipped(it) then return 'SKIPPED' end
	return 'NOT FOUND'
end

local function levelWord(it)
	return it.level == 'mandatory' and 'Required' or 'Optional'
end

-- ---------- render ----------

local function setColor(meter, color)
	SKIN:Bang('!SetOption', meter, 'FontColor', color)
end

local function render()
	local accent = SKIN:ReplaceVariables('#Accent#') .. ',255'
	local ink = SKIN:ReplaceVariables('#Ink#')
	local warn = SKIN:ReplaceVariables('#Warn#')
	local idx, list = stepIndex()
	local step = list[idx]
	for _, g in ipairs(GROUPS) do SKIN:Bang('!HideMeterGroup', g) end
	SKIN:Bang('!ShowMeterGroup', step.group)

	-- Step list at the left and the bar.
	for i = 1, #STEPS do
		local s = list[i]
		if s then
			SKIN:Bang('!ShowMeter', 'Step' .. i)
			setColor('Step' .. i, i == idx and (ink .. ',255') or (ink .. ',128'))
		else
			SKIN:Bang('!HideMeter', 'Step' .. i)
		end
	end
	SKIN:Bang('!SetOption', 'OnbBar', 'Y', '((#TabY0#+' .. (idx - 1) .. '*#TabStep#)*#PS#)')
	SKIN:Bang('!ShowMeter', 'OnbBar')

	-- Footer buttons.
	if idx == 1 then SKIN:Bang('!HideMeter', 'NavBack') else SKIN:Bang('!ShowMeter', 'NavBack') end
	if fixMode() or step.id == 'done' then SKIN:Bang('!HideMeter', 'NavSkip') else SKIN:Bang('!ShowMeter', 'NavSkip') end
	-- SKIP SETUP sits right after BACK; on the first step (no BACK) it takes BACK's place.
	SKIN:Bang('!SetOption', 'NavSkip', 'X', idx == 1 and '(#ColL#*#PS#)' or '(24*#PS#)R')

	-- Skins step: the note under each name.
	if step.id == 'skins' then
		for _, name in ipairs(SKINS) do
			local r = results[name]
			local bad = r and r.state == 'BLOCKED'
			setColor('Note' .. name, (bad and warn or ink) .. (bad and ',230' or ',140'))
		end
	end

	-- Setup step: rows, paging, details and buttons.
	if step.id == 'setup' then
		local rows, pages = pageItems()
		for i = 1, PER_PAGE do
			local it = rows[i]
			local names = { 'ItemLabel', 'ItemDesc', 'ItemStatus', 'ItemPath', 'ItemBox' }
			for _, n in ipairs(names) do
				local meter = n .. i
				if it and (it.key or (n ~= 'ItemPath' and n ~= 'ItemBox')) then
					SKIN:Bang('!ShowMeter', meter)
				else
					SKIN:Bang('!HideMeter', meter)
				end
			end
			if it then
				setColor('ItemStatus' .. i, it.ok and accent or (warn .. ',255'))
			end
		end
		if pages > 1 then SKIN:Bang('!ShowMeter', 'ItemMore') else SKIN:Bang('!HideMeter', 'ItemMore') end
		local it = selected()
		local h = it and it.helper and HELPERS.byId[it.helper]
		local canFix = it and not it.ok
		local runs = canFix and h and h.program and h.program ~= ''
		for _, n in ipairs({ 'BtnRun', 'BtnCopy' }) do
			if runs and not asking then SKIN:Bang('!ShowMeter', n) else SKIN:Bang('!HideMeter', n) end
		end
		-- SKIP follows COPY COMMAND; with no helper to run it starts the row.
		SKIN:Bang('!SetOption', 'BtnSkip', 'X', runs and '(24*#PS#)R' or '(#ColL#*#PS#)')
		if canFix and not asking and not skipped(it) then
			SKIN:Bang('!ShowMeter', 'BtnSkip')
		else
			SKIN:Bang('!HideMeter', 'BtnSkip')
		end
		for _, n in ipairs({ 'AskText', 'AskYes', 'AskNo' }) do
			if asking then SKIN:Bang('!ShowMeter', n) else SKIN:Bang('!HideMeter', n) end
		end
		if not it then
			for _, n in ipairs({ 'DetTitle', 'DetWhy', 'DetCmd', 'DetSrc', 'DetOut' }) do SKIN:Bang('!HideMeter', n) end
		end
	end
	redraw()
end

-- ---------- lifecycle ----------

function Initialize()
	rootPath = SKIN:GetVariable('ROOTCONFIGPATH')
	statePath = SKIN:GetVariable('@') .. 'State.inc'
	loadLibs()
	readActive()
	detect()
end

-- Every couple of seconds: installing something or toggling a skin shows up.
function Update()
	if not Needs then return 0 end
	if not rootPath then Initialize() end
	local a = readActive()
	local d = detect()
	if a or d or not rendered then
		rendered = true
		render()
	end
	return 0
end

-- ---------- navigation ----------

local function goStep(id)
	asking = nil
	save('OnbStep', id)
	-- Entering SKINS the first time: skins that cannot work (a mandatory need
	-- missing) start off, with the reason shown; the user can switch them on.
	if id == 'skins' and var('OnbPre') ~= '1' then
		save('OnbPre', 1)
		readActive()
		for _, name in ipairs(SKINS) do
			local r = results[name]
			if r and r.state == 'BLOCKED' and active[name] then
				SKIN:Bang('!CommandMeasure', 'mSettings', "SkinOn('" .. name .. "')")
			end
		end
		readActive()
	end
	render()
end

function Next()
	if fixMode() then
		Finish()
		return
	end
	local idx, list = stepIndex()
	if list[idx].id == 'done' then
		Finish()
	elseif list[idx + 1] then
		goStep(list[idx + 1].id)
	end
end

function Back()
	local idx, list = stepIndex()
	if list[idx - 1] then goStep(list[idx - 1].id) end
end

function GoIndex(i)
	local _, list = stepIndex()
	if not fixMode() and list[i] then goStep(list[i].id) end
end

local function close()
	save('OnbStep', 'welcome')
	save('OnbOnly', '')
	save('OnbSel', '')
	save('OnbPage', 0)
	save('OnbPlaced', 0)
	save('OnbScreen', '')
	save('OnbEdge', '')
	SKIN:Bang('!DeactivateConfig')
end

-- FINISH, and SKIP SETUP: both record SetupDone=1. Skipping leaves every
-- setting as it is.
function Finish()
	save('SetupDone', 1)
	save('OnbPre', 0)
	save('OnbSkip', '')
	close()
end

function SkipSetup()
	Finish()
end

-- ---------- setup step ----------

function Select(i)
	local rows = pageItems()
	local it = rows[i]
	if it then
		asking = nil
		save('OnbSel', it.skin .. ':' .. it.id)
		render()
	end
end

-- Click on a path box: the same editor the skin pages use (Settings.lua).
function EditItem(i)
	local it = pageItems()[i]
	if it and it.key then
		SKIN:Bang('!CommandMeasure', 'mSettings',
			string.format("EditPath('%s','%s','ItemPath%d')", it.key, it.skin, i))
	end
end

function More()
	local _, pages, page = pageItems()
	save('OnbPage', (page + 1) % pages)
	render()
end

function Run()
	local it = selected()
	local h = it and not it.ok and it.helper and HELPERS.byId[it.helper]
	if not h or running or not h.program or h.program == '' then return end
	local program, args = Needs.helperCommand(h, rootPath)
	running = h.id
	outcome[h.id] = nil
	copied = nil
	SKIN:Bang('!SetOption', 'mRun', 'Program', program)
	SKIN:Bang('!SetOption', 'mRun', 'Parameter', args)
	SKIN:Bang('!UpdateMeasure', 'mRun')
	SKIN:Bang('!CommandMeasure', 'mRun', 'Run')
	redraw()
end

-- FinishAction of mRun: check once, show the result, never retry.
function RunDone()
	local h = running and HELPERS.byId[running]
	running = nil
	if not h then return end
	local m = SKIN:GetMeasure('mRun')
	local out = m and m:GetStringValue() or ''
	outcome[h.id] = { ok = Needs.verifyHelper(h, env), tail = Needs.tail(out, 3, 90) }
	detect()
	render()
end

-- ---------- placement step ----------

local function screens()
	local list, primary = Place.screens(function(name)
		return SKIN:ReplaceVariables('#' .. name .. '#')
	end)
	return list, primary
end

-- Chosen screen (index into the list) and edge, with their defaults: the
-- primary screen, and the edge the skins already face (AlignAll right, else left).
local function chosenScreen()
	local list, primary = screens()
	local n = tonumber(var('OnbScreen'))
	if n and list[n] then return n, list end
	return primary, list
end

local function chosenEdge()
	local e = var('OnbEdge')
	if e == 'left' or e == 'right' then return e end
	return var('AlignAll') == 'right' and 'right' or 'left'
end

-- True when the last stacking had to pull a skin back onto the screen.
local placeClamped = false

-- Move every loaded skin Placement knows into its place.
local function placeSkins()
	if not Place then return 0 end
	readActive()
	local names = {}
	for _, name in ipairs(SKINS) do
		if active[name] then names[#names + 1] = name end
	end
	local n, list = chosenScreen()
	local scale = tonumber(var('Scale', '1')) or 1
	local boost = tonumber(var('SizeBoost', '1.25')) or 1
	local spots = Place.stack(names, list[n], chosenEdge(), scale, boost)
	local root = SKIN:GetVariable('ROOTCONFIG')
	placeClamped = false
	for _, s in ipairs(spots) do
		if s.clamped then placeClamped = true end
		SKIN:Bang('!Move', tostring(s.x), tostring(s.y), root .. '\\' .. s.name)
	end
	return #spots
end

-- Click on the screen word: next screen, and stack there.
function PlaceScreen()
	if not Place then return end
	local n, list = chosenScreen()
	save('OnbScreen', n % #list + 1)
	save('OnbEdge', chosenEdge())
	save('OnbPlaced', 1)
	placeSkins()
	redraw()
end

function PlaceEdge(edge)
	if not Place or (edge ~= 'left' and edge ~= 'right') then return end
	local n = chosenScreen()
	save('OnbScreen', n)
	save('OnbEdge', edge)
	save('OnbPlaced', 1)
	placeSkins()
	redraw()
end

-- Same as clicking the current edge again: stack once more (after the user
-- dragged things about, or switched a skin on).
function PlaceAgain()
	PlaceEdge(chosenEdge())
end

-- Choice highlight for EDGE (nothing is lit until the user has chosen).
function EdgeAlpha(edge)
	return (var('OnbPlaced') == '1' and chosenEdge() == edge) and 255 or 115
end

function EdgeLine(edge)
	return (var('OnbPlaced') == '1' and chosenEdge() == edge) and 255 or 0
end

function ScreenText()
	if not Place then return '' end
	local n, list = chosenScreen()
	local s = list[n]
	local word = #list > 1 and string.format('SCREEN %d OF %d', n, #list) or 'SCREEN'
	return string.format('%s  %d X %d', word, s.w, s.h)
end

function ScreenNote()
	if not Place then return '' end
	local _, list = chosenScreen()
	return #list > 1 and 'Click to use the next screen. The usable area, without the taskbar.' or 'Your only screen. The usable area, without the taskbar.'
end

function PlaceNote()
	if var('OnbPlaced') ~= '1' then
		return 'Nothing has moved yet. Click a screen or an edge to stack your skins there, or go on to keep them where they are.'
	end
	local count = 0
	for _, name in ipairs(SKINS) do
		if active[name] and Place and Place.SIZES[name] then count = count + 1 end
	end
	local note = string.format('%d SKINS STACKED ON THE %s EDGE. DRAG ANY OF THEM TO FINE-TUNE.', count, chosenEdge():upper())
	if placeClamped then note = note .. ' THE SCREEN IS TOO SMALL FOR ALL OF THEM: SOME OVERLAP.' end
	return note
end

function Copy()
	local it = selected()
	local h = it and it.helper and HELPERS.byId[it.helper]
	if not h then return end
	local _, _, text = Needs.helperCommand(h, rootPath)
	SKIN:Bang('!SetClip', text)
	copied = h.id
	redraw()
end

-- SKIP on an optional item keeps the skin (the function stays hidden); on a
-- mandatory one it asks whether to turn the skin off.
function SkipItem()
	local it = selected()
	if not it or it.ok then return end
	if it.level == 'mandatory' then
		asking = it.skin .. ':' .. it.id
	else
		markSkipped(it)
	end
	render()
end

function Ask(yes)
	local skin = asking and asking:match('^(%w+):')
	local it = selected()
	asking = nil
	if it then markSkipped(it) end
	if yes and skin and active[skin] then
		SKIN:Bang('!CommandMeasure', 'mSettings', "SkinOn('" .. skin .. "')")
		readActive()
	end
	render()
end

-- ---------- text for meters (inline Lua) ----------

function StepText(i)
	local _, list = stepIndex()
	local s = list[i]
	return s and string.format('%d  %s', i, s.title) or ''
end

function Title()
	local idx, list = stepIndex()
	return list[idx].title
end

function Progress()
	if fixMode() then return 'SET UP ' .. (NAMES[var('OnbOnly')] or '') end
	local idx, list = stepIndex()
	return string.format('STEP %d OF %d', idx, #list)
end

function Intro()
	local idx, list = stepIndex()
	local id = list[idx].id
	if id == 'welcome' then
		return 'Control-Plaine is a set of quiet desktop skins. This takes a minute: pick the skins you want, point them at the apps they use, and choose how they look. Nothing here runs a program without your click, and you can skip anything.'
	elseif id == 'skins' then
		return 'Switch off the skins you do not want. A skin that needs an app you do not have starts off, with the reason below its name.'
	elseif id == 'setup' then
		if #items() == 0 then return 'The skins you kept need nothing set up.' end
		return 'What your skins need. Click a row for details. A required item that is missing stops its skin; an optional one only hides a function.'
	elseif id == 'look' then
		return 'Applies to every skin now. Each skin can differ later on its own page.'
	elseif id == 'place' then
		return 'Stack the skins you kept in a column on one edge of a screen. Drag them anywhere afterwards.'
	elseif id == 'done' then
		return 'Setup is saved. Change anything later in Settings.'
	end
	return ''
end

function Facts()
	local rows = {}
	local os = SKIN:GetMeasure('mOS')
	rows[#rows + 1] = 'WINDOWS  ' .. (os and os:GetStringValue() or '')
	local list = Place and Place.screens(function(name)
		return SKIN:ReplaceVariables('#' .. name .. '#')
	end)
	local screens = (list and #list > 1) and (#list .. ' DISPLAYS, ') or ''
	rows[#rows + 1] = 'DISPLAYS  ' .. screens .. 'MAIN ' .. SKIN:ReplaceVariables('#SCREENAREAWIDTH#') ..
		' X ' .. SKIN:ReplaceVariables('#SCREENAREAHEIGHT#')
	local found, total = 0, 0
	for _, skin in ipairs(SKINS) do
		local r = results[skin]
		if r then
			for _, it in ipairs(r.items) do
				if it.onboard then
					total = total + 1
					if it.ok then found = found + 1 end
				end
			end
		end
	end
	rows[#rows + 1] = string.format('FOUND  %d OF %d APPS AND PLUGINS THE SKINS USE', found, total)
	return table.concat(rows, '\n')
end

-- SKINS step: one line under each skin name.
function Note(name)
	local r = results[name]
	if not r then return '' end
	if #r.blockers > 0 then
		return 'Needs ' .. r.blockers[1].label:lower() .. '.'
	end
	if #r.limits > 0 then
		return 'Ready. ' .. #r.limits .. (#r.limits == 1 and ' extra' or ' extras') .. ' missing.'
	end
	return 'Ready.'
end

function ItemLabel(i)
	local it = pageItems()[i]
	return it and (NAMES[it.skin] .. ' / ' .. it.label) or ''
end

function ItemDesc(i)
	local it = pageItems()[i]
	if not it then return '' end
	return levelWord(it) .. '. ' .. it.why
end

function ItemStatus(i)
	local it = pageItems()[i]
	return it and status(it) or ''
end

function ItemPath(i)
	local it = pageItems()[i]
	if not it or not it.key then return '' end
	local v = var(it.key)
	return v ~= '' and v or 'NOT SET'
end

function ItemKey(i)
	local it = pageItems()[i]
	return it and it.key or ''
end

function ItemSkin(i)
	local it = pageItems()[i]
	return it and it.skin or ''
end

function DetTitle()
	local it = selected()
	if not it then return '' end
	return it.label .. '  ' .. string.upper(levelWord(it)) .. '  ' .. status(it)
end

function DetWhy()
	local it = selected()
	if not it then return '' end
	local h = it.helper and HELPERS.byId[it.helper]
	local text = it.why
	if h and h.reason then text = text .. ' ' .. h.reason end
	if it.ok then return text end
	if it.level == 'mandatory' then
		return text .. ' Skipping turns the skin off.'
	end
	return text .. ' Skipping keeps the skin and leaves that out.'
end

function DetCmd()
	local it = selected()
	if not it then return '' end
	local h = it.helper and HELPERS.byId[it.helper]
	if not h or not h.program or h.program == '' then
		if it.ok then return '' end
		return it.key and 'Click the path above to set it, or install the app and it is found here.' or
			'Install it, then it is found here.'
	end
	local _, _, text = Needs.helperCommand(h, rootPath)
	return 'COMMAND  ' .. text
end

function DetSrc()
	local it = selected()
	if not it then return '' end
	local h = it.helper and HELPERS.byId[it.helper]
	if not h then return '' end
	local text = 'SOURCE  ' .. (h.source or '')
	if h.elevated == '1' then text = text .. '  Windows will ask for admin permission (UAC).' end
	if h.restart == '1' then text = text .. '  Restart Rainmeter afterwards.' end
	return text
end

function DetOut()
	local it = selected()
	local h = it and it.helper and HELPERS.byId[it.helper]
	if not h then return '' end
	if running == h.id then return 'RUNNING. WAIT FOR IT TO FINISH.' end
	if copied == h.id then return 'COPIED. RUN IT YOURSELF, THEN THIS ROW UPDATES BY ITSELF.' end
	local o = outcome[h.id]
	if not o then return '' end
	if o.ok then return 'DONE. FOUND.' end
	return 'NOT FOUND AFTER THE RUN. ' .. o.tail .. '\nCOPY THE COMMAND AND RUN IT YOURSELF.'
end

function AskText()
	if not asking then return '' end
	local skin = asking:match('^(%w+):')
	return 'TURN ' .. (NAMES[skin] or '') .. ' OFF?'
end

function RunLabel()
	return running and 'RUNNING' or 'RUN IT FOR ME'
end

function NextLabel()
	if fixMode() then return 'DONE' end
	local idx, list = stepIndex()
	return list[idx].id == 'done' and 'FINISH' or 'NEXT'
end

function SkipLabel()
	return 'SKIP SETUP'
end

function Summary()
	local rows = {}
	local on, attention = {}, {}
	for _, name in ipairs(SKINS) do
		if active[name] then
			on[#on + 1] = NAMES[name]
			local r = results[name]
			if r and r.state ~= 'OK' then
				local labels = {}
				for _, it in ipairs(r.state == 'BLOCKED' and r.blockers or r.limits) do labels[#labels + 1] = it.label end
				attention[#attention + 1] = string.format('%s  %s  %s', NAMES[name],
					r.state == 'BLOCKED' and 'SETUP NEEDED' or 'SOME FEATURES OFF', table.concat(labels, ', '))
			end
		end
	end
	rows[#rows + 1] = 'SKINS ON  ' .. (#on > 0 and table.concat(on, ', ') or 'NONE')
	if #attention == 0 then
		rows[#rows + 1] = 'ALL SKINS ARE READY'
	else
		rows[#rows + 1] = 'NEEDS ATTENTION (AN AMBER ! SHOWS IN SETTINGS)'
		for _, a in ipairs(attention) do rows[#rows + 1] = '    ' .. a end
	end
	local function pick(key)
		return (var(key, ''):upper())
	end
	rows[#rows + 1] = string.format('LOOK  SIZE %d%%  COLOURS %s  EDGE %s  DETAILS %s  TOOLTIPS %s',
		math.floor((tonumber(var('Scale', '1')) or 1) * 100 + 0.5), pick('Theme'), pick('AlignAll'),
		pick('DetailsAll'), pick('TooltipsAll'))
	if var('OnbPlaced') == '1' then
		rows[#rows + 1] = string.format('PLACEMENT  %s EDGE OF SCREEN %d', chosenEdge():upper(), (chosenScreen()))
	end
	rows[#rows + 1] = 'SAVED IN  @Resources\\User.inc'
	rows[#rows + 1] = 'HELP  docs\\guide\\first-time-setup.md  AND  docs\\guide\\troubleshooting.md'
	return table.concat(rows, '\n')
end
