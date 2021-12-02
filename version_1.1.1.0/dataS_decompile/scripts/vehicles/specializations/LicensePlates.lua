LicensePlates = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function LicensePlates.initSpecialization()
	g_storeManager:addSpecType("licensePlate", "shopListAttributeIconLicensePlate", LicensePlates.loadSpecValuePlateText, LicensePlates.getSpecValuePlateText, "vehicle")

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("LicensePlates")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.licensePlates.licensePlate(?)#node", "License plate node")
	schema:register(XMLValueType.STRING, "vehicle.licensePlates.licensePlate(?)#preferedType", "Prefered license plate type to be placed if available")
	schema:register(XMLValueType.VECTOR_4, "vehicle.licensePlates.licensePlate(?)#placementArea", "Defines the available area around the node (top, right, bottom, left) ('-' means unlimited)")
	schema:register(XMLValueType.STRING, "vehicle.licensePlates.licensePlate(?)#position", "Position of license plate ('FRONT' or 'BACK')", "ANY")
	schema:register(XMLValueType.BOOL, "vehicle.licensePlates.licensePlate(?)#frame", "License plate with frame of without frame", true)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.licensePlates.licensePlate(?)")
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).licensePlates#variation", "License plate variation", 1)
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).licensePlates#characters", "Characters string")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).licensePlates#colorIndex", "Selected color index", 1)
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).licensePlates#placementIndex", "Selected placement index", 1)
end

function LicensePlates.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setLicensePlatesData", LicensePlates.setLicensePlatesData)
	SpecializationUtil.registerFunction(vehicleType, "getLicensePlatesData", LicensePlates.getLicensePlatesData)
	SpecializationUtil.registerFunction(vehicleType, "getLicensePlatesDataIsEqual", LicensePlates.getLicensePlatesDataIsEqual)
	SpecializationUtil.registerFunction(vehicleType, "getHasLicensePlates", LicensePlates.getHasLicensePlates)
end

function LicensePlates.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", LicensePlates)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", LicensePlates)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", LicensePlates)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LicensePlates)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LicensePlates)
end

