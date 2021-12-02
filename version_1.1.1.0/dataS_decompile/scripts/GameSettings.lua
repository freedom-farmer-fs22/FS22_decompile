GameSettings = {}
local GameSettings_mt = Class(GameSettings)
GameSettings.SETTING = {
	VOLUME_VEHICLE = "vehicleVolume",
	USE_COLORBLIND_MODE = "useColorblindMode",
	GAMEPAD_ENABLED_SET_BY_USER = "gamepadEnabledSetByUser",
	MONEY_UNIT = "moneyUnit",
	MAX_NUM_MIRRORS = "maxNumMirrors",
	VOLUME_RADIO = "radioVolume",
	SHOW_HELP_MENU = "showHelpMenu",
	CAMERA_BOBBING = "cameraBobbing",
	SHOW_ALL_MODS = "showAllMods",
	SHOW_TRIGGER_MARKER = "showTriggerMarker",
	ONLINE_PRESENCE_NAME = "onlinePresenceName",
	HINTS = "hints",
	CAMERA_CHECK_COLLISION = "cameraCheckCollision",
	USE_ACRE = "useAcre",
	VOLUME_ENVIRONMENT = "environmentVolume",
	HORSE_ABANDON_TIMER_DURATION = "horseAbandonTimerDuration",
	USE_MILES = "useMiles",
	IS_GAMEPAD_ENABLED = "isGamepadEnabled",
	INVERT_Y_LOOK = "invertYLook",
	VEHICLE_ARM_SENSITIVITY = "vehicleArmSensitivity",
	EASY_ARM_CONTROL = "easyArmControl",
	HEAD_TRACKING_ENABLED_SET_BY_USER = "headTrackingEnabledSetByUser",
	GEAR_SHIFT_MODE = "gearShiftMode",
	USE_WORLD_CAMERA = "useWorldCamera",
	DIRECTION_CHANGE_MODE = "directionChangeMode",
	USE_FAHRENHEIT = "useFahrenheit",
	VOLUME_GUI = "volumeGUI",
	REAL_BEACON_LIGHTS = "realBeaconLights",
	RADIO_VEHICLE_ONLY = "radioVehicleOnly",
	VOLUME_VOICE = "volumeVoice",
	VOICE_MODE = "voiceMode",
	LIGHTS_PROFILE = "lightsProfile",
	FOV_Y = "fovY",
	VOLUME_VOICE_INPUT = "volumeVoiceInput",
	IS_TRAIN_TABBABLE = "isTrainTabbable",
	UI_SCALE = "uiScale",
	ACTIVE_SUSPENSION_CAMERA = "activeSuspensionCamera",
	LAST_PLAYER_STYLE_MALE = "lastPlayerStyleMale",
	CAMERA_SENSITIVITY = "cameraSensitivity",
	INPUT_HELP_MODE = "inputHelpMode",
	DEFAULT_SERVER_PORT = "defaultServerPort",
	STEERING_BACK_SPEED = "steeringBackSpeed",
	INGAME_MAP_STATE = "ingameMapState",
	INGAME_MAP_FILTER = "ingameMapFilter",
	RADIO_IS_ACTIVE = "radioIsActive",
	RESET_CAMERA = "resetCamera",
	STEERING_SENSITIVITY = "steeringSensitivity",
	VOLUME_MUSIC = "musicVolume",
	JOYSTICK_VIBRATION_ENABLED = "joystickVibrationEnabled",
	MOTOR_STOP_TIMER_DURATION = "motorStopTimerDuration",
	VOLUME_MASTER = "masterVolume",
	GYROSCOPE_STEERING = "gyroscopeSteering",
	SHOW_HELP_ICONS = "showHelpIcons",
	CAMERA_TILTING = "cameraTilting",
	IS_HEAD_TRACKING_ENABLED = "isHeadTrackingEnabled",
	SHOW_FIELD_INFO = "showFieldInfo",
	HUD_SPEED_GAUGE = "hudSpeedGauge",
	MP_LANGUAGE = "mpLanguage",
	FORCE_FEEDBACK = "forceFeedback",
	IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED = "isSoundPlayerStreamAccessAllowed"
}
GameSettings.PERFORMANCE_CLASS_PRESETS = {
	{
		maxNumMirrors = 0,
		realBeaconLights = false,
		lightsProfile = GS_PROFILE_LOW
	},
	{
		maxNumMirrors = 0,
		realBeaconLights = false,
		lightsProfile = GS_PROFILE_MEDIUM
	},
	{
		maxNumMirrors = 3,
		realBeaconLights = false,
		lightsProfile = GS_PROFILE_HIGH
	},
	{
		maxNumMirrors = 4,
		realBeaconLights = false,
		lightsProfile = GS_PROFILE_VERY_HIGH
	}
}

