InGameMenuMapUtil = {
	CONTEXT_BOX_ORIENTATION = {
		TOP_RIGHT = "topRight",
		BOTTOM_LEFT = "bottomLeft",
		BOTTOM_RIGHT = "bottomRight",
		TOP_LEFT = "topLeft"
	}
}
InGameMenuMapUtil.CONTEXT_BOX_CORNER_PROFILE = {
	[InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT] = "ingameMenuMapContextCornerTopRight",
	[InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT] = "ingameMenuMapContextCornerBottomRight",
	[InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT] = "ingameMenuMapContextCornerBottomLeft",
	[InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT] = "ingameMenuMapContextCornerTopLeft"
}

function InGameMenuMapUtil.getContextBoxPositionAndOrientation(hotspot, contextBox)
	local posX, posY, _ = hotspot:getLastScreenPositionCenter()
	local outRight = posX + contextBox.size[1] > 1
	local outLeft = posX - contextBox.size[1] < 0
	local outTop = posY + contextBox.size[2] > 1
	local orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
	local rotation = 0

	if outRight then
		if outTop then
			orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
			rotation = math.pi
		else
			orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT
			rotation = math.pi * 0.5
		end
	elseif outLeft then
		if outTop then
			orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
			rotation = -math.pi * 0.5
		else
			orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_RIGHT
		end
	elseif outTop then
		orientation = InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT
		rotation = -math.pi * 0.5
	end

	return posX, posY, orientation, rotation
end

function InGameMenuMapUtil.updateContextBoxPosition(contextBox, hotspot)
	if contextBox ~= nil and contextBox:getIsVisible() and hotspot ~= nil then
		local posX, posY, orientation, _ = InGameMenuMapUtil.getContextBoxPositionAndOrientation(hotspot, contextBox)
		local goLeft = orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.TOP_LEFT or orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT
		local goDown = orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_LEFT or orientation == InGameMenuMapUtil.CONTEXT_BOX_ORIENTATION.BOTTOM_RIGHT

		if goLeft then
			posX = posX - contextBox.size[1]
		end

		if goDown then
			posY = posY - contextBox.size[2]

			contextBox:applyProfile(InGameMenuMapUtil.CONTEXT_BOX_TOP_FRAME_PROFILE)
		else
			contextBox:applyProfile(InGameMenuMapUtil.CONTEXT_BOX_BOTTOM_FRAME_PROFILE)
		end

		contextBox:setAbsolutePosition(posX, posY)

		local cornerProfile = InGameMenuMapUtil.CONTEXT_BOX_CORNER_PROFILE[orientation]
		local corner = contextBox:getDescendantByName("corner")

		corner:applyProfile(cornerProfile)
	end
end

function InGameMenuMapUtil.showContextBox(contextBox, hotspot, description, imageFilename, uvs, farmId)
	if contextBox ~= nil then
		contextBox:setVisible(true)

		local x, y = InGameMenuMapUtil.getContextBoxPositionAndOrientation(hotspot, contextBox)

		contextBox:setAbsolutePosition(x, y)
		contextBox:applyProfile("ingameMenuMapContextBoxSmall")

		local hasImage = imageFilename ~= nil and string.find(imageFilename, "data/store/store_empty") == nil
		local image = contextBox:getDescendantByName("image")

		image:setVisible(hasImage)

		if hasImage then
			contextBox:applyProfile("ingameMenuMapContextBox")
			image:setImageFilename(imageFilename)
			image:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(uvs))
		end

		local text = contextBox:getDescendantByName("text")

		text:setText(description)

		local farmElem = contextBox:getDescendantByName("farm")

		if farmId ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then
			local farm = g_farmManager:getFarmById(farmId)

			farmElem:setText(farm.name)
			farmElem:setTextColor(unpack(farm:getColor()))
		else
			farmElem:setText("")
		end
	end
end

function InGameMenuMapUtil.hideContextBox(contextBox)
	if contextBox ~= nil then
		contextBox:setVisible(false)
	end
end

function InGameMenuMapUtil.getHotspotVehicle(hotspot)
	if hotspot ~= nil and hotspot.getVehicle ~= nil then
		return hotspot:getVehicle()
	end

	return nil
end
