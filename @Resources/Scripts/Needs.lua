-- Control-Plaine | Needs
-- Detection library for @Resources\Setup\NeedsList.lua. It is loaded with
-- dofile() by Settings.lua and Onboarding.lua (and, later, by a skin's own
-- script that gates a function on <Skin>Has<Feature>), and by the offline
-- tests in tools\test_onboarding.py.
--
-- It RUNS NOTHING and WRITES NOTHING: a check is a file-exists read
-- (io.open), a Rainmeter Registry measure that the host skin already has, or
-- a read of a variable. No process, no network. All outside access goes
-- through the env table, so the tests can fake files and the registry.
--
--   env.getenv(name)   Windows environment variable or nil
--   env.exists(path)   true when the file can be opened
--   env.var(key)       value of a skin variable, '' when unset
--   env.replace(text)  Rainmeter variable replacement (#@#, #Key#)
--   env.reg(measure)   string value of a Registry measure, '' when absent
--
-- Result of evaluate(): { skin, state = OK | DEGRADED | BLOCKED, items,
-- features = { Name = 0|1 }, blockers = {items}, limits = {items} }.
-- State: BLOCKED when a mandatory need fails, else DEGRADED when an optional
-- need fails, else OK. apply() hands the numbers to !SetVariable.

local M = {}

local function trim(s)
	return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function lower(s)
	return tostring(s or ''):lower()
end

-- #Var# first, then %ENV%.
function M.expand(path, env)
	path = env.replace and env.replace(path) or path
	return (path:gsub('%%([%w_%(%)]+)%%', function(v)
		return env.getenv(v) or ('%' .. v .. '%')
	end))
end

-- A link such as ms-settings:bluetooth or steam://run/1 (a scheme of two or
-- more characters, so a drive letter is not one).
function M.isUri(v)
	return v:match('^[%a][%w%+%.%-][%w%+%.%-]*:') ~= nil
end

-- name found in one of the PATH folders.
function M.onPath(name, env)
	local path = env.getenv('PATH') or ''
	for entry in path:gmatch('[^;]+') do
		local dir = trim(entry):gsub('^"(.*)"$', '%1')
		if dir ~= '' and not M.isUnc(dir) then
			local sep = dir:sub(-1) == '\\' and '' or '\\'
			if env.exists(dir .. sep .. name) then return true end
		end
	end
	return false
end

-- A network path (\\server\share) is not probed: io.open on a server that is
-- off or slow blocks Rainmeter's main thread for many seconds on every check.
-- Such a path counts as present.
function M.isUnc(path)
	return path:sub(1, 2) == '\\\\'
end

local function exists(path, env)
	local p = M.expand(path, env)
	if M.isUnc(p) then return true end
	return env.exists(p)
end

local checks = {}

function checks.bundled() return true end
function checks.assume() return true end

function checks.file(c, env)
	return exists(c.file, env)
end

function checks.any(c, env)
	for _, sub in ipairs(c.any) do
		if M.check(sub, env) then return true end
	end
	return false
end

function checks.all(c, env)
	for _, sub in ipairs(c.all) do
		if not M.check(sub, env) then return false end
	end
	return true
end

-- A Registry measure of the host skin returned something.
function checks.reg(c, env)
	return trim(env.reg(c.reg)) ~= ''
end

-- All the named variables hold something.
function checks.nonempty(c, env)
	for _, key in ipairs(c.nonempty) do
		if trim(env.var(key)) == '' then return false end
	end
	return true
end

-- A program path kept in a setting: the value (or 'auto' -> c.auto), then the
-- usual places (c.fallbacks), then a folder on PATH (c.onpath). A link counts.
function checks.path(c, env)
	local v = trim(env.var(c.path))
	if c.auto and lower(v) == 'auto' then return M.check(c.auto, env) end
	if v ~= '' then
		if M.isUri(v) or exists(v, env) then return true end
	end
	for _, p in ipairs(c.fallbacks or {}) do
		if exists(p, env) then return true end
	end
	if c.onpath and M.onPath(c.onpath, env) then return true end
	return false
end

-- A click target: empty or a built-in word is fine, a link is fine, a path
-- must exist, a bare program name must be on PATH.
function checks.target(c, env)
	local v = trim(env.var(c.target))
	if v == '' then return true end
	for _, word in ipairs(c.builtin or {}) do
		if lower(v) == lower(word) then return true end
	end
	if M.isUri(v) then return true end
	local quoted = v:match('^"([^"]+)"')
	if quoted then return exists(quoted, env) end
	if v:find('[\\/]') then return exists(v, env) end
	return M.onPath(v:match('^%S+'), env)
end

-- A file next to the program named by another setting, e.g. the Fan Control
-- profile in <program folder>\Configurations.
function checks.beside(c, env)
	local base = M.expand(trim(env.var(c.beside)), env)
	local dir = base:match('^(.*)[\\/][^\\/]*$')
	local name = trim(env.var(c.var))
	if not dir or name == '' then return false end
	local full = dir .. '\\' .. (c.rel or '') .. name
	if M.isUnc(full) then return true end
	return env.exists(full)
end

function M.check(c, env)
	if type(c) ~= 'table' then return false end
	for kind, fn in pairs(checks) do
		if c[kind] ~= nil then return fn(c, env) and true or false end
	end
	return false
