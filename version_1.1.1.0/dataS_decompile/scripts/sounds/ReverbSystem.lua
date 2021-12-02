ReverbSystem = {}
local ReverbSystem_mt = Class(ReverbSystem)

function ReverbSystem.getName(index)
	for name, id in pairs(Reverb) do
		if id == index then
			return name
		end
	end

	return nil
end

function ReverbSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or ReverbSystem_mt)
	self.mission = mission
	self.isDebugViewActive = false
	self.AREA_TYPE_TO_REVERB_TYPE = {
		[AreaType.OPEN_FIELD] = Reverb.GS_OPEN_FIELD,
		[AreaType.HALL] = Reverb.GS_INDOOR_HALL,
		[AreaType.CITY] = Reverb.GS_CITY,
		[AreaType.FOREST] = Reverb.GS_FOREST
	}
	self.blendFactor = 0
	self.reverbType1 = Reverb.GS_OPEN_FIELD
	self.reverbType2 = Reverb.GS_OPEN_FIELD

	addConsoleCommand("gsReverbSystemToggleDebugView", "Toggles the reverb debug view", "consoleCommandToggleDebugView", self)

	return self
end

function ReverbSystem:delete()
	self.mission:removeDrawable(self)
	removeConsoleCommand("gsReverbSystemToggleDebugView")

	self.mission = nil
end

function ReverbSystem:update(dt)
	local areaWeights = self.mission.environmentAreaSystem:getAreaWeights()
	local reverbType1, reverbType2 = nil
	local reverbType1Weight = 0
	local reverbType2Weight = 0

	for areaTypeIndex, weight in pairs(areaWeights) do
		local reverbTypeIndex = self.AREA_TYPE_TO_REVERB_TYPE[areaTypeIndex]

		if reverbTypeIndex ~= nil then
			if reverbType1 == nil then
				reverbType1 = reverbTypeIndex
				reverbType1Weight = weight
			elseif reverbType2 == nil or reverbType2Weight < weight then
				reverbType2 = reverbTypeIndex
				reverbType2Weight = weight
			end

			if reverbType1 ~= nil and reverbType2 ~= nil and reverbType1Weight < reverbType2Weight then
				reverbType1Weight = reverbType2Weight
				reverbType2Weight = reverbType1Weight
				reverbType1 = reverbType2
				reverbType2 = reverbType1
			end
		end
	end

	reverbType1 = reverbType1 or Reverb.GS_OPEN_FIELD
	reverbType2 = reverbType2 or Reverb.GS_OPEN_FIELD

	if reverbType2 < reverbType1 then
		reverbType1Weight = reverbType2Weight
		reverbType2Weight = reverbType1Weight
		reverbType1 = reverbType2
		reverbType2 = reverbType1
	end

	local sum = reverbType1Weight + reverbType2Weight
	local blendFactor = 0

	if sum > 0 then
		blendFactor = reverbType1Weight / sum
	end

	self.blendFactor = blendFactor
	self.reverbType1 = reverbType1
	self.reverbType2 = reverbType2

	setReverbEffect(SoundManager.DEFAULT_REVERB_EFFECT, reverbType2, reverbType1, blendFactor)
end

function ReverbSystem:draw()
	renderText(0.5, 0.52, 0.014, "Reverb System:")
	renderText(0.5, 0.5, 0.012, string.format("%s - %.3f", ReverbSystem.getName(self.reverbType2), 1 - self.blendFactor))
	renderText(0.5, 0.48, 0.012, string.format("%s - %.3f", ReverbSystem.getName(self.reverbType1), self.blendFactor))
end

function ReverbSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive

	if self.isDebugViewActive then
		self.mission:addDrawable(self)
	else
		self.mission:removeDrawable(self)
	end
end
