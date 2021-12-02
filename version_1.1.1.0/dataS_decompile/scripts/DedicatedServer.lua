DedicatedServer = {
	PAUSE_MODE_NO = 1,
	PAUSE_MODE_INSTANT = 2,
	MIN_FRAME_LIMIT = 5,
	MAX_FRAME_LIMIT = 60
}
local DedicatedServer_mt = Class(DedicatedServer)
local localSetFramerateLimiter = setFramerateLimiter
setFramerateLimiter = nil

function DedicatedServer.new(customMt)
	local self = setmetatable({}, customMt or DedicatedServer_mt)
	self.filename = ""
	self.name = "Farming Simulator Dedicated Game"
	self.password = ""
	self.savegame = 1
	self.maxPlayer = g_serverMaxCapacity
	self.ip = ""
	self.port = 10823
	self.useUpnp = true
	self.crossplayAllowed = true
	self.difficulty = 1
	self.mapName = ""
	self.mapFileName = ""
	self.adminPassword = ""
	self.pauseGameIfEmpty = true
	self.mpLanguageCode = "en"
	self.autoSaveInterval = 0
	self.gameStatsInterval = 60
	self.mods = {}
	self.gameStatsPath = nil

	return self
end

function DedicatedServer:load(filename)
	local xmlFile = XMLFile.load("DedicatedServerConfig", filename)

	if xmlFile ~= nil then
		local xmlKey = "gameserver.settings"
		self.filename = filename
		self.name = xmlFile:getString(xmlKey .. ".game_name", self.name)
		self.password = xmlFile:getString(xmlKey .. ".game_password", self.password)
		self.savegame = MathUtil.clamp(xmlFile:getInt(xmlKey .. ".savegame_index", self.savegame), 1, SavegameController.NUM_SAVEGAMES)
		self.maxPlayer = MathUtil.clamp(xmlFile:getInt(xmlKey .. ".max_player", self.maxPlayer), g_serverMinCapacity, g_serverMaxCapacity)
		self.ip = xmlFile:getString(xmlKey .. ".ip", self.ip)
		self.port = xmlFile:getInt(xmlKey .. ".port", self.port)
		self.useUpnp = xmlFile:getBool(xmlKey .. ".use_upnp", self.useUpnp)
		self.crossplayAllowed = xmlFile:getBool(xmlKey .. ".crossplay_allowed", self.crossplayAllowed)
		self.difficulty = MathUtil.clamp(xmlFile:getInt(xmlKey .. ".difficulty", self.difficulty), 1, 3)
		self.mapName = xmlFile:getString(xmlKey .. ".mapID", self.mapName)
		self.mapFileName = xmlFile:getString(xmlKey .. ".mapFilename", self.mapFileName)
		self.adminPassword = xmlFile:getString(xmlKey .. ".admin_password", self.adminPassword)

		if self.adminPassword == "" then
			Logging.info("Starting dedicated server without an admin password!")
		end

		self.mpLanguageCode = xmlFile:getString(xmlKey .. ".language", self.mpLanguageCode)
		self.pauseGameIfEmpty = xmlFile:getInt(xmlKey .. ".pause_game_if_empty", DedicatedServer.PAUSE_MODE_INSTANT) == DedicatedServer.PAUSE_MODE_INSTANT
		self.autoSaveInterval = MathUtil.clamp(xmlFile:getInt(xmlKey .. ".auto_save_interval", self.autoSaveInterval), 0, 360)
		self.gameStatsInterval = math.max(xmlFile:getInt(xmlKey .. ".stats_interval", self.gameStatsInterval), 10)

		xmlFile:iterate("gameserver.mods.mod", function (_, modKey)
			local modFilename = xmlFile:getString(modKey .. "#filename")
			local modIsDLC = xmlFile:getBool(modKey .. "#isDlc")

			if modIsDLC and g_dlcModNameHasPrefix[modFilename] then
				modFilename = g_uniqueDlcNamePrefix .. modFilename
			end

			table.insert(self.mods, modFilename)
		end)
		xmlFile:delete()
	end

	self.gameStatsInterval = self.gameStatsInterval * 1000

	if string.endsWith(self.mapFileName, ".dlc") and not string.startsWith(self.mapFileName, "pdlc_") then
		self.mapFileName = "pdlc_" .. self.mapFileName
	end

	local numL = getNumOfLanguages()

	for languageIndex = 0, numL - 1 do
		if getLanguageCode(languageIndex) == self.mpLanguageCode then
			g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, languageIndex)

			break
		end
	end
end

function DedicatedServer:lowerFramerate()
	localSetFramerateLimiter(true, DedicatedServer.MIN_FRAME_LIMIT)
end

function DedicatedServer:raiseFramerate()
	localSetFramerateLimiter(true, DedicatedServer.MAX_FRAME_LIMIT)
end

function DedicatedServer:updateServerInfo(serverName, password, capacity)
	if self.filename ~= nil then
		local xmlFile = XMLFile.load("DedicatedServerConfig", self.filename)
		local xmlKey = "gameserver.settings"

		xmlFile:setString(xmlKey .. ".game_name", serverName)
		xmlFile:setString(xmlKey .. ".game_password", password)
		xmlFile:setInt(xmlKey .. ".max_player", capacity)
		xmlFile:save()
		xmlFile:delete()
	end
end

function DedicatedServer:start()
	g_gui:setIsMultiplayer(true)
	g_gui:showGui("CareerScreen")
	g_gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, "Server")
end

function DedicatedServer:setGameStatsPath(path)
	self.gameStatsPath = path
end
