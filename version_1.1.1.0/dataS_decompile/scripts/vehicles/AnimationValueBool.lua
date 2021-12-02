AnimationValueBool = {}
local AnimationValueBool_mt = Class(AnimationValueBool, AnimationValueFloat)

function AnimationValueBool.new(vehicle, animation, part, startName, endName, name, initialUpdate, get, set, extraLoad, customMt)
	return AnimationValueFloat.new(vehicle, animation, part, startName, endName, name, initialUpdate, get, set, extraLoad, customMt or AnimationValueBool_mt)
end

function AnimationValueBool:load(xmlFile, key)
	self.value = xmlFile:getValue(key .. "#" .. self.startName)
	self.warningInfo = key
	self.xmlFile = xmlFile

	return self.value ~= nil and self:extraLoad(xmlFile, key)
end

function AnimationValueBool:init(index, numParts)
end

function AnimationValueBool:postInit()
end

function AnimationValueBool:reset()
	self.curValue = nil
end

function AnimationValueBool:update(durationToEnd, dtToUse, realDt)
	if self.curValue == nil then
		self.curValue = self:get()
	end

	if self.value ~= self.curValue then
		self.curValue = self.value

		self:set(self.value)

		return true
	end

	return false
end
