PlayerHotspot = {
	FILE_RESOLUTION = {
		1024,
		512
	}
}
PlayerHotspot.UVS = GuiUtils.getUVs({
	4,
	4,
	100,
	100
}, PlayerHotspot.FILE_RESOLUTION)
PlayerHotspot.FILENAME = "dataS/menu/hud/mapHotspots.png"
local PlayerHotspot_mt = Class(PlayerHotspot, MapHotspot)

function PlayerHotspot.new(customMt)
	local self = MapHotspot.new(customMt or PlayerHotspot_mt)
	self.width, self.height = getNormalizedScreenValues(60, 60)
	self.color = {
		1,
		1,
		1,
		1
	}
	self.icon = Overlay.new(PlayerHotspot.FILENAME, 0, 0, self.width, self.height)

	self.icon:setUVs(PlayerHotspot.UVS)
	self.icon:setColor(unpack(self.color))

	self.vehicle = nil
	self.player = nil
	self.isBlinking = true
	self.clickArea = MapHotspot.getClickArea({
		32,
		40,
		36,
		46
	}, {
		100,
		100
	}, 0)

	return self
end

function PlayerHotspot:delete()
	PlayerHotspot:superClass().delete(self)

	self.vehicle = nil
	self.player = nil
end

function PlayerHotspot:getRenderLast()
	return true
end

function PlayerHotspot:getCategory()
	return MapHotspot.CATEGORY_PLAYER
end

function PlayerHotspot:getWorldPosition()
	local x, _, z = nil

	if self.vehicle ~= nil then
		x, _, z = getWorldTranslation(self.vehicle.rootNode)
	elseif self.player ~= nil then
		x, _, z, _ = self.player:getPositionData()
	end

	return x, z
end

function PlayerHotspot:getWorldRotation()
	if self.vehicle ~= nil then
		local dx, _, dz = localDirectionToWorld(self.vehicle.rootNode, 0, 0, 1)

		return MathUtil.getYRotationFromDirection(dx, dz) + math.pi
	elseif self.player ~= nil then
		local _, _, _, rot = self.player:getPositionData()

		return rot
	end

	return 0
end

function PlayerHotspot:setVehicle(vehicle)
	self.vehicle = vehicle
end

function PlayerHotspot:getVehicle()
	return self.vehicle
end

function PlayerHotspot:setPlayer(player)
	self.player = player
end

function PlayerHotspot:getPlayer()
	return self.player
end

function PlayerHotspot:getColor()
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		local farm = g_farmManager:getFarmById(self.ownerFarmId)

		if farm ~= nil then
			local color = Farm.COLORS[farm.color]

			if color ~= nil then
				return color
			end
		end
	end

	return self.color
end

function PlayerHotspot:getCanBlink()
	return self.lastScreenLayout:getBlinkPlayerArrow() and self.player == g_currentMission.player
end
