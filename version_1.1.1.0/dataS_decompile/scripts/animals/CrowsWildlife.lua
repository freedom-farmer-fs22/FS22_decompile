CrowsWildlife = {}
local CrowsWildlife_mt = Class(CrowsWildlife, LightWildlife)

InitStaticObjectClass(CrowsWildlife, "CrowsWildlife", ObjectIds.OBJECT_ANIMAL_CROWS_WILDLIFE)

CrowsWildlife.CROW_STATES = {
	{
		id = "default",
		classObject = CrowStateDefault
	},
	{
		id = "fly_glide",
		classObject = CrowStateFlyGlide
	},
	{
		id = "fly",
		classObject = CrowStateFly
	},
	{
		id = "flyUp",
		classObject = CrowStateFlyUp
	},
	{
		id = "flyDown",
		classObject = CrowStateFlyDown
	},
	{
		id = "flyDownFlapping",
		classObject = CrowStateFlyDownFlapping
	},
	{
		id = "land",
		classObject = CrowStateLand
	},
	{
		id = "takeOff",
		classObject = CrowStateTakeOff
	},
	{
		id = "idle_walk",
		classObject = CrowStateIdleWalk
	},
	{
		id = "idle_eat",
		classObject = CrowStateIdleEat
	},
	{
		id = "idle_attention",
		classObject = CrowStateIdleAttention
	}
}
CrowsWildlife.CROW_SOUND_STATES = {
	TAKEOFF = 5,
	BUSY = 4,
	CALM_GROUND = 2,
	CALM_AIR = 3,
	NONE = 1
}

function CrowsWildlife.new(customMt)
	local self = CrowsWildlife:superClass().new(customMt or CrowsWildlife_mt)
	self.animalStates = {}

	for _, stateEntry in pairs(CrowsWildlife.CROW_STATES) do
		table.insert(self.animalStates, stateEntry)
	end

	self.tree = nil
	self.soundFSM = FSMUtil.create()

	self.soundFSM:addState(CrowsWildlife.CROW_SOUND_STATES.NONE, CrowSoundStateDefault.new(CrowsWildlife.CROW_SOUND_STATES.NONE, self, self.soundFSM))
	self.soundFSM:addState(CrowsWildlife.CROW_SOUND_STATES.CALM_GROUND, CrowSoundStateCalmGround.new(CrowsWildlife.CROW_SOUND_STATES.CALM_GROUND, self, self.soundFSM))
	self.soundFSM:addState(CrowsWildlife.CROW_SOUND_STATES.CALM_AIR, CrowSoundStateCalmAir.new(CrowsWildlife.CROW_SOUND_STATES.CALM_AIR, self, self.soundFSM))
	self.soundFSM:addState(CrowsWildlife.CROW_SOUND_STATES.BUSY, CrowSoundStateBusy.new(CrowsWildlife.CROW_SOUND_STATES.BUSY, self, self.soundFSM))
	self.soundFSM:addState(CrowsWildlife.CROW_SOUND_STATES.TAKEOFF, CrowSoundStateTakeOff.new(CrowsWildlife.CROW_SOUND_STATES.TAKEOFF, self, self.soundFSM))
	self.soundFSM:changeState(CrowsWildlife.CROW_SOUND_STATES.NONE)

	return self
end

function CrowsWildlife:delete()
	g_soundManager:deleteSamples(self.samples.flyAway)
	g_soundManager:deleteSamples(self.samples.calmGround)
	g_soundManager:deleteSample(self.samples.busy)
	g_soundManager:deleteSample(self.samples.calmAir)
	CrowsWildlife:superClass().delete(self)
end

function CrowsWildlife:load(xmlFilename)
	CrowsWildlife:superClass().load(self, xmlFilename)

	local xmlFile = loadXMLFile("TempXML", self.xmlFilename)

	if xmlFile == 0 then
		self.xmlFilename = nil

		return false
	end

	self.samples = {
		flyAway = {}
	}
	local i = 0

	while true do
		local sampleFlyAway = g_soundManager:loadSampleFromXML(xmlFile, "wildlifeAnimal.sounds.flyAways", string.format("flyAway(%d)", i), self.baseDirectory, self.soundsNode, 1, AudioGroup.ENVIRONMENT, nil, )

		if sampleFlyAway == nil then
			break
		end

		table.insert(self.samples.flyAway, sampleFlyAway)

		i = i + 1
	end

	self.samples.flyAwayCount = i
	self.samples.calmGround = {}
	local j = 0

	while true do
		local sampleCalmGround = g_soundManager:loadSampleFromXML(xmlFile, "wildlifeAnimal.sounds.calmGrounds", string.format("calmGround(%d)", j), self.baseDirectory, self.soundsNode, 1, AudioGroup.ENVIRONMENT, nil, )

		if sampleCalmGround == nil then
			break
		end

		table.insert(self.samples.calmGround, sampleCalmGround)

		j = j + 1
	end

	self.samples.calmCount = j
	self.samples.busy = g_soundManager:loadSampleFromXML(xmlFile, "wildlifeAnimal.sounds", "busy", self.baseDirectory, self.soundsNode, 0, AudioGroup.ENVIRONMENT, nil, )
	self.samples.calmAir = g_soundManager:loadSampleFromXML(xmlFile, "wildlifeAnimal.sounds", "calmAir", self.baseDirectory, self.soundsNode, 0, AudioGroup.ENVIRONMENT, nil, )

	delete(xmlFile)

	return true
end

function CrowsWildlife:createAnimals(name, spawnPosX, spawnPosY, spawnPosZ, nbAnimals)
	if #self.animals == 0 then
		self.soundFSM:changeState(CrowsWildlife.CROW_SOUND_STATES.CALM_GROUND)
	end

	local id = CrowsWildlife:superClass().createAnimals(self, name, spawnPosX, spawnPosY, spawnPosZ, nbAnimals)

	return id
end

function CrowsWildlife:update(dt)
	CrowsWildlife:superClass().update(self, dt)

	if #self.animals > 0 then
		self.soundFSM:update(dt)
	elseif self.soundFSM.currentState.id ~= CrowsWildlife.CROW_SOUND_STATES.NONE then
		self.soundFSM:changeState(CrowsWildlife.CROW_SOUND_STATES.NONE)
	end
end

function CrowsWildlife:searchTree(x, y, z, radius)
	overlapSphere(x, y, z, radius, "treeSearchCallback", self, CollisionFlag.TREE, false, true, false)
end

function CrowsWildlife:treeSearchCallback(transformId)
	self.tree = nil

	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local object = getParent(transformId)

		if object ~= nil and getSplitType(transformId) ~= 0 then
			self.tree = object
		end
	end

	return true
end

function CrowsWildlife:getAverageLocationOfIdleAnimals()
	local nbIdleAnimals = 0
	local accPosX = 0
	local accPosZ = 0

	for _, animal in pairs(self.animals) do
		local currentState = animal.stateMachine.currentState.id

		if currentState == "idle_walk" or currentState == "idle_eat" or currentState == "idle_attention" then
			local posX, _, posZ = getWorldTranslation(animal.i3dNodeId)
			accPosZ = accPosZ + posZ
			accPosX = accPosX + posX
			nbIdleAnimals = nbIdleAnimals + 1
		end
	end

	if nbIdleAnimals > 0 then
		accPosZ = accPosZ / nbIdleAnimals
		accPosX = accPosX / nbIdleAnimals
		local terrainHeight = self:getTerrainHeightWithProps(accPosX, accPosZ)

		return true, accPosX, terrainHeight, accPosZ
	end

	return false, 0, 0, 0
end
