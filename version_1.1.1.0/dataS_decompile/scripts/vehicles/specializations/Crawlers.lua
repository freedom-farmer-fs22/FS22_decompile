Crawlers = {
	xmlSchema = nil,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Wheels, specializations)
	end
}

function Crawlers.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Crawlers")

	local crawlerKey = "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).crawlers.crawler(?)"

	schema:register(XMLValueType.NODE_INDEX, crawlerKey .. "#linkNode", "Link node")
	schema:register(XMLValueType.BOOL, crawlerKey .. "#isLeft", "Is left crawler", false)
	schema:register(XMLValueType.FLOAT, crawlerKey .. "#trackWidth", "Track width", 1)
	schema:register(XMLValueType.STRING, crawlerKey .. "#filename", "Crawler filename")
	schema:register(XMLValueType.VECTOR_TRANS, crawlerKey .. "#offset", "Crawler position offset")
	schema:register(XMLValueType.INT, crawlerKey .. "#wheelIndex", "Speed reference wheel index")
	schema:register(XMLValueType.VECTOR_N, crawlerKey .. "#wheelIndices", "Multiple speed reference wheels. The average speed of the wheels WITH ground contact is used")
	schema:register(XMLValueType.NODE_INDEX, crawlerKey .. "#speedReferenceNode", "Speed reference node")
	schema:register(XMLValueType.FLOAT, crawlerKey .. "#fieldDirtMultiplier", "Field dirt multiplier", 75)
	schema:register(XMLValueType.FLOAT, crawlerKey .. "#streetDirtMultiplier", "Street dirt multiplier", -150)
	schema:register(XMLValueType.FLOAT, crawlerKey .. "#minDirtPercentage", "Min. dirt while getting clean on non field ground", 0.35)
	schema:register(XMLValueType.FLOAT, crawlerKey .. "#maxDirtOffset", "Max. dirt amount offset to global dirt node", 0.5)
	schema:register(XMLValueType.FLOAT, crawlerKey .. "#dirtColorChangeSpeed", "Defines speed to change the dirt color (sec)", 20)
	schema:setXMLSpecializationType()

	local crawlerSchema = XMLSchema.new("crawler")

	crawlerSchema:shareDelayedRegistrationFuncs(schema)
	crawlerSchema:register(XMLValueType.STRING, "crawler.file#name", "Crawler i3d filename")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.file#leftNode", "Crawler left node in i3d")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.file#rightNode", "Crawler right node in i3d")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.scrollerNodes.scrollerNode(?)#node", "Scroller node")
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#scrollSpeed", "Scroll speed", 1)
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#scrollLength", "Scroll length", 1)
	crawlerSchema:register(XMLValueType.STRING, "crawler.scrollerNodes.scrollerNode(?)#shaderParameterName", "Shader parameter name", "offsetUV")
	crawlerSchema:register(XMLValueType.STRING, "crawler.scrollerNodes.scrollerNode(?)#shaderParameterNamePrev", "Shader parameter name (Prev)", "#shaderParameterName prefixed with 'prev'")
	crawlerSchema:register(XMLValueType.INT, "crawler.scrollerNodes.scrollerNode(?)#shaderParameterComponent", "Shader paramater component", 1)
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#maxSpeed", "Max. speed in m/s", "unlimited")
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.scrollerNodes.scrollerNode(?)#isTrackPart", "Is part of track (Track width is set as scale X)")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.rotatingParts.rotatingPart(?)#node", "Rotating node")
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.rotatingParts.rotatingPart(?)#radius", "Radius")
	crawlerSchema:register(XMLValueType.FLOAT, "crawler.rotatingParts.rotatingPart(?)#speedScale", "Speed scale")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.rimColorNodes.rimColorNode(?)#node", "Rim color node")
	crawlerSchema:register(XMLValueType.STRING, "crawler.rimColorNodes.rimColorNode(?)#shaderParameter", "Shader parameter to set")
	crawlerSchema:register(XMLValueType.NODE_INDEX, "crawler.dirtNodes.dirtNode(?)#node", "Nodes that act the same way as wheels and get dirty faster when on field. If not defined everything gets dirty faster.")
	crawlerSchema:register(XMLValueType.BOOL, "crawler.animations.animation(?)#isLeft", "Load for left crawler", false)
	AnimatedVehicle.registerAnimationXMLPaths(crawlerSchema, "crawler.animations.animation(?)")
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(crawlerSchema, "crawler")

	Crawlers.xmlSchema = crawlerSchema
