-- Control-Plaine | Playnite
-- Checks the one mandatory need of this skin (Setup\NeedsList.lua: the
-- Playnite program at PlaynitePath) and hides the skin while it is missing,
-- with SelfHidden and mVisible. Runs at load and about once a minute (the
-- measure's UpdateDivider); it reads files only and starts nothing.
-- Sets PlayniteNeedState (OK | BLOCKED) and PlayniteNeedBlocked (0 | 1).

local Needs, NEEDS
local lastSig

local function loadNeeds()
	local at = SKIN:GetVariable('@')
	local okLib, lib = pcall(dofile, at .. 'Scripts\\Needs.lua')
	local okList, list = pcall(dofile, at .. 'Setup\\NeedsList.lua')
	if okLib and okList and type(lib) == 'table' and type(list) == 'table' and list.Playnite then
		Needs, NEEDS = lib, list.Playnite
	end
end

function Initialize()
	loadNeeds()
end

function Update()
	if not Needs then return 0 end
	local okEval, res = pcall(Needs.evaluate, 'Playnite', NEEDS, Needs.rainmeterEnv(SKIN))
	if not okEval or type(res) ~= 'table' then return 0 end
	if res.state == lastSig then return 0 end
	lastSig = res.state
	Needs.apply(res, function(name, value) SKIN:Bang('!SetVariable', name, value) end)
	SKIN:Bang('!SetVariable', 'SelfHidden', res.state == 'BLOCKED' and '1' or '0')
	SKIN:Bang('!UpdateMeasure', 'mVisible')
	return res.state == 'BLOCKED' and 0 or 1
end
