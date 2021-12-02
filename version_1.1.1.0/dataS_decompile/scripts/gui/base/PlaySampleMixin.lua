PlaySampleMixin = {}
local PlaySampleMixin_mt = Class(PlaySampleMixin, GuiMixin)

local function NO_CALLBACK()
end

function PlaySampleMixin.new()
	return GuiMixin.new(PlaySampleMixin_mt, PlaySampleMixin)
end

function PlaySampleMixin:addTo(guiElement)
	if PlaySampleMixin:superClass().addTo(self, guiElement) then
		guiElement.setPlaySampleCallback = PlaySampleMixin.setPlaySampleCallback
		guiElement.playSample = PlaySampleMixin.playSample
		guiElement.disablePlaySample = PlaySampleMixin.disablePlaySample
		guiElement[PlaySampleMixin].playSampleCallback = NO_CALLBACK

		return true
	else
		return false
	end
end

function PlaySampleMixin.setPlaySampleCallback(guiElement, callback)
	guiElement[PlaySampleMixin].playSampleCallback = callback
end

function PlaySampleMixin.playSample(guiElement, sampleName)
	if not guiElement.soundDisabled then
		guiElement[PlaySampleMixin].playSampleCallback(sampleName)
	end
end

function PlaySampleMixin.disablePlaySample(guiElement)
	guiElement[PlaySampleMixin].playSampleCallback = NO_CALLBACK
end

function PlaySampleMixin:clone(srcGuiElement, dstGuiElement)
	dstGuiElement[PlaySampleMixin].playSampleCallback = srcGuiElement[PlaySampleMixin].playSampleCallback
end
