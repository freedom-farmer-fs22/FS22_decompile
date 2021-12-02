MultipleItemPurchase = {
	initSpecialization = function ()
		g_configurationManager:addConfigurationType("multipleItemPurchaseAmount", g_i18n:getText("configuration_buyableBaleAmount"), nil, , , , ConfigurationUtil.SELECTOR_MULTIOPTION)

		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("MultipleItemPurchase")
		schema:register(XMLValueType.STRING, "vehicle.multipleItemPurchase#filename", "Item filename")
		schema:register(XMLValueType.BOOL, "vehicle.multipleItemPurchase#isVehicle", "Is Loading a vehicle (false=Bale)", false)
		schema:register(XMLValueType.STRING, "vehicle.multipleItemPurchase#fillType", "Bale fill type", "STRAW")
		schema:register(XMLValueType.BOOL, "vehicle.multipleItemPurchase#baleIsWrapped", "Bale is wrapped", false)
		schema:register(XMLValueType.VECTOR_TRANS, "vehicle.multipleItemPurchase.offsets.offset(?)#offset", "Offset")
		schema:register(XMLValueType.FLOAT, "vehicle.multipleItemPurchase.offsets.offset(?)#amount", "Amount of items to activate offset")
		schema:register(XMLValueType.VECTOR_TRANS, "vehicle.multipleItemPurchase.itemPositions.itemPosition(?)#position", "Bale position")
		schema:register(XMLValueType.VECTOR_ROT, "vehicle.multipleItemPurchase.itemPositions.itemPosition(?)#rotation", "Bale rotation")
		schema:setXMLSpecializationType(XMLManager.XML_SPECIALIZATION_NONE)
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end
}

function MultipleItemPurchase.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadItemAtPosition", MultipleItemPurchase.loadItemAtPosition)
	SpecializationUtil.registerFunction(vehicleType, "onFinishLoadingVehicle", MultipleItemPurchase.onFinishLoadingVehicle)
end

function MultipleItemPurchase.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTotalMass", MultipleItemPurchase.getTotalMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitCapacity", MultipleItemPurchase.getFillUnitCapacity)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setVisibility", MultipleItemPurchase.setVisibility)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", MultipleItemPurchase.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", MultipleItemPurchase.removeFromPhysics)
end

function MultipleItemPurchase.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", MultipleItemPurchase)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoadFinished", MultipleItemPurchase)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", MultipleItemPurchase)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", MultipleItemPurchase)
end

function MultipleItemPurchase:onLoad(savegame)
	local spec = self.spec_multipleItemPurchase
	spec.loadedBales = {}
	spec.loadedVehicles = {}
	spec.itemFilename = Utils.getFilename(self.xmlFile:getValue("vehicle.multipleItemPurchase#filename"), self.baseDirectory)
	spec.isVehicle = self.xmlFile:getValue("vehicle.multipleItemPurchase#isVehicle", false)
	local fillTypeName = self.xmlFile:getValue("vehicle.multipleItemPurchase#fillType", "STRAW")
	spec.baleFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
	spec.baleIsWrapped = self.xmlFile:getValue("vehicle.multipleItemPurchase#baleIsWrapped", false)
	local positionOffset = {
		0,
		0,
		0
	}
	local i = 0

	while true do
		local baseKey = string.format("vehicle.multipleItemPurchase.offsets.offset(%d)", i)

		if not self.xmlFile:hasProperty(baseKey) then
			break
		end

		local offset = self.xmlFile:getValue(baseKey .. "#offset", nil, true)
		local amount = self.xmlFile:getValue(baseKey .. "#amount")

		if amount <= self.configurations.multipleItemPurchaseAmount then
			positionOffset = offset
		end

		i = i + 1
	end

	spec.positions = {}
	i = 0

	while true do
		local baseKey = string.format("vehicle.multipleItemPurchase.itemPositions.itemPosition(%d)", i)

		if not self.xmlFile:hasProperty(baseKey) then
			break
		end

		local position = self.xmlFile:getValue(baseKey .. "#position", nil, true)
		local rotation = self.xmlFile:getValue(baseKey .. "#rotation", nil, true)

		if position ~= nil and rotation ~= nil then
			if positionOffset ~= nil then
				for j = 1, 3 do
					position[j] = position[j] + positionOffset[j]
				end
			end

			table.insert(spec.positions, {
				position = position,
				rotation = rotation
			})
		end

		i = i + 1
	end

	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdate", MultipleItemPurchase)
	end
end

function MultipleItemPurchase:onPreLoadFinished(savegame)
	local spec = self.spec_multipleItemPurchase

	for j, position in ipairs(spec.positions) do
		if j <= self.configurations.multipleItemPurchaseAmount then
			self:loadItemAtPosition(position)
		end
	end
