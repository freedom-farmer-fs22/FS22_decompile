DepthOfFieldManager = {
	DEFAULT_VALUES = {
		0.8,
		0.5,
		0.4,
		1000,
		1400,
		false
	}
}
local DepthOfFieldManager_mt = Class(DepthOfFieldManager, AbstractManager)

function DepthOfFieldManager.new(customMt)
	local self = AbstractManager.new(customMt or DepthOfFieldManager_mt)
	self.defaultState = table.copy(DepthOfFieldManager.DEFAULT_VALUES)

	setDoFparams(unpack(self.defaultState))

	self.initialState = {
		getDoFparams()
	}
	self.currentState = {
		getDoFparams()
	}
	self.blurState = {
		0.8,
		0.5,
		0.4,
		1000,
		1400,
		true
	}

	function self.oldSetDoFparams()
	end

	self.areaStack = {
		{
			-1,
			-1,
			-1,
			-1,
			false
		}
	}

	return self
end

function DepthOfFieldManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.defaultState[1] = getXMLFloat(xmlFile, "map.depthOfField#nearCoC") or DepthOfFieldManager.DEFAULT_VALUES[1]
	self.defaultState[2] = getXMLFloat(xmlFile, "map.depthOfField#nearBlurEnd") or DepthOfFieldManager.DEFAULT_VALUES[2]
	self.defaultState[3] = getXMLFloat(xmlFile, "map.depthOfField#farCoC") or DepthOfFieldManager.DEFAULT_VALUES[3]
	self.defaultState[4] = getXMLFloat(xmlFile, "map.depthOfField#farBlurStart") or DepthOfFieldManager.DEFAULT_VALUES[4]
	self.defaultState[5] = getXMLFloat(xmlFile, "map.depthOfField#farBlurEnd") or DepthOfFieldManager.DEFAULT_VALUES[5]

	setDoFparams(unpack(self.defaultState))
end

function DepthOfFieldManager:getInitialDoFParams()
	return unpack(self.initialState)
end

function DepthOfFieldManager:setEnvironmentDoFEnabled(enabled, skipReset)
	if enabled then
		self.initialState = self.defaultState
	else
		self.initialState = {
			self.defaultState[1],
			self.defaultState[2],
			self.defaultState[3],
			0,
			0,
			false
		}
	end

	if not skipReset then
		self:reset()
	end
end

function DepthOfFieldManager:getCurrentDoFParams()
	return unpack(self.currentState)
end

function DepthOfFieldManager:getBlurDoFParams()
	return unpack(self.blurState)
end

function DepthOfFieldManager:reset()
	setDoFparams(unpack(self.initialState))
end

function DepthOfFieldManager:setManipulatedParams(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd, applyToSky)
	self.currentState[1] = nearCoCRadius or self.initialState[1]
	self.currentState[2] = nearBlurEnd or self.initialState[2]
	self.currentState[3] = farCoCRadius or self.initialState[3]
	self.currentState[4] = farBlurStart or self.initialState[4]
	self.currentState[5] = farBlurEnd or self.initialState[5]
	self.currentState[6] = applyToSky or self.initialState[6]

	setDoFparams(unpack(self.currentState))
end

function DepthOfFieldManager:getIsDoFChangeAllowed()
	return #self.areaStack == 1
end

function DepthOfFieldManager:pushArea(x, y, width, height)
	table.insert(self.areaStack, 1, {
		x,
		y,
		x + width,
		y + height,
		true
	})
	self:updateArea()
end

function DepthOfFieldManager:popArea()
	assertWithCallstack(#self.areaStack > 1)
	table.remove(self.areaStack, 1)
	self:updateArea()
end

function DepthOfFieldManager:updateArea()
	if #self.areaStack > 0 then
		local x1 = 1
		local x2 = 0
		local y1 = 1
		local y2 = 0
		local isBlurred = false

		for _, item in ipairs(self.areaStack) do
			if item[5] then
				local x, y, xs, ys = unpack(item)
				x1 = math.min(x1, x)
				y1 = math.min(y1, y)
				x2 = math.max(x2, xs)
				y2 = math.max(y2, ys)
				isBlurred = true
			end
		end

		if not isBlurred then
			y2 = -1
			y1 = -1
			x2 = -1
			x1 = -1
		end

		setDoFBlurArea(x1, y1, x2, y2)
	end
end

function DepthOfFieldManager:queueDoFChange(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd, applyToSky)
	self.currentState = {
		nearCoCRadius,
		nearBlurEnd,
		farCoCRadius,
		farBlurStart,
		farBlurEnd,
		applyToSky
	}
end

g_depthOfFieldManager = DepthOfFieldManager.new()
g_depthOfFieldManager.oldSetDoFparams = setDoFparams

function setDoFparams(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd, applyToSky)
	if g_depthOfFieldManager:getIsDoFChangeAllowed() then
		g_depthOfFieldManager.oldSetDoFparams(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd, applyToSky)
	end

	g_depthOfFieldManager:queueDoFChange(nearCoCRadius, nearBlurEnd, farCoCRadius, farBlurStart, farBlurEnd, applyToSky)
end
