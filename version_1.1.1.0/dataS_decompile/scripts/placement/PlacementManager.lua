PlacementManager = {
	TEST_STEP_SIZE = 1,
	ASYNC_NUM_OVERLAPS_PER_TICK = 4,
	DEFAULT_COLLISION_MASK = CollisionFlag.VEHICLE + CollisionFlag.PLAYER + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.TREE + CollisionFlag.STATIC_OBJECT
}
local PlacementManager_mt = Class(PlacementManager)

function PlacementManager.new(customMt)
	local self = setmetatable({}, customMt or PlacementManager_mt)
	self.getPlaceQueue = {}
	self.currentPos = {
		posOffset = 0,
		placeIndex = 1
	}
	self.spaceIsFree = true
	self.noMoreSpaces = false

	return self
end

function PlacementManager:delete()
	g_currentMission:removeUpdateable(self)
end

function PlacementManager:getPlaceAsync(places, reqSpace, callback, callbackTarget, filterFunction)
	local task = FindPlaceTask.new(places, reqSpace, callback, callbackTarget, filterFunction)

	table.insert(self.getPlaceQueue, task)
	g_currentMission:addUpdateable(self)
end

function PlacementManager:update()
	if #self.getPlaceQueue > 0 then
		local findPlaceTask = self.getPlaceQueue[1]

		for _ = 1, PlacementManager.ASYNC_NUM_OVERLAPS_PER_TICK do
			local pos = findPlaceTask:getNextPosition()
			self.spaceIsFree = false

			if pos then
				self.spaceIsFree = true

				overlapBox(pos.x, pos.y + findPlaceTask.halfHeight, pos.z, pos.xRot, pos.yRot, pos.zRot, findPlaceTask.halfWidth, findPlaceTask.halfHeight, findPlaceTask.halfLength, "overlapBoxCallbackFuncFindPlace", self, PlacementManager.DEFAULT_COLLISION_MASK, true, true, true)
			else
				self.noMoreSpaces = true
			end

			if self.spaceIsFree or self.noMoreSpaces then
				if self.spaceIsFree then
					findPlaceTask.callback(findPlaceTask.callbackTarget, pos)
				else
					findPlaceTask.callback(findPlaceTask.callbackTarget, nil)
				end

				table.remove(self.getPlaceQueue, 1)

				self.noMoreSpaces = false
				self.spaceIsFree = false

				return
			end
		end
	else
		g_currentMission:removeUpdateable(self)
	end
end

function PlacementManager:overlapBoxCallbackFuncFindPlace(node)
	if node ~= 0 and node ~= g_currentMission.terrainRootNode then
		self.spaceIsFree = false

		return false
	end
end

function PlacementManager:consoleCommandTogglePlacementDebug()
	PlacementManager.debugEnabled = not PlacementManager.debugEnabled

	if not PlacementManager.debugEnabled then
		for _, debugElement in pairs(self.debugElements) do
			g_debugManager:removePermanentElement(debugElement)
		end
	end

	return "PlacementManager debug = " .. tostring(PlacementManager.debugEnabled)
end