end

function MultipleItemPurchase:loadItemAtPosition(position)
	local spec = self.spec_multipleItemPurchase

	if self.isServer or self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG then
		local x, y, z = localToWorld(self.components[1].node, unpack(position.position))
		local rx, ry, rz = localRotationToWorld(self.components[1].node, unpack(position.rotation))

		if not spec.isVehicle then
			local baleObject = Bale.new(self.isServer, self.isClient)

			if baleObject:loadFromConfigXML(spec.itemFilename, x, y, z, rx, ry, rz) then
				baleObject:setFillType(spec.baleFillTypeIndex, true)
				baleObject:setOwnerFarmId(self:getActiveFarm(), true)

				if self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then
					baleObject:register()
				end

				if spec.baleIsWrapped then
					baleObject:setWrappingState(1)

					if self.configurations.baseColor ~= nil then
						local color = ConfigurationUtil.getColorByConfigId(self, "baseColor", self.configurations.baseColor)

						baleObject:setColor(unpack(color))
					end
				end

				setPairCollision(self.components[1].node, baleObject.nodeId, false)
				table.insert(spec.loadedBales, baleObject)
			end
		else
			local location = {
				x = x,
				y = y,
				z = z,
				xRot = rx,
				yRot = ry,
				zRot = rz
			}
			local registerVehicle = self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG
			local forceServer = self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG

			VehicleLoadingUtil.loadVehicle(spec.itemFilename, location, true, 0, self.propertyState, self:getActiveFarm(), nil, , self.onFinishLoadingVehicle, self, nil, registerVehicle, forceServer)

			self.subLoadingTasksFinished = false
			self.numPendingSubLoadingTasks = self.numPendingSubLoadingTasks + 1
		end
	end
end

function MultipleItemPurchase:onFinishLoadingVehicle(vehicle, vehicleLoadState)
	local spec = self.spec_multipleItemPurchase

	if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
		table.insert(spec.loadedVehicles, vehicle)
	end

	self.numPendingSubLoadingTasks = self.numPendingSubLoadingTasks - 1
	self.subLoadingTasksFinished = self.numPendingSubLoadingTasks == 0

	if not self.isDeleted and not self.isDeleting and self.syncVehicleLoadingFinished then
		self:tryFinishLoading()
	end
end

function MultipleItemPurchase:onDelete()
	if self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG or g_iconGenerator ~= nil or g_currentMission.debugVehiclesToBeLoaded ~= nil then
		local spec = self.spec_multipleItemPurchase

		if spec.loadedBales ~= nil then
			for _, bale in ipairs(spec.loadedBales) do
				bale:delete()
			end

			for _, vehicle in ipairs(spec.loadedVehicles) do
				vehicle:delete()
			end
		end
	end
end

function MultipleItemPurchase:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then
		g_currentMission:removeVehicle(self)
	end
end

function MultipleItemPurchase:getTotalMass(superFunc, onlyGivenVehicle)
	if self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG then
		local mass = 0
		local spec = self.spec_multipleItemPurchase

		for _, bale in ipairs(spec.loadedBales) do
			mass = mass + bale:getMass()
		end

		for _, vehicle in ipairs(spec.loadedVehicles) do
			mass = mass + vehicle:getTotalMass()
		end

		return mass
	end

	return 0
end

function MultipleItemPurchase:getFillUnitCapacity(superFunc, fillUnitIndex)
	if self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG then
		local fillLevel = 0
		local spec = self.spec_multipleItemPurchase

		for _, bale in ipairs(spec.loadedBales) do
			fillLevel = fillLevel + bale:getFillLevel()
		end

		for _, vehicle in ipairs(spec.loadedVehicles) do
			if vehicle.getFillUnitCapacity ~= nil then
				fillLevel = fillLevel + vehicle:getFillUnitCapacity(1)
			end
		end

		return fillLevel
	end

	return 0
end

function MultipleItemPurchase:setVisibility(superFunc, state)
	local spec = self.spec_multipleItemPurchase

	for _, vehicle in ipairs(spec.loadedVehicles) do
		vehicle:setVisibility(state)
	end

	superFunc(self, state)
end

function MultipleItemPurchase:addToPhysics(superFunc)
end

function MultipleItemPurchase:removeFromPhysics(superFunc)
	local spec = self.spec_multipleItemPurchase

	for _, bale in ipairs(spec.loadedBales) do
		bale:removeFromPhysics()
	end

	for _, vehicle in ipairs(spec.loadedVehicles) do
		vehicle:removeFromPhysics()
	end

	superFunc(self)
end