end

function Crawlers.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCrawlerFromXML", Crawlers.loadCrawlerFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadCrawlerFromConfigFile", Crawlers.loadCrawlerFromConfigFile)
	SpecializationUtil.registerFunction(vehicleType, "onCrawlerI3DLoaded", Crawlers.onCrawlerI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "getCrawlerWheelMovedDistance", Crawlers.getCrawlerWheelMovedDistance)
end

function Crawlers.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", Crawlers.validateWashableNode)
end

function Crawlers.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Crawlers)
	SpecializationUtil.registerEventListener(vehicleType, "onWheelConfigurationChanged", Crawlers)
end

function Crawlers:onLoad(savegame)
	local spec = self.spec_crawlers
	local wheelConfigId = Utils.getNoNil(self.configurations.wheel, 1)
	local wheelKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", wheelConfigId - 1)
	spec.crawlers = {}
	spec.sharedLoadRequestIds = {}
	spec.xmlLoadingHandles = {}

	self.xmlFile:iterate(wheelKey .. ".crawlers.crawler", function (_, key)
		self:loadCrawlerFromXML(self.xmlFile, key)
	end)
end

function Crawlers:onLoadFinished(savegame)
	if #self.spec_crawlers.crawlers == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", Crawlers)
	end
end

function Crawlers:onDelete()
	local spec = self.spec_crawlers

	if spec.xmlLoadingHandles ~= nil then
		for xmlFile, _ in pairs(spec.xmlLoadingHandles) do
			xmlFile:delete()

			spec.xmlLoadingHandles[xmlFile] = nil
		end
	end

	if spec.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end

		spec.sharedLoadRequestIds = nil
	end
end

function Crawlers:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_crawlers

	for _, crawler in pairs(spec.crawlers) do
		crawler.movedDistance = 0

		if crawler.wheel ~= nil then
			crawler.movedDistance = self:getCrawlerWheelMovedDistance(crawler, "lastRotationScroll", false)
		else
			local newX, newY, newZ = getWorldTranslation(crawler.speedReferenceNode)

			if crawler.lastPosition == nil then
				crawler.lastPosition = {
					newX,
					newY,
					newZ
				}
			end

			local dx, dy, dz = worldDirectionToLocal(crawler.speedReferenceNode, newX - crawler.lastPosition[1], newY - crawler.lastPosition[2], newZ - crawler.lastPosition[3])
			local movingDirection = 0

			if dz > 0.0001 then
				movingDirection = 1
			elseif dz < -0.0001 then
				movingDirection = -1
			end

			crawler.movedDistance = MathUtil.vector3Length(dx, dy, dz) * movingDirection
			crawler.lastPosition[1] = newX
			crawler.lastPosition[2] = newY
			crawler.lastPosition[3] = newZ
		end

		for _, scrollerNode in pairs(crawler.scrollerNodes) do
			local movedDistance = crawler.movedDistance * scrollerNode.scrollSpeed
			local moveDirection = MathUtil.sign(movedDistance)
			movedDistance = math.min(math.abs(movedDistance), scrollerNode.maxSpeed) * moveDirection
			scrollerNode.scrollPosition = (scrollerNode.scrollPosition + movedDistance) % scrollerNode.scrollLength
			local x, y, z, w = getShaderParameter(scrollerNode.node, scrollerNode.shaderParameterName)

			if scrollerNode.shaderParameterComponent == 1 then
				x = scrollerNode.scrollPosition
			else
				y = scrollerNode.scrollPosition
			end

			if scrollerNode.shaderParameterNamePrev ~= nil then
				g_animationManager:setPrevShaderParameter(scrollerNode.node, scrollerNode.shaderParameterName, x, y, z, w, false, scrollerNode.shaderParameterNamePrev)
			else
				setShaderParameter(scrollerNode.node, scrollerNode.shaderParameterName, x, y, z, w, false)
			end
		end

		local rotationDifference = self:getCrawlerWheelMovedDistance(crawler, "lastRotationRot", true)

		for _, rotatingPart in pairs(crawler.rotatingParts) do
			if crawler.wheel ~= nil and rotatingPart.speedScale == nil then
				rotate(rotatingPart.node, rotationDifference, 0, 0)
			elseif rotatingPart.speedScale ~= nil then
				rotate(rotatingPart.node, rotatingPart.speedScale * crawler.movedDistance, 0, 0)
			end
		end
	end
