Input = {
	keyPressedState = {},
	mouseButtonPressedState = {},
	keyPressedThisFrame = {},
	mouseButtonPressedThisFrame = {}
}

function Input.updateFrameEnd()
	for key, _ in pairs(Input.keyPressedThisFrame) do
		Input.keyPressedThisFrame[key] = false
	end

	for button, _ in pairs(Input.mouseButtonPressedThisFrame) do
		Input.mouseButtonPressedThisFrame[button] = false
	end
end

function Input.updateKeyState(key, isDown)
	if isDown then
		Input.keyPressedState[key] = true
		Input.keyPressedThisFrame[key] = true
	else
		Input.keyPressedState[key] = false
	end
end

function Input.isKeyPressed(key)
	return Input.keyPressedState[key] or Input.keyPressedThisFrame[key]
end

function Input.updateMouseButtonState(button, isDown)
	if isDown then
		Input.mouseButtonPressedState[button] = true
		Input.mouseButtonPressedThisFrame[button] = true
	else
		Input.mouseButtonPressedState[button] = false
	end
end

function Input.isMouseButtonPressed(button)
	return Input.mouseButtonPressedState[button] or Input.mouseButtonPressedThisFrame[button]
end

Input.MOD_LSHIFT = 1
Input.MOD_RSHIFT = 2
Input.MOD_LCTRL = 64
Input.MOD_RCTRL = 128
Input.MOD_LALT = 256
Input.MOD_RALT = 512
Input.MOD_LMETA = 1024
Input.MOD_RMETA = 2048
Input.MOD_NUM = 4096
Input.MOD_CAPS = 8192
Input.MOD_MODE = 16384
Input.MOD_SHIFT = 3
Input.MOD_CTRL = 192
Input.MOD_ALT = 768
Input.MOD_META = 3072
Input.keyIdToIdName = {}
Input.keyIdIsModifier = {}

function Input.addKeyDefine(idName, id, isModifier)
	if Input[idName] ~= nil or Input.keyIdToIdName[id] ~= nil then
		print("Error: Duplicate key define " .. idName .. " = " .. id)

		return
	end

	Input.keyIdToIdName[id] = idName
	Input.keyIdIsModifier[id] = isModifier
	Input[idName] = id
end

Input.mouseButtonIdToIdName = {}

function Input.addMouseButtonDefine(idName, id)
	if Input[idName] ~= nil or Input.mouseButtonIdToIdName[id] ~= nil then
		print("Error: Duplicate mouse button define " .. idName .. " = " .. id)

		return
	end

	Input.mouseButtonIdToIdName[id] = idName
	Input[idName] = id
end

Input.axisIdToIdName = {}
Input.axisIdNameToId = {}

function Input.addFullAxisDefine(idName, id, isOverwrite)
	if Input[idName] ~= nil or not isOverwrite and Input.axisIdToIdName[id] ~= nil then
		print("Error: Duplicate axis define " .. idName .. " = " .. id)

		return
	elseif isOverwrite and Input.axisIdToIdName[id] == nil then
		print("Error: Missing axis define to overwrite  for " .. idName .. " = " .. id)
	end

	Input[idName] = id
	Input.axisIdNameToId[idName] = id
	Input.axisIdToIdName[id] = idName
	Input[idName .. "-"] = id
	Input.axisIdNameToId[idName .. "-"] = id
	Input[idName .. "+"] = id
	Input.axisIdNameToId[idName .. "+"] = id
end

function Input.addHalfAxisDefine(idName, id, isOverwrite)
	if Input[idName] ~= nil or not isOverwrite and Input.axisIdToIdName[id] ~= nil then
		print("Error: Duplicate axis define " .. idName .. " = " .. id)

		return
	elseif isOverwrite and Input.axisIdToIdName[id] == nil then
		print("Error: Missing axis define to overwrite  for " .. idName .. " = " .. id)
	end

	Input[idName] = id
	Input.axisIdNameToId[idName] = id
	Input.axisIdToIdName[id] = idName
end

