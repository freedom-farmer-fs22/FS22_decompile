PlaceableHusbandryMilk = {}

source("dataS/scripts/animals/husbandry/objects/MilkingRobot.lua")

function PlaceableHusbandryMilk.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableHusbandry, specializations)
end

function PlaceableHusbandryMilk.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onMilkingRobotLoaded", PlaceableHusbandryMilk.onMilkingRobotLoaded)
end

function PlaceableHusbandryMilk.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryMilk.updateOutput)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateProduction", PlaceableHusbandryMilk.updateProduction)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryMilk.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryMilk.getConditionInfos)
end

function PlaceableHusbandryMilk.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryMilk)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryMilk)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryMilk)
	SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PlaceableHusbandryMilk)
end

function PlaceableHusbandryMilk.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")

	basePath = basePath .. ".husbandry.milk"

	schema:register(XMLValueType.NODE_INDEX, basePath .. ".milkingRobots.milkingRobot(?)#linkNode", "Milkingrobot link node")
	schema:register(XMLValueType.STRING, basePath .. ".milkingRobots.milkingRobot(?)#class", "Milkingrobot class name")
	schema:register(XMLValueType.STRING, basePath .. ".milkingRobots.milkingRobot(?)#filename", "Milkingrobot config file")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryMilk:onLoad(savegame)
	local spec = self.spec_husbandryMilk
	spec.litersPerHour = 0
	spec.fillType = FillType.MILK
	spec.info = {
		text = "",
		title = g_i18n:getText("fillType_milk")
	}
	spec.milkingRobots = {}
	spec.husbandry = nil

	self.xmlFile:iterate("placeable.husbandry.milk.milkingRobots.milkingRobot", function (_, key)
		local filename = Utils.getFilename(self.xmlFile:getValue(key .. "#filename", nil), self.baseDirectory)

		if filename == nil then
			Logging.xmlWarning(self.xmlFile, "Milkingrobot filename missing for '%s'", key)

			return
		end

		local className = self.xmlFile:getValue(key .. "#class", "")
		local class = ClassUtil.getClassObject(className)

		if class == nil then
			Logging.xmlWarning(self.xmlFile, "Milkingrobot class '%s' not defined for '%s'", className, key)

			return
		end

		local linkNode = self.xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)

		if linkNode == nil then
			Logging.xmlWarning(self.xmlFile, "Milkingrobot linkNode not defined for '%s'", key)

			return
		end

		local loadingTask = self:createLoadingTask(self)
		local robot = class.new(self, self.baseDirectory)

		robot:load(linkNode, filename, self.onMilkingRobotLoaded, self, {
			loadingTask
		})
		table.insert(spec.milkingRobots, robot)
	end)
end

function PlaceableHusbandryMilk:onMilkingRobotLoaded(robot, args)
	local task = unpack(args)

	self:finishLoadingTask(task)
end

function PlaceableHusbandryMilk:onDelete()
	local spec = self.spec_husbandryMilk

	if spec.milkingRobots ~= nil then
		for _, robot in ipairs(spec.milkingRobots) do
			robot:delete()
		end

		spec.milkingRobots = {}
	end
end

function PlaceableHusbandryMilk:onFinalizePlacement()
	local spec = self.spec_husbandryMilk

	if not self:getHusbandryIsFillTypeSupported(spec.fillType) then
		Logging.warning("Missing filltype 'milk' in husbandry storage!")
	end

	for _, robot in ipairs(spec.milkingRobots) do
		robot:finalizePlacement()
	end
end

function PlaceableHusbandryMilk:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	local spec = self.spec_husbandryMilk

	if self.isServer and spec.litersPerHour > 0 then
		local liters = productionFactor * globalProductionFactor * spec.litersPerHour * g_currentMission.environment.timeAdjustment

		self:addHusbandryFillLevelFromTool(self:getOwnerFarmId(), liters, spec.fillType, nil, , )
	end

	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end

function PlaceableHusbandryMilk:updateProduction(superFunc, foodFactor)
	local spec = self.spec_husbandryMilk
	local factor = superFunc(self, foodFactor)
	local freeCapacity = self:getHusbandryFreeCapacity(spec.fillType)

	if freeCapacity <= 0 then
		factor = 0
	end

	return factor
end

function PlaceableHusbandryMilk:onHusbandryAnimalsUpdate(clusters)
	local spec = self.spec_husbandryMilk
	spec.litersPerHour = 0

	for _, cluster in ipairs(clusters) do
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)

		if subType ~= nil then
			local milk = subType.output.milk

			if milk ~= nil then
				local age = cluster:getAge()
				local litersPerAnimals = milk:get(age)
				local litersPerDay = litersPerAnimals * cluster:getNumAnimals()
				spec.litersPerHour = spec.litersPerHour + litersPerDay / 24
			end
		end
	end
end

function PlaceableHusbandryMilk:updateInfo(superFunc, infoTable)
	local spec = self.spec_husbandryMilk

	superFunc(self, infoTable)

	local fillLevel = self:getHusbandryFillLevel(spec.fillType)
	spec.info.text = string.format("%d l", fillLevel)

	table.insert(infoTable, spec.info)
end

function PlaceableHusbandryMilk:getConditionInfos(superFunc)
	local spec = self.spec_husbandryMilk
	local infos = superFunc(self)
	local info = {}
	local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillType)
	info.title = fillType.title
	info.value = self:getHusbandryFillLevel(spec.fillType)
	local capacity = self:getHusbandryCapacity(spec.fillType)
	local ratio = 0

	if capacity > 0 then
		ratio = info.value / capacity
	end

	info.ratio = MathUtil.clamp(ratio, 0, 1)
	info.invertedBar = true

	table.insert(infos, info)

	return infos
end
