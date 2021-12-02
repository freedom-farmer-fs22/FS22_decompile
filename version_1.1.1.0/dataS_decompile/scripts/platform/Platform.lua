Platform = {}

function Platform.init()
	local self = Platform
	self.id = getPlatformId()
	self.gameplay = {}
	self.blockedKeyboardCombos = {}
	self.lockedInputActionNames = {}

	Platform.Default.apply(self)

	if GS_PLATFORM_XBOX then
		Platform.Console.apply(self)
		Platform.Xbox.apply(self)
	elseif GS_PLATFORM_PLAYSTATION then
		Platform.Console.apply(self)
		Platform.Playstation.apply(self)
	elseif GS_PLATFORM_GGP then
		Platform.Stadia.apply(self)
	elseif GS_PLATFORM_SWITCH then
		Platform.Mobile.apply(self)
		Platform.Switch.apply(self)
	elseif GS_PLATFORM_ID == PlatformId.IOS then
		Platform.Mobile.apply(self)
		Platform.IOS.apply(self)
	elseif GS_PLATFORM_ID == PlatformId.ANDROID then
		Platform.Mobile.apply(self)
		Platform.Android.apply(self)
	end
end

Platform.Default = {}

function Platform.Default:apply()
	print("Platform: loading defaults")

	self.isPC = GS_PLATFORM_PC
	self.isSteam = GS_IS_STEAM_VERSION
	self.showStartupScreen = true
	self.showGamerTagInMainScreen = false
	self.canChangeGamerTag = true
	self.showRentServerWebButton = true
	self.hasFriendInvitation = false
	self.hasFriendFilter = false
	self.hasNativeProfiles = false
	self.hasNetworkSettings = true
	self.guiPrefixes = {}
	self.supportsMods = true
	self.allowsScriptMods = true
	self.allowsModDirectoryOverride = self.isPC
	self.hasSlotLimitation = true
	self.supportsCustomInternetRadios = self.isPC
	self.hasLimitedModSpace = false
	self.supportsPushToTalk = true
	self.hasTextChat = true
	self.hasAudioChat = false
	self.hasPlayer = true
	self.allowPlayerPickUp = true
	self.supportsPedestrians = true
	self.supportsFoliageBending = true
	self.canQuitApplication = true
	self.supportsMultiplayer = true
	self.safeFrameOffsetX = 25
	self.safeFrameOffsetY = 25
	self.safeFrameMajorOffsetX = 25
	self.safeFrameMajorOffsetY = 25
	self.minFovY = 45
	self.maxFovY = 120
	self.forcedUIResolution = nil
	self.usesFixedExposure = false
	self.verifyMultiplayerAvailabilityInMenu = Platform.Default.verifyMultiplayerAvailabilityInMenu
	self.gameplay.defaultTimeScale = 5
	self.gameplay.timeScaleSettings = {
		0.5,
		1,
		2,
		3,
		5,
		6,
		10,
		15,
		30,
		60,
		120
	}
	self.gameplay.timeScaleDevSettings = {
		2000,
		12000,
		60000
	}
	self.gameplay.sprayLevelMaxValue = 2
	self.gameplay.harvestScaleRation = {
		0.45,
		0.15,
		0.15,
		0.2,
		0.025,
		0.025
	}
	self.gameplay.useSprayDiffuseMaps = true
	self.gameplay.useTerrainDetailAngle = true
	self.gameplay.useMultipleSprayLevels = true
	self.gameplay.usePlowCounter = true
	self.gameplay.useLimeCounter = true
	self.gameplay.useStubbleShred = true
	self.gameplay.automaticDischarge = false
	self.gameplay.automaticFilling = false
	self.gameplay.automaticAttach = false
	self.gameplay.automaticBaleDrop = false
	self.gameplay.automaticLights = false
	self.gameplay.automaticPipeUnfolding = false
	self.gameplay.automaticVehicleControl = false
	self.gameplay.keepFoldingWhileDetached = false
	self.gameplay.foldAfterAIFinished = false
	self.gameplay.lightsProfile = nil
	self.gameplay.useWorldCameraInside = true
	self.gameplay.useWorldCameraOutside = true
	self.gameplay.maxCameraZoomFactor = 1
	self.gameplay.dirtDurationScale = 1
	self.gameplay.wheelSink = true
	self.gameplay.wheelDensityHeightSmooth = true
	self.gameplay.wheelVisualPressure = true
	self.gameplay.defaultFruitDestruction = true
	self.gameplay.defaultGyroscopeSteering = false
	self.gameplay.defaultCameraTilt = false
end

function Platform.Default.verifyMultiplayerAvailabilityInMenu()
	if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
		g_masterServerConnection:disconnectFromMasterServer()
		g_gui:changeScreen(nil, MainScreen)
	end

	if getNetworkError() then
		g_masterServerConnection:disconnectFromMasterServer()
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	end
end