end

function Crawlers:onWheelConfigurationChanged(lastConfigurationIndex, newConfigurationIndex)
	local spec = self.spec_crawlers

	for _, crawler in pairs(spec.crawlers) do
		local washableNode = self:getWashableNodeByCustomIndex(crawler)

		if washableNode ~= nil then
			self:setNodeDirtAmount(washableNode, 0, true)
		end
	end
end

function Crawlers:loadCrawlerFromXML(xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#crawlerIndex", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#length", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#shaderParameterComponent", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#shaderParameterName", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#scrollLength", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#scrollSpeed", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".rotatingPart", "Moved to external crawler config file")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#linkIndex", key .. "#linkNode")

	local linkNode = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)

	if linkNode == nil then
		Logging.xmlWarning(self.xmlFile, "Missing link node for crawler '%s'", key)

		return
	end

	local crawler = {
		linkNode = linkNode,
		isLeft = xmlFile:getValue(key .. "#isLeft", false),
		trackWidth = xmlFile:getValue(key .. "#trackWidth", 1)
	}
	local offset = xmlFile:getValue(key .. "#offset", nil, true)

	if offset ~= nil then
		setTranslation(crawler.loadedCrawler, unpack(offset))
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#speedRefWheel", key .. "#wheelIndex")

	local wheelIndex = xmlFile:getValue(key .. "#wheelIndex")
	local wheelIndices = xmlFile:getValue(key .. "#wheelIndices", nil, true)

	if wheelIndex ~= nil or wheelIndices ~= nil then
		wheelIndices = wheelIndices or {}

		table.insert(wheelIndices, wheelIndex)

		crawler.wheels = {}

		for i = 1, #wheelIndices do
			local index = wheelIndices[i]
			local wheels = self:getWheels()

			if wheels[index] ~= nil then
				wheels[index].syncContactState = true

				table.insert(crawler.wheels, {
					wheel = wheels[index]
				})

				if not wheels[index].isSynchronized then
					Logging.xmlWarning(self.xmlFile, "Wheel '%s' for crawler '%s' in not synchronized! It won't rotate on the client side.", index, key)
				end
			end
		end

		if #crawler.wheels > 0 then
			crawler.wheel = crawler.wheels[1].wheel
		end
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, key .. "#speedRefNode", key .. "#speedReferenceNode")

	crawler.speedReferenceNode = xmlFile:getValue(key .. "#speedReferenceNode", linkNode, self.components, self.i3dMappings)
	crawler.movedDistance = 0
	crawler.fieldDirtMultiplier = xmlFile:getValue(key .. "#fieldDirtMultiplier", 75)
	crawler.streetDirtMultiplier = xmlFile:getValue(key .. "#streetDirtMultiplier", -150)
	crawler.minDirtPercentage = xmlFile:getValue(key .. "#minDirtPercentage", 0.35)
	crawler.maxDirtOffset = xmlFile:getValue(key .. "#maxDirtOffset", 0.5)
	crawler.dirtColorChangeSpeed = 1 / (xmlFile:getValue(key .. "#dirtColorChangeSpeed", 20) * 1000)
	local filename = xmlFile:getValue(key .. "#filename")

	self:loadCrawlerFromConfigFile(crawler, filename, linkNode)
end

function Crawlers:loadCrawlerFromConfigFile(crawler, xmlFilename, linkNode)
	xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
	local xmlFile = XMLFile.load("crawlerXml", xmlFilename, Crawlers.xmlSchema)

	if xmlFile ~= nil then
		local filename = xmlFile:getValue("crawler.file#name")

		if filename ~= nil then
			local spec = self.spec_crawlers
			spec.xmlLoadingHandles[xmlFile] = true
			crawler.filename = Utils.getFilename(filename, self.baseDirectory)
			local sharedLoadRequestId = self:loadSubSharedI3DFile(crawler.filename, false, false, self.onCrawlerI3DLoaded, self, {
				xmlFile,
				crawler
			})

			table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
		else
			Logging.xmlWarning(xmlFile, "Failed to open crawler i3d file '%s' in '%s'", filename, xmlFilename)
			xmlFile:delete()
		end
	else
		Logging.xmlWarning(self.xmlFile, "Failed to open crawler config file '%s'", xmlFilename)
	end
end