function GameSettings.new(customMt, messageCenter)
	if customMt == nil then
		customMt = GameSettings_mt
	end

	local self = {}

	setmetatable(self, customMt)

	self.messageCenter = messageCenter
	self.notifyOnChange = false
	self.joinGame = {}
	self.createGame = {}
	local maxMirrors = 3

	if GS_IS_CONSOLE_VERSION then
		if GS_PLATFORM_PLAYSTATION then
			if getNeoMode() then
				maxMirrors = 5
			else
				maxMirrors = 5
			end
		elseif GS_PLATFORM_XBOX then
			maxMirrors = 3
		else
			maxMirrors = 0
		end
	end

	self[GameSettings.SETTING.DEFAULT_SERVER_PORT] = 10823
	self[GameSettings.SETTING.MAX_NUM_MIRRORS] = maxMirrors
	self[GameSettings.SETTING.LIGHTS_PROFILE] = GS_PROFILE_VERY_HIGH
	self[GameSettings.SETTING.REAL_BEACON_LIGHTS] = false
	self[GameSettings.SETTING.MP_LANGUAGE] = getSystemLanguage()
	self[GameSettings.SETTING.CAMERA_BOBBING] = true
	self[GameSettings.SETTING.INPUT_HELP_MODE] = GS_INPUT_HELP_MODE_AUTO
	self[GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED] = false
	self[GameSettings.SETTING.GAMEPAD_ENABLED_SET_BY_USER] = false
	self[GameSettings.SETTING.IS_GAMEPAD_ENABLED] = true
	self[GameSettings.SETTING.JOYSTICK_VIBRATION_ENABLED] = false
	self[GameSettings.SETTING.GYROSCOPE_STEERING] = Platform.gameplay.defaultGyroscopeSteering
	self[GameSettings.SETTING.HEAD_TRACKING_ENABLED_SET_BY_USER] = false
	self[GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED] = true
	self[GameSettings.SETTING.FORCE_FEEDBACK] = 0.5
	self[GameSettings.SETTING.MOTOR_STOP_TIMER_DURATION] = 30000
	self[GameSettings.SETTING.HORSE_ABANDON_TIMER_DURATION] = 30000
	self[GameSettings.SETTING.FOV_Y] = g_fovYDefault
	self[GameSettings.SETTING.UI_SCALE] = 1
	self[GameSettings.SETTING.HINTS] = true
	self[GameSettings.SETTING.CAMERA_TILTING] = Platform.gameplay.defaultCameraTilt
	self[GameSettings.SETTING.SHOW_ALL_MODS] = false
	self[GameSettings.SETTING.ONLINE_PRESENCE_NAME] = getUserName():trim()
	self[GameSettings.SETTING.LAST_PLAYER_STYLE_MALE] = true
	self[GameSettings.SETTING.INVERT_Y_LOOK] = false
	self[GameSettings.SETTING.VOLUME_MASTER] = 1
	self[GameSettings.SETTING.VOLUME_MUSIC] = 0.5
	self[GameSettings.SETTING.VOLUME_VEHICLE] = 1
	self[GameSettings.SETTING.VOLUME_ENVIRONMENT] = 0.7
	self[GameSettings.SETTING.VOLUME_RADIO] = 0.5
	self[GameSettings.SETTING.VOLUME_GUI] = 0.5
	self[GameSettings.SETTING.VOLUME_VOICE] = 1
	self[GameSettings.SETTING.VOLUME_VOICE_INPUT] = 1
	self[GameSettings.SETTING.VOICE_MODE] = VoiceChatUtil.MODE.VOICE_ACTIVITY
	self[GameSettings.SETTING.RADIO_IS_ACTIVE] = false
	self[GameSettings.SETTING.RADIO_VEHICLE_ONLY] = true
	self[GameSettings.SETTING.SHOW_HELP_ICONS] = true
	self[GameSettings.SETTING.USE_COLORBLIND_MODE] = false
	self[GameSettings.SETTING.EASY_ARM_CONTROL] = true
	self[GameSettings.SETTING.MONEY_UNIT] = GS_MONEY_EURO

	if GS_IS_MOBILE_VERSION then
		self[GameSettings.SETTING.MONEY_UNIT] = GS_MONEY_DOLLAR
	end

	self[GameSettings.SETTING.USE_MILES] = false
	self[GameSettings.SETTING.USE_FAHRENHEIT] = false
	self[GameSettings.SETTING.USE_ACRE] = false
	self[GameSettings.SETTING.SHOW_TRIGGER_MARKER] = true
	self[GameSettings.SETTING.SHOW_FIELD_INFO] = true
	self[GameSettings.SETTING.RESET_CAMERA] = false
	self[GameSettings.SETTING.USE_WORLD_CAMERA] = true
	self[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA] = false
	self[GameSettings.SETTING.CAMERA_CHECK_COLLISION] = true
	self[GameSettings.SETTING.SHOW_HELP_MENU] = true
	self[GameSettings.SETTING.IS_TRAIN_TABBABLE] = true
	self[GameSettings.SETTING.CAMERA_SENSITIVITY] = 1
	self[GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY] = 1
	self[GameSettings.SETTING.STEERING_BACK_SPEED] = 5
	self[GameSettings.SETTING.STEERING_SENSITIVITY] = GS_IS_MOBILE_VERSION and 0.8 or 1
	self[GameSettings.SETTING.DIRECTION_CHANGE_MODE] = VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC
	self[GameSettings.SETTING.GEAR_SHIFT_MODE] = VehicleMotor.SHIFT_MODE_AUTOMATIC
	self[GameSettings.SETTING.HUD_SPEED_GAUGE] = SpeedMeterDisplay.GAUGE_MODE_RPM
	self[GameSettings.SETTING.INGAME_MAP_FILTER] = 0
	self[GameSettings.SETTING.INGAME_MAP_STATE] = IngameMap.STATE_MINIMAP_ROUND

	if GS_IS_CONSOLE_VERSION then
		self[GameSettings.SETTING.IS_GAMEPAD_ENABLED] = true
		self[GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED] = false
		self[GameSettings.SETTING.INPUT_HELP_MODE] = GS_INPUT_HELP_MODE_GAMEPAD
	end

	if GS_PLATFORM_GGP then
		self[GameSettings.SETTING.IS_GAMEPAD_ENABLED] = true

		if not getIsKeyboardAvailable() then
			self[GameSettings.SETTING.INPUT_HELP_MODE] = GS_INPUT_HELP_MODE_GAMEPAD
		end
	end

	self.printedSettingsChanges = {
		[GameSettings.SETTING.VOLUME_MASTER] = "Setting 'Master Volume': %.3f",
		[GameSettings.SETTING.VOLUME_MUSIC] = "Setting 'Music Volume': %.3f",
		[GameSettings.SETTING.VOLUME_VEHICLE] = "Setting 'Vehicle Volume': %.3f",
		[GameSettings.SETTING.VOLUME_ENVIRONMENT] = "Setting 'Environment Volume': %.3f",
		[GameSettings.SETTING.VOLUME_RADIO] = "Setting 'Radio Volume': %.3f",
		[GameSettings.SETTING.VOLUME_GUI] = "Setting 'GUI Volume': %.3f",
		[GameSettings.SETTING.SHOW_TRIGGER_MARKER] = "Setting 'Show Trigger Marker': %s",
		[GameSettings.SETTING.IS_TRAIN_TABBABLE] = "Setting 'Is Train Tabbable': %s",
		[GameSettings.SETTING.RADIO_IS_ACTIVE] = "Setting 'Radio Active': %s",
		[GameSettings.SETTING.RADIO_VEHICLE_ONLY] = "Setting 'Radio Vehicle Only': %s",
		[GameSettings.SETTING.SHOW_HELP_ICONS] = "Setting 'Show Help Icons': %s",
		[GameSettings.SETTING.USE_COLORBLIND_MODE] = "Setting 'Use Colorblind Mode': %s",
		[GameSettings.SETTING.EASY_ARM_CONTROL] = "Setting 'Easy Arm Control': %s",
		[GameSettings.SETTING.INVERT_Y_LOOK] = "Setting 'Invert Y-Look': %s",
		[GameSettings.SETTING.SHOW_FIELD_INFO] = "Setting 'Show Field-Info': %s"
	}

	return self
