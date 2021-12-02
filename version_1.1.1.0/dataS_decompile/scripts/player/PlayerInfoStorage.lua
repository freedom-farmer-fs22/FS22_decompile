PlayerInfoStorage = {}
local PlayerInfoStorage_mt = Class(PlayerInfoStorage)

function PlayerInfoStorage.new(isServer, userManager, customMt)
	local self = setmetatable({}, customMt or PlayerInfoStorage_mt)
	self.isServer = isServer
	self.userManager = userManager
	self.players = {}
	self.playerByUniqueUserId = {}

	return self
end

function PlayerInfoStorage:delete()
end

function PlayerInfoStorage:loadFromXMLFile(xmlFilename)
	local xmlFile = XMLFile.load("TempXML", xmlFilename)

	if xmlFile == nil then
		return false
	end

	xmlFile:iterate("players.player", function (index, key)
		local player = {
			uniqueUserId = xmlFile:getString(key .. "#uniqueUserId"),
			playerStyle = PlayerStyle.new()
		}

		player.playerStyle:loadFromXMLFile(xmlFile, key .. ".style")
		table.insert(self.players, player)

		self.playerByUniqueUserId[player.uniqueUserId] = player
	end)
	xmlFile:delete()
end

function PlayerInfoStorage:saveToXMLFile(xmlFilename)
	local xmlFile = XMLFile.create("TempXML", xmlFilename, "players")

	if xmlFile == nil then
		return false
	end

	for i, player in ipairs(self.players) do
		local key = string.format("players.player(%d)", i - 1)

		xmlFile:setString(key .. "#uniqueUserId", player.uniqueUserId)
		player.playerStyle:saveToXMLFile(xmlFile, key .. ".style")
	end

	xmlFile:save()
	xmlFile:delete()
end

function PlayerInfoStorage:addNewPlayer(uniqueUserId, style)
	if self:hasPlayerWithUniqueUserId(uniqueUserId) then
		return
	end

	local player = {
		uniqueUserId = uniqueUserId,
		playerStyle = PlayerStyle.new()
	}

	player.playerStyle:copyMinimalFrom(style)
	table.insert(self.players, player)

	self.playerByUniqueUserId[uniqueUserId] = player
end

function PlayerInfoStorage:hasPlayerWithUniqueUserId(uniqueUserId)
	return self.playerByUniqueUserId[uniqueUserId] ~= nil
end

function PlayerInfoStorage:getPlayerStyle(userId)
	local uuid = self.userManager:getUniqueUserIdByUserId(userId)

	if uuid ~= nil and self.playerByUniqueUserId[uuid] ~= nil then
		local playerStyle = PlayerStyle.new()

		playerStyle:copyMinimalFrom(self.playerByUniqueUserId[uuid].playerStyle)

		return playerStyle
	end

	return PlayerStyle.defaultStyle()
end

function PlayerInfoStorage:setPlayerStyle(userId, style)
	local uuid = self.userManager:getUniqueUserIdByUserId(userId)

	if uuid ~= nil then
		self.playerByUniqueUserId[uuid].playerStyle:copyFrom(style)
	end
end
