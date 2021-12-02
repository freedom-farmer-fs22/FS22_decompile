MultiOptionElement = {}
local MultiOptionElement_mt = Class(MultiOptionElement, MultiTextOptionElement)

function MultiOptionElement.new(target, custom_mt)
	local self = MultiTextOptionElement.new(target, custom_mt or MultiOptionElement_mt)
	self.options = {}

	return self
end

function MultiOptionElement:loadFromXML(xmlFile, key)
	MultiOptionElement:superClass().loadFromXML(self, xmlFile, key)
end

function MultiOptionElement:loadProfile(profile, applyProfile)
	MultiOptionElement:superClass().loadProfile(self, profile, applyProfile)
end

function MultiOptionElement:copyAttributes(src)
	MultiOptionElement:superClass().copyAttributes(self, src)
end

function MultiOptionElement:setState(state, forceEvent)
	MultiOptionElement:superClass().setState(self, state, forceEvent)
end

function MultiOptionElement:getState()
	return self.state
end

function MultiOptionElement:setOptions(options)
	self.options = options or {}

	self:updateContents()
end

function MultiOptionElement:updateContents()
	local texts = {}

	for _, option in ipairs(self.options) do
		table.insert(texts, option.title)
	end

	self:setTexts(texts)
	self:setDisabled(#self.options == 0)
end

function MultiOptionElement:raiseClickCallback(v)
	local option = self.options[self.state]

	if option ~= nil then
		self:raiseCallback("onClickCallback", option, self, v)
	end
end
