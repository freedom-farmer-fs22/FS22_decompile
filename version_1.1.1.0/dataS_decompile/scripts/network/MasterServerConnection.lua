MasterServerConnection = {
	FAILED_NONE = 0,
	FAILED_UNKNOWN = 1,
	FAILED_WRONG_VERSION = 2,
	FAILED_MAINTENANCE = 3,
	FAILED_TEMPORARY_BAN = 4,
	FAILED_PERMANENT_BAN = 5,
	FAILED_CONNECTION_LOST = 6,
	FAILED_TEMPORARY_BAN_INVALID_MODS = 7,
	FAILED_CONSOLE_USER_FAILED_AUTHENTICATION = 8,
	FAILED_WRONG_PASSWORD = 11
}
local MasterServerConnection_mt = Class(MasterServerConnection)

function MasterServerConnection.new()
	local self = {}

	setmetatable(self, MasterServerConnection_mt)

	self.lastBackServerIndex = -1
	self.isInit = false

	return self
end

function MasterServerConnection:setCallbackTarget(target)
	self.masterServerCallbackTarget = target
end

function MasterServerConnection:onMasterServerList(name, id)
	self.masterServerCallbackTarget:onMasterServerList(name, id)
end

function MasterServerConnection:onMasterServerListStart(numMasterServers)
	self.masterServerCallbackTarget:onMasterServerListStart(numMasterServers)
end

function MasterServerConnection:onMasterServerListEnd()
	self.masterServerCallbackTarget:onMasterServerListEnd()
end

function MasterServerConnection:onConnectionReady()
	self.masterServerCallbackTarget:onMasterServerConnectionReady()
end

function MasterServerConnection:onConnectionFailed(reason)
	self.masterServerCallbackTarget:onMasterServerConnectionFailed(reason)
end

function MasterServerConnection:onServerInfo(id, name, language, capacity, numPlayers, mapName, hasPassword, allModsAvailable, isLanServer, isFriendServer, allowCrossPlay, platformId)
	if self.masterServerCallbackTarget.onServerInfo ~= nil then
		self.masterServerCallbackTarget:onServerInfo(id, name, language, capacity, numPlayers, mapName, hasPassword, allModsAvailable, isLanServer, isFriendServer, allowCrossPlay, platformId)
	else
		Logging.devWarning("Warning: Callback target is missing onServerInfo")
	end
end

function MasterServerConnection:onServerInfoStart(numServers, totalNumServers)
	if self.masterServerCallbackTarget.onServerInfoStart ~= nil then
		self.masterServerCallbackTarget:onServerInfoStart(numServers, totalNumServers)
	else
		Logging.devWarning("Warning: Callback target is missing onServerInfoStart")
	end
end

function MasterServerConnection:onServerInfoEnd()
	if self.masterServerCallbackTarget.onServerInfoEnd ~= nil then
		self.masterServerCallbackTarget:onServerInfoEnd()
	else
		Logging.devWarning("Warning: Callback target is missing onServerInfoEnd")
	end
end

function MasterServerConnection:onServerInfoDetails(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, allowCrossPlay, platformId, password)
	if self.masterServerCallbackTarget.onServerInfoDetails ~= nil then
		self.masterServerCallbackTarget:onServerInfoDetails(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, allowCrossPlay, platformId, password)
	else
		Logging.devWarning("Warning: Callback target is missing onServerInfoDetails")
	end
end

function MasterServerConnection:onServerInfoDetailsFailed()
	if self.masterServerCallbackTarget.onServerInfoDetailsFailed ~= nil then
		self.masterServerCallbackTarget:onServerInfoDetailsFailed()
	else
		Logging.devWarning("Warning: Callback target is missing onServerInfoDetailsFailed")
	end
end

function MasterServerConnection:init()
	if not self.isInit and not GS_IS_MOBILE_VERSION then
		masterServerInit(g_gameVersion, g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE))
		masterServerAddDlcStart()

		for _, mod in ipairs(g_modManager:getMultiplayerMods()) do
			if string.endsWith(mod.modFile, "dlcDesc.xml") then
				masterServerAddDlc(mod.modFile)
			end
		end

		masterServerAddDlcEnd()
		masterServerSetCallbacks("onMasterServerList", "onMasterServerListStart", "onMasterServerListEnd", "onConnectionReady", "onConnectionFailed", "onServerInfo", "onServerInfoStart", "onServerInfoEnd", "onServerInfoDetails", "onServerInfoDetailsFailed", self)

		self.isInit = true
	end
end

function MasterServerConnection:connectToMasterServerFront()
	self:init()

	self.lastBackServerIndex = -1

	if not GS_IS_MOBILE_VERSION then
		masterServerConnectFront()
	end
end

function MasterServerConnection:connectToMasterServer(index)
	self:init()

	self.lastBackServerIndex = index

	if not GS_IS_MOBILE_VERSION then
		masterServerConnectBack(index)
	end
end

function MasterServerConnection:disconnectFromMasterServer()
	if not GS_IS_MOBILE_VERSION then
		masterServerDisconnect()
	end

	self.isInit = false
end

function MasterServerConnection:reconnectToMasterServer()
	if not GS_IS_MOBILE_VERSION then
		masterServerReconnect()
	end
end