function LicensePlates:onLoad(savegame)
	local spec = self.spec_licensePlates
	spec.licensePlates = {}

	if g_licensePlateManager:getAreLicensePlatesAvailable() then
		local i = 0

		while true do
			local plateKey = string.format("vehicle.licensePlates.licensePlate(%d)", i)

			if not self.xmlFile:hasProperty(plateKey) then
				break
			end

			local licensePlate = {
				node = self.xmlFile:getValue(plateKey .. "#node", nil, self.components, self.i3dMappings)
			}

			if licensePlate.node ~= nil then
				local preferedTypeStr = self.xmlFile:getValue(plateKey .. "#preferedType", "ELONGATED")
				licensePlate.preferedType = LicensePlateManager.PLATE_TYPE[preferedTypeStr]

				if licensePlate.preferedType ~= nil then
					licensePlate.placementArea = {
						1,
						1,
						1,
						1
					}
					local placementAreaString = self.xmlFile:getString(plateKey .. "#placementArea")

					if placementAreaString ~= nil then
						local placementArea = string.split(placementAreaString, " ")

						if #placementArea == 4 then
							for j = 1, 4 do
								if placementArea[j] ~= "-" then
									local numberValue = tonumber(placementArea[j])

									if numberValue == nil then
										Logging.xmlWarning(self.xmlFile, "Invalid 4-vector '%s' for '%s'. '%s' is not a number!", placementAreaString, plateKey .. "#placementArea", placementArea[j])
									else
										licensePlate.placementArea[j] = numberValue
									end
								end
							end
						else
							Logging.xmlWarning(self.xmlFile, "Invalid 4-vector '%s' for '%s' ", placementAreaString, plateKey .. "#placementArea")
						end
					end

					local positionStr = self.xmlFile:getValue(plateKey .. "#position", "ANY")
					licensePlate.position = LicensePlateManager.PLATE_POSITION[positionStr] or LicensePlateManager.PLATE_POSITION.ANY
					local includeFrame = self.xmlFile:getValue(plateKey .. "#frame", true)
					licensePlate.data = g_licensePlateManager:getLicensePlate(licensePlate.preferedType, includeFrame)

					if licensePlate.data ~= nil then
						link(licensePlate.node, licensePlate.data.node)
						setTranslation(licensePlate.data.node, 0, 0, 0)
						setRotation(licensePlate.data.node, 0, 0, 0)
						setVisibility(licensePlate.data.node, false)

						local widthPos = licensePlate.data.rawWidth * 0.5 + licensePlate.data.widthOffsetLeft
						local widthNeg = licensePlate.data.rawWidth * 0.5 + licensePlate.data.widthOffsetRight
						local heightPos = licensePlate.data.rawHeight * 0.5 + licensePlate.data.heightOffsetTop
						local heightNeg = licensePlate.data.rawHeight * 0.5 + licensePlate.data.heightOffsetBot
						local scaleFactorWidth = (licensePlate.placementArea[2] + licensePlate.placementArea[4]) / (widthPos + widthNeg)
						local scaleFactorHeight = (licensePlate.placementArea[1] + licensePlate.placementArea[3]) / (heightPos + heightNeg)
						local minFactor = MathUtil.clamp(math.min(scaleFactorWidth, scaleFactorHeight), 0, 1)

						if minFactor < 1 then
							setScale(licensePlate.data.node, minFactor, minFactor, minFactor)

							widthPos = widthPos * minFactor
							widthNeg = widthNeg * minFactor
							heightPos = heightPos * minFactor
							heightNeg = heightNeg * minFactor
						end

						local moveX = 0
						local moveY = 0
						moveX = moveX - math.max(widthPos - licensePlate.placementArea[2], 0)
						moveX = moveX + math.max(widthNeg - licensePlate.placementArea[4], 0)
						moveY = moveY - math.max(heightPos - licensePlate.placementArea[1], 0)
						moveY = moveY + math.max(heightNeg - licensePlate.placementArea[3], 0)

						setTranslation(licensePlate.data.node, moveX, moveY, 0)

						licensePlate.changeObjects = {}

						ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, plateKey, licensePlate.changeObjects, self.components, self)
						table.insert(spec.licensePlates, licensePlate)
					end
				else
					Logging.xmlError(self.xmlFile, "Unknown preferedType '%s' for license plate '%s'", preferedTypeStr, plateKey)
				end
			end

			i = i + 1
		end

		if self:getHasLicensePlates() then
			spec.licensePlateData = {
				variation = 1
			}
		end
	end
end

function LicensePlates:onPostLoad(savegame)
	local spec = self.spec_licensePlates

	if savegame ~= nil and not savegame.resetVehicles and self:getHasLicensePlates() then
		local variation = savegame.xmlFile:getValue(savegame.key .. ".licensePlates#variation", 1)
		local characters = savegame.xmlFile:getValue(savegame.key .. ".licensePlates#characters")
		local colorIndex = savegame.xmlFile:getValue(savegame.key .. ".licensePlates#colorIndex", 1)
		local placementIndex = savegame.xmlFile:getValue(savegame.key .. ".licensePlates#placementIndex", 1)

		if variation ~= nil and characters ~= nil and colorIndex ~= nil and placementIndex ~= nil then
			local characterTbl = {}
			local characterLength = characters:len()

			for i = 1, characterLength do
				table.insert(characterTbl, characters:sub(i, i))
			end

			spec.licensePlateData = {
				variation = variation,
				characters = characterTbl,
				colorIndex = colorIndex,
				placementIndex = placementIndex
			}

			self:setLicensePlatesData(spec.licensePlateData)
		end
	end
end

function LicensePlates:onDelete(savegame)
	local spec = self.spec_licensePlates
	spec.licensePlates = {}
end

