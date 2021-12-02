GameplayHintManager = {}
local GameplayHintManager_mt = Class(GameplayHintManager, AbstractManager)

function GameplayHintManager.new(customMt)
	local self = AbstractManager.new(customMt or GameplayHintManager_mt)

	return self
end

function GameplayHintManager:initDataStructures()
	self.gameplayHints = {}
	self.isLoaded = false
end

function GameplayHintManager:loadMapData(xmlFile, missionInfo)
	GameplayHintManager:superClass().loadMapData(self)

	local filename = Utils.getFilename(getXMLString(xmlFile, "map.gameplayHints#filename"), g_currentMission.baseDirectory)

	if filename == nil or filename == "" then
		print("Error: Could not load gameplayHint config file '" .. tostring(filename) .. "'!")

		return false
	end

	local gameplayHintXmlFile = loadXMLFile("gameplayHints", filename)
	local i = 0

	while true do
		local key = string.format("gameplayHints.gameplayHint(%d)", i)

		if not hasXMLProperty(gameplayHintXmlFile, key) then
			break
		end

		local text = getXMLString(gameplayHintXmlFile, key)

		if text:sub(1, 6) == "$l10n_" then
			text = g_i18n:getText(text:sub(7), missionInfo.customEnvironment)
		end

		table.insert(self.gameplayHints, text)

		i = i + 1
	end

	delete(gameplayHintXmlFile)

	self.isLoaded = true

	return true
end

function GameplayHintManager:getRandomGameplayHint(numberOfHints)
	local hints = {}
	local addedHints = {}

	if numberOfHints >= #self.gameplayHints then
		return self.gameplayHints
	end

	local numHints = #self.gameplayHints

	while numberOfHints > #hints do
		local hintId = math.random(1, numHints)

		if addedHints[hintId] == nil then
			table.insert(hints, self.gameplayHints[hintId])

			addedHints[hintId] = hintId
		end
	end

	return hints
end

function GameplayHintManager:getIsLoaded()
	return self.isLoaded
end

g_gameplayHintManager = GameplayHintManager.new()