function Crawlers:onCrawlerI3DLoaded(i3dNode, failedReason, args)
	local xmlFile, crawler = unpack(args)
	local spec = self.spec_crawlers

	if i3dNode ~= 0 then
		local leftRightKey = crawler.isLeft and "leftNode" or "rightNode"
		crawler.loadedCrawler = xmlFile:getValue("crawler.file#" .. leftRightKey, nil, i3dNode)

		if crawler.loadedCrawler ~= nil then
			link(crawler.linkNode, crawler.loadedCrawler)

			crawler.scrollerNodes = {}
			local j = 0

			while true do
				local key = string.format("crawler.scrollerNodes.scrollerNode(%d)", j)

				if not xmlFile:hasProperty(key) then
					break
				end

				local entry = {
					node = xmlFile:getValue(key .. "#node", nil, crawler.loadedCrawler)
				}

				if entry.node ~= nil then
					entry.scrollSpeed = xmlFile:getValue(key .. "#scrollSpeed", 1)
					entry.scrollLength = xmlFile:getValue(key .. "#scrollLength", 1)
					entry.shaderParameterName = xmlFile:getValue(key .. "#shaderParameterName", "offsetUV")
					entry.shaderParameterNamePrev = xmlFile:getValue(key .. "#shaderParameterNamePrev")

					if entry.shaderParameterNamePrev ~= nil then
						if not getHasShaderParameter(entry.node, entry.shaderParameterNamePrev) then
							Logging.xmlWarning(xmlFile, "Node '%s' has no shader parameter '%s' (prev) for crawler node '%s'!", getName(entry.node), entry.shaderParameterNamePrev, key)

							return nil
						end
					else
						local prevName = "prev" .. entry.shaderParameterName:sub(1, 1):upper() .. entry.shaderParameterName:sub(2)

						if getHasShaderParameter(entry.node, prevName) then
							entry.shaderParameterNamePrev = prevName
						end
					end

					entry.shaderParameterComponent = xmlFile:getValue(key .. "#shaderParameterComponent", 1)
					entry.maxSpeed = xmlFile:getValue(key .. "#maxSpeed", math.huge) / 1000
					entry.scrollPosition = 0

					if crawler.trackWidth ~= 1 and xmlFile:getValue(key .. "#isTrackPart", true) then
						setScale(entry.node, crawler.trackWidth, 1, 1)
					end

					table.insert(crawler.scrollerNodes, entry)
				end

				j = j + 1
			end

			crawler.rotatingParts = {}
			j = 0

			while true do
				local key = string.format("crawler.rotatingParts.rotatingPart(%d)", j)

				if not xmlFile:hasProperty(key) then
					break
				end

				local entry = {
					node = xmlFile:getValue(key .. "#node", nil, crawler.loadedCrawler)
				}

				if entry.node ~= nil then
					entry.radius = xmlFile:getValue(key .. "#radius")
					entry.speedScale = xmlFile:getValue(key .. "#speedScale")

					if entry.speedScale == nil and entry.radius ~= nil then
						entry.speedScale = 1 / entry.radius
					end

					table.insert(crawler.rotatingParts, entry)
				end

				j = j + 1
			end

			local function applyColor(name, color)
				j = 0

				while true do
					local key = string.format("crawler.%s.%s(%d)", name .. "s", name, j)

					if not xmlFile:hasProperty(key) then
						break
					end

					local node = xmlFile:getValue(key .. "#node", nil, crawler.loadedCrawler)

					if node ~= nil then
						local shaderParameter = xmlFile:getValue(key .. "#shaderParameter")

						if getHasShaderParameter(node, shaderParameter) then
							local r, g, b, mat = unpack(color)

							if mat == nil then
								local _ = nil
								_, _, _, mat = getShaderParameter(node, shaderParameter)
							end

							I3DUtil.setShaderParameterRec(node, shaderParameter, r, g, b, mat, true)
						else
							Logging.xmlWarning(xmlFile, "Missing shaderParameter '%s' on object '%s' in %s", shaderParameter, getName(node), key)
						end
					end

					j = j + 1
				end
			end

			crawler.hasDirtNodes = false
			crawler.dirtNodes = {}
			j = 0

			while true do
				local key = string.format("crawler.dirtNodes.dirtNode(%d)", j)

				if not xmlFile:hasProperty(key) then
					break
				end

				local node = xmlFile:getValue(key .. "#node", nil, crawler.loadedCrawler)

				if node ~= nil then
					crawler.dirtNodes[node] = node
					crawler.hasDirtNodes = true
				end

				j = j + 1
			end

			local rimColor = Utils.getNoNil(ConfigurationUtil.getColorByConfigId(self, "rimColor", self.configurations.rimColor), self.spec_wheels.rimColor)

			if rimColor ~= nil then
				crawler.rimColorNodes = applyColor("rimColorNode", rimColor)
			end

			crawler.objectChanges = {}

			ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, "crawler", crawler.objectChanges, crawler.loadedCrawler, self)
			ObjectChangeUtil.setObjectChanges(crawler.objectChanges, true)

			local i = 0

			while true do
				local key = string.format("crawler.animations.animation(%d)", i)

				if not xmlFile:hasProperty(key) then
					break
				end

				if crawler.isLeft == xmlFile:getValue(key .. "#isLeft", false) then
					local animation = {}

					if self:loadAnimation(xmlFile, key, animation, crawler.loadedCrawler) then
						self.spec_animatedVehicle.animations[animation.name] = animation
					end
				end

				i = i + 1
			end

			table.insert(self.spec_crawlers.crawlers, crawler)
		end

		delete(i3dNode)
	elseif not self.isDeleted and not self.isDeleting then
		Logging.xmlWarning(xmlFile, "Failed to find crawler in i3d file '%s'", crawler.filename)
	end

	xmlFile:delete()

	spec.xmlLoadingHandles[xmlFile] = nil