function LicensePlates:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_licensePlates

	if self:getHasLicensePlates() and spec.licensePlateData and spec.licensePlateData.placementIndex ~= LicensePlateManager.PLACEMENT_OPTION.NONE and spec.licensePlateData.variation ~= nil and spec.licensePlateData.characters ~= nil and spec.licensePlateData.colorIndex ~= nil then
		xmlFile:setValue(key .. "#variation", spec.licensePlateData.variation)
		xmlFile:setValue(key .. "#characters", table.concat(spec.licensePlateData.characters, ""))
		xmlFile:setValue(key .. "#colorIndex", spec.licensePlateData.colorIndex)
		xmlFile:setValue(key .. "#placementIndex", spec.licensePlateData.placementIndex)
	end
end

function LicensePlates:onReadStream(streamId, connection)
	local spec = self.spec_licensePlates
	spec.licensePlateData = LicensePlateManager.readLicensePlateData(streamId, connection)

	self:setLicensePlatesData(spec.licensePlateData)
end

function LicensePlates:onWriteStream(streamId, connection)
	local spec = self.spec_licensePlates

	LicensePlateManager.writeLicensePlateData(streamId, connection, spec.licensePlateData)
end

function LicensePlates:setLicensePlatesData(licensePlateData)
	local spec = self.spec_licensePlates

	if licensePlateData ~= nil and licensePlateData.variation ~= nil and licensePlateData.characters ~= nil and licensePlateData.colorIndex ~= nil and licensePlateData.placementIndex ~= nil then
		for i = 1, #spec.licensePlates do
			local licensePlate = spec.licensePlates[i]
			local allowLicensePlate = true

			if licensePlateData.placementIndex == LicensePlateManager.PLACEMENT_OPTION.NONE then
				allowLicensePlate = false
			elseif licensePlateData.placementIndex == LicensePlateManager.PLACEMENT_OPTION.BACK_ONLY and licensePlate.position == LicensePlateManager.PLATE_POSITION.FRONT then
				allowLicensePlate = false
			end

			if allowLicensePlate then
				licensePlate.data:updateData(licensePlateData.variation, licensePlate.position, table.concat(licensePlateData.characters, ""), true)
				licensePlate.data:setColorIndex(licensePlateData.colorIndex)
				setVisibility(licensePlate.data.node, true)
			else
				setVisibility(licensePlate.data.node, false)
			end

			ObjectChangeUtil.setObjectChanges(licensePlate.changeObjects, allowLicensePlate, self, self.setMovingToolDirty)
		end

		spec.licensePlateData = licensePlateData
	else
		for i = 1, #spec.licensePlates do
			setVisibility(spec.licensePlates[i].data.node, false)
		end
	end
end

function LicensePlates:getLicensePlatesData()
	return self.spec_licensePlates.licensePlateData
end

function LicensePlates:getLicensePlatesDataIsEqual(data)
	if data == nil or self.spec_licensePlates.licensePlateData == nil then
		return true
	end

	local ownData = self.spec_licensePlates.licensePlateData

	if data.variation ~= ownData.variation or data.colorIndex ~= ownData.colorIndex or data.placementIndex ~= ownData.placementIndex then
		return false
	end

	if data.characters ~= nil and ownData.characters ~= nil then
		if #data.characters ~= #ownData.characters then
			return false
		end

		for i = 1, #data.characters do
			if data.characters[i] ~= ownData.characters[i] then
				return false
			end
		end
	end

	return true
end

function LicensePlates:getHasLicensePlates()
	return #self.spec_licensePlates.licensePlates > 0
end

function LicensePlates.loadSpecValuePlateText(xmlFile, customEnvironment)
	return nil
end

function LicensePlates.getSpecValuePlateText(storeItem, realItem)
	if realItem == nil then
		return nil
	end

	if realItem.getHasLicensePlates == nil or not realItem:getHasLicensePlates() then
		return nil
	end

	local spec = realItem.spec_licensePlates

	for i = 1, #spec.licensePlates do
		local licensePlate = spec.licensePlates[i]

		if licensePlate.position == LicensePlateManager.PLATE_POSITION.BACK or i == #spec.licensePlates then
			return licensePlate.data:getFormattedString()
		end
	end

	return nil
end
