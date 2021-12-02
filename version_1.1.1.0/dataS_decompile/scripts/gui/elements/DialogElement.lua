DialogElement = {
	TYPE_LOADING = 0,
	TYPE_QUESTION = 1,
	TYPE_WARNING = 2,
	TYPE_KEY = 3,
	TYPE_INFO = 4,
	CONTROLS = {
		"dialogCircle",
		"dialogElement",
		ICON_WARNING_ELEMENT = "iconWarningElement",
		ICON_INFO_ELEMENT = "iconInfoElement",
		ICON_KEY_ELEMENT = "iconKeyElement",
		ICON_LOADING_ELEMENT = "iconLoadingElement",
		ICON_QUESTION_ELEMENT = "iconQuestionElement"
	},
	DIALOG_CIRCLE_PROFILE = "dialogCircle",
	DIALOG_CIRCLE_PROFILE_WARNING = "dialogCircleWarning"
}
local TYPE_ICON_ID_MAPPING = {
	[DialogElement.TYPE_LOADING] = DialogElement.CONTROLS.ICON_LOADING_ELEMENT,
	[DialogElement.TYPE_QUESTION] = DialogElement.CONTROLS.ICON_QUESTION_ELEMENT,
	[DialogElement.TYPE_WARNING] = DialogElement.CONTROLS.ICON_WARNING_ELEMENT,
	[DialogElement.TYPE_KEY] = DialogElement.CONTROLS.ICON_KEY_ELEMENT,
	[DialogElement.TYPE_INFO] = DialogElement.CONTROLS.ICON_INFO_ELEMENT
}
local DialogElement_mt = Class(DialogElement, ScreenElement)

function DialogElement.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or DialogElement_mt)
	self.isCloseAllowed = true

	self:registerControls(DialogElement.CONTROLS)

	return self
end

function DialogElement:close()
	g_gui:closeDialogByName(self.name)
end

function DialogElement:onClickBack(forceBack, usedMenuButton)
	if (self.isCloseAllowed or forceBack) and not usedMenuButton then
		self:close()

		return false
	else
		return true
	end
end

function DialogElement:setDialogType(dialogType)
	dialogType = Utils.getNoNil(dialogType, DialogElement.TYPE_WARNING)
	self.dialogType = dialogType

	for dt, id in pairs(TYPE_ICON_ID_MAPPING) do
		local typeElement = self[id]

		if typeElement then
			typeElement:setVisible(dt == dialogType)
		end
	end

	if self.dialogCircle ~= nil then
		self.dialogCircle:setVisible(dialogType ~= DialogElement.TYPE_LOADING)
	end
end

function DialogElement:setIsCloseAllowed(isAllowed)
	self.isCloseAllowed = isAllowed
end

function DialogElement:getBlurArea()
	if self.dialogElement == nil then
		return nil
	else
		return self.dialogElement.absPosition[1], self.dialogElement.absPosition[2], self.dialogElement.absSize[1], self.dialogElement.absSize[2]
	end
end
