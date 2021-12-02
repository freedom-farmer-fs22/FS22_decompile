source("dataS/scripts/vehicles/specializations/events/WaterTrailerSetIsFillingEvent.lua")

WaterTrailer = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("WaterTrailer")
		schema:register(XMLValueType.INT, "vehicle.waterTrailer#fillUnitIndex", "Fill unit index")
		schema:register(XMLValueType.FLOAT, "vehicle.waterTrailer#fillLitersPerSecond", "Fill liters per second", 500)
		schema:register(XMLValueType.NODE_INDEX, "vehicle.waterTrailer#fillNode", "Fill node", "Root component")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.waterTrailer.sounds", "refill")
		schema:setXMLSpecializationType()
	end
}

function WaterTrailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setIsWaterTrailerFilling", WaterTrailer.setIsWaterTrailerFilling)
end

function WaterTrailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", WaterTrailer.getDrawFirstFillText)
end

function WaterTrailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", WaterTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WaterTrailer)
end

function WaterTrailer:onLoad(savegame)
	local spec = self.spec_waterTrailer
	local fillUnitIndex = self.xmlFile:getValue("vehicle.waterTrailer#fillUnitIndex")

	if fillUnitIndex ~= nil then
		spec.fillUnitIndex = fillUnitIndex
		spec.fillLitersPerSecond = self.xmlFile:getValue("vehicle.waterTrailer#fillLitersPerSecond", 500)
		spec.waterFillNode = self.xmlFile:getValue("vehicle.waterTrailer#fillNode", self.components[1].node, self.components, self.i3dMappings)
	end

	spec.isFilling = false
	spec.activatable = WaterTrailerActivatable.new(self)

	if self.isClient then
		spec.samples = {
			refill = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.waterTrailer.sounds", "refill", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end
end

function WaterTrailer:onDelete()
	local spec = self.spec_waterTrailer

	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
	g_soundManager:deleteSamples(spec.samples)
end

function WaterTrailer:onReadStream(streamId, connection)
	local isFilling = streamReadBool(streamId)

	self:setIsWaterTrailerFilling(isFilling, true)
end

function WaterTrailer:onWriteStream(streamId, connection)
	local spec = self.spec_waterTrailer

	streamWriteBool(streamId, spec.isFilling)
end

function WaterTrailer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_waterTrailer
	local _, y, _ = getWorldTranslation(spec.waterFillNode)
	local isNearWater = y <= self.waterY + 0.2

	if isNearWater then
		g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
	else
		g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
	end

	if self.isServer then
		if spec.isFilling and not isNearWater then
			self:setIsWaterTrailerFilling(false)
		end

		if spec.isFilling and self:getFillUnitAllowsFillType(spec.fillUnitIndex, FillType.WATER) then
			local delta = self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, spec.fillLitersPerSecond * dt * 0.001, FillType.WATER, ToolType.TRIGGER, nil)

			if delta <= 0 then
				self:setIsWaterTrailerFilling(false)
			end
		end
	end
end

function WaterTrailer:setIsWaterTrailerFilling(isFilling, noEventSend)
	local spec = self.spec_waterTrailer

	if isFilling ~= spec.isFilling then
		WaterTrailerSetIsFillingEvent.sendEvent(self, isFilling, noEventSend)

		spec.isFilling = isFilling

		if self.isClient then
			if isFilling then
				g_soundManager:playSample(spec.samples.refill)
			else
				g_soundManager:stopSample(spec.samples.refill)
			end
		end
	end
end

function WaterTrailer:getDrawFirstFillText(superFunc)
	local spec = self.spec_waterTrailer

	if self.isClient and self:getIsActiveForInput() and self:getIsSelected() and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
		return true
	end

	return superFunc(self)
end

function WaterTrailer:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_waterTrailer

	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
end

WaterTrailerActivatable = {}
local WaterTrailerActivatable_mt = Class(WaterTrailerActivatable)

function WaterTrailerActivatable.new(trailer)
	local self = {}

	setmetatable(self, WaterTrailerActivatable_mt)

	self.trailer = trailer
	self.activateText = "unknown"

	return self
end

function WaterTrailerActivatable:getIsActivatable()
	local fillUnitIndex = self.trailer.spec_waterTrailer.fillUnitIndex

	if self.trailer:getIsActiveForInput(true) and self.trailer:getFillUnitFillLevel(fillUnitIndex) < self.trailer:getFillUnitCapacity(fillUnitIndex) and self.trailer:getFillUnitAllowsFillType(fillUnitIndex, FillType.WATER) then
		self:updateActivateText()

		return true
	end

	return false
end

function WaterTrailerActivatable:run()
	self.trailer:setIsWaterTrailerFilling(not self.trailer.spec_waterTrailer.isFilling)
	self:updateActivateText()
end

function WaterTrailerActivatable:updateActivateText()
	if self.trailer.spec_waterTrailer.isFilling then
		self.activateText = string.format(g_i18n:getText("action_stopRefillingOBJECT"), self.trailer.typeDesc)
	else
		self.activateText = string.format(g_i18n:getText("action_refillOBJECT"), self.trailer.typeDesc)
	end
end
