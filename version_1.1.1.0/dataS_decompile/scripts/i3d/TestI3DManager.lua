TestI3DManager = {
	init = function ()
		local self = TestI3DManager
		self.file = "data/vehicles/fendt/vario900/vario900.i3d"
		self.sharedLoadRequestIds = {}
	end,
	update = function (dt)
		local self = TestI3DManager

		g_i3DManager:update(dt)
	end,
	draw = function ()
		local self = TestI3DManager
	end,
	mouseEvent = function (posX, posY, isDown, isUp, button)
	end,
	keyEvent = function (unicode, sym, modifier, isDown)
		if not isDown then
			local self = TestI3DManager

			if sym == Input.KEY_m then
				local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.file, false, false, self.finishedLoading, TestI3DManager, {
					file = self.file
				}, 1000)

				table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
			elseif sym == Input.KEY_n then
				local sharedLoadRequestId = table.remove(self.sharedLoadRequestIds, 1)

				if sharedLoadRequestId ~= nil then
					g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
				end
			elseif sym == Input.KEY_q then
				restartApplication(false, "")
			end
		end
	end,
	finishedLoading = function (_, nodeId, failedReason, args)
		local self = TestI3DManager

		log("loaded", getName(nodeId))
		delete(nodeId)
	end
}