Input.buttonIdToIdName = {}
Input.buttonIdNameToId = {}

function Input.addButtonDefine(idName, id)
	if Input[idName] ~= nil or Input.buttonIdToIdName[id] ~= nil then
		print("Error: Duplicate button define " .. idName .. " = " .. id)

		return
	end

	Input[idName] = id
	Input.buttonIdNameToId[idName] = id
	Input.buttonIdToIdName[id] = idName
end

Input.addKeyDefine("KEY_backspace", 8)
Input.addKeyDefine("KEY_tab", 9)
Input.addKeyDefine("KEY_clear", 12)
Input.addKeyDefine("KEY_return", 13)
Input.addKeyDefine("KEY_pause", 19)
Input.addKeyDefine("KEY_esc", 27)
Input.addKeyDefine("KEY_space", 32)
Input.addKeyDefine("KEY_exclaim", 33)
Input.addKeyDefine("KEY_quotedbl", 34)
Input.addKeyDefine("KEY_hash", 35)
Input.addKeyDefine("KEY_dollar", 36)
Input.addKeyDefine("KEY_ampersand", 38)
Input.addKeyDefine("KEY_quote", 39)
Input.addKeyDefine("KEY_leftparen", 40)
Input.addKeyDefine("KEY_rightparen", 41)
Input.addKeyDefine("KEY_asterisk", 42)
Input.addKeyDefine("KEY_plus", 43)
Input.addKeyDefine("KEY_comma", 44)
Input.addKeyDefine("KEY_minus", 45)
Input.addKeyDefine("KEY_period", 46)
Input.addKeyDefine("KEY_slash", 47)
Input.addKeyDefine("KEY_0", 48)
Input.addKeyDefine("KEY_1", 49)
Input.addKeyDefine("KEY_2", 50)
Input.addKeyDefine("KEY_3", 51)
Input.addKeyDefine("KEY_4", 52)
Input.addKeyDefine("KEY_5", 53)
Input.addKeyDefine("KEY_6", 54)
Input.addKeyDefine("KEY_7", 55)
Input.addKeyDefine("KEY_8", 56)
Input.addKeyDefine("KEY_9", 57)
Input.addKeyDefine("KEY_colon", 58)
Input.addKeyDefine("KEY_semicolon", 59)
Input.addKeyDefine("KEY_less", 60)
Input.addKeyDefine("KEY_equals", 61)
Input.addKeyDefine("KEY_greater", 62)
Input.addKeyDefine("KEY_question", 63)
Input.addKeyDefine("KEY_at", 64)
Input.addKeyDefine("KEY_leftbracket", 91)
Input.addKeyDefine("KEY_backslash", 92)
Input.addKeyDefine("KEY_rightbracket", 93)
Input.addKeyDefine("KEY_caret", 94)
Input.addKeyDefine("KEY_underscore", 95)
Input.addKeyDefine("KEY_backquote", 96)
Input.addKeyDefine("KEY_a", 97)
Input.addKeyDefine("KEY_b", 98)
Input.addKeyDefine("KEY_c", 99)
Input.addKeyDefine("KEY_d", 100)
Input.addKeyDefine("KEY_e", 101)
Input.addKeyDefine("KEY_f", 102)
Input.addKeyDefine("KEY_g", 103)
Input.addKeyDefine("KEY_h", 104)
Input.addKeyDefine("KEY_i", 105)
Input.addKeyDefine("KEY_j", 106)
Input.addKeyDefine("KEY_k", 107)
Input.addKeyDefine("KEY_l", 108)
Input.addKeyDefine("KEY_m", 109)
Input.addKeyDefine("KEY_n", 110)
Input.addKeyDefine("KEY_o", 111)
Input.addKeyDefine("KEY_p", 112)
Input.addKeyDefine("KEY_q", 113)
Input.addKeyDefine("KEY_r", 114)
Input.addKeyDefine("KEY_s", 115)
Input.addKeyDefine("KEY_t", 116)
Input.addKeyDefine("KEY_u", 117)
Input.addKeyDefine("KEY_v", 118)
Input.addKeyDefine("KEY_w", 119)
Input.addKeyDefine("KEY_x", 120)
Input.addKeyDefine("KEY_y", 121)
Input.addKeyDefine("KEY_z", 122)
Input.addKeyDefine("KEY_delete", 127)
Input.addKeyDefine("KEY_KP_0", 256)
Input.addKeyDefine("KEY_KP_1", 257)
Input.addKeyDefine("KEY_KP_2", 258)
Input.addKeyDefine("KEY_KP_3", 259)
Input.addKeyDefine("KEY_KP_4", 260)
Input.addKeyDefine("KEY_KP_5", 261)
Input.addKeyDefine("KEY_KP_6", 262)
Input.addKeyDefine("KEY_KP_7", 263)
Input.addKeyDefine("KEY_KP_8", 264)
Input.addKeyDefine("KEY_KP_9", 265)
Input.addKeyDefine("KEY_KP_period", 266)
Input.addKeyDefine("KEY_KP_divide", 267)
Input.addKeyDefine("KEY_KP_multiply", 268)
Input.addKeyDefine("KEY_KP_minus", 269)
Input.addKeyDefine("KEY_KP_plus", 270)
Input.addKeyDefine("KEY_KP_enter", 271)
Input.addKeyDefine("KEY_KP_equals", 272)
Input.addKeyDefine("KEY_up", 273)
Input.addKeyDefine("KEY_down", 274)
Input.addKeyDefine("KEY_right", 275)
Input.addKeyDefine("KEY_left", 276)
Input.addKeyDefine("KEY_insert", 277)
Input.addKeyDefine("KEY_home", 278)
Input.addKeyDefine("KEY_end", 279)
Input.addKeyDefine("KEY_pageup", 280)
Input.addKeyDefine("KEY_pagedown", 281)
Input.addKeyDefine("KEY_f1", 282)
Input.addKeyDefine("KEY_f2", 283)
Input.addKeyDefine("KEY_f3", 284)
Input.addKeyDefine("KEY_f4", 285)
Input.addKeyDefine("KEY_f5", 286)
Input.addKeyDefine("KEY_f6", 287)
Input.addKeyDefine("KEY_f7", 288)
Input.addKeyDefine("KEY_f8", 289)
Input.addKeyDefine("KEY_f9", 290)
Input.addKeyDefine("KEY_f10", 291)
Input.addKeyDefine("KEY_f11", 292)
Input.addKeyDefine("KEY_f12", 293)
Input.addKeyDefine("KEY_f13", 294)
Input.addKeyDefine("KEY_f14", 295)
Input.addKeyDefine("KEY_f15", 296)
Input.addKeyDefine("KEY_rshift", 303, true)
Input.addKeyDefine("KEY_lshift", 304, true)
Input.addKeyDefine("KEY_rctrl", 305, true)
Input.addKeyDefine("KEY_lctrl", 306, true)
Input.addKeyDefine("KEY_ralt", 307, true)
Input.addKeyDefine("KEY_lalt", 308, true)
Input.addKeyDefine("KEY_print", 316)
Input.addKeyDefine("KEY_scrolllock", 302)
Input.addKeyDefine("KEY_lwin", 311)
Input.addKeyDefine("KEY_rwin", 312)
Input.addKeyDefine("KEY_menu", 319)
Input.addMouseButtonDefine("MOUSE_BUTTON_NONE", 0)
Input.addMouseButtonDefine("MOUSE_BUTTON_LEFT", 1)
Input.addMouseButtonDefine("MOUSE_BUTTON_MIDDLE", 2)
Input.addMouseButtonDefine("MOUSE_BUTTON_RIGHT", 3)
Input.addMouseButtonDefine("MOUSE_BUTTON_WHEEL_UP", 4)
Input.addMouseButtonDefine("MOUSE_BUTTON_WHEEL_DOWN", 5)
Input.addMouseButtonDefine("MOUSE_BUTTON_X1", 6)
Input.addMouseButtonDefine("MOUSE_BUTTON_X2", 7)

