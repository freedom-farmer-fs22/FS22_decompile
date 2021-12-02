ModHubLoadingFrame = {}
local ModHubLoadingFrame_mt = Class(ModHubLoadingFrame, TabbedMenuFrameElement)
ModHubLoadingFrame.CONTROLS = {}

function ModHubLoadingFrame.new(subclass_mt)
	local self = ModHubLoadingFrame:superClass().new(nil, subclass_mt or ModHubLoadingFrame_mt)

	self:registerControls(ModHubLoadingFrame.CONTROLS)

	return self
end

function ModHubLoadingFrame:onFrameOpen()
	ModHubLoadingFrame:superClass().onFrameOpen(self)
	g_modHubScreen.header:setVisible(false)
end

function ModHubLoadingFrame:onFrameClose()
	g_modHubScreen.header:setVisible(true)
	ModHubLoadingFrame:superClass().onFrameClose(self)
end
