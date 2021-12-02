VehicleSchemaDisplay = {}
local VehicleSchemaDisplay_mt = Class(VehicleSchemaDisplay, HUDDisplayElement)
VehicleSchemaDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH = "dataS/vehicleSchemaOverlays.xml"
VehicleSchemaDisplay.MAX_SCHEMA_COLLECTION_DEPTH = 5

function VehicleSchemaDisplay.new(modManager)
	local backgroundOverlay = VehicleSchemaDisplay.createBackground()
	local self = VehicleSchemaDisplay:superClass().new(backgroundOverlay, nil, VehicleSchemaDisplay_mt)

	self:createBackgroundBar()

	self.modManager = modManager
	self.vehicle = nil
	self.isDocked = false
	self.vehicleSchemaOverlays = {}
	self.iconSizeY = 0
	self.iconSizeX = 0
	self.maxSchemaWidth = 0

	return self
end

function VehicleSchemaDisplay:delete()
	VehicleSchemaDisplay:superClass().delete(self)

	if self.overlayFront ~= nil then
		self.overlayFront:delete()
	end

	if self.overlayMiddle ~= nil then
		self.overlayMiddle:delete()
	end

	if self.overlayBack ~= nil then
		self.overlayBack:delete()
	end

	for k, v in pairs(self.vehicleSchemaOverlays) do
		v:delete()

		self.vehicleSchemaOverlays[k] = nil
	end
end

function VehicleSchemaDisplay:loadVehicleSchemaOverlays()
	local xmlFile = loadXMLFile("VehicleSchemaDisplayOverlays", VehicleSchemaDisplay.SCHEMA_OVERLAY_DEFINITIONS_PATH)

	self:loadVehicleSchemaOverlaysFromXML(xmlFile)
	delete(xmlFile)

	for _, modDesc in ipairs(self.modManager:getMods()) do
		xmlFile = loadXMLFile("ModFile", modDesc.modFile)

		self:loadVehicleSchemaOverlaysFromXML(xmlFile, modDesc.modFile)
		delete(xmlFile)
	end

	self:storeScaledValues()
end