end

function GameSettings:getTableValue(name, index)
	if name == nil then
		print("Error: GameSetting table name missing or nil!")

		return false
	end

	if index == nil then
		print("Error: GameSetting table index missing or nil!")

		return false
	end

	return self[name][index]
end

function GameSettings:setTableValue(name, index, value, doSave)
	if name == nil then
		print("Error: GameSetting table name missing or nil!")

		return false
	end

	if index == nil then
		print("Error: GameSetting table index missing or nil!")

		return false
	end

	if value == nil then
		print("Error: GameSetting table value missing or nil for index '" .. index("'!"))

		return false
	end

	if self[name] == nil then
		print("Error: GameSetting table '" .. name .. "' not found!")

		return false
	end

	self[name][index] = value

	if doSave then
		self:saveToXMLFile(g_savegameXML)
	end

	return true
end

function GameSettings:getValue(name)
	if name == nil then
		Logging.error("GameSetting %s missing or nil!", name)
		printCallstack()

		return false
	end

	return self[name]
end

function GameSettings:setValue(name, value, doSave)
	if name == nil then
		Logging.error("GameSetting %s missing or nil!", name)
		printCallstack()

		return false
	end

	if value == nil then
		Logging.error("GameSetting value missing or nil for setting '%s'!", name)
		printCallstack()

		return false
	end

	if self[name] == nil then
		Logging.error("GameSetting '" .. name .. "' not found!")

		return false
	end

	self[name] = value

	if self.printedSettingsChanges[name] ~= nil then
		print("  " .. string.format(self.printedSettingsChanges[name], value))
	end

	if self.notifyOnChange then
		local messageType = MessageType.SETTING_CHANGED[name]

		self.messageCenter:publish(messageType, value)
	end

	if doSave then
		self:saveToXMLFile(g_savegameXML)
	end

	return true
