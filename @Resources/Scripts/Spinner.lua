-- Control-Plaine | shared loader spinner.
-- A 270 degree arc that turns while something slow runs (a speed test, an
-- app starting). The skin needs a Shape meter and an ActionTimer:
--   [Spinner]
--   Meter=Shape
--   Hidden=1
--   [mSpin]
--   Measure=Plugin
--   Plugin=ActionTimer
--   ActionList1=Repeat Spin,40,100000
--   Spin=[!CommandMeasure <script measure> "Spin()"]
-- and its script does:
--   function Initialize()
--     spin = dofile(SKIN:GetVariable('@') .. 'Scripts\\Spinner.lua').new('Spinner', 'mSpin')
--   end
--   function Spin() spin:step() end
-- then spin:start() / spin:stop().

local Spinner = {}
Spinner.__index = Spinner

-- Size at scale 1 (px): radius and stroke. The meter is 2*(R+W) square.
local R, W, STEP = 5, 1.5, 30

function Spinner.new(meter, timer)
	return setmetatable({ meter = meter, timer = timer, angle = 0, on = false }, Spinner)
end

function Spinner:draw()
	local s = tonumber(SKIN:ParseFormula('(' .. SKIN:GetVariable('Sz', SKIN:GetVariable('Scale', '1')) .. ')')) or 1
	local r, w = R * s, W * s
	local c = r + w
	local a1, a2 = math.rad(self.angle), math.rad(self.angle + 270)
	local shape = string.format(
		'Arc %.2f,%.2f,%.2f,%.2f,%.2f,%.2f,0,0,1 | Fill Color 0,0,0,0 | StrokeWidth %.2f | Stroke Color %s,255 | StrokeStartCap Round | StrokeEndCap Round',
		c + r * math.sin(a1), c - r * math.cos(a1), c + r * math.sin(a2), c - r * math.cos(a2), r, r, w,
		SKIN:GetVariable('Accent'))
	SKIN:Bang('!SetOption', self.meter, 'Shape', shape)
	SKIN:Bang('!UpdateMeter', self.meter)
	SKIN:Bang('!Redraw')
end

function Spinner:start()
	if self.on then return end
	self.on = true
	self.angle = 0
	self:draw()
	SKIN:Bang('!ShowMeter', self.meter)
	SKIN:Bang('!CommandMeasure', self.timer, 'Stop 1')
	SKIN:Bang('!CommandMeasure', self.timer, 'Execute 1')
end

function Spinner:stop()
	if not self.on then return end
	self.on = false
	SKIN:Bang('!CommandMeasure', self.timer, 'Stop 1')
	SKIN:Bang('!HideMeter', self.meter)
	SKIN:Bang('!Redraw')
end

function Spinner:step()
	if not self.on then return end
	self.angle = (self.angle + STEP) % 360
	self:draw()
end

return Spinner