function VehicleSchemaDisplay:loadVehicleSchemaOverlaysFromXML(xmlFile, modPath)
	local rootPath = "vehicleSchemaOverlays"
	local baseDirectory = ""
	local prefix = ""

	if modPath then
		rootPath = "modDesc.vehicleSchemaOverlays"
		local modName, dir = Utils.getModNameAndBaseDirectory(modPath)
		baseDirectory = dir
		prefix = modName
	end

	local atlasPath = getXMLString(xmlFile, rootPath .. "#filename")
	local imageSize = GuiUtils.get2DArray(getXMLString(xmlFile, rootPath .. "#imageSize"), {
		1024,
		1024
	})
	local i = 0

	while true do
		local baseName = string.format("%s.overlay(%d)", rootPath, i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		local baseOverlayName = getXMLString(xmlFile, baseName .. "#name")
		local uvString = getXMLString(xmlFile, baseName .. "#uvs") or string.format("0px 0px %ipx %ipx", imageSize[1], imageSize[2])
		local uvs = GuiUtils.getUVs(uvString, imageSize)
		local sizeString = getXMLString(xmlFile, baseName .. "#size") or string.format("%ipx %ipx", VehicleSchemaDisplay.SIZE.ICON[1], VehicleSchemaDisplay.SIZE.ICON[1])
		local size = GuiUtils.getNormalizedValues(sizeString, {
			1,
			1
		})

		if baseOverlayName then
			local overlayName = prefix .. baseOverlayName
			local atlasFileName = Utils.getFilename(atlasPath, baseDirectory)
			local schemaOverlay = Overlay.new(atlasFileName, 0, 0, size[1], size[2])

			schemaOverlay:setUVs(uvs)

			self.vehicleSchemaOverlays[overlayName] = schemaOverlay
		end

		i = i + 1
	end
end

function VehicleSchemaDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
end

function VehicleSchemaDisplay:lateSetDocked(isDocked)
	self.isDocked = isDocked
end

function VehicleSchemaDisplay:setDocked(isDocked, animate)
	local targetX, targetY = VehicleSchemaDisplay.getBackgroundPosition(isDocked, self:getScale())

	if animate and self.animation:getFinished() then
		local startX, startY = self:getPosition()

		self:animateDocking(startX, startY, targetX, targetY, isDocked)
	else
		self.animation:stop()

		self.isDocked = isDocked

		self:setPosition(targetX, targetY)
	end
end

function VehicleSchemaDisplay:draw()
	if self.vehicle ~= nil then
		VehicleSchemaDisplay:superClass().draw(self)
		self:drawVehicleSchemaOverlays(self.vehicle)
	end
end

function VehicleSchemaDisplay:animateDocking(startX, startY, targetX, targetY, isDocking)
	local sequence = TweenSequence.new(self)
	local lateDockInstant = HUDDisplayElement.MOVE_ANIMATION_DURATION * 0.5

	if not isDocking then
		sequence:addInterval(HUDDisplayElement.MOVE_ANIMATION_DURATION)

		lateDockInstant = lateDockInstant + HUDDisplayElement.MOVE_ANIMATION_DURATION
	end

	sequence:addTween(MultiValueTween.new(self.setPosition, {
		startX,
		startY
	}, {
		targetX,
		targetY
	}, HUDDisplayElement.MOVE_ANIMATION_DURATION))
	sequence:insertCallback(self.lateSetDocked, isDocking, lateDockInstant)
	sequence:start()

	self.animation = sequence
end

function VehicleSchemaDisplay:collectVehicleSchemaDisplayOverlays(overlays, depth, vehicle, rootVehicle, parentOverlay, x, y, rotation, invertingX)
	if vehicle.getAttachedImplements == nil then
		return
	end

	local attachedImplements = vehicle:getAttachedImplements()

	for _, implement in pairs(attachedImplements) do
		local object = implement.object

		if object ~= nil and object.schemaOverlay ~= nil then
			local selected = object:getIsSelected()
			local turnedOn = object.getIsTurnedOn ~= nil and object:getIsTurnedOn()
			local jointDesc = vehicle.schemaOverlay.attacherJoints[implement.jointDescIndex]

			if jointDesc ~= nil then
				local invertX = invertingX ~= jointDesc.invertX
				local overlay = self:getSchemaOverlayForState(object.schemaOverlay, true)
				local baseY = y + jointDesc.y * parentOverlay.height
				local baseX = nil

				if invertX then
					baseX = x + jointDesc.x * parentOverlay.width
				else
					baseX = x - overlay.width + (1 - jointDesc.x) * parentOverlay.width
				end

				local rot = rotation + jointDesc.rotation
				local offsetX, offsetY = nil

				if invertX then
					offsetX = -object.schemaOverlay.offsetX * overlay.width
				else
					offsetX = object.schemaOverlay.offsetX * overlay.width
				end

				offsetY = object.schemaOverlay.offsetY * overlay.height
				local rotatedX = offsetX * math.cos(rot) - offsetY * math.sin(rot)
				local rotatedY = offsetX * math.sin(rot) + offsetY * math.cos(rot)
				baseX = baseX - rotatedX
				baseY = baseY - rotatedY
				local isLowered = object.getIsLowered ~= nil and object:getIsLowered(true)

				if not isLowered then
					local widthOffset, heightOffset = getNormalizedScreenValues(jointDesc.liftedOffsetX, jointDesc.liftedOffsetY)
					baseX = baseX + widthOffset
					baseY = baseY + heightOffset * 0.5
				end

				local additionalText = object:getAdditionalSchemaText()

				table.insert(overlays, {
					overlay = overlay,
					additionalText = additionalText,
					x = baseX,
					y = baseY,
					rotation = rot,
					invertX = not invertX,
					invisibleBorderRight = object.schemaOverlay.invisibleBorderRight,
					invisibleBorderLeft = object.schemaOverlay.invisibleBorderLeft,
					selected = selected,
					turnedOn = turnedOn
				})

				if depth <= VehicleSchemaDisplay.MAX_SCHEMA_COLLECTION_DEPTH then
					self:collectVehicleSchemaDisplayOverlays(overlays, depth + 1, object, rootVehicle, overlay, baseX, baseY, rot, invertX)
				end
			end
		end
	end
end

function VehicleSchemaDisplay:getVehicleSchemaOverlays(vehicle)
	local overlay = self:getSchemaOverlayForState(vehicle.schemaOverlay, false)
	local additionalText = vehicle:getAdditionalSchemaText()
	local overlays = {}

	table.insert(overlays, {
		rotation = 0,
		y = 0,
		invertX = false,
		x = 0,
		overlay = overlay,
		additionalText = additionalText,
		invisibleBorderRight = vehicle.schemaOverlay.invisibleBorderRight,
		invisibleBorderLeft = vehicle.schemaOverlay.invisibleBorderLeft,
		turnedOn = vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn(),
		selected = vehicle:getIsSelected()
	})
	self:collectVehicleSchemaDisplayOverlays(overlays, 1, vehicle, vehicle, overlay, 0, 0, 0, false)

	return overlays, overlay.height
end

function VehicleSchemaDisplay:getSchemaDelimiters(overlayDescriptions)
	local minX = math.huge
	local maxX = -math.huge

	for _, overlayDesc in pairs(overlayDescriptions) do
		local overlay = overlayDesc.overlay
		local cosRot = math.cos(overlayDesc.rotation)
		local sinRot = math.sin(overlayDesc.rotation)
		local offX = overlayDesc.invisibleBorderLeft * overlay.width
		local dx = overlay.width + (overlayDesc.invisibleBorderRight + overlayDesc.invisibleBorderLeft) * overlay.width
		local dy = overlay.height
		local x = overlayDesc.x + offX * cosRot
		local dx2 = dx * cosRot
		local dx3 = -dy * sinRot
		local dx4 = dx2 + dx3
		maxX = math.max(maxX, x, x + dx2, x + dx3, x + dx4)
		minX = math.min(minX, x, x + dx2, x + dx3, x + dx4)
	end

	return minX, maxX
end

function VehicleSchemaDisplay:drawVehicleSchemaOverlays(vehicle)
	vehicle = vehicle.rootVehicle

	if vehicle.schemaOverlay ~= nil then
		local overlays, overlayHeight = self:getVehicleSchemaOverlays(vehicle)
		local x, y = self:getPosition()
		local baseX = x
		local baseY = y
		baseY = baseY + (self:getHeight() - overlayHeight) * 0.5

		if self.isDocked then
			baseX = baseX + self:getWidth()
		end

		local minX, maxX = self:getSchemaDelimiters(overlays)
		local scale = 1
		local sizeX = maxX - minX

		if self.maxSchemaWidth < sizeX then
			scale = self.maxSchemaWidth / sizeX
		end

		local _, h = getNormalizedScreenValues(unpack(VehicleSchemaDisplay.SIZE.SELF))
		local barOffsetX = self:updateBarComponents(baseX, y, sizeX, h * self.uiScale, self.isDocked)

		self.overlayFront:render()
		self.overlayMiddle:render()
		self.overlayBack:render()

		local newPosX = baseX

		if self.isDocked then
			newPosX = newPosX - maxX * scale - barOffsetX
		else
			newPosX = newPosX - minX * scale + barOffsetX
		end

		for _, overlayDesc in pairs(overlays) do
			local overlay = overlayDesc.overlay
			local width = overlay.width
			local height = overlay.height

			overlay:setInvertX(overlayDesc.invertX)
			overlay:setPosition(newPosX + overlayDesc.x, baseY + overlayDesc.y)
			overlay:setRotation(overlayDesc.rotation, 0, 0)
			overlay:setDimension(width * scale, height * scale)

			local color = overlayDesc.turnedOn and VehicleSchemaDisplay.COLOR.TURNED_ON or VehicleSchemaDisplay.COLOR.DEFAULT

			overlay:setColor(color[1], color[2], color[3], overlayDesc.selected and 1 or 0.5)
			overlay:render()

			if overlayDesc.additionalText ~= nil then
				local posX = newPosX + overlayDesc.x + width * scale * 0.5
				local posY = baseY + overlayDesc.y + height * scale * 0.85

				setTextBold(false)
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(posX, posY, getCorrectTextSize(0.008), overlayDesc.additionalText)
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextColor(1, 1, 1, 1)
			end

			overlay:setDimension(width, height)
		end
	end
end

function VehicleSchemaDisplay:getSchemaOverlayForState(schemaOverlayData, isImplement, iconOverride)
	local schemaName = nil
	schemaName = schemaOverlayData.schemaName

	if schemaName == "DEFAULT_IMPLEMENT" then
		schemaName = "IMPLEMENT"
	elseif schemaName == "DEFAULT_VEHICLE" then
		schemaName = "VEHICLE"
	end

	if not schemaName or schemaName == "" or self.vehicleSchemaOverlays[schemaName] == nil then
		schemaName = isImplement and VehicleSchemaOverlayData.SCHEMA_OVERLAY.IMPLEMENT or VehicleSchemaOverlayData.SCHEMA_OVERLAY.VEHICLE
	end

	return self.vehicleSchemaOverlays[schemaName]
end

function VehicleSchemaDisplay:setScale(uiScale)
	VehicleSchemaDisplay:superClass().setScale(self, uiScale, uiScale)

	local posX, posY = VehicleSchemaDisplay.getBackgroundPosition(self.isDocked, uiScale)

	self:setPosition(posX, posY)
	self:storeScaledValues()

	self.uiScale = uiScale
end

function VehicleSchemaDisplay:storeScaledValues()
	self.iconSizeX, self.iconSizeY = self:scalePixelToScreenVector(VehicleSchemaDisplay.SIZE.ICON)
	self.maxSchemaWidth = self:scalePixelToScreenWidth(VehicleSchemaDisplay.MAX_SCHEMA_WIDTH)

	for _, overlay in pairs(self.vehicleSchemaOverlays) do
		overlay:resetDimensions()

		local pixelSize = {
			overlay.defaultWidth,
			overlay.defaultHeight
		}
		local width, height = self:scalePixelToScreenVector(pixelSize)

		overlay:setDimension(width, height)
	end
end

function VehicleSchemaDisplay.getBackgroundPosition(isDocked, uiScale)
	local width, height = getNormalizedScreenValues(unpack(VehicleSchemaDisplay.SIZE.SELF))
	local posX = g_safeFrameOffsetX
	local posY = 1 - g_safeFrameOffsetY - height * uiScale

	if isDocked then
		local offX, offY = getNormalizedScreenValues(unpack(VehicleSchemaDisplay.POSITION.SELF_DOCKED))
		posX = posX + (offX - width) * uiScale
		posY = posY + offY * uiScale
	end

	return posX, posY
end

function VehicleSchemaDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(VehicleSchemaDisplay.SIZE.SELF))
	local posX, posY = VehicleSchemaDisplay.getBackgroundPosition(false, 1)

	return Overlay.new(nil, posX, posY, width, height)
