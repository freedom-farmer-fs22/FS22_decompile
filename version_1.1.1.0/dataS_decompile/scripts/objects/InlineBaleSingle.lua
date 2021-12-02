InlineBaleSingle = {}
local InlineBaleSingle_mt = Class(InlineBaleSingle, Bale)

InitStaticObjectClass(InlineBaleSingle, "InlineBaleSingle", ObjectIds.OBJECT_INLINE_BALE_SINGLE)

function InlineBaleSingle.new(isServer, isClient, customMt)
	local self = Bale.new(isServer, isClient, customMt or InlineBaleSingle_mt)

	registerObjectClassName(self, "InlineBaleSingle")

	self.connectedInlineBale = nil

	return self
end

function InlineBaleSingle:getBaleSupportsBaleLoader()
	return false
end

function InlineBaleSingle:getCanBeOpened()
	return false
end

function InlineBaleSingle:setConnectedInlineBale(inlineBale)
	self.connectedInlineBale = inlineBale
end

function InlineBaleSingle:getConnectedInlineBale()
	return self.connectedInlineBale
end

function InlineBaleSingle:setConnector(connectedBale, filename, axis, offset)
	filename = NetworkUtil.convertFromNetworkFilename(filename)
	local rootNode, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(filename, false, false)

	if rootNode == 0 then
		return false
	end

	local startNode = getChildAt(rootNode, 0)
	local endNode = getChildAt(rootNode, 1)
	local skinnedMesh = getChildAt(rootNode, 2)

	link(connectedBale.nodeId, endNode)
	link(self.nodeId, startNode)
	link(self.nodeId, skinnedMesh)

	local translation = {
		0,
		0,
		0,
		[axis] = offset
	}

	setTranslation(startNode, unpack(translation))

	translation[axis] = -offset

	setTranslation(endNode, unpack(translation))
	delete(rootNode)

	self.inlineConnector = {
		isDirty = true,
		filename = filename,
		sharedLoadRequestId = sharedLoadRequestId,
		mesh = skinnedMesh,
		joint1 = startNode,
		joint2 = endNode
	}

	setVisibility(skinnedMesh, self.wrappingState > 0)

	if getHasShaderParameter(skinnedMesh, "colorMat0") then
		local r, g, b, _ = unpack(connectedBale.wrappingColor)
		local _, _, _, a = getShaderParameter(skinnedMesh, "colorMat0")

		setShaderParameter(skinnedMesh, "colorMat0", r, g, b, a, false)
	end

	if getHasShaderParameter(skinnedMesh, "RDT") then
		setShaderParameter(skinnedMesh, "RDT", 0, 0, 0, 0, false)
	end
end

function InlineBaleSingle:setConnectorVisibility(state)
	if self:getHasConnector() then
		setVisibility(self.inlineConnector.mesh, state)
	end
end

function InlineBaleSingle:getHasConnector()
	return self.inlineConnector ~= nil
end

function InlineBaleSingle:removeConnector()
	local connector = self.inlineConnector

	if connector ~= nil then
		if entityExists(connector.joint1) then
			delete(connector.joint1)
		end

		if entityExists(connector.joint2) then
			delete(connector.joint2)
		end

		if entityExists(connector.mesh) then
			delete(connector.mesh)
		end

		if connector.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(connector.sharedLoadRequestId)
		end

		self.inlineConnector = nil
	end
end

function InlineBaleSingle:setWrappingState(wrappingState, noEventSend)
	self:setConnectorVisibility(wrappingState > 0)
	InlineBaleSingle:superClass().setWrappingState(self, wrappingState, noEventSend)
end