end

-- A need with a `when` only counts while that variable has that value.
local function applies(when, env)
	if not when then return true end
	return lower(trim(env.var(when.var))) == lower(when.eq)
end

function M.evaluate(skin, needs, env)
	local res = { skin = skin, state = 'OK', items = {}, features = {}, blockers = {}, limits = {} }
	for _, n in ipairs(needs or {}) do
		if n.feature then res.features[n.feature] = 1 end
	end
	for _, n in ipairs(needs or {}) do
		if applies(n.when, env) then
			local ok = M.check(n.check, env)
			local item = {
				skin = skin, id = n.id, label = n.label, level = n.level, ok = ok,
				feature = n.feature, key = n.key, helper = n.helper, why = n.why,
				onboard = n.onboard,
			}
			res.items[#res.items + 1] = item
			if not ok then
				if n.feature then res.features[n.feature] = 0 end
				if n.level == 'mandatory' then
					res.blockers[#res.blockers + 1] = item
					res.state = 'BLOCKED'
				else
					res.limits[#res.limits + 1] = item
					if res.state ~= 'BLOCKED' then res.state = 'DEGRADED' end
				end
			end
		end
	end
	return res
end

function M.evaluateAll(list, skins, env)
	local out = {}
	for _, skin in ipairs(skins) do
		out[skin] = M.evaluate(skin, list[skin], env)
	end
	return out
end

-- Hand the result to a setter (SKIN:Bang('!SetVariable', name, value)):
-- <Skin>Has<Feature> = 0|1, <Skin>NeedState = OK|DEGRADED|BLOCKED and
-- <Skin>NeedBlocked = 0|1 (1 when a skin should hide itself).
function M.apply(res, setVar)
	for feature, value in pairs(res.features) do
		setVar(res.skin .. 'Has' .. feature, tostring(value))
	end
	setVar(res.skin .. 'NeedState', res.state)
	setVar(res.skin .. 'NeedBlocked', res.state == 'BLOCKED' and '1' or '0')
end

-- One-line text for tooltips and banners.
function M.reason(res)
	local parts = {}
	for _, it in ipairs(res.blockers) do parts[#parts + 1] = it.label .. ': ' .. it.why end
	for _, it in ipairs(res.limits) do parts[#parts + 1] = it.label .. ': ' .. it.why end
	return table.concat(parts, '  ')
end

-- ---------- install helpers (Setup\Helpers.txt) ----------

-- Parse the allow-list: { list = {h, ...}, byId = {id = h} }. A helper has
-- id, label, reason, required_for, optional_for, program, args, elevated,
-- source, restart, installer (strings) and verify (list of strings).
function M.parseHelpers(text)
	local out = { list = {}, byId = {} }
	local cur
	for raw in (text .. '\n'):gmatch('([^\n]*)\n') do
		local line = raw:gsub('\r', '')
		if not line:match('^%s*;') and not line:match('^%s*$') then
			local id = line:match('^%[([%w%-_]+)%]%s*$')
			if id then
				cur = { id = id, verify = {} }
				out.list[#out.list + 1] = cur
				out.byId[id] = cur
			elseif cur then
				local k, v = line:match('^([%w_]+)=(.*)$')
				if k == 'verify' then
					cur.verify[#cur.verify + 1] = v
				elseif k then
					cur[k] = v
				end
			end
		end
	end
	return out
end

-- program, args and the text shown to the user. root is the Control-Plaine
-- folder; {ROOT} is the only thing substituted, never user text.
function M.helperCommand(h, root)
	if root:sub(-1) ~= '\\' then root = root .. '\\' end
	local args = (h.args or ''):gsub('{ROOT}', function() return root end)
	return h.program, args, h.program .. ' ' .. args
end

-- Any verify entry satisfied: file:<path> or path:<name>.
function M.verifyHelper(h, env)
	for _, v in ipairs(h.verify) do
		local kind, value = v:match('^(%w+):(.*)$')
		if kind == 'file' and exists(value, env) then return true end
		if kind == 'path' and M.onPath(value, env) then return true end
	end
	return false
end

-- Last few non-empty lines of a command's output, for a failure message.
function M.tail(text, lines, width)
	local keep = {}
	for raw in (tostring(text or '') .. '\n'):gmatch('([^\n]*)\n') do
		local line = raw:gsub('\r', ''):gsub('^%s+', ''):gsub('%s+$', '')
		if line ~= '' then keep[#keep + 1] = line:sub(1, width or 90) end
	end
	local first = math.max(1, #keep - (lines or 3) + 1)
	local out = {}
	for i = first, #keep do out[#out + 1] = keep[i] end
	return table.concat(out, '\n')
end

-- The real environment, inside Rainmeter. skin is the SKIN object.
function M.rainmeterEnv(skin)
	return {
		getenv = os.getenv,
		exists = function(path)
			local f = path ~= '' and io.open(path, 'rb')
			if f then f:close() return true end
			return false
		end,
		var = function(key)
			local v = trim(skin:ReplaceVariables('#' .. key .. '#'))
			return v == '#' .. key .. '#' and '' or v
		end,
		replace = function(text) return skin:ReplaceVariables(text) end,
		reg = function(measure)
			local m = skin:GetMeasure(measure)
			return m and m:GetStringValue() or ''
		end,
	}
end

return M