Platform.Console = {
	apply = function (self)
		print("Platform: loading console")

		self.isConsole = true
		self.allowsScriptMods = false
		self.allowsModDirectoryOverride = false
		self.hasSlotLimitation = true
		self.canChangeGamerTag = false
		self.hasLimitedModSpace = true
		self.showRentServerWebButton = false
		self.hasFriendInvitation = true
		self.hasFriendFilter = true
		self.hasNativeProfiles = true
		self.hasNetworkSettings = false
		self.supportsPushToTalk = false
		self.hasTextChat = false
		self.hasAudioChat = true
		self.canQuitApplication = false
		self.hasNativeStore = true
		self.requiresConnectedGamepad = true
		self.safeFrameOffsetX = 40
		self.safeFrameOffsetY = 40
		self.safeFrameMajorOffsetX = 96
		self.safeFrameMajorOffsetY = 54
		self.forcedUIResolution = 1080
		self.maxFovY = 90
	end
}
Platform.Xbox = {
	apply = function (self)
		print("Platform: loading Xbox")

		self.isXbox = true
		self.needsSignIn = true
		self.showGamerTagInMainScreen = true

		table.insert(self.guiPrefixes, "xbox_")
	end
}
Platform.Playstation = {
	apply = function (self)
		print("Platform: loading Playstation")

		self.isPlaystation = true
		self.territory = getGameTerritory()

		if self.territory == "" then
			self.territory = nil
		end

		self.xoSwap = getPlatformXOSwap()

		table.insert(self.guiPrefixes, "ps_")

		if self.xoSwap then
			table.insert(self.guiPrefixes, "ps_xoSwap_")
		end

		if self.territory ~= nil then
			table.insert(self.guiPrefixes, "ps_" .. self.territory .. "_")

			if self.xoSwap then
				table.insert(self.guiPrefixes, "ps_xoSwap_" .. self.territory .. "_")
			end
		end
	end
}
Platform.Mobile = {
	apply = function (self)
		print("Platform: loading mobile")

		self.isMobile = true
		self.showStartupScreen = false
		self.supportsMods = false
		self.allowsScriptMods = false
		self.supportsPedestrians = false
		self.supportsFoliageBending = false
		self.canQuitApplication = false
		self.supportsMultiplayer = false
		self.hasPlayer = true
		self.allowPlayerPickUp = false
		self.safeFrameOffsetX = 50
		self.safeFrameOffsetY = 50
		self.forcedUIResolution = 1080
		self.usesFixedExposure = true
		self.gameplay.defaultTimeScale = 30
		self.gameplay.timeScaleSettings = {
			1,
			2,
			5,
			10,
			30,
			45
		}
		self.gameplay.hasShortNights = true
		self.gameplay.sprayLevelMaxValue = 1
		self.gameplay.harvestScaleRation = {
			1,
			0,
			0,
			0,
			0,
			0
		}
		self.gameplay.useSprayDiffuseMaps = false
		self.gameplay.useTerrainDetailAngle = false
		self.gameplay.useMultipleSprayLevels = false
		self.gameplay.usePlowCounter = false
		self.gameplay.useLimeCounter = false
		self.gameplay.useStubbleShred = false
		self.gameplay.automaticDischarge = true
		self.gameplay.automaticFilling = true
		self.gameplay.automaticAttach = true
		self.gameplay.automaticBaleDrop = true
		self.gameplay.automaticLights = true
		self.gameplay.automaticPipeUnfolding = true
		self.gameplay.automaticVehicleControl = true
		self.gameplay.keepFoldingWhileDetached = true
		self.gameplay.foldAfterAIFinished = true
		self.gameplay.lightsProfile = GS_PROFILE_LOW
		self.gameplay.useWorldCameraInside = false
		self.gameplay.useWorldCameraOutside = true
		self.gameplay.maxCameraZoomFactor = 0.6
		self.gameplay.dirtDurationScale = 2
		self.gameplay.wheelSink = false
		self.gameplay.wheelDensityHeightSmooth = false
		self.gameplay.wheelVisualPressure = false
		self.gameplay.defaultFruitDestruction = false
	end
}
Platform.Switch = {
	apply = function (self)
		print("Platform: loading Switch")

		self.isSwitch = true
		self.showStartupScreen = true

		table.insert(self.guiPrefixes, "switch_")

		self.territory = getGameTerritory()

		if self.territory == "" then
			self.territory = nil
		end

		self.gameplay.defaultGyroscopeSteering = false
		self.gameplay.defaultCameraTilt = false
	end
}
Platform.Stadia = {
	apply = function (self)
		print("Platform: loading Stadia")

		self.isStadia = true
		self.supportsMods = false
		self.showGamerTagInMainScreen = true
		self.showRentServerWebButton = false
		self.hasFriendInvitation = true
		self.hasNativeProfiles = true
		self.hasNetworkSettings = false
		self.maxFovY = 90

		table.insert(self.blockedKeyboardCombos, {
			"KEY_lshift",
			"KEY_tab"
		})
		table.insert(self.blockedKeyboardCombos, {
			"KEY_f8"
		})
		table.insert(self.blockedKeyboardCombos, {
			"KEY_f12"
		})
		table.insert(self.blockedKeyboardCombos, {
			"KEY_esc"
		})
		table.insert(self.blockedKeyboardCombos, {
			"BUTTON_10"
		})
		table.insert(self.lockedInputActionNames, "TAKE_SCREENSHOT")
		table.insert(self.lockedInputActionNames, "PUSH_TO_TALK")
		table.insert(self.lockedInputActionNames, "TOGGLE_MAP")
		table.insert(self.lockedInputActionNames, "TOGGLE_STORE")
		table.insert(self.guiPrefixes, "stadia_")
	end
}
Platform.IOS = {
	apply = function (self)
		print("Platform: loading iOS")

		self.isIOS = true
		self.hasInAppPurchases = false
	end
}
Platform.Android = {
	apply = function (self)
		print("Platform: loading Android")

		self.isAndroid = true
		self.hasInAppPurchases = false
	end
}
