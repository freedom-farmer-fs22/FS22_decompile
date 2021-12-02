InputHelpElement = {}
local InputHelpElement_mt = Class(InputHelpElement)
InputHelpElement.SEPARATOR = {
	COMBO_INPUT = 2,
	ANY_INPUT = 3,
	NONE = 1
}
InputHelpElement.NO_DATA = {}

function InputHelpElement.new(actionName, actionName2, buttonOverlays, keyLabels, separators, textLeft, textRight, inlineModifierButtons, iconOverlay, priority)
	local self = setmetatable({}, InputHelpElement_mt)

	if textRight and iconOverlay then
		textRight = ""
	end

	self.actionName = actionName or ""
	self.actionName2 = actionName2 or ""
	self.buttons = buttonOverlays or InputHelpElement.NO_DATA
	self.separators = separators or InputHelpElement.NO_DATA
	self.keys = keyLabels or InputHelpElement.NO_DATA
	self.textLeft = textLeft or ""
	self.textRight = textRight or ""
	self.inlineModifierButtons = inlineModifierButtons
	self.iconOverlay = iconOverlay
	self.priority = priority or GS_PRIO_NORMAL

	return self
end

function InputHelpElement:getActionNames()
	local actionNames = {}

	if self.actionName ~= "" then
		table.insert(actionNames, self.actionName)
	end

	if self.actionName2 ~= "" then
		table.insert(actionNames, self.actionName2)
	end

	return actionNames
end

InputHelpElement.AXIS_ICON = {
	CRANE_ARM1_ROTATE_X = "CRANE_ARM1_ROTATE_X",
	CRANE_ARM1_ROTATE_Y = "CRANE_ARM1_ROTATE_Y",
	CRANE_ARM1_TRANSLATE = "CRANE_ARM1_TRANSLATE",
	CRANE_ARM2_ROTATE_X = "CRANE_ARM2_ROTATE_X",
	CRANE_ARM2_ROTATE_TOOL = "CRANE_ARM2_ROTATE_TOOL",
	CRANE_ARM2_TRANSLATE = "CRANE_ARM2_TRANSLATE",
	DRAWBAR_ROTATE_X = "DRAWBAR_ROTATE_X",
	FRONTLOADER_ARM_ROTATE = "FRONTLOADER_ARM_ROTATE",
	FRONTLOADER_ARM_ROTATE_TOOL = "FRONTLOADER_ARM_ROTATE_TOOL",
	GRABBER_OPEN_CLOSE = "GRABBER_OPEN_CLOSE",
	GRABBER_ROTATE_Y = "GRABBER_ROTATE_Y",
	IMPLEMENT_ATTACHER_ROTX = "IMPLEMENT_ATTACHER_ROTX",
	IMPLEMENT_ATTACHER_TRANS = "IMPLEMENT_ATTACHER_TRANS",
	IMPLEMENT_TRANS_X = "IMPLEMENT_TRANS_X",
	IMPLEMENT_TRANS_Y = "IMPLEMENT_TRANS_Y",
	PIPE_END_ROTATE = "PIPE_END_ROTATE",
	PIPE_ROTATE_X = "PIPE_ROTATE_X",
	PIPE_ROTATE_Y = "PIPE_ROTATE_Y",
	REEL_TRANSLATE_X = "REEL_TRANSLATE_X",
	REEL_TRANSLATE_Y = "REEL_TRANSLATE_Y",
	SPRAYER_ARM_TRANSLATE_Y = "SPRAYER_ARM_TRANSLATE_Y",
	SUPPORT_ARM_TRANSLATE_Y = "SUPPORT_ARM_TRANSLATE_Y",
	TOOL_OPEN_CLOSE = "TOOL_OPEN_CLOSE",
	TOP_DOOR_ROTATE = "TOP_DOOR_ROTATE",
	WHEEL_BASE_TRANSLATE_X = "WHEEL_BASE_TRANSLATE_X",
	WORKING_WIDTH_TRANSLATE_X = "WORKING_WIDTH_TRANSLATE_X",
	CRANE_EC_TRANSLATE_Y = "CRANE_EC_TRANSLATE_Y",
	CRANE_EC_TRANSLATE_Z = "CRANE_EC_TRANSLATE_Z",
	BEET_PICKUP_TRANS_X = "BEET_PICKUP_TRANS_X",
	BEET_PICKUP_TRANS_Y = "BEET_PICKUP_TRANS_Y",
	SEAT_ROT_Y = "SEAT_ROT_Y",
	SNOW_PLOW_ROT_LEFT = "SNOW_PLOW_ROT_LEFT",
	SNOW_PLOW_ROT_CENTER = "SNOW_PLOW_ROT_CENTER",
	SNOW_PLOW_ROT_RIGHT = "SNOW_PLOW_ROT_RIGHT",
	FORKLIFT_ROTATE_X = "FORKLIFT_ROTATE_X",
	FORKLIFT_TRANSLATE_Y = "FORKLIFT_TRANSLATE_Y"
}
