PipeEffect = {
	SAFETY_OFFSET = 0.01
}
local PipeEffect_mt = Class(PipeEffect, ShaderPlaneEffect)

function PipeEffect.new(customMt)
	if customMt == nil then
		customMt = PipeEffect_mt
	end

	local self = ShaderPlaneEffect.new(customMt)

	return self
end

function PipeEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not PipeEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.maxBending = Effect.getValue(xmlFile, key, node, "maxBending", 0.25)
	self.shapeScaleSpread = Effect.getValue(xmlFile, key, node, "shapeScaleSpread", "0.6 1 1 0", true)
	self.uvScaleSpeedFreqAmp = Effect.getValue(xmlFile, key, node, "uvScaleSpeedFreqAmp", nil, true)
	local positionUpdateNodesStr = Effect.getValue(xmlFile, key, node, "positionUpdateNodes")

	if positionUpdateNodesStr ~= nil then
		local nodeStrs = positionUpdateNodesStr:split(" ")
		self.positionUpdateNodes = {}

		for _, nodeStr in pairs(nodeStrs) do
			local updateNode = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), nodeStr, i3dMapping)

			if updateNode ~= nil then
				table.insert(self.positionUpdateNodes, updateNode)
			end
		end
	end

	self.updateDistance = Effect.getValue(xmlFile, key, node, "updateDistance", true)
	self.extraDistance = Effect.getValue(xmlFile, key, node, "extraDistance", 0)
	self.worldTarget = {
		0,
		0,
		0
	}
	self.controlPoint = Effect.getValue(xmlFile, key, node, "controlPoint", "10 0.25 0 0", true)
	self.controlPointY = 0
	self.distance = 0

	return true
end

function PipeEffect:update(dt)
	PipeEffect:superClass().update(self, dt)

	if self.distance > 0 then
		local mCos = math.cos(self.controlPointY)
		local mSin = math.sin(self.controlPointY)
		local y = MathUtil.dotProduct(0, 0, self.distance, 0, mCos, -mSin)
		local z = MathUtil.dotProduct(0, 0, self.distance, 0, mSin, mCos)
		local wx, wy, wz = localToWorld(self.node, 0, y, z)
		self.worldTarget[3] = wz
		self.worldTarget[2] = wy
		self.worldTarget[1] = wx
	end

	if self.positionUpdateNodes ~= nil then
		for _, node in pairs(self.positionUpdateNodes) do
			setWorldTranslation(node, self.worldTarget[1], self.worldTarget[2], self.worldTarget[3])
		end
	end
end

function PipeEffect:setDistance(distance, terrain)
	setVisibility(self.node, distance > 0)

	if self.updateDistance and getHasShaderParameter(self.node, "controlPoint") then
		distance = distance + self.extraDistance
		local _, dirY, _ = localDirectionToWorld(self.node, 0, 1, 0)
		self.controlPointY = dirY * self.maxBending
		self.distance = distance
		local mCos = math.cos(self.controlPointY)
		local mSin = math.sin(self.controlPointY)
		local y = MathUtil.dotProduct(0, 0, distance, 0, mCos, -mSin)
		local z = MathUtil.dotProduct(0, 0, distance, 0, mSin, mCos)
		local realDistance = MathUtil.vector2Length(y, z)
		distance = distance + distance - realDistance

		setShaderParameter(self.node, "controlPoint", distance - PipeEffect.SAFETY_OFFSET, self.controlPointY, 0, 0, false)
	end
end

function PipeEffect:setFillType(fillType)
	local success = PipeEffect:superClass().setFillType(self, fillType)

	if success then
		if getHasShaderParameter(self.node, "shapeScaleSpread") then
			setShaderParameter(self.node, "shapeScaleSpread", self.shapeScaleSpread[1], self.shapeScaleSpread[2], self.shapeScaleSpread[3], self.shapeScaleSpread[4], false)
		end

		if self.uvScaleSpeedFreqAmp ~= nil and getHasShaderParameter(self.node, "uvScaleSpeedFreqAmp") then
			setShaderParameter(self.node, "uvScaleSpeedFreqAmp", self.uvScaleSpeedFreqAmp[1], self.uvScaleSpeedFreqAmp[2], self.uvScaleSpeedFreqAmp[3], self.uvScaleSpeedFreqAmp[4], false)
		end

		if getHasShaderParameter(self.node, "controlPoint") then
			setShaderParameter(self.node, "controlPoint", self.controlPoint[1], self.controlPoint[2], 0, 0, false)
		end
	end

	return success
end

function PipeEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxBending", "(PipeEffect) Max bending", 0.25)
	schema:register(XMLValueType.VECTOR_4, basePath .. "#shapeScaleSpread", "(PipeEffect) Shape scale spread", "0.6 1 1 0")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#uvScaleSpeedFreqAmp", "(PipeEffect) UV Scale, speed, frequency, amplitude")
	schema:register(XMLValueType.STRING, basePath .. "#positionUpdateNodes", "(PipeEffect) List of nodes to position at control point")
	schema:register(XMLValueType.STRING, basePath .. "#updateDistance", "(PipeEffect) Update effect distance", true)
	schema:register(XMLValueType.STRING, basePath .. "#extraDistance", "(PipeEffect) Extra distance", 0)
	schema:register(XMLValueType.VECTOR_4, basePath .. "#controlPoint", "(PipeEffect) Control point position", "10 0.25 0 0")
end