end

function Crawlers:getCrawlerWheelMovedDistance(crawler, lastName, useOnlyRotation)
	local minMovedDistance = math.huge
	local direction = 1

	for i = 1, #crawler.wheels do
		local wheelData = crawler.wheels[i]

		if wheelData.wheel.contact ~= Wheels.WHEEL_NO_CONTACT or #crawler.wheels == 1 then
			local newX, _, _ = getRotation(wheelData.wheel.driveNode)

			if wheelData[lastName] == nil then
				wheelData[lastName] = newX
			end

			local lastRotation = wheelData[lastName]

			if newX - lastRotation < -math.pi then
				lastRotation = lastRotation - 2 * math.pi
			elseif math.pi < newX - lastRotation then
				lastRotation = lastRotation + 2 * math.pi
			end

			local distance = wheelData.wheel.radius * (newX - lastRotation)

			if useOnlyRotation then
				distance = newX - lastRotation
			end

			if distance < 0 then
				if distance > -minMovedDistance then
					minMovedDistance = -distance
					direction = -1
				end
			elseif distance < minMovedDistance then
				minMovedDistance = distance
				direction = 1
			end

			wheelData[lastName] = newX
		end
	end

	if minMovedDistance ~= math.huge then
		return minMovedDistance * direction
	end

	return 0
end

function Crawlers:validateWashableNode(superFunc, node)
	local spec = self.spec_crawlers

	for _, crawler in pairs(spec.crawlers) do
		local crawlerNodes = crawler.dirtNodes

		if not crawler.hasDirtNodes then
			I3DUtil.getNodesByShaderParam(crawler.loadedCrawler, "RDT", crawlerNodes)
		end

		if crawlerNodes[node] ~= nil then
			local nodeData = {
				wheel = crawler.wheel,
				fieldDirtMultiplier = crawler.fieldDirtMultiplier,
				streetDirtMultiplier = crawler.streetDirtMultiplier,
				minDirtPercentage = crawler.minDirtPercentage,
				maxDirtOffset = crawler.maxDirtOffset,
				dirtColorChangeSpeed = crawler.dirtColorChangeSpeed,
				isSnowNode = true
			}

			function nodeData.loadFromSavegameFunc(xmlFile, key)
				nodeData.wheel.snowScale = xmlFile:getValue(key .. "#snowScale", 0)
				local defaultColor, snowColor = g_currentMission.environment:getDirtColors()
				local r, g, b = MathUtil.lerp3(defaultColor[1], defaultColor[2], defaultColor[3], snowColor[1], snowColor[2], snowColor[3], nodeData.wheel.snowScale)
				local washableNode = self:getWashableNodeByCustomIndex(crawler)

				self:setNodeDirtColor(washableNode, r, g, b, true)
			end

			function nodeData.saveToSavegameFunc(xmlFile, key)
				xmlFile:setValue(key .. "#snowScale", nodeData.wheel.snowScale)
			end

			return false, self.updateWheelDirtAmount, crawler, nodeData
		end
	end

	return superFunc(self, node)
end