end

function VehicleSchemaDisplay:createBackgroundBar()
	local width, height = getNormalizedScreenValues(unpack(VehicleSchemaDisplay.SIZE.SELF))
	self.overlayFront = Overlay.new(g_baseHUDFilename, 0, 0, width, height)

	self.overlayFront:setUVs(GuiUtils.getUVs(VehicleSchemaDisplay.UV.FRONT))
	self.overlayFront:setColor(unpack(VehicleSchemaDisplay.COLOR.BACKGROUND))

	self.overlayMiddle = Overlay.new(g_baseHUDFilename, 0, 0, width, height)

	self.overlayMiddle:setUVs(GuiUtils.getUVs(VehicleSchemaDisplay.UV.MIDDLE))
	self.overlayMiddle:setColor(unpack(VehicleSchemaDisplay.COLOR.BACKGROUND))

	self.overlayBack = Overlay.new(g_baseHUDFilename, 0, 0, width, height)

	self.overlayBack:setUVs(GuiUtils.getUVs(VehicleSchemaDisplay.UV.BACK))
	self.overlayBack:setColor(unpack(VehicleSchemaDisplay.COLOR.BACKGROUND))
end

function VehicleSchemaDisplay:updateBarComponents(x, y, width, height, isDocked)
	local endUVs = VehicleSchemaDisplay.UV.FRONT
	local endSizeX, endSizeY = getNormalizedScreenValues(endUVs[3], endUVs[4])
	local endWidth = endSizeX / endSizeY * height

	if isDocked then
		x = x - endWidth * 2 - width
	end

	self.overlayFront:setDimension(endWidth, height)
	self.overlayFront:setPosition(x, y)
	self.overlayMiddle:setDimension(width, height)
	self.overlayMiddle:setPosition(x + endWidth, y)
	self.overlayBack:setDimension(endWidth, height)
	self.overlayBack:setPosition(x + width + endWidth, y)

	return endWidth
end

VehicleSchemaDisplay.MAX_SCHEMA_WIDTH = 180
VehicleSchemaDisplay.SIZE = {
	SELF = {
		VehicleSchemaDisplay.MAX_SCHEMA_WIDTH,
		30
	},
	ICON = {
		26,
		26
	}
}
VehicleSchemaDisplay.COLOR = {
	TURNED_ON = {
		0.0003,
		0.5647,
		0.9822
	},
	DEFAULT = {
		1,
		1,
		1
	},
	BACKGROUND = {
		0,
		0,
		0,
		0.75
	}
}
VehicleSchemaDisplay.POSITION = {
	SELF_DOCKED = {
		InputHelpDisplay.POSITION.FRAME[1] + InputHelpDisplay.SIZE.HEADER[1],
		0
	}
}
VehicleSchemaDisplay.UV = {
	FRONT = {
		377,
		296,
		13,
		27
	},
	MIDDLE = {
		400,
		296,
		1,
		27
	},
	BACK = {
		459,
		296,
		13,
		27
	}
}
