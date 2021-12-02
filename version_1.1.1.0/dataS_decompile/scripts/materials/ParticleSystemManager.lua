ParticleSystemManager = {}
ParticleType = nil
local ParticleSystemManager_mt = Class(ParticleSystemManager, AbstractManager)

function ParticleSystemManager.new(customMt)
	local self = AbstractManager.new(customMt or ParticleSystemManager_mt)

	return self
end

function ParticleSystemManager:initDataStructures()
	self.nameToIndex = {}
	self.particleTypes = {}
	self.particleSystems = {}
end

function ParticleSystemManager:loadMapData()
	ParticleSystemManager:superClass().loadMapData(self)
	self:addParticleType("unloading")
	self:addParticleType("smoke")
	self:addParticleType("chopper")
	self:addParticleType("straw")
	self:addParticleType("cutter_chopper")
	self:addParticleType("soil")
	self:addParticleType("soil_smoke")
	self:addParticleType("soil_chunks")
	self:addParticleType("soil_big_chunks")
	self:addParticleType("soil_harvesting")
	self:addParticleType("spreader")
	self:addParticleType("spreader_smoke")
	self:addParticleType("windrower")
	self:addParticleType("tedder")
	self:addParticleType("weeder")
	self:addParticleType("crusher_wood")
	self:addParticleType("crusher_dust")
	self:addParticleType("prepare_fruit")
	self:addParticleType("cleaning_soil")
	self:addParticleType("cleaning_dust")
	self:addParticleType("washer_water")
	self:addParticleType("chainsaw_wood")
	self:addParticleType("chainsaw_dust")
	self:addParticleType("pickup")
	self:addParticleType("pickup_falling")
	self:addParticleType("sowing")
	self:addParticleType("loading")
	self:addParticleType("wheel_dust")
	self:addParticleType("wheel_dry")
	self:addParticleType("wheel_wet")
	self:addParticleType("wheel_snow")
	self:addParticleType("bees")
	self:addParticleType("horse_step_slow")
	self:addParticleType("horse_step_fast")

	ParticleType = self.nameToIndex

	return true
end

function ParticleSystemManager:unloadMapData()
	for _, fillTypeParticleSystem in pairs(self.particleSystems) do
		ParticleUtil.deleteParticleSystem(fillTypeParticleSystem)
	end

	ParticleSystemManager:superClass().unloadMapData(self)
end

function ParticleSystemManager:addParticleType(name)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a particleType. Ignoring it!")

		return nil
	end

	name = name:upper()

	if self.nameToIndex[name] == nil then
		table.insert(self.particleTypes, name)

		self.nameToIndex[name] = #self.particleTypes
	end
end

function ParticleSystemManager:getParticleSystemTypeByName(name)
	if name ~= nil then
		name = name:upper()

		if self.nameToIndex[name] ~= nil then
			return name
		end
	end

	return nil
end

function ParticleSystemManager:addParticleSystem(particleType, particleSystem)
	if self.particleSystems[particleType] ~= nil then
		ParticleUtil.deleteParticleSystem(self.particleSystems[particleType])
	end

	self.particleSystems[particleType] = particleSystem
end

function ParticleSystemManager:getParticleSystem(particleTypeName)
	local particleType = self:getParticleSystemTypeByName(particleTypeName)

	if particleType == nil then
		return nil
	end

	return self.particleSystems[particleType]
end

g_particleSystemManager = ParticleSystemManager.new()