function Input.addKeyDefine(idName, id, isModifier)
	if Input[idName] ~= nil or Input.keyIdToIdName[id] ~= nil then
		print("Error: duplicate key define " .. idName .. " = " .. id)

		return
	end

	Input.keyIdToIdName[id] = idName
	Input.keyIdIsModifier[id] = isModifier
	Input[idName] = id
end

Input.addFullAxisDefine("AXIS_X", 0)
Input.addFullAxisDefine("AXIS_1", 0, true)
Input.addFullAxisDefine("AXIS_Y", 1)
Input.addFullAxisDefine("AXIS_2", 1, true)
Input.addFullAxisDefine("AXIS_Z", 2)
Input.addFullAxisDefine("AXIS_3", 2, true)
Input.addFullAxisDefine("AXIS_W", 3)
Input.addFullAxisDefine("AXIS_4", 3, true)
Input.addFullAxisDefine("AXIS_5", 4)
Input.addFullAxisDefine("AXIS_6", 5)
Input.addFullAxisDefine("AXIS_7", 6)
Input.addFullAxisDefine("AXIS_8", 7)
Input.addFullAxisDefine("AXIS_9", 8)
Input.addFullAxisDefine("AXIS_10", 9)
Input.addFullAxisDefine("AXIS_11", 10)
Input.addFullAxisDefine("AXIS_12", 11)
Input.addFullAxisDefine("AXIS_13", 12)
Input.addFullAxisDefine("AXIS_14", 13)

