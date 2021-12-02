IndexChangeSubjectMixin = {}
local IndexableElementMixin_mt = Class(IndexChangeSubjectMixin, GuiMixin)

function IndexChangeSubjectMixin.new()
	local self = GuiMixin.new(IndexableElementMixin_mt, IndexChangeSubjectMixin)
	self.callbacks = {}

	return self
end

function IndexChangeSubjectMixin:addTo(guiElement)
	if IndexChangeSubjectMixin:superClass().addTo(self, guiElement) then
		guiElement.addIndexChangeObserver = IndexChangeSubjectMixin.addIndexChangeObserver
		guiElement.notifyIndexChange = IndexChangeSubjectMixin.notifyIndexChange

		return true
	else
		return false
	end
end

function IndexChangeSubjectMixin.addIndexChangeObserver(guiElement, observer, indexChangeCallback)
	guiElement[IndexChangeSubjectMixin].callbacks[observer] = indexChangeCallback
end

function IndexChangeSubjectMixin.notifyIndexChange(guiElement, index, count)
	local callbacks = guiElement[IndexChangeSubjectMixin].callbacks

	for observer, callback in pairs(callbacks) do
		callback(observer, index, count)
	end
end

function IndexChangeSubjectMixin:clone(srcGuiElement, dstGuiElement)
	dstGuiElement[IndexChangeSubjectMixin].callbacks = {
		unpack(srcGuiElement[IndexChangeSubjectMixin])
	}
end
