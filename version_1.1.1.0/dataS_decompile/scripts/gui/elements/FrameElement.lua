FrameElement = {}
local FrameElement_mt = Class(FrameElement, GuiElement)

local function NO_CALLBACK()
end

function FrameElement.new(target, customMt)
	local self = GuiElement.new(target, customMt or FrameElement_mt)
	self.controlIDs = {}
	self.changeScreenCallback = NO_CALLBACK
	self.toggleCustomInputContextCallback = NO_CALLBACK
	self.playSampleCallback = NO_CALLBACK
	self.hasCustomInputContext = false
	self.time = 0
	self.inputDisableTime = 0
	self.playHoverSoundOnFocus = false

	return self
end

function FrameElement:clone(parent, includeId, suppressOnCreate)
	local ret = FrameElement:superClass().clone(self, parent, includeId, suppressOnCreate)

	ret:exposeControlsAsFields(self.name)

	ret.changeScreenCallback = self.changeScreenCallback
	ret.toggleCustomInputContextCallback = self.toggleCustomInputContextCallback
	ret.playSampleCallback = self.playSampleCallback
	ret.hasCustomInputContext = self.hasCustomInputContext

	return ret
end

function FrameElement:copyAttributes(src)
	FrameElement:superClass().copyAttributes(self, src)

	for k, _ in pairs(src.controlIDs) do
		self.controlIDs[k] = false
	end
end

function FrameElement:delete()
	FrameElement:superClass().delete(self)

	for k, _ in pairs(self.controlIDs) do
		self.controlIDs[k] = nil
		self[k] = nil
	end
end

function FrameElement:getRootElement()
	if #self.elements > 0 then
		return self.elements[1]
	else
		local newRoot = GuiElement.new()

		self:addElement(newRoot)

		return newRoot
	end
end

function FrameElement:registerControls(controlIDs)
	for _, id in pairs(controlIDs) do
		if self.controlIDs[id] then
			Logging.warning("Registered multiple control elements with the same ID '%s'. Check screen setup.", tostring(id))
		else
			self.controlIDs[id] = false
		end
	end
end

function FrameElement:exposeControlsAsFields(viewName)
	local allChildren = self:getDescendants()

	for _, element in pairs(allChildren) do
		if element.id and element.id ~= "" then
			local index, varName = GuiElement.extractIndexAndNameFromID(element.id)

			if self.controlIDs[varName] ~= nil then
				if index then
					if not self[varName] then
						self[varName] = {}
					end

					self[varName][index] = element
				else
					self[varName] = element
				end

				self.controlIDs[varName] = true
			end
		end
	end

	if self.debugEnabled or g_uiDebugEnabled then
		for id, isResolved in pairs(self.controlIDs) do
			if not isResolved then
				Logging.warning("FrameElement for GUI view '%s' could not resolve registered control element ID '%s'. Check configuration.", tostring(viewName), tostring(id))
			end
		end
	end
end

function FrameElement:disableInputForDuration(duration)
	self.inputDisableTime = MathUtil.clamp(duration, 0, 10000)
end

function FrameElement:isInputDisabled()
	return self.inputDisableTime > 0
end

function FrameElement:update(dt)
	FrameElement:superClass().update(self, dt)

	self.time = self.time + dt

	if self.inputDisableTime > 0 then
		self.inputDisableTime = self.inputDisableTime - dt
	end
end

function FrameElement:setChangeScreenCallback(callback)
	self.changeScreenCallback = callback or NO_CALLBACK
end

function FrameElement:setInputContextCallback(callback)
	self.toggleCustomInputContextCallback = callback or NO_CALLBACK
end

function FrameElement:setPlaySampleCallback(callback)
	self.playSampleCallback = callback or NO_CALLBACK
end

function FrameElement:changeScreen(targetScreenClass, returnScreenClass)
	self:changeScreenCallback(targetScreenClass, returnScreenClass)
end

function FrameElement:toggleCustomInputContext(isContextActive, contextName)
	if self.hasCustomInputContext and not isContextActive or not self.hasCustomInputContext and isContextActive then
		self.toggleCustomInputContextCallback(isContextActive, contextName)

		self.hasCustomInputContext = isContextActive
	end
end

function FrameElement:playSample(sampleName)
	if not self:getSoundSuppressed() then
		self.playSampleCallback(sampleName)
	end
end
