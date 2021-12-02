RotationAnimationSpikes = {}
local RotationAnimationSpikes_mt = Class(RotationAnimationSpikes, RotationAnimation)

function RotationAnimationSpikes.new(customMt)
	return RotationAnimation.new(customMt or RotationAnimationSpikes_mt)
end

function RotationAnimationSpikes:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if RotationAnimationSpikes:superClass().load(self, xmlFile, key, rootNodes, owner, i3dMapping) == nil then
		return nil
	end

	self.spikeMaxRot = xmlFile:getValue(key .. ".spikes#maxRot", 0)
	self.spikeRotAxis = xmlFile:getValue(key .. ".spikes#rotAxis", 3)
	local moveUpRange = xmlFile:getValue(key .. ".spikes#moveUpRange", nil, true)
	local moveDownRange = xmlFile:getValue(key .. ".spikes#moveDownRange", nil, true)
	self.moveUpStart = moveUpRange[1]
	self.moveUpEnd = moveUpRange[2]
	self.moveDownStart = moveDownRange[1]
	self.moveDownEnd = moveDownRange[2]
	self.spikes = {}

	xmlFile:iterate(key .. ".spikes.spike", function (index, spikeKey)
		local spike = {
			node = xmlFile:getValue(spikeKey .. "#node", nil, rootNodes, i3dMapping)
		}

		if spike.node ~= nil then
			spike.direction = xmlFile:getValue(spikeKey .. "#direction", 1)

			table.insert(self.spikes, spike)
		end
	end)

	self.rotOffset = 2 * math.pi / #self.spikes

	self:updateSpikes()

	return self
end

function RotationAnimationSpikes:update(dt)
	RotationAnimationSpikes:superClass().update(self, dt)

	if self.currentAlpha > 0 then
		self:updateSpikes()
	end
end

function RotationAnimationSpikes:updateSpikes()
	local currentRot = self.currentRot % (2 * math.pi)

	if self.rotSpeed < 0 then
		currentRot = math.abs(2 * math.pi - currentRot)
	end

	for i = 1, #self.spikes do
		local spike = self.spikes[i]
		local yRot = (currentRot - (i - 1) * self.rotOffset + 2 * math.pi) % (2 * math.pi)
		local alpha = 0

		if self.moveUpStart < yRot and yRot <= self.moveUpEnd then
			alpha = 1 - (self.moveUpEnd - yRot) / (self.moveUpEnd - self.moveUpStart)
		elseif self.moveDownStart < yRot and yRot <= self.moveDownEnd then
			alpha = (self.moveDownEnd - yRot) / (self.moveDownEnd - self.moveDownStart)
		elseif self.moveUpEnd < yRot and yRot <= self.moveDownStart then
			alpha = 1
		end

		local rot = self.spikeMaxRot * alpha * spike.direction

		if self.spikeRotAxis == 1 then
			setRotation(spike.node, rot, 0, 0)
		elseif self.spikeRotAxis == 2 then
			setRotation(spike.node, 0, rot, 0)
		else
			setRotation(spike.node, 0, 0, rot)
		end
	end
end

function RotationAnimationSpikes.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".spikes#moveUpRange", "Move up range")
	schema:register(XMLValueType.VECTOR_ROT_2, basePath .. ".spikes#moveDownRange", "Move down range")
	schema:register(XMLValueType.ANGLE, basePath .. ".spikes#maxRot", "Max. spike rotation")
	schema:register(XMLValueType.INT, basePath .. ".spikes#rotAxis", "Rotation axis", 3)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".spikes.spike(?)#node", "Spike node")
	schema:register(XMLValueType.INT, basePath .. ".spikes.spike(?)#direction", "Spike rot. direction")
end