Input.MAX_NUM_AXES = 14

function Input.isHalfAxis(axis)
	return axis ~= nil and Input.HALF_AXIS_1 <= axis
end

Input.addHalfAxisDefine("HALF_AXIS_1", Input.AXIS_11, true)
Input.addHalfAxisDefine("HALF_AXIS_2", Input.AXIS_12, true)
Input.addHalfAxisDefine("HALF_AXIS_3", Input.AXIS_13, true)
Input.addHalfAxisDefine("HALF_AXIS_4", Input.AXIS_14, true)
Input.addButtonDefine("BUTTON_1", 0)
Input.addButtonDefine("BUTTON_2", 1)
Input.addButtonDefine("BUTTON_3", 2)
Input.addButtonDefine("BUTTON_4", 3)
Input.addButtonDefine("BUTTON_5", 4)
Input.addButtonDefine("BUTTON_6", 5)
Input.addButtonDefine("BUTTON_7", 6)
Input.addButtonDefine("BUTTON_8", 7)
Input.addButtonDefine("BUTTON_9", 8)
Input.addButtonDefine("BUTTON_10", 9)
Input.addButtonDefine("BUTTON_11", 10)
Input.addButtonDefine("BUTTON_12", 11)
Input.addButtonDefine("BUTTON_13", 12)
Input.addButtonDefine("BUTTON_14", 13)
Input.addButtonDefine("BUTTON_15", 14)
Input.addButtonDefine("BUTTON_16", 15)
Input.addButtonDefine("BUTTON_17", 16)
Input.addButtonDefine("BUTTON_18", 17)
Input.addButtonDefine("BUTTON_19", 18)
Input.addButtonDefine("BUTTON_20", 19)
Input.addButtonDefine("BUTTON_21", 20)
Input.addButtonDefine("BUTTON_22", 21)
Input.addButtonDefine("BUTTON_23", 22)
Input.addButtonDefine("BUTTON_24", 23)
Input.addButtonDefine("BUTTON_25", 24)
Input.addButtonDefine("BUTTON_26", 25)
Input.addButtonDefine("BUTTON_27", 26)
Input.addButtonDefine("BUTTON_28", 27)
Input.addButtonDefine("BUTTON_29", 28)
Input.addButtonDefine("BUTTON_30", 29)
Input.addButtonDefine("BUTTON_31", 30)
Input.addButtonDefine("BUTTON_32", 31)

Input.MAX_NUM_BUTTONS = 32
Input.MOD_BUTTON_1 = Input.BUTTON_5
Input.MOD_BUTTON_2 = Input.BUTTON_6