end

function GameSettings:loadFromXML(xmlFile)
	if xmlFile ~= nil then
		if GS_PLATFORM_PC then
			self:setValue(GameSettings.SETTING.DEFAULT_SERVER_PORT, MathUtil.clamp(Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.defaultMultiplayerPort"), 10823), 0, 65535))

			local preset = GameSettings.PERFORMANCE_CLASS_PRESETS[Utils.getPerformanceClassId()]

			self:setValue(GameSettings.SETTING.MAX_NUM_MIRRORS, MathUtil.clamp(Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.maxNumMirrors"), preset.maxNumMirrors), 0, 7))
			self:setValue(GameSettings.SETTING.LIGHTS_PROFILE, MathUtil.clamp(Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.lightsProfile"), preset.lightsProfile), GS_PROFILE_LOW, GS_PROFILE_VERY_HIGH))

			local isHeadTrackingEnabled = getXMLBool(xmlFile, "gameSettings.isHeadTrackingEnabled")

			if isHeadTrackingEnabled ~= nil then
				self:setValue(GameSettings.SETTING.HEAD_TRACKING_ENABLED_SET_BY_USER, true)
				self:setValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED, isHeadTrackingEnabled)
			end

			self:setValue(GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.soundPlayer#allowStreams"), self[GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED]))

			local motorStopTimerDuration = getXMLInt(xmlFile, "gameSettings.motorStopTimerDuration")

			if motorStopTimerDuration ~= nil then
				self:setValue(GameSettings.SETTING.MOTOR_STOP_TIMER_DURATION, motorStopTimerDuration * 1000)
			end

			local horseAbandonTimerDuration = getXMLInt(xmlFile, "gameSettings.horseAbandonTimerDuration")

			if horseAbandonTimerDuration ~= nil then
				self:setValue(GameSettings.SETTING.HORSE_ABANDON_TIMER_DURATION, horseAbandonTimerDuration * 1000)
			end

			local isGamepadEnabled = getXMLBool(xmlFile, "gameSettings.isGamepadEnabled")

			if isGamepadEnabled ~= nil then
				self:setValue(GameSettings.SETTING.GAMEPAD_ENABLED_SET_BY_USER, true)
				self:setValue(GameSettings.SETTING.IS_GAMEPAD_ENABLED, isGamepadEnabled)
			end
		end

		self:setValue(GameSettings.SETTING.REAL_BEACON_LIGHTS, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.realBeaconLights"), self[GameSettings.SETTING.REAL_BEACON_LIGHTS]))

		if GS_PLATFORM_PC or GS_PLATFORM_GGP then
			local mpLanguage = getXMLInt(xmlFile, "gameSettings.mpLanguage")

			if mpLanguage ~= nil and mpLanguage >= 0 and mpLanguage <= getNumOfLanguages() - 1 then
				self:setValue(GameSettings.SETTING.MP_LANGUAGE, mpLanguage)
			end

			local inputHelpMode = getXMLInt(xmlFile, "gameSettings.inputHelpMode")

			if inputHelpMode ~= nil then
				if inputHelpMode == GS_INPUT_HELP_MODE_AUTO or inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD or inputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD then
					self:setValue(GameSettings.SETTING.INPUT_HELP_MODE, inputHelpMode)

					if not getGamepadEnabled() and inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
						self:setValue(GameSettings.SETTING.INPUT_HELP_MODE, GS_INPUT_HELP_MODE_AUTO)
					end
				else
					print("Warning: Invalid input help mode")
				end
			end
		end

		local fovY = getXMLFloat(xmlFile, "gameSettings.fovY")

		if fovY ~= nil then
			self:setValue(GameSettings.SETTING.FOV_Y, MathUtil.clamp(math.rad(fovY), g_fovYMin, g_fovYMax))
		end

		local uiScale = getXMLFloat(xmlFile, "gameSettings.uiScale")

		if uiScale ~= nil then
			self:setValue(GameSettings.SETTING.UI_SCALE, MathUtil.clamp(uiScale, 0.5, 1.5))
		end

		local modToggle = getXMLBool(xmlFile, "gameSettings.showAllMods")

		if modToggle ~= nil then
			self:setValue(GameSettings.SETTING.SHOW_ALL_MODS, modToggle)
		end

		if not GS_IS_CONSOLE_VERSION and not GS_PLATFORM_GGP then
			local val = Utils.getNoNil(getXMLString(xmlFile, "gameSettings.onlinePresenceName"), self[GameSettings.SETTING.ONLINE_PRESENCE_NAME])

			if val == "" then
				val = getUserName():trim()
			end

			self:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, val)
		end

		self:setValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.player#lastPlayerStyleMale"), self[GameSettings.SETTING.LAST_PLAYER_STYLE_MALE]))
		self:setTableValueFromXML("joinGame", "password", getXMLString, xmlFile, "gameSettings.joinGame#password")
		self:setTableValueFromXML("joinGame", "hasNoPassword", getXMLBool, xmlFile, "gameSettings.joinGame#hasNoPassword")
		self:setTableValueFromXML("joinGame", "isNotEmpty", getXMLBool, xmlFile, "gameSettings.joinGame#isNotEmpty")
		self:setTableValueFromXML("joinGame", "onlyWithAllModsAvailable", getXMLBool, xmlFile, "gameSettings.joinGame#onlyWithAllModsAvailable")
		self:setTableValueFromXML("joinGame", "serverName", getXMLString, xmlFile, "gameSettings.joinGame#serverName")
		self:setTableValueFromXML("joinGame", "mapId", getXMLString, xmlFile, "gameSettings.joinGame#mapId")
		self:setTableValueFromXML("joinGame", "language", getXMLInt, xmlFile, "gameSettings.joinGame#language")
		self:setTableValueFromXML("joinGame", "capacity", getXMLInt, xmlFile, "gameSettings.joinGame#capacity")
		self:setTableValueFromXML("joinGame", "allowCrossPlay", getXMLBool, xmlFile, "gameSettings.joinGame#allowCrossPlay")
		self:setTableValueFromXML("createGame", "password", getXMLString, xmlFile, "gameSettings.createGame#password")

		if not GS_IS_CONSOLE_VERSION then
			self:setTableValueFromXML("createGame", "serverName", getXMLString, xmlFile, "gameSettings.createGame#name")
		end

		self:setTableValueFromXML("createGame", "port", getXMLInt, xmlFile, "gameSettings.createGame#port")
		self:setTableValueFromXML("createGame", "useUpnp", getXMLBool, xmlFile, "gameSettings.createGame#useUpnp")
		self:setTableValueFromXML("createGame", "autoAccept", getXMLBool, xmlFile, "gameSettings.createGame#autoAccept")
		self:setTableValueFromXML("createGame", "autoSave", getXMLBool, xmlFile, "gameSettings.createGame#autoSave")
		self:setTableValueFromXML("createGame", "allowOnlyFriends", getXMLBool, xmlFile, "gameSettings.createGame#allowOnlyFriends")
		self:setTableValueFromXML("createGame", "allowCrossPlay", getXMLBool, xmlFile, "gameSettings.createGame#allowCrossPlay")
		self:setTableValueFromXML("createGame", "capacity", getXMLInt, xmlFile, "gameSettings.createGame#capacity")
		self:setTableValueFromXML("createGame", "bandwidth", getXMLInt, xmlFile, "gameSettings.createGame#bandwidth")
		self:setTableValueFromXML("createGame", "allowCrossPlay", getXMLBool, xmlFile, "gameSettings.createGame#allowCrossPlay")
		self:setValue(GameSettings.SETTING.IS_TRAIN_TABBABLE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.isTrainTabbable"), self[GameSettings.SETTING.IS_TRAIN_TABBABLE]))
		self:setValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.radioVehicleOnly"), self[GameSettings.SETTING.RADIO_VEHICLE_ONLY]))
		self:setValue(GameSettings.SETTING.RADIO_IS_ACTIVE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.radioIsActive"), self[GameSettings.SETTING.RADIO_IS_ACTIVE]))
		self:setValue(GameSettings.SETTING.USE_COLORBLIND_MODE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.useColorblindMode"), self[GameSettings.SETTING.USE_COLORBLIND_MODE]))
		self:setValue(GameSettings.SETTING.EASY_ARM_CONTROL, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.easyArmControl"), self[GameSettings.SETTING.EASY_ARM_CONTROL]))
		self:setValue(GameSettings.SETTING.SHOW_TRIGGER_MARKER, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showTriggerMarker"), self[GameSettings.SETTING.SHOW_TRIGGER_MARKER]))
		self:setValue(GameSettings.SETTING.SHOW_FIELD_INFO, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showFieldInfo"), self[GameSettings.SETTING.SHOW_FIELD_INFO]))
		self:setValue(GameSettings.SETTING.RESET_CAMERA, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.resetCamera"), self[GameSettings.SETTING.RESET_CAMERA]))
		self:setValue(GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.activeSuspensionCamera"), self[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA]))
		self:setValue(GameSettings.SETTING.CAMERA_CHECK_COLLISION, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.cameraCheckCollision"), self[GameSettings.SETTING.CAMERA_CHECK_COLLISION]))
		self:setValue(GameSettings.SETTING.USE_WORLD_CAMERA, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.useWorldCamera"), self[GameSettings.SETTING.USE_WORLD_CAMERA]))
		self:setValue(GameSettings.SETTING.INVERT_Y_LOOK, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.invertYLook"), self[GameSettings.SETTING.INVERT_Y_LOOK]))
		self:setValue(GameSettings.SETTING.SHOW_HELP_ICONS, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showHelpIcons"), self[GameSettings.SETTING.SHOW_HELP_ICONS]))
		self:setValue(GameSettings.SETTING.SHOW_HELP_MENU, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.showHelpMenu"), self[GameSettings.SETTING.SHOW_HELP_MENU]))
		self:setValue(GameSettings.SETTING.VOLUME_RADIO, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.radio"), self[GameSettings.SETTING.VOLUME_RADIO]))
		self:setValue(GameSettings.SETTING.VOLUME_VEHICLE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.vehicle"), self[GameSettings.SETTING.VOLUME_VEHICLE]))
		self:setValue(GameSettings.SETTING.VOLUME_ENVIRONMENT, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.environment"), self[GameSettings.SETTING.VOLUME_ENVIRONMENT]))
		self:setValue(GameSettings.SETTING.VOLUME_GUI, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.gui"), self[GameSettings.SETTING.VOLUME_GUI]))
		self:setValue(GameSettings.SETTING.VOLUME_MASTER, getMasterVolume())
		self:setValue(GameSettings.SETTING.VOLUME_MUSIC, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.music"), self[GameSettings.SETTING.VOLUME_MUSIC]))
		self:setValue(GameSettings.SETTING.VOLUME_VOICE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.voice"), self[GameSettings.SETTING.VOLUME_VOICE]))
		self:setValue(GameSettings.SETTING.VOLUME_VOICE_INPUT, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.volume.voiceInput"), self[GameSettings.SETTING.VOLUME_VOICE_INPUT]))
		self:setValue(GameSettings.SETTING.VOICE_MODE, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.voice#mode"), self[GameSettings.SETTING.VOICE_MODE]))
		self:setValue(GameSettings.SETTING.FORCE_FEEDBACK, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.forceFeedback"), self[GameSettings.SETTING.FORCE_FEEDBACK]))
		self:setValue(GameSettings.SETTING.CAMERA_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.cameraSensitivity"), self[GameSettings.SETTING.CAMERA_SENSITIVITY]))
		self:setValue(GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.vehicleArmSensitivity"), self[GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY]))
		self:setValue(GameSettings.SETTING.STEERING_BACK_SPEED, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.steeringBackSpeed"), self[GameSettings.SETTING.STEERING_BACK_SPEED]))
		self:setValue(GameSettings.SETTING.STEERING_SENSITIVITY, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.steeringSensitivity"), self[GameSettings.SETTING.STEERING_SENSITIVITY]))
		self:setValue(GameSettings.SETTING.DIRECTION_CHANGE_MODE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.directionChangeMode"), self[GameSettings.SETTING.DIRECTION_CHANGE_MODE]))
		self:setValue(GameSettings.SETTING.GEAR_SHIFT_MODE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.gearShiftMode"), self[GameSettings.SETTING.GEAR_SHIFT_MODE]))
		self:setValue(GameSettings.SETTING.HUD_SPEED_GAUGE, Utils.getNoNil(getXMLFloat(xmlFile, "gameSettings.hudSpeedGauge"), self[GameSettings.SETTING.HUD_SPEED_GAUGE]))
		self:setValue(GameSettings.SETTING.INGAME_MAP_STATE, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.ingameMapState"), IngameMap.STATE_MINIMAP_ROUND))
		self:setValue(GameSettings.SETTING.INGAME_MAP_FILTER, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.ingameMapFilters"), self[GameSettings.SETTING.INGAME_MAP_FILTER]))
		self:setValue(GameSettings.SETTING.MONEY_UNIT, Utils.getNoNil(getXMLInt(xmlFile, "gameSettings.units.money"), self[GameSettings.SETTING.MONEY_UNIT]))
		self:setValue(GameSettings.SETTING.USE_MILES, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.units.miles"), self[GameSettings.SETTING.USE_MILES]))
		self:setValue(GameSettings.SETTING.USE_FAHRENHEIT, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.units.fahrenheit"), self[GameSettings.SETTING.USE_FAHRENHEIT]))
		self:setValue(GameSettings.SETTING.USE_ACRE, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.units.acre"), self[GameSettings.SETTING.USE_ACRE]))
		self:setValue(GameSettings.SETTING.GYROSCOPE_STEERING, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.gyroscopeSteering"), self[GameSettings.SETTING.GYROSCOPE_STEERING]))
		self:setValue(GameSettings.SETTING.HINTS, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.hints"), self[GameSettings.SETTING.HINTS]))
		self:setValue(GameSettings.SETTING.CAMERA_TILTING, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.cameraTilting"), self[GameSettings.SETTING.CAMERA_TILTING]))
		self:setValue(GameSettings.SETTING.CAMERA_BOBBING, Utils.getNoNil(getXMLBool(xmlFile, "gameSettings.cameraBobbing"), self[GameSettings.SETTING.CAMERA_BOBBING]))

		self.notifyOnChange = true
	end
end

function GameSettings:setTableValueFromXML(tableName, index, xmlFunc, xmlFile, xmlPath)
	local value = xmlFunc(xmlFile, xmlPath)

	if value ~= nil then
		self:setTableValue(tableName, index, value)
	end
end

function GameSettings:saveToXMLFile(xmlFile)
	if xmlFile ~= nil then
		setXMLBool(xmlFile, "gameSettings.invertYLook", self[GameSettings.SETTING.INVERT_Y_LOOK])
		setXMLBool(xmlFile, "gameSettings.isHeadTrackingEnabled", self[GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED])
		setXMLFloat(xmlFile, "gameSettings.forceFeedback", self[GameSettings.SETTING.FORCE_FEEDBACK])
		setXMLBool(xmlFile, "gameSettings.isGamepadEnabled", self[GameSettings.SETTING.IS_GAMEPAD_ENABLED])
		setXMLFloat(xmlFile, "gameSettings.cameraSensitivity", self[GameSettings.SETTING.CAMERA_SENSITIVITY])
		setXMLFloat(xmlFile, "gameSettings.vehicleArmSensitivity", self[GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY])
		setXMLFloat(xmlFile, "gameSettings.steeringBackSpeed", self[GameSettings.SETTING.STEERING_BACK_SPEED])
		setXMLFloat(xmlFile, "gameSettings.steeringSensitivity", self[GameSettings.SETTING.STEERING_SENSITIVITY])
		setXMLInt(xmlFile, "gameSettings.inputHelpMode", self[GameSettings.SETTING.INPUT_HELP_MODE])
		setXMLBool(xmlFile, "gameSettings.easyArmControl", self[GameSettings.SETTING.EASY_ARM_CONTROL])
		setXMLBool(xmlFile, "gameSettings.gyroscopeSteering", self[GameSettings.SETTING.GYROSCOPE_STEERING])
		setXMLBool(xmlFile, "gameSettings.hints", self[GameSettings.SETTING.HINTS])
		setXMLBool(xmlFile, "gameSettings.cameraTilting", self[GameSettings.SETTING.CAMERA_TILTING])
		setXMLBool(xmlFile, "gameSettings.showAllMods", self[GameSettings.SETTING.SHOW_ALL_MODS])
		setXMLString(xmlFile, "gameSettings.onlinePresenceName", self[GameSettings.SETTING.ONLINE_PRESENCE_NAME])
		setXMLBool(xmlFile, "gameSettings.player#lastPlayerStyleMale", self[GameSettings.SETTING.LAST_PLAYER_STYLE_MALE])
		setXMLInt(xmlFile, "gameSettings.mpLanguage", self[GameSettings.SETTING.MP_LANGUAGE])
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.createGame#password", self.createGame.password)
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.createGame#name", self.createGame.serverName)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.createGame#port", self.createGame.port)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#useUpnp", self.createGame.useUpnp)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#autoAccept", self.createGame.autoAccept)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#autoSave", self.createGame.autoSave)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#allowOnlyFriends", self.createGame.allowOnlyFriends)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#allowCrossPlay", self.createGame.allowCrossPlay)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.createGame#capacity", self.createGame.capacity)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.createGame#bandwidth", self.createGame.bandwidth)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.createGame#allowCrossPlay", self.createGame.allowCrossPlay)
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.joinGame#password", self.joinGame.password)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#hasNoPassword", self.joinGame.hasNoPassword)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#isNotEmpty", self.joinGame.isNotEmpty)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#onlyWithAllModsAvailable", self.joinGame.onlyWithAllModsAvailable)
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.joinGame#serverName", self.joinGame.serverName)
		self:setXMLValue(xmlFile, setXMLString, "gameSettings.joinGame#mapId", self.joinGame.mapId)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.joinGame#language", self.joinGame.language)
		self:setXMLValue(xmlFile, setXMLInt, "gameSettings.joinGame#capacity", self.joinGame.capacity)
		self:setXMLValue(xmlFile, setXMLBool, "gameSettings.joinGame#allowCrossPlay", self.joinGame.allowCrossPlay)
		setXMLFloat(xmlFile, "gameSettings.volume.music", self[GameSettings.SETTING.VOLUME_MUSIC])
		setXMLFloat(xmlFile, "gameSettings.volume.vehicle", self[GameSettings.SETTING.VOLUME_VEHICLE])
		setXMLFloat(xmlFile, "gameSettings.volume.environment", self[GameSettings.SETTING.VOLUME_ENVIRONMENT])
		setXMLFloat(xmlFile, "gameSettings.volume.radio", self[GameSettings.SETTING.VOLUME_RADIO])
		setXMLFloat(xmlFile, "gameSettings.volume.gui", self[GameSettings.SETTING.VOLUME_GUI])
		setXMLFloat(xmlFile, "gameSettings.volume.voice", self[GameSettings.SETTING.VOLUME_VOICE])
		setXMLFloat(xmlFile, "gameSettings.volume.voiceInput", self[GameSettings.SETTING.VOLUME_VOICE_INPUT])
		setXMLBool(xmlFile, "gameSettings.soundPlayer#allowStreams", self[GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED])
		setXMLBool(xmlFile, "gameSettings.radioIsActive", self[GameSettings.SETTING.RADIO_IS_ACTIVE])
		setXMLBool(xmlFile, "gameSettings.radioVehicleOnly", self[GameSettings.SETTING.RADIO_VEHICLE_ONLY])
		setXMLInt(xmlFile, "gameSettings.voice#mode", self[GameSettings.SETTING.VOICE_MODE])
		setXMLInt(xmlFile, "gameSettings.units.money", self[GameSettings.SETTING.MONEY_UNIT])
		setXMLBool(xmlFile, "gameSettings.units.miles", self[GameSettings.SETTING.USE_MILES])
		setXMLBool(xmlFile, "gameSettings.units.fahrenheit", self[GameSettings.SETTING.USE_FAHRENHEIT])
		setXMLBool(xmlFile, "gameSettings.units.acre", self[GameSettings.SETTING.USE_ACRE])
		setXMLBool(xmlFile, "gameSettings.isTrainTabbable", self[GameSettings.SETTING.IS_TRAIN_TABBABLE])
		setXMLBool(xmlFile, "gameSettings.showTriggerMarker", self[GameSettings.SETTING.SHOW_TRIGGER_MARKER])
		setXMLBool(xmlFile, "gameSettings.showFieldInfo", self[GameSettings.SETTING.SHOW_FIELD_INFO])
		setXMLBool(xmlFile, "gameSettings.showHelpIcons", self[GameSettings.SETTING.SHOW_HELP_ICONS])
		setXMLBool(xmlFile, "gameSettings.showHelpMenu", self[GameSettings.SETTING.SHOW_HELP_MENU])
		setXMLBool(xmlFile, "gameSettings.resetCamera", self[GameSettings.SETTING.RESET_CAMERA])
		setXMLBool(xmlFile, "gameSettings.activeSuspensionCamera", self[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA])
		setXMLBool(xmlFile, "gameSettings.cameraCheckCollision", self[GameSettings.SETTING.CAMERA_CHECK_COLLISION])
		setXMLBool(xmlFile, "gameSettings.useWorldCamera", self[GameSettings.SETTING.USE_WORLD_CAMERA])
		setXMLInt(xmlFile, "gameSettings.ingameMapState", self[GameSettings.SETTING.INGAME_MAP_STATE])
		setXMLInt(xmlFile, "gameSettings.ingameMapFilters", self[GameSettings.SETTING.INGAME_MAP_FILTER])
		setXMLInt(xmlFile, "gameSettings.directionChangeMode", self[GameSettings.SETTING.DIRECTION_CHANGE_MODE])
		setXMLInt(xmlFile, "gameSettings.gearShiftMode", self[GameSettings.SETTING.GEAR_SHIFT_MODE])
		setXMLInt(xmlFile, "gameSettings.hudSpeedGauge", self[GameSettings.SETTING.HUD_SPEED_GAUGE])
		setXMLBool(xmlFile, "gameSettings.useColorblindMode", self[GameSettings.SETTING.USE_COLORBLIND_MODE])
		setXMLInt(xmlFile, "gameSettings.maxNumMirrors", self[GameSettings.SETTING.MAX_NUM_MIRRORS])
		setXMLInt(xmlFile, "gameSettings.lightsProfile", self[GameSettings.SETTING.LIGHTS_PROFILE])
		setXMLFloat(xmlFile, "gameSettings.fovY", math.deg(self[GameSettings.SETTING.FOV_Y]))
		setXMLFloat(xmlFile, "gameSettings.uiScale", self[GameSettings.SETTING.UI_SCALE])
		setXMLBool(xmlFile, "gameSettings.realBeaconLights", self[GameSettings.SETTING.REAL_BEACON_LIGHTS])
		setXMLBool(xmlFile, "gameSettings.cameraBobbing", self[GameSettings.SETTING.CAMERA_BOBBING])
		saveXMLFile(xmlFile)
		syncProfileFiles()
	end
end

function GameSettings:setXMLValue(xmlFile, func, xPath, value)
	if value ~= nil then
		func(xmlFile, xPath, value)
	end
end
