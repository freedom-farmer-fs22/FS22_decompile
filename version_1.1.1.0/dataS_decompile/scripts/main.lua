local platformId = getPlatformId()
GS_PLATFORM_ID = platformId
GS_PLATFORM_PC = platformId == PlatformId.WIN or platformId == PlatformId.MAC
GS_PLATFORM_XBOX = platformId == PlatformId.XBOX_ONE or platformId == PlatformId.XBOX_SERIES
GS_PLATFORM_PLAYSTATION = platformId == PlatformId.PS4 or platformId == PlatformId.PS5
GS_PLATFORM_GGP = platformId == PlatformId.GGP
GS_PLATFORM_SWITCH = platformId == PlatformId.SWITCH
GS_PLATFORM_PHONE = platformId == PlatformId.ANDROID or platformId == PlatformId.IOS
GS_IS_CONSOLE_VERSION = GS_PLATFORM_XBOX or GS_PLATFORM_PLAYSTATION
GS_IS_MOBILE_VERSION = GS_PLATFORM_PHONE or GS_PLATFORM_SWITCH
GS_PROFILE_LOW = 1
GS_PROFILE_MEDIUM = 2
GS_PROFILE_HIGH = 3
GS_PROFILE_VERY_HIGH = 4
local debugTool = debug
debug = nil
g_gameVersion = 4
g_gameVersionNotification = "1.1.1.0"
g_gameVersionDisplay = "1.1.1.0"
g_gameVersionDisplayExtra = ""
g_presentationSettingsFile = "dataS/presentationSettings.xml"
g_isPresentationVersion = false
g_isPresentationVersionLogoEnabled = true
g_isPresentationVersionShopEnabled = false
g_isPresentationVersionWardrobeEnabled = false
g_isPresentationVersionBuildModeEnabled = false
g_isPresentationVersionDlcEnabled = false
g_isPresentationVersionAllMapsEnabled = false
g_isPresentationVersionUSMapEnabled = false
g_isPresentationVersionFRMapEnabled = false
g_isPresentationVersionAlpineMapEnabled = false
g_isPresentationVersionSpecialStore = false
g_isPresentationVersionSpecialStorePath = "dataS/storeItems_presentationVersion.xml"
g_isPresentationVersionAIEnabled = false
g_isPresentationVersionHideMenuButtons = true
g_isPresentationVersionUseReloadButton = false
g_showWatermark = false
g_isDevelopmentConsoleScriptModTesting = false
g_isPresentationVersionAlwaysDay = false
g_isPresentationVersionShowDrivingHelp = false
g_isPresentationVersionMenuDisabled = false
g_isPresentationVersionNextLanguageIndex = nil
g_isPresentationVersionNextLanguageTimer = nil
g_isPresentationVersionPlaytimeCountdown = nil
g_isPresentationVersionIsTourEnabled = false
g_minModDescVersion = 60
g_maxModDescVersion = 62

source("dataS/scripts/std.lua")
source("dataS/scripts/events.lua")
source("dataS/scripts/game.lua")
source("dataS/scripts/mods.lua")
source("dataS/scripts/testing.lua")
source("dataS/scripts/Benchmark.lua")

g_language = 0
g_languageShort = "en"
g_languageSuffix = "_en"
g_showSafeFrame = false
g_flightModeEnabled = false
g_noHudModeEnabled = false
g_woodCuttingMarkerEnabled = true
g_isDevelopmentVersion = false
g_isServerStreamingVersion = false
g_addTestCommands = false
g_addCheatCommands = false
g_showDevelopmentWarnings = false
g_appIsSuspended = false
g_networkDebug = false
g_networkDebugPrints = false
g_gameRevision = "000"
g_buildName = ""
g_buildTypeParam = ""
g_showDeeplinkingFailedMessage = false
g_isSignedIn = false
g_settingsLanguageGUI = 0
g_availableLanguageNamesTable = {}
g_availableLanguagesTable = {}
g_fovYDefault = math.rad(60)
g_fovYMin = math.rad(45)
g_fovYMax = math.rad(90)
g_uiDebugEnabled = false
g_logFilePrefixTimestamp = true
g_vehicleColors = {
	{
		brandColor = "SHARED_WHITE2",
		name = "$l10n_ui_colorWhite"
	},
	{
		g = 0.8388,
		name = "$l10n_ui_colorBeige",
		b = 0.7304,
		r = 0.8228
	},
	{
		g = 0.5271,
		name = "$l10n_ui_colorSilver",
		b = 0.5271,
		r = 0.5271
	},
	{
		g = 0.294,
		name = "$l10n_ui_colorGreyLight",
		b = 0.294,
		r = 0.294
	},
	{
		g = 0.129,
		name = "$l10n_ui_colorGrey",
		b = 0.129,
		r = 0.129
	},
	{
		g = 0.069,
		name = "$l10n_ui_colorGreyDark",
		b = 0.069,
		r = 0.069
	},
	{
		g = 0.0254,
		name = "$l10n_ui_colorBlackOnyx",
		b = 0.0231,
		r = 0.0278
	},
	{
		g = 0.01,
		name = "$l10n_ui_colorBlackJet",
		b = 0.01,
		r = 0.01
	},
	{
		brandColor = "JOHNDEERE_YELLOW1",
		name = "John Deere"
	},
	{
		brandColor = "JCB_YELLOW1",
		name = "JCB"
	},
	{
		brandColor = "CHALLENGER_YELLOW1",
		name = "Challenger"
	},
	{
		brandColor = "SCHOUTEN_ORANGE1",
		name = "Schouten"
	},
	{
		brandColor = "FENDT_RED1",
		name = "Fendt"
	},
	{
		brandColor = "CASEIH_RED1",
		name = "Case IH"
	},
	{
		brandColor = "MASSEYFERGUSON_RED",
		name = "Massey Ferguson"
	},
	{
		brandColor = "HARDI_RED",
		name = "Hardi"
	},
	{
		brandColor = "NEWHOLLAND_BLUE2",
		name = "$l10n_ui_colorAzul"
	},
	{
		brandColor = "RABE_BLUE1",
		name = "Rabe"
	},
	{
		brandColor = "LEMKEN_BLUE1",
		name = "Lemken"
	},
	{
		brandColor = "NEWHOLLAND_BLUE1",
		name = "New Holland"
	},
	{
		brandColor = "BOECKMANN_BLUE1",
		name = "Boeckmann"
	},
	{
		brandColor = "GOLDHOFER_BLUE",
		name = "Goldhofer"
	},
	{
		g = 0.003,
		name = "$l10n_ui_colorBlueNavy",
		b = 0.031,
		r = 0.004
	},
	{
		brandColor = "LIZARD_PURPLE1",
		name = "$l10n_ui_colorPurple"
	},
	{
		brandColor = "VALTRA_GREEN2",
		name = "Valtra"
	},
	{
		brandColor = "DEUTZ_GREEN4",
		name = "Deutz Fahr"
	},
	{
		brandColor = "JOHNDEERE_GREEN1",
		name = "John Deere"
	},
	{
		brandColor = "FENDT_NEWGREEN1",
		name = "Fendt Nature Green"
	},
	{
		brandColor = "FENDT_OLDGREEN1",
		name = "Fendt Classic"
	},
	{
		brandColor = "KOTTE_GREEN2",
		name = "Kotte"
	},
	{
		brandColor = "CLAAS_GREEN1",
		name = "Claas"
	},
	{
		brandColor = "LIZARD_OLIVE1",
		name = "$l10n_ui_colorGreenOlive"
	},
	{
		brandColor = "LIZARD_ECRU1",
		name = "$l10n_ui_colorBeige"
	},
	{
		g = 0.068,
		name = "$l10n_ui_colorBrown",
		b = 0.03,
		r = 0.168
	},
	{
		g = 0.009,
		name = "$l10n_ui_colorRedCrimson",
		b = 0.006,
		r = 0.105
	},
	{
		brandColor = "LIZARD_PINK1",
		name = "$l10n_ui_colorPink"
	}
}

if Platform.isConsole then
	addReplacedCustomShader("alphaBlendedDecalShader.xml", "data/shaders/alphaBlendedDecalShader.xml")
	addReplacedCustomShader("alphaTestDisableShader.xml", "data/shaders/alphaTestDisableShader.xml")
	addReplacedCustomShader("beaconGlassShader.xml", "data/shaders/beaconGlassShader.xml")
	addReplacedCustomShader("buildingShader.xml", "data/shaders/buildingShader.xml")
	addReplacedCustomShader("buildingShaderUS.xml", "data/shaders/buildingShaderUS.xml")
	addReplacedCustomShader("bunkerSiloSilageShader.xml", "data/shaders/bunkerSiloSilageShader.xml")
	addReplacedCustomShader("carColorShader.xml", "data/shaders/carColorShader.xml")
	addReplacedCustomShader("characterShader.xml", "data/shaders/characterShader.xml")
	addReplacedCustomShader("cultivatorSoilShader.xml", "data/shaders/cultivatorSoilShader.xml")
	addReplacedCustomShader("cuttersShader.xml", "data/shaders/cuttersShader.xml")
	addReplacedCustomShader("emissiveAdditiveShader.xml", "data/shaders/emissiveAdditiveShader.xml")
	addReplacedCustomShader("emissiveFalloffShader.xml", "data/shaders/emissiveFalloffShader.xml")
	addReplacedCustomShader("emissiveLightsShader.xml", "data/shaders/emissiveLightsShader.xml")
	addReplacedCustomShader("envIntensityShader.xml", "data/shaders/envIntensityShader.xml")
	addReplacedCustomShader("exhaustShader.xml", "data/shaders/exhaustShader.xml")
	addReplacedCustomShader("fillIconShader.xml", "data/shaders/fillIconShader.xml")
	addReplacedCustomShader("fillPlaneShader.xml", "data/shaders/fillPlaneShader.xml")
	addReplacedCustomShader("flagShader.xml", "data/shaders/flagShader.xml")
	addReplacedCustomShader("fruitGrowthFoliageShader.xml", "data/shaders/fruitGrowthFoliageShader.xml")
	addReplacedCustomShader("fxCircleShader.xml", "data/shaders/fxCircleShader.xml")
	addReplacedCustomShader("grainSmokeShader.xml", "data/shaders/grainSmokeShader.xml")
	addReplacedCustomShader("grainUnloadingShader.xml", "data/shaders/grainUnloadingShader.xml")
	addReplacedCustomShader("grimmeMeshScrollShader.xml", "data/shaders/grimmeMeshScrollShader.xml")
	addReplacedCustomShader("groundHeightShader.xml", "data/shaders/groundHeightShader.xml")
	addReplacedCustomShader("groundHeightStaticShader.xml", "data/shaders/groundHeightStaticShader.xml")
	addReplacedCustomShader("lightBeamShader.xml", "data/shaders/lightBeamShader.xml")
	addReplacedCustomShader("localCatmullRomRopeShader.xml", "data/shaders/localCatmullRomRopeShader.xml")
	addReplacedCustomShader("meshRotateShader.xml", "data/shaders/meshRotateShader.xml")
	addReplacedCustomShader("meshScrollShader.xml", "data/shaders/meshScrollShader.xml")
	addReplacedCustomShader("morphTargetShader.xml", "data/shaders/morphTargetShader.xml")
	addReplacedCustomShader("numberShader.xml", "data/shaders/numberShader.xml")
	addReplacedCustomShader("oceanShader.xml", "data/shaders/oceanShader.xml")
	addReplacedCustomShader("oceanShaderMasked.xml", "data/shaders/oceanShaderMasked.xml")
	addReplacedCustomShader("particleSystemShader.xml", "data/shaders/particleSystemShader.xml")
	addReplacedCustomShader("pipeUnloadingShader.xml", "data/shaders/pipeUnloadingShader.xml")
	addReplacedCustomShader("placeableShader.xml", "data/shaders/placeableShader.xml")
	addReplacedCustomShader("psColorShader.xml", "data/shaders/psColorShader.xml")
	addReplacedCustomShader("psSubUVShader.xml", "data/shaders/psSubUVShader.xml")
	addReplacedCustomShader("rainShader.xml", "data/shaders/rainShader.xml")
	addReplacedCustomShader("roadShader.xml", "data/shaders/roadShader.xml")
	addReplacedCustomShader("scrollUVShader.xml", "data/shaders/scrollUVShader.xml")
	addReplacedCustomShader("shadowDisableShader.xml", "data/shaders/shadowDisableShader.xml")
	addReplacedCustomShader("silageBaleShader.xml", "data/shaders/silageBaleShader.xml")
	addReplacedCustomShader("simpleOceanShader.xml", "data/shaders/simpleOceanShader.xml")
	addReplacedCustomShader("skyShader.xml", "data/shaders/skyShader.xml")
	addReplacedCustomShader("slurryMeasurementShader.xml", "data/shaders/slurryMeasurementShader.xml")
	addReplacedCustomShader("slurryShader.xml", "data/shaders/slurryShader.xml")
	addReplacedCustomShader("solidFoliageShader.xml", "data/shaders/solidFoliageShader.xml")
	addReplacedCustomShader("streamShader.xml", "data/shaders/streamShader.xml")
	addReplacedCustomShader("tensionBeltShader.xml", "data/shaders/tensionBeltShader.xml")
	addReplacedCustomShader("terrainShader.xml", "data/shaders/terrainShader.xml")
	addReplacedCustomShader("tileAndMirrorShader.xml", "data/shaders/tileAndMirrorShader.xml")
	addReplacedCustomShader("tintAlphaShader.xml", "data/shaders/tintAlphaShader.xml")
	addReplacedCustomShader("tireTrackShader.xml", "data/shaders/tireTrackShader.xml")
	addReplacedCustomShader("treeBillboardShader.xml", "data/shaders/treeBillboardShader.xml")
	addReplacedCustomShader("treeBillboardSSShader.xml", "data/shaders/treeBillboardSSShader.xml")
	addReplacedCustomShader("treeBranchShader.xml", "data/shaders/treeBranchShader.xml")
	addReplacedCustomShader("treeMarkerShader.xml", "data/shaders/treeMarkerShader.xml")
	addReplacedCustomShader("treeTrunkShader.xml", "data/shaders/treeTrunkShader.xml")
	addReplacedCustomShader("triPlanarShader.xml", "data/shaders/triPlanarShader.xml")
	addReplacedCustomShader("underwaterFogShader.xml", "data/shaders/underwaterFogShader.xml")
	addReplacedCustomShader("uvOffsetShader.xml", "data/shaders/uvOffsetShader.xml")
	addReplacedCustomShader("uvRotateShader.xml", "data/shaders/uvRotateShader.xml")
	addReplacedCustomShader("uvScrollShader.xml", "data/shaders/uvScrollShader.xml")
	addReplacedCustomShader("vehicleShader.xml", "data/shaders/vehicleShader.xml")
	addReplacedCustomShader("vertexPaintShader.xml", "data/shaders/vertexPaintShader.xml")
	addReplacedCustomShader("windowShader.xml", "data/shaders/windowShader.xml")
	addReplacedCustomShader("windrowFoliageShader.xml", "data/shaders/windrowFoliageShader.xml")
	addReplacedCustomShader("windrowUnloadingShader.xml", "data/shaders/windrowUnloadingShader.xml")
	addReplacedCustomShader("windShader.xml", "data/shaders/windShader.xml")
end

g_densityMapRevision = 3
g_terrainTextureRevision = 1
g_terrainLodTextureRevision = 2
g_splitShapesRevision = 2
g_tipCollisionRevision = 2
g_placementCollisionRevision = 2
g_navigationCollisionRevision = 2
g_menuMusic = nil
g_menuMusicIsPlayingStarted = false
g_clientInterpDelay = 100
g_clientInterpDelayMin = 60
g_clientInterpDelayMax = 150
g_clientInterpDelayBufferOffset = 30
g_clientInterpDelayBufferScale = 0.5
g_clientInterpDelayBufferMin = 45
g_clientInterpDelayBufferMax = 60
g_clientInterpDelayAdjustDown = 0.002
g_clientInterpDelayAdjustUp = 0.08
g_time = 0
g_currentDt = 16.666666666666668
g_updateLoopIndex = 0
g_physicsTimeLooped = 0
g_physicsDt = 16.666666666666668
g_physicsDtUnclamped = 16.666666666666668
g_physicsDtNonInterpolated = 16.666666666666668
g_physicsDtLastValidNonInterpolated = 16.666666666666668
g_packetPhysicsNetworkTime = 0
g_networkTime = netGetTime()
g_physicsNetworkTime = g_networkTime
g_analogStickHTolerance = 0.45
g_analogStickVTolerance = 0.45
g_referenceScreenWidth = 1920
g_referenceScreenHeight = 1080
g_maxUploadRate = 30.72
g_maxUploadRatePerClient = 393.216
g_drawGuiHelper = false
g_guiHelperSteps = 0.1
g_lastMousePosX = 0
g_lastMousePosY = 0
g_screenWidth = 800
g_screenHeight = 600
g_screenAspectRatio = g_screenWidth / g_screenHeight
g_presentedScreenAspectRatio = g_screenAspectRatio
g_darkControllerOverlay = nil
g_aspectScaleX = 1
g_aspectScaleX = 1
g_dedicatedServer = nil
g_serverMaxCapacity = GS_IS_CONSOLE_VERSION and 6 or 16
g_joinServerMaxCapacity = 16
g_serverMaxClientCapacity = 16
g_serverMinCapacity = 2
g_nextModRecommendationTime = 0
g_maxNumLoadingBarSteps = 35
g_curNumLoadingBarStep = 0
g_updateDownloadFinished = false
g_updateDownloadFinishedDialogShown = false
g_skipStartupScreen = false

local function updateLoadingBarProgress(isLast)
	g_curNumLoadingBarStep = g_curNumLoadingBarStep + 1
	local ratio = g_curNumLoadingBarStep / g_maxNumLoadingBarSteps

	if isLast and ratio < 1 or ratio > 1 then
		print("Invalid g_maxNumLoadingBarSteps. Last step number is " .. g_curNumLoadingBarStep)
	end

	updateLoadingBar(ratio)
end

local function onShowDeepLinkingErrorMsg()
	g_deepLinkingInfo = nil

	g_gui:showConnectionFailedDialog({
		text = g_i18n:getText("ui_failedToConnectToGame"),
		callback = OnInGameMenuMenu
	})

	g_showDeeplinkingFailedMessage = false
end

g_postAnimationUpdateCallbacks = {}

function addPostAnimationCallback(callbackFunc, callbackTarget, callbackArguments)
	local callbackData = {
		callbackFunc = callbackFunc,
		callbackTarget = callbackTarget,
		callbackArguments = callbackArguments
	}

	table.insert(g_postAnimationUpdateCallbacks, callbackData)

	return callbackData
end

function removePostAnimationCallback(callbackDataToRemove)
	for i, callbackData in pairs(g_postAnimationUpdateCallbacks) do
		if callbackData == callbackDataToRemove then
			table.remove(g_postAnimationUpdateCallbacks, i)
		end
	end
end

function init(args)
	StartParams.init(args)

	if initTesting() then
		return
	end

	g_i3DManager:init()
	updateLoadingBarProgress()

	g_messageCenter = MessageCenter.new()

	updateLoadingBarProgress()

	g_soundMixer = SoundMixer.new()

	updateLoadingBarProgress()

	g_autoSaveManager = AutoSaveManager.new()

	g_gamingStationManager:load()
	updateLoadingBarProgress()

	g_lifetimeStats = LifetimeStats.new()

	g_lifetimeStats:load()

	local isServerStart = StartParams.getIsSet("server")
	local autoStartSavegameId = StartParams.getValue("autoStartSavegameId")
	local devStartServer = StartParams.getValue("devStartServer")
	local devStartClient = StartParams.getValue("devStartClient")
	local devUniqueUserId = g_isDevelopmentVersion and StartParams.getValue("uniqueUserId") or nil

	if Platform.isPlaystation then
		g_screenWidth = 1920
		g_screenHeight = 1080
	else
		g_screenWidth, g_screenHeight = getScreenModeInfo(getScreenMode())
	end

	local uiPostfix = Platform.isMobile and "_mobile" or ""
	g_baseUIPostfix = ""
	g_baseUIFilename = "dataS/menu/hud/ui_elements" .. uiPostfix .. ".png"
	g_iconsUIFilename = "dataS/menu/hud/ui_icons" .. uiPostfix .. ".png"
	g_baseHUDFilename = "dataS/menu/hud/hud_elements" .. uiPostfix .. ".png"

	if g_isDevelopmentVersion then
		print(string.format(" Loading UI-textures: '%s' '%s' '%s'", g_baseUIFilename, g_baseHUDFilename, g_iconsUIFilename))
	end

	g_screenAspectRatio = g_screenWidth / g_screenHeight
	g_presentedScreenAspectRatio = getScreenAspectRatio()

	updateAspectRatio(g_presentedScreenAspectRatio)

	g_colorBgUVs = GuiUtils.getUVs({
		10,
		1010,
		4,
		4
	})
	local safeFrameOffsetX = Platform.safeFrameOffsetX
	local safeFrameOffsetY = Platform.safeFrameOffsetY
	g_safeFrameOffsetX, g_safeFrameOffsetY = getNormalizedScreenValues(safeFrameOffsetX, safeFrameOffsetY)
	local safeFrameMajorOffsetX = Platform.safeFrameMajorOffsetX
	local safeFrameMajorOffsetY = Platform.safeFrameMajorOffsetY
	g_safeFrameMajorOffsetX, g_safeFrameMajorOffsetY = getNormalizedScreenValues(safeFrameMajorOffsetX, safeFrameMajorOffsetY)

	registerProfileFile("gameSettings.xml")
	registerProfileFile("characterPresets.xml")
	registerProfileFile("extraContent.xml")

	g_gameSettings = GameSettings.new(nil, g_messageCenter)

	loadUserSettings(g_gameSettings)
	updateLoadingBarProgress()

	local xmlFile = XMLFile.load("SettingsFile", "dataS/settings.xml")

	loadLanguageSettings(xmlFile)

	local availableLanguagesString = "Available Languages:"

	for _, lang in ipairs(g_availableLanguagesTable) do
		availableLanguagesString = availableLanguagesString .. " " .. getLanguageCode(lang)
	end

	local developmentLevel = xmlFile:getString("settings#developmentLevel", "release"):lower()
	g_buildName = xmlFile:getString("settings#buildName", g_buildName)
	g_buildTypeParam = xmlFile:getString("settings#buildTypeParam", g_buildTypeParam)
	g_gameRevision = xmlFile:getString("settings#revision", g_gameRevision)
	g_gameRevision = g_gameRevision .. getGameRevisionExtraText()

	xmlFile:delete()

	g_isDevelopmentVersion = false

	if developmentLevel == "internal" then
		print("INTERNAL VERSION")

		g_addTestCommands = true
	elseif developmentLevel == "development" then
		print("DEVELOPMENT VERSION")

		g_isDevelopmentVersion = true
		g_addTestCommands = true

		enableDevelopmentControls()
	end

	if g_isDevelopmentVersion then
		g_networkDebug = true
	end

	if g_addTestCommands or StartParams.getIsSet("cheats") then
		g_addCheatCommands = true
	end

	if g_addTestCommands or StartParams.getIsSet("devWarnings") then
		g_showDevelopmentWarnings = true
	end

	local caption = "Farming Simulator 22"

	if Platform.isPlaystation then
		caption = caption .. " (PlayStation 4)"
	elseif Platform.isXbox then
		caption = caption .. " (XboxOne)"
	end

	if g_isDevelopmentVersion then
		caption = caption .. " - DevelopmentVersion"
	elseif g_addTestCommands then
		caption = caption .. " - InternalVersion"
	end

	if I3DManager.loadingDelay ~= nil then
		caption = caption .. " - I3D Delay " .. I3DManager.loadingDelay .. "ms"
	end

	setCaption(caption)
	loadPresentationSettings(g_presentationSettingsFile)
	addNotificationFilter(GS_PRODUCT_ID, g_gameVersionNotification)
	updateLoadingBarProgress()

	local nameExtra = ""

	if g_buildTypeParam ~= "" then
		nameExtra = nameExtra .. " " .. g_buildTypeParam
	end

	if GS_IS_STEAM_VERSION then
		nameExtra = nameExtra .. " (Steam)"
	end

	if GS_IS_EPIC_VERSION then
		nameExtra = nameExtra .. " (Epic)"
	end

	if isServerStart then
		nameExtra = nameExtra .. " (Server)"
	end

	print("Farming Simulator 22" .. nameExtra)
	print("  Version: " .. g_gameVersionDisplay .. g_gameVersionDisplayExtra .. " " .. g_buildName)
	print("  " .. availableLanguagesString)
	print("  Language: " .. g_languageShort)
	print("  Time: " .. getDate("%Y-%m-%d %H:%M:%S"))
	print("  ModDesc Version: " .. g_maxModDescVersion)

	if Platform.isPC then
		local screenshotsDir = getUserProfileAppPath() .. "screenshots/"
		g_screenshotsDirectory = screenshotsDir

		createFolder(screenshotsDir)

		local modSettingsDir = getUserProfileAppPath() .. "modSettings/"
		g_modSettingsDirectory = modSettingsDir

		createFolder(modSettingsDir)
	end

	local modsDir = getModInstallPath()
	local modDownloadDir = getModDownloadPath()

	updateLoadingBarProgress()

	if Platform.allowsModDirectoryOverride then
		local modsDir2 = nil

		if Utils.getNoNil(getXMLBool(g_savegameXML, "gameSettings.modsDirectoryOverride#active"), false) then
			modsDir2 = getXMLString(g_savegameXML, "gameSettings.modsDirectoryOverride#directory")

			if modsDir2 ~= nil and modsDir2 ~= "" then
				modsDir = modsDir2
				modsDir = modsDir:gsub("\\", "/")

				if modsDir:sub(1, 2) == "//" then
					modsDir = "\\\\" .. modsDir:sub(3)
				end

				if modsDir:sub(modsDir:len(), modsDir:len()) ~= "/" then
					modsDir = modsDir .. "/"
				end
			end
		end
	end

	updateLoadingBarProgress()

	if modsDir then
		print("  Mod Directory: " .. modsDir)
		createFolder(modsDir)
	end

	if modDownloadDir then
		createFolder(modDownloadDir)
	end

	g_modsDirectory = modsDir

	if g_addTestCommands then
		print("  Testing Commands: Enabled")
	elseif g_addCheatCommands then
		print("  Cheats: Enabled")
	end

	updateLoadingBarProgress()

	g_i18n = I18N.new()

	g_i18n:load()

	g_extraContentSystem = ExtraContentSystem.new()

	g_extraContentSystem:loadFromXML("dataS/extraContent.xml")
	g_extraContentSystem:loadFromProfile()
	updateLoadingBarProgress()
	setMaxNumOfReflectionPlanes(math.max(g_gameSettings:getValue("maxNumMirrors") + 1, 3))
	math.randomseed(getTime())
	math.random()
	math.random()
	math.random()
	updateLoadingBarProgress()
	g_splitTypeManager:load()
	addSplitShapesShaderParameterOverwrite("windSnowLeafScale", 0, 0, 0, 80)

	local loadAllMaps = not g_isPresentationVersion or g_isPresentationVersionAllMapsEnabled

	if loadAllMaps or g_isPresentationVersionUSMapEnabled then
		g_mapManager:addMapItem("MapUS", "dataS/scripts/missions/mission00.lua", "Mission00", "data/maps/mapUS/map.xml", "data/maps/mapUS/vehicles.xml", "data/maps/mapUS/placeables.xml", "data/maps/mapUS/items.xml", g_i18n:getText("mapUS_title"), g_i18n:getText("mapUS_description"), "data/maps/mapUS/preview.png", "", nil, true, false)
	end

	if loadAllMaps or g_isPresentationVersionFRMapEnabled then
		g_mapManager:addMapItem("MapFR", "dataS/scripts/missions/mission00.lua", "Mission00", "data/maps/mapFR/map.xml", "data/maps/mapFR/vehicles.xml", "data/maps/mapFR/placeables.xml", "data/maps/mapFR/items.xml", g_i18n:getText("mapFR_title"), g_i18n:getText("mapFR_description"), "data/maps/mapFR/preview.png", "", nil, true, false)
	end

	if loadAllMaps or g_isPresentationVersionAlpineMapEnabled then
		g_mapManager:addMapItem("mapAlpine", "dataS/scripts/missions/mission00.lua", "Mission00", "data/maps/mapAlpine/map.xml", "data/maps/mapAlpine/vehicles.xml", "data/maps/mapAlpine/placeables.xml", "data/maps/mapAlpine/items.xml", g_i18n:getText("mapDE_title"), g_i18n:getText("mapDE_description"), "data/maps/mapAlpine/preview.png", "", nil, true, false)
	end

	updateLoadingBarProgress()
	g_characterModelManager:load("dataS/character/humans/player/playerModels.xml")
	updateLoadingBarProgress()
	registerHandTool("chainsaw", Chainsaw)
	registerHandTool("highPressureWasherLance", HighPressureWasherLance)

	g_animCache = AnimationCache.new()

	g_animCache:load(AnimationCache.CHARACTER, "dataS/character/humans/player/animations.i3d")
	updateLoadingBarProgress()
	g_animCache:load(AnimationCache.VEHICLE_CHARACTER, "dataS/character/humans/player/animations.i3d")

	if Platform.supportsPedestrians then
		g_animCache:load(AnimationCache.PEDESTRIAN, "dataS/character/humans/npc/animations.i3d")
	end

	g_achievementManager = AchievementManager.new(nil, g_messageCenter)

	g_achievementManager:load()
	updateLoadingBarProgress()
	initModDownloadManager(g_modsDirectory, modDownloadDir, g_minModDescVersion, g_maxModDescVersion, g_isDevelopmentVersion)
	startUpdatePendingMods()
	updateLoadingBarProgress()
	loadDlcs()
	updateLoadingBarProgress()

	local startedRepeat = startFrameRepeatMode()

	while isModUpdateRunning() do
		usleep(16000)
	end

	if startedRepeat then
		endFrameRepeatMode()
	end

	if Platform.supportsMods then
		loadMods()
	end

	if not Platform.isConsole then
		copyFile(getAppBasePath() .. "VERSION", getUserProfileAppPath() .. "VERSION", true)
	end

	updateLoadingBarProgress()

	g_inputBinding = InputBinding.new(g_modManager, g_messageCenter, GS_IS_CONSOLE_VERSION)

	g_inputBinding:load()

	g_inputDisplayManager = InputDisplayManager.new(g_messageCenter, g_inputBinding, g_modManager, GS_IS_CONSOLE_VERSION)

	g_inputDisplayManager:load()

	if Platform.isMobile then
		g_touchHandler = TouchHandler.new()
	end

	updateLoadingBarProgress()
	simulatePhysics(false)

	if isServerStart then
		g_dedicatedServer = DedicatedServer.new()

		g_dedicatedServer:load(getUserProfileAppPath() .. "dedicated_server/dedicatedServerConfig.xml")
		g_dedicatedServer:setGameStatsPath(getUserProfileAppPath() .. "dedicated_server/gameStats.xml")
	end

	updateLoadingBarProgress()

	g_connectionManager = ConnectionManager.new()
	g_masterServerConnection = MasterServerConnection.new()
	local guiSoundPlayer = GuiSoundPlayer.new(g_soundManager)
	g_gui = Gui.new(g_messageCenter, g_languageSuffix, g_inputBinding, guiSoundPlayer)

	g_gui:loadProfiles("dataS/guiProfiles.xml")

	local startMissionInfo = StartMissionInfo.new()
	g_mainScreen = MainScreen.new(nil, , startMissionInfo)
	g_creditsScreen = CreditsScreen.new(nil, , startMissionInfo)

	updateLoadingBarProgress()

	local settingsModel = SettingsModel.new(g_gameSettings, g_savegameXML, g_i18n, g_soundMixer, GS_IS_CONSOLE_VERSION)
	g_settingsScreen = SettingsScreen.new(nil, , g_messageCenter, g_i18n, g_inputBinding, settingsModel, GS_IS_CONSOLE_VERSION)
	local savegameController = SavegameController.new()
	g_careerScreen = CareerScreen.new(nil, , savegameController, startMissionInfo)
	g_difficultyScreen = DifficultyScreen.new(nil, , startMissionInfo)

	updateLoadingBarProgress()

	g_wardrobeScreen = WardrobeScreen.new(nil, , g_messageCenter, g_i18n, g_inputBinding)
	local wardrobeItemsFrame = WardrobeItemsFrame.new(nil)
	local wardrobeColorsFrame = WardrobeColorsFrame.new(nil)
	local wardrobeOutfitsFrame = WardrobeOutfitsFrame.new(nil)
	local wardrobeCharactersFrame = WardrobeCharactersFrame.new(nil)
	local inAppPurchaseController = InAppPurchaseController.new(g_messageCenter, g_i18n, g_gameSettings)
	local shopController = ShopController.new(g_messageCenter, g_i18n, g_storeManager, g_brandManager, g_fillTypeManager, inAppPurchaseController)
	local inGameMenuMapFrame = InGameMenuMapFrame.new(nil, g_messageCenter, g_i18n, g_inputBinding, g_inputDisplayManager, g_fruitTypeManager, g_fillTypeManager, g_storeManager, shopController, g_farmlandManager, g_farmManager)
	local inGameMenuAIFrame = InGameMenuAIFrame.new(nil, g_messageCenter, g_i18n, g_inputBinding, g_inputDisplayManager, g_fruitTypeManager, g_fillTypeManager, g_storeManager, shopController, g_farmlandManager, g_farmManager)
	local inGameMenuPricesFrame = InGameMenuPricesFrame.new(nil, g_i18n, g_fillTypeManager)
	local inGameMenuVehiclesFrame = InGameMenuVehiclesFrame.new(nil, g_messageCenter, g_i18n, g_storeManager, g_brandManager, shopController)
	local inGameMenuFinancesFrame = InGameMenuFinancesFrame.new(nil, g_messageCenter, g_i18n, g_inputBinding)
	local animalFrameClass = GS_IS_MOBILE_VERSION and InGameMenuAnimalsFrameMobile or InGameMenuAnimalsFrame
	local inGameMenuAnimalsFrame = animalFrameClass.new(nil, g_messageCenter, g_i18n, g_fillTypeManager)
	local inGameMenuContractsFrame = InGameMenuContractsFrame.new(nil, g_messageCenter, g_i18n, g_missionManager)
	local inGameMenuCalendarFrame = InGameMenuCalendarFrame.new(nil, g_messageCenter, g_i18n)
	local inGameMenuWeatherFrame = InGameMenuWeatherFrame.new(nil, g_messageCenter, g_i18n)
	local inGameMenuProductionFrame = InGameMenuProductionFrame.new(g_messageCenter, g_i18n)
	local inGameMenuStatisticsFrame = InGameMenuStatisticsFrame.new()
	local inGameMenuMultiplayerFarmsFrame = InGameMenuMultiplayerFarmsFrame.new(nil, g_messageCenter, g_i18n, g_farmManager)
	local inGameMenuMultiplayerUsersFrame = InGameMenuMultiplayerUsersFrame.new(nil, g_messageCenter, g_i18n, g_farmManager)
	local inGameMenuHelpFrame = InGameMenuHelpFrame.new(nil, g_i18n, g_helpLineManager)
	local inGameMenuGeneralSettingsFrame = InGameMenuGeneralSettingsFrame.new(nil, settingsModel)
	local inGameMenuGameSettingsFrame = InGameMenuGameSettingsFrame.new(nil, g_i18n)
	local inGameMenuMobileSettingsFrame, inGameMenuMainFrame = nil

	if Platform.isMobile then
		inGameMenuMobileSettingsFrame = InGameMenuMobileSettingsFrame.new(nil, settingsModel, g_messageCenter)
		inGameMenuMainFrame = InGameMenuMainFrame.new(nil, g_i18n)
	end

	local shopCategoriesFrame = ShopCategoriesFrame.new(nil, shopController)
	local shopOthersFrame = ShopOthersFrame.new()
	local shopItemsFrame = ShopItemsFrame.new(nil, shopController, g_i18n, g_brandManager, GS_IS_CONSOLE_VERSION)
	g_shopConfigScreen = ShopConfigScreen.new(shopController, g_messageCenter, g_i18n, g_i3DManager, g_brandManager, g_configurationManager, g_vehicleTypeManager, g_inputBinding, g_inputDisplayManager)
	local inGameMenu = InGameMenu.new(nil, , g_messageCenter, g_i18n, g_inputBinding, savegameController, g_fruitTypeManager, g_fillTypeManager, GS_IS_CONSOLE_VERSION)
	local shopMenu = ShopMenu.new(nil, , g_messageCenter, g_i18n, g_inputBinding, g_fruitTypeManager, g_fillTypeManager, g_storeManager, shopController, g_shopConfigScreen, GS_IS_CONSOLE_VERSION, inAppPurchaseController)
	local constructionScreen = ConstructionScreen.new(nil, , g_i18n, g_messageCenter, g_inputBinding)

	updateLoadingBarProgress()

	if Platform.needsSignIn then
		g_gamepadSigninScreen = GamepadSigninScreen.new(inGameMenu, shopMenu, g_achievementManager, settingsModel)
	end

	g_animalScreen = AnimalScreen.new()
	g_workshopScreen = WorkshopScreen.new(nil, , g_shopConfigScreen, g_messageCenter)
	local missionCollaborators = MissionCollaborators.new()
	missionCollaborators.messageCenter = g_messageCenter
	missionCollaborators.savegameController = savegameController
	missionCollaborators.achievementManager = g_achievementManager
	missionCollaborators.inputManager = g_inputBinding
	missionCollaborators.inputDisplayManager = g_inputDisplayManager
	missionCollaborators.modManager = g_modManager
	missionCollaborators.fillTypeManager = g_fillTypeManager
	missionCollaborators.fruitTypeManager = g_fruitTypeManager
	missionCollaborators.inGameMenu = inGameMenu
	missionCollaborators.shopMenu = shopMenu
	missionCollaborators.guiSoundPlayer = guiSoundPlayer
	missionCollaborators.shopController = shopController
	g_mpLoadingScreen = MPLoadingScreen.new(nil, , missionCollaborators, savegameController, OnLoadingScreen)
	g_mapSelectionScreen = MapSelectionScreen.new(nil, , startMissionInfo)
	g_modSelectionScreen = ModSelectionScreen.new(nil, , startMissionInfo, g_i18n, GS_IS_CONSOLE_VERSION)
	g_achievementsScreen = AchievementsScreen.new(nil, , g_achievementManager)

	updateLoadingBarProgress()

	if Platform.showStartupScreen and g_skipStartupScreen == false then
		g_startupScreen = StartupScreen.new()
	end

	g_createGameScreen = CreateGameScreen.new(nil, , startMissionInfo)
	g_multiplayerScreen = MultiplayerScreen.new(nil, , startMissionInfo)
	g_joinGameScreen = JoinGameScreen.new(nil, , startMissionInfo, g_messageCenter, g_inputBinding)
	g_connectToMasterServerScreen = ConnectToMasterServerScreen.new(nil, , startMissionInfo)

	updateLoadingBarProgress()

	g_serverDetailScreen = ServerDetailScreen.new()
	g_messageDialog = MessageDialog.new()
	g_yesNoDialog = YesNoDialog.new()
	local optionDialog = OptionDialog.new()
	local sleepDialog = SleepDialog.new()
	g_textInputDialog = TextInputDialog.new(nil, , g_inputBinding)
	g_passwordDialog = TextInputDialog.new(nil, , g_inputBinding)
	g_infoDialog = InfoDialog.new()
	local placeableInfoDialog = PlaceableInfoDialog.new()
	g_connectionFailedDialog = ConnectionFailedDialog.new()
	g_colorPickerDialog = ColorPickerDialog.new()
	g_licensePlateDialog = LicensePlateDialog.new()
	g_chatDialog = ChatDialog.new()
	g_denyAcceptDialog = DenyAcceptDialog.new()
	g_siloDialog = SiloDialog.new()
	g_refillDialog = RefillDialog.new()
	g_animalDialog = AnimalDialog.new()
	g_savegameConflictDialog = SavegameConflictDialog.new(nil, , g_i18n, savegameController)
	g_gameRateDialog = GameRateDialog.new()
	local transferMoneyDialog = TransferMoneyDialog.new()
	g_sellItemDialog = SellItemDialog.new()
	local editFarmDialog = EditFarmDialog.new(nil, , g_i18n, g_farmManager)
	local unBanDialog = UnBanDialog.new(nil, , g_i18n)
	local serverSettingsDialog = ServerSettingsDialog.new(nil, , g_i18n, settingsModel)
	local voteDialog = nil

	if Platform.supportsMods then
		voteDialog = VoteDialog.new(nil, )
	end

	updateLoadingBarProgress()

	g_modHubController = ModHubController.new(g_messageCenter, g_i18n, g_gameSettings)

	if Platform.supportsMods then
		g_modHubScreen = ModHubScreen.new(nil, , g_messageCenter, g_i18n, g_inputBinding, g_modHubController, GS_IS_CONSOLE_VERSION)
	end

	g_gui:loadGui("dataS/gui/SettingsGeneralFrame.xml", "SettingsGeneralFrame", SettingsGeneralFrame.new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsAdvancedFrame.xml", "SettingsAdvancedFrame", SettingsAdvancedFrame.new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsHDRFrame.xml", "SettingsHDRFrame", SettingsHDRFrame.new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsDisplayFrame.xml", "SettingsDisplayFrame", SettingsDisplayFrame.new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsControlsFrame.xml", "SettingsControlsFrame", SettingsControlsFrame.new(nil, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsConsoleFrame.xml", "SettingsConsoleFrame", SettingsConsoleFrame.new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/SettingsDeviceFrame.xml", "SettingsDeviceFrame", SettingsDeviceFrame.new(nil, , settingsModel, g_i18n), true)
	g_gui:loadGui("dataS/gui/MainScreen.xml", "MainScreen", g_mainScreen)

	if Platform.isMobile then
		g_gui:loadGui("dataS/gui_mobile/CreditsScreen.xml", "CreditsScreen", g_creditsScreen)
	else
		g_gui:loadGui("dataS/gui/CreditsScreen.xml", "CreditsScreen", g_creditsScreen)
	end

	if Platform.needsSignIn then
		g_gui:loadGui("dataS/gui/GamepadSigninScreen.xml", "GamepadSigninScreen", g_gamepadSigninScreen)
	end

	g_gui:loadGui("dataS/gui/SettingsScreen.xml", "SettingsScreen", g_settingsScreen)

	if Platform.isMobile then
		g_gui:loadGui("dataS/gui_mobile/CareerScreen.xml", "CareerScreen", g_careerScreen)
	else
		g_gui:loadGui("dataS/gui/CareerScreen.xml", "CareerScreen", g_careerScreen)
	end

	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/DifficultyScreen.xml", "DifficultyScreen", g_difficultyScreen)
	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/ShopConfigScreen.xml", "ShopConfigScreen", g_shopConfigScreen)
	g_gui:loadGui("dataS/gui/ConstructionScreen.xml", "ConstructionScreen", constructionScreen)
	g_gui:loadGui("dataS/gui/MapSelectionScreen.xml", "MapSelectionScreen", g_mapSelectionScreen)
	g_gui:loadGui("dataS/gui/ModSelectionScreen.xml", "ModSelectionScreen", g_modSelectionScreen)
	updateLoadingBarProgress()

	if Platform.isMobile then
		g_gui:loadGui("dataS/gui_mobile/AchievementsScreen.xml", "AchievementsScreen", g_achievementsScreen)
		g_gui:loadGui("dataS/gui_mobile/AnimalScreen.xml", "AnimalScreen", g_animalScreen)
	else
		g_gui:loadGui("dataS/gui/AchievementsScreen.xml", "AchievementsScreen", g_achievementsScreen)
		g_gui:loadGui("dataS/gui/AnimalScreen.xml", "AnimalScreen", g_animalScreen)
	end

	if Platform.showStartupScreen and g_skipStartupScreen == false then
		g_gui:loadGui("dataS/gui/StartupScreen.xml", "StartupScreen", g_startupScreen)
	end

	g_gui:loadGui("dataS/gui/MPLoadingScreen.xml", "MPLoadingScreen", g_mpLoadingScreen)
	g_gui:loadGui("dataS/gui/CreateGameScreen.xml", "CreateGameScreen", g_createGameScreen)
	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/WorkshopScreen.xml", "WorkshopScreen", g_workshopScreen)
	g_gui:loadGui("dataS/gui/MultiplayerScreen.xml", "MultiplayerScreen", g_multiplayerScreen)
	g_gui:loadGui("dataS/gui/JoinGameScreen.xml", "JoinGameScreen", g_joinGameScreen)
	g_gui:loadGui("dataS/gui/ConnectToMasterServerScreen.xml", "ConnectToMasterServerScreen", g_connectToMasterServerScreen)
	g_gui:loadGui("dataS/gui/ServerDetailScreen.xml", "ServerDetailScreen", g_serverDetailScreen)

	local modHubLoadingFrame = ModHubLoadingFrame.new(nil)
	local modHubCategoriesFrame = ModHubCategoriesFrame.new(nil, g_modHubController, g_i18n, GS_IS_CONSOLE_VERSION)
	local modHubItemsFrame = ModHubItemsFrame.new(nil, g_modHubController, g_i18n, GS_IS_CONSOLE_VERSION)
	local modHubDetailsFrame = ModHubDetailsFrame.new(nil, g_modHubController, g_i18n, GS_IS_CONSOLE_VERSION, GS_IS_STEAM_VERSION)
	local modHubExtraContentFrame = ModHubExtraContentFrame.new(nil)

	g_gui:loadGui("dataS/gui/ModHubLoadingFrame.xml", "ModHubLoadingFrame", modHubLoadingFrame, true)
	g_gui:loadGui("dataS/gui/ModHubCategoriesFrame.xml", "ModHubCategoriesFrame", modHubCategoriesFrame, true)
	g_gui:loadGui("dataS/gui/ModHubItemsFrame.xml", "ModHubItemsFrame", modHubItemsFrame, true)
	g_gui:loadGui("dataS/gui/ModHubDetailsFrame.xml", "ModHubDetailsFrame", modHubDetailsFrame, true)
	g_gui:loadGui("dataS/gui/ModHubExtraContentFrame.xml", "ModHubExtraContentFrame", modHubExtraContentFrame, true)

	if Platform.supportsMods then
		g_gui:loadGui("dataS/gui/ModHubScreen.xml", "ModHubScreen", g_modHubScreen)
	end

	g_gui:loadGui("dataS/gui/WardrobeItemsFrame.xml", "WardrobeItemsFrame", wardrobeItemsFrame, true)
	g_gui:loadGui("dataS/gui/WardrobeColorsFrame.xml", "WardrobeColorsFrame", wardrobeColorsFrame, true)
	g_gui:loadGui("dataS/gui/WardrobeOutfitsFrame.xml", "WardrobeOutfitsFrame", wardrobeOutfitsFrame, true)
	g_gui:loadGui("dataS/gui/WardrobeCharactersFrame.xml", "WardrobeCharactersFrame", wardrobeCharactersFrame, true)
	g_gui:loadGui("dataS/gui/WardrobeScreen.xml", "WardrobeScreen", g_wardrobeScreen)
	updateLoadingBarProgress()

	if Platform.isMobile then
		g_gui:loadGui("dataS/gui_mobile/InGameMenuMapFrame.xml", "MapFrame", inGameMenuMapFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuPricesFrame.xml", "PricesFrame", inGameMenuPricesFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuVehiclesFrame.xml", "VehiclesFrame", inGameMenuVehiclesFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuFinancesFrame.xml", "FinancesFrame", inGameMenuFinancesFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuStatisticsFrame.xml", "StatisticsFrame", inGameMenuStatisticsFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenuAnimalsFrame.xml", "AnimalsFrame", inGameMenuAnimalsFrame, true)
	else
		g_gui:loadGui("dataS/gui/InGameMenuMapFrame.xml", "MapFrame", inGameMenuMapFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuAIFrame.xml", "AIFrame", inGameMenuAIFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuPricesFrame.xml", "PricesFrame", inGameMenuPricesFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuVehiclesFrame.xml", "VehiclesFrame", inGameMenuVehiclesFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuFinancesFrame.xml", "FinancesFrame", inGameMenuFinancesFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuStatisticsFrame.xml", "StatisticsFrame", inGameMenuStatisticsFrame, true)
		g_gui:loadGui("dataS/gui/InGameMenuAnimalsFrame.xml", "AnimalsFrame", inGameMenuAnimalsFrame, true)
	end

	g_gui:loadGui("dataS/gui/InGameMenuContractsFrame.xml", "ContractsFrame", inGameMenuContractsFrame, true)
	g_gui:loadGui("dataS/gui/InGameMenuProductionFrame.xml", "ProductionFrame", inGameMenuProductionFrame, true)
	g_gui:loadGui("dataS/gui/InGameMenuWeatherFrame.xml", "WeatherFrame", inGameMenuWeatherFrame, true)
	g_gui:loadGui("dataS/gui/InGameMenuCalendarFrame.xml", "CalendarFrame", inGameMenuCalendarFrame, true)
	g_gui:loadGui("dataS/gui/InGameMenuMultiplayerFarmsFrame.xml", "MultiplayerFarmsFrame", inGameMenuMultiplayerFarmsFrame, true)
	g_gui:loadGui("dataS/gui/InGameMenuMultiplayerUsersFrame.xml", "StatisticsFrame", inGameMenuMultiplayerUsersFrame, true)

	if Platform.isMobile then
		g_gui:loadGui("dataS/gui_mobile/InGameMenuHelpFrame.xml", "HelpFrame", inGameMenuHelpFrame, true)
	else
		g_gui:loadGui("dataS/gui/InGameMenuHelpFrame.xml", "HelpFrame", inGameMenuHelpFrame, true)
	end

	if Platform.isMobile then
		g_gui:loadGui("dataS/gui_mobile/InGameMenuMainFrame.xml", "MainFrame", inGameMenuMainFrame, true)
	end

	g_gui:loadGui("dataS/gui/InGameMenuGeneralSettingsFrame.xml", "GeneralSettingsFrame", inGameMenuGeneralSettingsFrame, true)
	g_gui:loadGui("dataS/gui/InGameMenuGameSettingsFrame.xml", "GameSettingsFrame", inGameMenuGameSettingsFrame, true)

	if Platform.isMobile then
		g_gui:loadGui("dataS/gui_mobile/InGameMenuMobileSettingsFrame.xml", "InGameMenuMobileSettingsFrame", inGameMenuMobileSettingsFrame, true)
		g_gui:loadGui("dataS/gui_mobile/InGameMenu.xml", "InGameMenu", inGameMenu)
	else
		g_gui:loadGui("dataS/gui/InGameMenu.xml", "InGameMenu", inGameMenu)
	end

	if Platform.isMobile then
		g_gui:loadGui("dataS/gui_mobile/ShopCategoriesFrame.xml", "ShopCategoriesFrame", shopCategoriesFrame, true)
		g_gui:loadGui("dataS/gui_mobile/ShopItemsFrame.xml", "ShopItemsFrame", shopItemsFrame, true)
		g_gui:loadGui("dataS/gui_mobile/ShopMenu.xml", "ShopMenu", shopMenu)
	else
		g_gui:loadGui("dataS/gui/ShopCategoriesFrame.xml", "ShopCategoriesFrame", shopCategoriesFrame, true)
		g_gui:loadGui("dataS/gui/ShopItemsFrame.xml", "ShopItemsFrame", shopItemsFrame, true)
		g_gui:loadGui("dataS/gui/ShopOthersFrame.xml", "ShopOthersFrame", shopOthersFrame, true)
		g_gui:loadGui("dataS/gui/ShopMenu.xml", "ShopMenu", shopMenu)
	end

	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/dialogs/MessageDialog.xml", "MessageDialog", g_messageDialog)
	g_gui:loadGui("dataS/gui/dialogs/YesNoDialog.xml", "YesNoDialog", g_yesNoDialog)
	g_gui:loadGui("dataS/gui/dialogs/OptionDialog.xml", "OptionDialog", optionDialog)
	g_gui:loadGui("dataS/gui/dialogs/InfoDialog.xml", "InfoDialog", g_infoDialog)
	g_gui:loadGui("dataS/gui/dialogs/PlaceableInfoDialog.xml", "PlaceableInfoDialog", placeableInfoDialog)
	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/dialogs/InfoDialog.xml", "ConnectionFailedDialog", g_connectionFailedDialog)
	g_gui:loadGui("dataS/gui/dialogs/TextInputDialog.xml", "TextInputDialog", g_textInputDialog)
	g_gui:loadGui("dataS/gui/dialogs/PasswordDialog.xml", "PasswordDialog", g_passwordDialog)
	g_gui:loadGui("dataS/gui/dialogs/ColorPickerDialog.xml", "ColorPickerDialog", g_colorPickerDialog)
	g_gui:loadGui("dataS/gui/dialogs/LicensePlateDialog.xml", "LicensePlateDialog", g_licensePlateDialog)
	g_gui:loadGui("dataS/gui/dialogs/ChatDialog.xml", "ChatDialog", g_chatDialog)
	g_gui:loadGui("dataS/gui/dialogs/DenyAcceptDialog.xml", "DenyAcceptDialog", g_denyAcceptDialog)
	g_gui:loadGui("dataS/gui/dialogs/UnBanDialog.xml", "UnBanDialog", unBanDialog)
	g_gui:loadGui("dataS/gui/dialogs/SleepDialog.xml", "SleepDialog", sleepDialog)
	g_gui:loadGui("dataS/gui/dialogs/ServerSettingsDialog.xml", "ServerSettingsDialog", serverSettingsDialog)
	updateLoadingBarProgress()
	g_gui:loadGui("dataS/gui/dialogs/SiloDialog.xml", "SiloDialog", g_siloDialog)
	g_gui:loadGui("dataS/gui/dialogs/RefillDialog.xml", "RefillDialog", g_refillDialog)
	g_gui:loadGui("dataS/gui/dialogs/AnimalDialog.xml", "AnimalDialog", g_animalDialog)
	g_gui:loadGui("dataS/gui/dialogs/GameRateDialog.xml", "GameRateDialog", g_gameRateDialog)
	g_gui:loadGui("dataS/gui/dialogs/SellItemDialog.xml", "SellItemDialog", g_sellItemDialog)
	g_gui:loadGui("dataS/gui/dialogs/EditFarmDialog.xml", "EditFarmDialog", editFarmDialog)
	g_gui:loadGui("dataS/gui/dialogs/TransferMoneyDialog.xml", "TransferMoneyDialog", transferMoneyDialog)
	g_gui:loadGui("dataS/gui/dialogs/SavegameConflictDialog.xml", "SavegameConflictDialog", g_savegameConflictDialog)

	if Platform.supportsMods then
		g_gui:loadGui("dataS/gui/dialogs/VoteDialog.xml", "VoteDialog", voteDialog)
	end

	g_menuMusic = createStreamedSample("menuMusic", true)

	loadStreamedSample(g_menuMusic, "data/music/menu.ogg")
	setStreamedSampleGroup(g_menuMusic, AudioGroup.MENU_MUSIC)
	setStreamedSampleVolume(g_menuMusic, 1)

	local function func(target, audioGroupIndex, volume)
		if g_menuMusicIsPlayingStarted then
			if volume > 0 then
				resumeStreamedSample(g_menuMusic)
			else
				pauseStreamedSample(g_menuMusic)
			end
		end
	end

	g_soundMixer:addVolumeChangedListener(AudioGroup.MENU_MUSIC, func, nil)
	updateLoadingBarProgress(true)
	g_gamingStationManager:initBrand()

	if Platform.showStartupScreen and g_skipStartupScreen == false then
		g_gui:showGui("StartupScreen")
	else
		g_gui:showGui("MainScreen")
	end

	g_inputBinding:setShowMouseCursor(true)

	g_defaultCamera = getCamera()

	if g_dedicatedServer == nil then
		local soundPlayerLocal = getAppBasePath() .. "data/music/"
		local soundPlayerTemplate = getAppBasePath() .. "profileTemplate/streamingInternetRadios.xml"
		local soundPlayerReadmeTemplate = getAppBasePath() .. "profileTemplate/ReadmeMusic.txt"
		local soundUserPlayerLocal = soundPlayerLocal
		local soundPlayerTarget = soundPlayerTemplate

		if Platform.supportsCustomInternetRadios then
			soundUserPlayerLocal = getUserProfileAppPath() .. "music/"
			soundPlayerTarget = soundUserPlayerLocal .. "streamingInternetRadios.xml"
			local soundPlayerReadme = soundUserPlayerLocal .. "ReadmeMusic.txt"

			createFolder(soundUserPlayerLocal)
			copyFile(soundPlayerTemplate, soundPlayerTarget, false)
			copyFile(soundPlayerReadmeTemplate, soundPlayerReadme, false)
		end

		g_soundPlayer = SoundPlayer.new(getAppBasePath(), "https://www.farming-simulator.com/feed/fs2022-radio-station-feed.xml", soundPlayerTarget, soundPlayerLocal, soundUserPlayerLocal, g_languageShort, AudioGroup.RADIO)
	end

	RestartManager:init(args)

	if RestartManager.restarting then
		g_gui:showGui("MainScreen")
		RestartManager:handleRestart()
	end

	addConsoleCommand("gsGuiDrawHelper", "", "drawGuiHelper", SystemConsoleCommands)
	addConsoleCommand("gsI3DCacheClean", "Removes all cached i3d files to ensure the latest versions are loaded from disk", "cleanI3DCache", SystemConsoleCommands)
	addConsoleCommand("gsSetHighQuality", "Incease draw and LOD distances of foliage, terrain and objects", "setHighQuality", SystemConsoleCommands)
	addConsoleCommand("gsGuiSafeFrameShow", "", "showSafeFrame", SystemConsoleCommands)
	addConsoleCommand("gsGuiDebug", "", "toggleUiDebug", SystemConsoleCommands)
	addConsoleCommand("gsRenderColorAndDepthScreenShot", "", "renderColorAndDepthScreenShot", SystemConsoleCommands)

	if g_addCheatCommands then
		addConsoleCommand("gsRenderingDebugMode", "", "setDebugRenderingMode", SystemConsoleCommands)
		addConsoleCommand("gsInputDrawRaw", "", "drawRawInput", SystemConsoleCommands)
		addConsoleCommand("gsTestForceFeedback", "", "testForceFeedback", SystemConsoleCommands)
	end

	if g_addTestCommands then
		addConsoleCommand("gsLanguageSet", "Set active language", "changeLanguage", SystemConsoleCommands)
		addConsoleCommand("gsGuiReloadCurrent", "", "reloadCurrentGui", SystemConsoleCommands)

		if not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
			addConsoleCommand("gsSuspendApp", "", "suspendApp", SystemConsoleCommands)
		end

		addConsoleCommand("gsInputFuzz", "", "fuzzInput", SystemConsoleCommands)
		addConsoleCommand("gsUpdateDownloadFinished", "", "updateDownloadFinished", SystemConsoleCommands)
		addConsoleCommand("gsSoftRestart", "", "softRestart", SystemConsoleCommands)
	end

	if g_dedicatedServer ~= nil then
		g_dedicatedServer:start()
	end

	if devStartServer ~= nil then
		startDevServer(devStartServer, devUniqueUserId)
	end

	if devStartClient ~= nil then
		startDevClient(devUniqueUserId)
	end

	if autoStartSavegameId ~= nil then
		autoStartLocalSavegame(autoStartSavegameId)
	end

	if GS_PLATFORM_PC then
		registerGlobalActionEvents(g_inputBinding)
	elseif GS_IS_CONSOLE_VERSION and g_isDevelopmentVersion then
		local eventAdded, eventId = g_inputBinding:registerActionEvent(InputAction.CONSOLE_DEBUG_TOGGLE_FPS, InputBinding.NO_EVENT_TARGET, toggleShowFPS, false, true, false, true)

		if eventAdded then
			g_inputBinding:setActionEventTextVisibility(eventId, false)
		end

		eventAdded, eventId = g_inputBinding:registerActionEvent(InputAction.CONSOLE_DEBUG_TOGGLE_STATS, InputBinding.NO_EVENT_TARGET, toggleStatsOverlay, false, true, false, true)

		if eventAdded then
			g_inputBinding:setActionEventTextVisibility(eventId, false)
		end
	end

	g_logFilePrefixTimestamp = true

	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)

	return true
end

function update(dt)
	g_time = g_time + dt
	g_currentDt = dt
	g_physicsDt = getPhysicsDt()
	g_physicsDtUnclamped = getPhysicsDtUnclamped()
	g_physicsDtNonInterpolated = getPhysicsDtNonInterpolated()

	if g_physicsDtNonInterpolated > 0 then
		g_physicsDtLastValidNonInterpolated = g_physicsDtNonInterpolated
	end

	g_networkTime = netGetTime()
	g_physicsNetworkTime = g_physicsNetworkTime + g_physicsDtUnclamped
	g_physicsTimeLooped = (g_physicsTimeLooped + g_physicsDt * 10) % 65535
	g_updateLoopIndex = g_updateLoopIndex + 1

	if g_updateLoopIndex > 1073741824 then
		g_updateLoopIndex = 0
	end

	g_physicsDt = math.max(g_physicsDt, 0.001)
	g_physicsDtUnclamped = math.max(g_physicsDtUnclamped, 0.001)

	if g_currentTest ~= nil then
		g_currentTest.update(dt)

		return
	end

	g_debugManager:update(dt)
	g_benchmark:update(dt)
	g_lifetimeStats:update(dt)
	g_soundMixer:update(dt)
	g_asyncTaskManager:update(dt)
	g_i3DManager:update(dt)
	g_messageCenter:update(dt)

	if g_nextModRecommendationTime < g_time and g_currentMission == nil and g_dedicatedServer == nil and g_modHubController ~= nil then
		g_modHubController:updateRecommendationSystem()

		g_nextModRecommendationTime = g_time + 1800000
	end

	g_inputBinding:update(dt)

	if g_currentMission ~= nil and g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen" then
		g_currentMission:preUpdate(dt)
	end

	if Platform.hasFriendInvitation and g_showDeeplinkingFailedMessage == true and g_gui.currentGuiName ~= "GamepadSigninScreen" then
		g_showDeeplinkingFailedMessage = false

		if GS_PLATFORM_XBOX then
			if PlatformPrivilegeUtil.checkMultiplayer(onShowDeepLinkingErrorMsg, nil, , 30000) then
				onShowDeepLinkingErrorMsg()
			end
		else
			onShowDeepLinkingErrorMsg()
		end
	end

	if GS_PLATFORM_GGP then
		if getIsKeyboardAvailable() and g_gameSettings:getValue(GameSettings.SETTING.INPUT_HELP_MODE) ~= GS_INPUT_HELP_MODE_AUTO then
			g_gameSettings:setValue(GameSettings.SETTING.INPUT_HELP_MODE, GS_INPUT_HELP_MODE_AUTO)
		elseif not getIsKeyboardAvailable() and g_gameSettings:getValue(GameSettings.SETTING.INPUT_HELP_MODE) ~= GS_INPUT_HELP_MODE_GAMEPAD then
			g_gameSettings:setValue(GameSettings.SETTING.INPUT_HELP_MODE, GS_INPUT_HELP_MODE_GAMEPAD)
		end
	end

	if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
		g_gui:update(dt)
	end

	if g_currentMission ~= nil and g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen" then
		g_currentMission:update(dt)
	end

	if g_soundPlayer ~= nil then
		g_soundPlayer:update(dt)
	end

	if g_gui.currentGuiName == "MainScreen" then
		g_achievementManager:update(dt)
	end

	g_soundManager:update(dt)
	g_gamingStationManager:update(dt)
	Input.updateFrameEnd()

	if GS_PLATFORM_PC then
		if getIsUpdateDownloadFinished() then
			g_updateDownloadFinished = true
		end

		if g_updateDownloadFinished and not g_updateDownloadFinishedDialogShown and (g_gui.currentGuiName == "MainScreen" or g_currentMission ~= nil and g_currentMission.gameStarted) then
			g_updateDownloadFinishedDialogShown = true

			g_gui:showInfoDialog({
				title = g_i18n:getText("ui_updateDownloadFinishedTitle"),
				text = g_i18n:getText("ui_updateDownloadFinishedText")
			})
		end

		if g_isPresentationVersionNextLanguageTimer ~= nil and g_isPresentationVersionNextLanguageTimer < g_time then
			RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
			restartApplication(true, "")
		end
	end
end

function draw()
	if g_currentTest ~= nil then
		g_currentTest.draw()

		return
	end

	g_debugManager:draw()

	if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
		g_gui:draw()
	end

	if g_currentMission ~= nil and g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen" then
		g_currentMission:draw()
	end

	if g_isPresentationVersionNextLanguageIndex ~= nil then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(0, 0, 0, 1)

		local timeLeft = math.ceil((g_isPresentationVersionNextLanguageTimer - g_time) / 1000)

		renderText(0.5 + 2 / g_screenWidth, 0.75 - 1 / g_screenHeight, 0.025, string.format("Changing Language.\nNew language after restart will be '%s'. \nRestarting in %d seconds...", getLanguageName(g_isPresentationVersionNextLanguageIndex), timeLeft))
		setTextColor(1, 1, 1, 1)
		renderText(0.5, 0.75, 0.025, string.format("Changing Language.\nNew language after restart will be '%s'. \nRestarting in %d seconds...", getLanguageName(g_isPresentationVersionNextLanguageIndex), timeLeft))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end

	if g_showWatermark then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(1, 1, 1, 0.5)
		renderText(0.5, 0.75, getCorrectTextSize(0.075), "INTERNAL USE ONLY")
		renderText(0.5, 0.73, getCorrectTextSize(0.03), "Copyright GIANTS Software GmbH")
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end

	if g_isDevelopmentConsoleScriptModTesting then
		renderText(0.2, 0.85, getCorrectTextSize(0.05), "CONSOLE SCRIPTS. DEVELOPMENT USE ONLY")
	end

	if g_showSafeFrame then
		if g_safeFrameOverlay == nil then
			g_safeFrameOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

			setOverlayColor(g_safeFrameOverlay, 1, 0, 0, 0.4)
		end

		renderOverlay(g_safeFrameOverlay, g_safeFrameOffsetX, 0, 1 - 2 * g_safeFrameOffsetX, g_safeFrameOffsetY)
		renderOverlay(g_safeFrameOverlay, g_safeFrameOffsetX, 1 - g_safeFrameOffsetY, 1 - 2 * g_safeFrameOffsetX, g_safeFrameOffsetY)
		renderOverlay(g_safeFrameOverlay, 0, 0, g_safeFrameOffsetX, 1)
		renderOverlay(g_safeFrameOverlay, 1 - g_safeFrameOffsetX, 0, g_safeFrameOffsetX, 1)

		if g_safeFrameMajorOverlay == nil then
			g_safeFrameMajorOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

			setOverlayColor(g_safeFrameMajorOverlay, 1, 0, 0, 0.4)
		end

		renderOverlay(g_safeFrameMajorOverlay, g_safeFrameMajorOffsetX, 0, 1 - 2 * g_safeFrameMajorOffsetX, g_safeFrameMajorOffsetY)
		renderOverlay(g_safeFrameMajorOverlay, g_safeFrameMajorOffsetX, 1 - g_safeFrameMajorOffsetY, 1 - 2 * g_safeFrameMajorOffsetX, g_safeFrameMajorOffsetY)
		renderOverlay(g_safeFrameMajorOverlay, 0, 0, g_safeFrameMajorOffsetX, 1)
		renderOverlay(g_safeFrameMajorOverlay, 1 - g_safeFrameMajorOffsetX, 0, g_safeFrameMajorOffsetX, 1)
	end

	if g_drawGuiHelper then
		if g_guiHelperOverlay == nil then
			g_guiHelperOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")
		end

		if g_guiHelperOverlay ~= 0 then
			setTextColor(1, 1, 1, 1)

			local width, height = getScreenModeInfo(getScreenMode())

			for i = g_guiHelperSteps, 1, g_guiHelperSteps do
				renderOverlay(g_guiHelperOverlay, i, 0, 1 / width, 1)
				renderOverlay(g_guiHelperOverlay, 0, i, 1, 1 / height)
			end

			for i = 0.05, 1, 0.05 do
				renderText(i, 0.97, getCorrectTextSize(0.02), tostring(i))
				renderText(0.01, i, getCorrectTextSize(0.02), tostring(i))
			end

			setTextAlignment(RenderText.ALIGN_RIGHT)
			setTextColor(0, 0, 0, 0.9)
			renderText(g_lastMousePosX - 0.015, g_lastMousePosY - 0.0125 - 0.002, getCorrectTextSize(0.025), string.format("%1.4f", g_lastMousePosY))
			setTextColor(1, 1, 1, 1)
			renderText(g_lastMousePosX - 0.015, g_lastMousePosY - 0.0125, getCorrectTextSize(0.025), string.format("%1.4f", g_lastMousePosY))
			setTextAlignment(RenderText.ALIGN_CENTER)
			setTextColor(0, 0, 0, 0.9)
			renderText(g_lastMousePosX, g_lastMousePosY + 0.015 - 0.002, getCorrectTextSize(0.025), string.format("%1.4f", g_lastMousePosX))
			setTextColor(1, 1, 1, 1)
			renderText(g_lastMousePosX, g_lastMousePosY + 0.015, getCorrectTextSize(0.025), string.format("%1.4f", g_lastMousePosX))
			setTextAlignment(RenderText.ALIGN_LEFT)

			local halfCrosshairWidth = 5 / width
			local halfCrosshairHeight = 5 / width

			renderOverlay(g_guiHelperOverlay, g_lastMousePosX - halfCrosshairWidth, g_lastMousePosY, 2 * halfCrosshairWidth, 1 / height)
			renderOverlay(g_guiHelperOverlay, g_lastMousePosX, g_lastMousePosY - halfCrosshairHeight, 1 / width, 2 * halfCrosshairHeight)
		end
	end

	if Platform.requiresConnectedGamepad and getNumOfGamepads() == 0 and g_gui.currentGuiName ~= "StartupScreen" and g_gui.currentGuiName ~= "GamepadSigninScreen" then
		if Platform.isXbox then
			requestGamepadSignin(Input.BUTTON_2, true, false)
		end

		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(0, 0, 0, 1)

		local xPos = 0.5
		local yPos = 0.6
		local blackOffset = 0.003
		local textSize = getCorrectTextSize(0.05)
		local text = g_i18n:getText("ui_pleaseReconnectController")

		renderText(xPos - blackOffset, yPos + blackOffset * 1.7777777777777777, textSize, text)
		renderText(xPos, yPos + blackOffset * 1.7777777777777777, textSize, text)
		renderText(xPos + blackOffset, yPos + blackOffset * 1.7777777777777777, textSize, text)
		renderText(xPos - blackOffset, yPos, textSize, text)
		renderText(xPos + blackOffset, yPos, textSize, text)
		renderText(xPos - blackOffset, yPos - blackOffset * 1.7777777777777777, textSize, text)
		renderText(xPos, yPos - blackOffset * 1.7777777777777777, textSize, text)
		renderText(xPos + blackOffset, yPos - blackOffset * 1.7777777777777777, textSize, text)
		setTextColor(1, 1, 1, 1)
		renderText(xPos, yPos, textSize, text)
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_LEFT)

		if g_darkControllerOverlay == nil then
			g_darkControllerOverlay = createImageOverlay("dataS/menu/blank.png")

			setOverlayColor(g_darkControllerOverlay, 1, 1, 1, 0.3)
		else
			renderOverlay(g_darkControllerOverlay, 0, 0, 1, 1)
		end
	end

	if g_showRawInput then
		setOverlayColor(GuiElement.debugOverlay, 0, 0, 0, 0.9)
		renderOverlay(GuiElement.debugOverlay, 0, 0, 1, 1)
		setTextAlignment(RenderText.ALIGN_LEFT)

		local numGamepads = getNumOfGamepads()
		local yCoord = 0.95

		for i = 0, numGamepads - 1 do
			local numButtons = 0

			for j = 0, Input.MAX_NUM_BUTTONS - 1 do
				if getHasGamepadButton(Input.BUTTON_1 + j, i) then
					numButtons = numButtons + 1
				end
			end

			local numAxes = 0

			for axis = 0, Input.MAX_NUM_AXES - 1 do
				if getHasGamepadAxis(axis, i) then
					numAxes = numAxes + 1
				end
			end

			local versionId = getGamepadVersionId(i)
			local versionText = ""

			if versionId < 65535 then
				versionText = string.format("Version: %04X ", versionId)
			end

			yCoord = yCoord - 0.025

			renderText(0.02, yCoord, 0.025, string.format("Index: %d Name: %s PID: %04X VID: %04X %s#Buttons: %d #Axes: %d", i, getGamepadName(i), getGamepadProductId(i), getGamepadVendorId(i), versionText, numButtons, numAxes))

			for axis = 0, Input.MAX_NUM_AXES - 1 do
				if getHasGamepadAxis(axis, i) then
					local physical = getGamepadAxisPhysicalName(axis, i)
					yCoord = yCoord - 0.016

					renderText(0.025, yCoord, 0.016, string.format("%s->%d: '%s' %1.2f", physical, axis, getGamepadAxisLabel(axis, i), getInputAxis(axis, i)))
				end
			end

			for button = 0, Input.MAX_NUM_BUTTONS - 1 do
				if getInputButton(button, i) > 0 then
					local physical = getGamepadButtonPhysicalName(button, i)
					yCoord = yCoord - 0.025

					renderText(0.025, yCoord, 0.025, string.format("%s->%d: '%s'", physical, button, getGamepadButtonLabel(button, i)))
				end
			end

			yCoord = yCoord - 0.016
		end

		if numGamepads == 0 then
			renderText(0.025, yCoord, 0.025, "No gamepads found")
		end
	end
end

function postAnimationUpdate(dt)
	for _, callbackData in pairs(g_postAnimationUpdateCallbacks) do
		callbackData.callbackFunc(callbackData.callbackTarget, dt, callbackData.callbackArguments)
	end
end

function cleanUp()
	if g_safeFrameOverlay ~= nil then
		delete(g_safeFrameOverlay)
	end

	if g_safeFrameMajorOverlay ~= nil then
		delete(g_safeFrameMajorOverlay)
	end

	if g_guiHelperOverlay ~= nil then
		delete(g_guiHelperOverlay)
	end

	if GuiElement.debugOverlay ~= nil then
		delete(GuiElement.debugOverlay)
	end

	deleteDrawingOverlays()
	g_masterServerConnection:disconnectFromMasterServer()
	g_connectionManager:shutdownAll()
	g_createGameScreen:removePortMapping()
	g_inputDisplayManager:delete()
	g_gui:delete()
	delete(g_menuMusic)
	delete(g_savegameXML)
	g_lifetimeStats:save()

	if g_soundPlayer ~= nil then
		g_soundPlayer:delete()

		g_soundPlayer = nil
	end

	g_animCache:delete()
	g_i3DManager:clearEntireSharedI3DFileCache(g_isDevelopmentVersion)
	g_soundManager:delete()

	if g_isDevelopmentVersion then
		setFileLogPrefixTimestamp(false)
		printActiveEntities()
		setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
	end

	removeConsoleCommand("gsGuiDrawHelper")
	removeConsoleCommand("gsI3DCacheClean")
	removeConsoleCommand("gsSetHighQuality")
	removeConsoleCommand("gsGuiSafeFrameShow")
	removeConsoleCommand("gsGuiDebug")
	removeConsoleCommand("gsRenderColorAndDepthScreenShot")
	removeConsoleCommand("gsRenderingDebugMode")
	removeConsoleCommand("gsInputDrawRaw")
	removeConsoleCommand("gsTestForceFeedback")
	removeConsoleCommand("gsLanguageSet")
	removeConsoleCommand("gsGuiReloadCurrent")
	removeConsoleCommand("gsSuspendApp")
	removeConsoleCommand("gsInputFuzz")
	removeConsoleCommand("gsUpdateDownloadFinished")
	removeConsoleCommand("gsSoftRestart")
end

function doExit()
	cleanUp()
	print("Application quit")
	requestExit()
end

function doRestart(restartProcess, args)
	cleanUp()

	local restartType = ""

	if not restartProcess then
		restartType = "(soft restart)"
	end

	print("Application restart " .. restartType)
	restartApplication(restartProcess, args)
end

function loadLanguageSettings(xmlFile)
	local numLanguages = getNumOfLanguages()
	local languageCodeToLanguage = {}

	for i = 0, numLanguages - 1 do
		languageCodeToLanguage[getLanguageCode(i)] = i
	end

	local language = getLanguage()
	local languageSet = false
	local availableLanguages = {}

	xmlFile:iterate("settings.languages.language", function (_, key)
		local code = xmlFile:getString(key .. "#code")
		local languageShort = xmlFile:getString(key .. "#short")
		local languageSuffix = xmlFile:getString(key .. "#suffix")
		local lang = languageCodeToLanguage[code]

		if lang ~= nil then
			if lang == language or not languageSet then
				languageSet = true
				g_language = lang
				g_languageShort = languageShort
				g_languageSuffix = languageSuffix
			end

			if getIsLanguageEnabled(lang) then
				availableLanguages[lang] = true
			end
		end
	end)

	g_availableLanguagesTable = {}
	g_availableLanguageNamesTable = {}

	for i = 0, numLanguages - 1 do
		if availableLanguages[i] or i == g_language then
			table.insert(g_availableLanguagesTable, i)
			table.insert(g_availableLanguageNamesTable, getLanguageName(i))

			if i == g_language then
				g_settingsLanguageGUI = table.getn(g_availableLanguagesTable) - 1
			end
		end
	end

	if GS_IS_CONSOLE_VERSION then
		g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, getSystemLanguage())
	end
end

function loadUserSettings(gameSettings, settingsModel)
	local nickname = getUserName():trim()

	if nickname == nil or nickname == "" then
		nickname = "Player"
	end

	gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, nickname)
	gameSettings:setValue(GameSettings.SETTING.VOLUME_MASTER, getMasterVolume())
	gameSettings:setValue("joystickVibrationEnabled", getGamepadVibrationEnabled())

	if g_savegameXML ~= nil then
		delete(g_savegameXML)
	end

	local gameSettingsPathTemplate = getAppBasePath() .. "profileTemplate/gameSettingsTemplate.xml"
	g_savegamePath = getUserProfileAppPath() .. "gameSettings.xml"

	copyFile(gameSettingsPathTemplate, g_savegamePath, false)

	g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)

	if settingsModel ~= nil then
		settingsModel:setSettingsFileHandle(g_savegameXML)
	end

	syncProfileFiles()

	local revision = getXMLInt(g_savegameXML, "gameSettings#revision")
	local gameSettingsTemplate = loadXMLFile("GameSettingsTemplate", gameSettingsPathTemplate)
	local revisionTemplate = getXMLInt(gameSettingsTemplate, "gameSettings#revision")

	delete(gameSettingsTemplate)

	if revision == nil or revision ~= revisionTemplate then
		copyFile(gameSettingsPathTemplate, g_savegamePath, true)
		delete(g_savegameXML)

		g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)

		if settingsModel ~= nil then
			settingsModel:setSettingsFileHandle(g_savegameXML)
		end
	end

	if settingsModel ~= nil then
		settingsModel:refresh()
	end

	gameSettings:loadFromXML(g_savegameXML)
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.MENU_MUSIC, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_MUSIC))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))

	if GS_IS_MOBILE_VERSION then
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.DEFAULT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
	end

	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
	g_soundMixer:setMasterVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_MASTER))
	VoiceChatUtil.setOutputVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VOICE))
	VoiceChatUtil.setInputVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VOICE_INPUT))
	VoiceChatUtil.setInputMode(g_gameSettings:getValue(GameSettings.SETTING.VOICE_MODE))
	g_lifetimeStats:reload()

	if g_extraContentSystem ~= nil then
		g_extraContentSystem:reset()
		g_extraContentSystem:loadFromProfile()
	end
end

function registerGlobalActionEvents(inputManager)
	local function onTakeScreenShot()
		if g_screenshotsDirectory ~= nil then
			local screenshotName = g_screenshotsDirectory .. "fsScreen_" .. getDate("%Y_%m_%d_%H_%M_%S") .. ".png"

			print("Saving screenshot: " .. screenshotName)
			saveScreenshot(screenshotName)
		else
			print("Unable to find screenshot directory!")
		end
	end

	local eventAdded, eventId = inputManager:registerActionEvent(InputAction.TAKE_SCREENSHOT, InputBinding.NO_EVENT_TARGET, onTakeScreenShot, false, true, false, true)

	if eventAdded then
		inputManager:setActionEventTextVisibility(eventId, false)
	end

	local function onPushToTalk(_, _, isActive)
		VoiceChatUtil.setIsPushToTalkPressed(isActive == 1)
	end

	local _ = nil
	_, eventId = inputManager:registerActionEvent(InputAction.PUSH_TO_TALK, InputBinding.NO_EVENT_TARGET, onPushToTalk, true, true, false, true)

	inputManager:setActionEventTextVisibility(eventId, false)
end

function loadPresentationSettings(file)
	if fileExists(file) then
		local xmlFile = loadXMLFile("settingsFile", file)
		g_isPresentationVersion = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.active"), false)
		g_isPresentationVersionLogoEnabled = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.logo"), false)
		g_isPresentationVersionShopEnabled = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.shop"), false)
		g_isPresentationVersionDlcEnabled = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.dlcs"), false)
		g_isPresentationVersionAllMapsEnabled = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.allMaps"), true)
		g_isPresentationVersionUSMapEnabled = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.usMap"), false)
		g_isPresentationVersionFRMapEnabled = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.frMap"), false)
		g_isPresentationVersionAlpineMapEnabled = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.alpineMap"), false)

		if not g_isPresentationVersionUSMapEnabled and not g_isPresentationVersionAlpineMapEnabled then
			g_isPresentationVersionFRMapEnabled = true
		end

		g_isPresentationVersionSpecialStore = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.specialStore"), false)

		if g_isPresentationVersionSpecialStore then
			g_isPresentationVersionSpecialStorePath = getXMLString(xmlFile, "presentationSettings.specialStore#path") or "dataS/storeItems_presentationVersion.xml"
		end

		g_presentationVersionDifficulty = getXMLInt(xmlFile, "presentationSettings.difficulty")
		g_isPresentationVersionAIEnabled = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.ai"), false)
		g_isPresentationVersionHideMenuButtons = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.limitedMainMenu"), false)
		g_isPresentationVersionUseReloadButton = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.reloadButton"), false)
		g_showWatermark = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.waterMark"), false)

		if hasXMLProperty(xmlFile, "presentationSettings.playtimeResetDuration") then
			g_isPresentationVersionPlaytimeCountdown = getXMLFloat(xmlFile, "presentationSettings.playtimeResetDuration")
		end

		g_isPresentationVersionAlwaysDay = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.alwaysDay"), false)
		g_isPresentationVersionShowDrivingHelp = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.drivingHelp"), false)
		g_isPresentationVersionMenuDisabled = not Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.menuActive"), true)
		g_isPresentationVersionIsTourEnabled = Utils.getNoNil(getXMLBool(xmlFile, "presentationSettings.isTourEnabled"), false)

		delete(xmlFile)
	end
end

function updateAspectRatio(aspect)
	local referenceAspect = g_referenceScreenWidth / g_referenceScreenHeight

	if aspect > referenceAspect then
		g_aspectScaleX = referenceAspect / aspect
		g_aspectScaleY = 1
	else
		g_aspectScaleX = 1
		g_aspectScaleY = aspect / referenceAspect
	end
end

SystemConsoleCommands = {
	drawGuiHelper = function (self, steps)
		steps = tonumber(steps)

		if steps ~= nil then
			g_guiHelperSteps = math.max(steps, 0.001)
			g_drawGuiHelper = true
		else
			g_guiHelperSteps = 0.1
			g_drawGuiHelper = false
		end

		if g_drawGuiHelper then
			return "DrawGuiHelper = true (step = " .. g_guiHelperSteps .. ")"
		else
			return "DrawGuiHelper = false"
		end
	end,
	showSafeFrame = function (self)
		g_showSafeFrame = not g_showSafeFrame

		return string.format("showSafeFrame = %s", g_showSafeFrame)
	end,
	drawRawInput = function (self)
		g_showRawInput = not g_showRawInput

		return string.format("showRawInput = %s", g_showRawInput)
	end,
	testForceFeedback = function (self)
		if getHasGamepadAxisForceFeedback(0, 0) then
			co = coroutine.create(function ()
				for i = 1, 0, -0.2 do
					setGamepadAxisForceFeedback(0, 0, 0.8, i)
					print(string.format("TestForceFeedback %1.2f", i))
					usleep(500000)
					setGamepadAxisForceFeedback(0, 0, 0.8, -i)
					usleep(500000)
				end

				setGamepadAxisForceFeedback(0, 0, 0, 0)
			end)

			coroutine.resume(co)
		else
			print("Force feedback not available")
		end
	end,
	cleanI3DCache = function (self, verbose)
		verbose = Utils.stringToBoolean(verbose)

		g_i3DManager:clearEntireSharedI3DFileCache(verbose)

		local ret = "I3D cache cleaned."

		if not verbose then
			ret = ret .. " Use 'true' parameter for verbose output"
		end

		return ret
	end,
	setHighQuality = function (self, coeffOverride)
		local minValue = 1e-06
		local maxValue = 10
		local default = 5
		local usage = string.format("Usage 'gsSetHighQuality <factor (default=%d)>'", default)
		local coeff = MathUtil.clamp(tonumber(coeffOverride) or default, minValue, maxValue)

		setViewDistanceCoeff(coeff)
		setLODDistanceCoeff(coeff)
		setTerrainLODDistanceCoeff(coeff)
		setFoliageViewDistanceCoeff(math.max(1, coeff * 0.5))

		return string.format("High quality activated, used factor=%s.%s", MathUtil.round(coeff, 8), coeffOverride == nil and " " .. usage or "")
	end,
	renderColorAndDepthScreenShot = function (self, inWidth, inHeight)
		local width, height = nil

		if inWidth == nil or inHeight == nil then
			local curScrMode = getScreenMode()
			width, height = getScreenModeInfo(curScrMode)
		else
			width = tonumber(inWidth)
			height = tonumber(inHeight)
		end

		setDebugRenderingMode(DebugRendering.NONE)

		local strDate = getDate("%Y_%m_%d_%H_%M_%S") .. ".hdr"
		local colorScreenShot = g_screenshotsDirectory .. "fsScreen_color_" .. strDate

		print("Saving color screenshot: " .. colorScreenShot)
		renderScreenshot(colorScreenShot, width, height, width / height, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false, 4)
		setDebugRenderingMode(DebugRendering.DEPTH)

		local depthScreenShot = g_screenshotsDirectory .. "fsScreen_depth_" .. strDate

		print("Saving depth screenshot: " .. depthScreenShot)
		renderScreenshot(depthScreenShot, width, height, width / height, "raw_hdr", 1, 0, 0, 0, 0, 0, 15, false, 0)
		setDebugRenderingMode(DebugRendering.NONE)
	end,
	setDebugRenderingMode = function (self, newMode)
		if newMode == nil or newMode == "" then
			setDebugRenderingMode(DebugRendering.NONE)

			return "Possible modes: alpha, parallax, albedo, normals, smoothness, metalness, ambientOcclusion (ao), bakedAmbientOcclusion (bakedAO), screenSpaceAmbientOcclusion(ssao), specularOcclusion, diffuseLighting, specularLighting, indirectLighting, lightGrid, shadowSplits, depth, mipLevels, triangleDensity, terrainSlopes, motionVectors"
		end

		newMode = newMode:lower()
		local modeDescs = {
			alpha = {
				DebugRendering.ALPHA,
				"alpha"
			},
			parallax = {
				DebugRendering.PARALLAX,
				"parallax"
			},
			albedo = {
				DebugRendering.ALBEDO,
				"albedo"
			},
			normals = {
				DebugRendering.NORMALS,
				"normals"
			},
			smoothness = {
				DebugRendering.SMOOTHNESS,
				"smoothness"
			},
			metalness = {
				DebugRendering.METALNESS,
				"metalness"
			},
			ambient_occlusion = {
				DebugRendering.AMBIENT_OCCLUSION,
				"ambientOcclusion"
			},
			ambientocclusion = {
				DebugRendering.AMBIENT_OCCLUSION,
				"ambientOcclusion"
			},
			ao = {
				DebugRendering.AMBIENT_OCCLUSION,
				"ambientOcclusion"
			},
			baked_ambient_occlusion = {
				DebugRendering.BAKED_AMBIENT_OCCLUSION,
				"bakedAmbientOcclusion"
			},
			bakedambientocclusion = {
				DebugRendering.BAKED_AMBIENT_OCCLUSION,
				"bakedAmbientOcclusion"
			},
			bakedao = {
				DebugRendering.BAKED_AMBIENT_OCCLUSION,
				"bakedAmbientOcclusion"
			},
			screenspaceambientocclusion = {
				DebugRendering.SCREEN_SPACE_AMBIENT_OCCLUSION,
				"screenSpaceAmbientOcclusion"
			},
			screen_space_ambient_occlusion = {
				DebugRendering.SCREEN_SPACE_AMBIENT_OCCLUSION,
				"screenSpaceAmbientOcclusion"
			},
			ssao = {
				DebugRendering.SCREEN_SPACE_AMBIENT_OCCLUSION,
				"screenSpaceAmbientOcclusion"
			},
			specular_occlusion = {
				DebugRendering.SPECULAR_OCCLUSION,
				"specularOcclusion"
			},
			specularocclusion = {
				DebugRendering.SPECULAR_OCCLUSION,
				"specularOcclusion"
			},
			diffuse_lighting = {
				DebugRendering.DIFFUSE_LIGHTING,
				"diffuseLighting"
			},
			diffuselighting = {
				DebugRendering.DIFFUSE_LIGHTING,
				"diffuseLighting"
			},
			diffuse = {
				DebugRendering.DIFFUSE_LIGHTING,
				"diffuseLighting"
			},
			specular_lighting = {
				DebugRendering.SPECULAR_LIGHTING,
				"specularLighting"
			},
			specularlighting = {
				DebugRendering.SPECULAR_LIGHTING,
				"specularLighting"
			},
			specular = {
				DebugRendering.SPECULAR_LIGHTING,
				"specularLighting"
			},
			indirect_lighting = {
				DebugRendering.INDIRECT_LIGHTING,
				"indirectLighting"
			},
			indirectlighting = {
				DebugRendering.INDIRECT_LIGHTING,
				"indirectLighting"
			},
			indirect = {
				DebugRendering.INDIRECT_LIGHTING,
				"indirectLighting"
			},
			light_grid = {
				DebugRendering.LIGHT_GRID,
				"lightGrid"
			},
			lightgrid = {
				DebugRendering.LIGHT_GRID,
				"lightGrid"
			},
			shadow_splits = {
				DebugRendering.SHADOW_SPLITS,
				"shadowSplits"
			},
			shadowsplits = {
				DebugRendering.SHADOW_SPLITS,
				"shadowSplits"
			},
			depth = {
				DebugRendering.DEPTH_SCALED,
				"depth"
			},
			miplevels = {
				DebugRendering.MIP_LEVELS,
				"mipLevels"
			},
			mips = {
				DebugRendering.MIP_LEVELS,
				"mipLevels"
			},
			triangledensity = {
				DebugRendering.TRIANGLE_DENSITY,
				"triangleDensity"
			},
			terrainslopes = {
				DebugRendering.TERRAIN_SLOPES,
				"terrainSlopes"
			},
			motionvectors = {
				DebugRendering.MOTION_VECTORS,
				"motionVectors"
			},
			custom1 = {
				DebugRendering.CUSTOM1,
				"custom1"
			},
			custom2 = {
				DebugRendering.CUSTOM2,
				"custom2"
			}
		}
		local modeDesc = modeDescs[newMode]
		local modeName = "none"
		local mode = DebugRendering.NONE

		if modeDesc ~= nil then
			mode = modeDesc[1]
			modeName = modeDesc[2]
		end

		setDebugRenderingMode(mode)

		return "Changed debug rendering to " .. modeName
	end,
	changeLanguage = function (self, newCode)
		local numLanguages = getNumOfLanguages()
		local newLang = -1

		if newCode == nil then
			local newIndex = g_settingsLanguageGUI + 1

			if table.getn(g_availableLanguagesTable) <= newIndex then
				newIndex = 0
			end

			newLang = g_availableLanguagesTable[newIndex + 1]
		else
			for i = 0, numLanguages - 1 do
				if getLanguageCode(i) == newCode then
					newLang = i

					break
				end
			end

			if newLang < 0 then
				return "Invalid language parameter " .. tostring(newCode)
			end
		end

		if setLanguage(newLang) then
			local xmlFile = XMLFile.load("SettingsFile", "dataS/settings.xml")

			loadLanguageSettings(xmlFile)
			xmlFile:delete()
			g_i18n:load()

			return string.format("Changed language to '%s'. Note that many texts are loaded on game start and need a reboot to be updated.", getLanguageCode(newLang))
		end

		return "Invalid language parameter " .. tostring(newCode)
	end,
	reloadCurrentGui = function (self)
		if g_gui.currentGuiName ~= nil and g_gui.currentGuiName ~= "" then
			local guiName = g_gui.currentGuiName
			local guiController = g_gui.currentGui.target
			local class = ClassUtil.getClassObject(guiName)
			g_dummyGui = nil

			if class.createFromExistingGui ~= nil then
				g_dummyGui = class.createFromExistingGui(guiController)
			else
				g_dummyGui = class.new()
			end

			g_gui:showGui("")
			g_i18n:load()
			g_gui:loadProfiles("dataS/guiProfiles.xml")
			g_gui:loadGui("dataS/gui/" .. guiName .. ".xml", guiName, g_dummyGui)
			g_gui:showGui(guiName)
		end
	end,
	toggleUiDebug = function (self)
		if g_uiDebugEnabled then
			g_uiDebugEnabled = false

			return "UI Debug disabled"
		else
			g_uiDebugEnabled = true

			return "UI Debug enabled"
		end
	end,
	suspendApp = function (self)
		if g_appIsSuspended then
			notifyAppResumed()
		else
			notifyAppSuspended()
		end

		return "App Suspended: " .. tostring(g_appIsSuspended)
	end,
	fuzzInput = function (self)
		beginInputFuzzing()
	end,
	softRestart = function (self)
		RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
		doRestart(false, "")
	end,
	updateDownloadFinished = function (self)
		g_updateDownloadFinished = true

		log("g_updateDownloadFinished = true")
	end
}

function startDevServer(savegameId, uniqueUserId)
	print("Start developer mp server (Savegame-Id: " .. tostring(savegameId) .. ")")
	g_mainScreen:onMultiplayerClick()
	g_multiplayerScreen:onClickCreateGame()

	local savegameController = g_careerScreen.savegameController
	local savegame = savegameController:getSavegame(tonumber(savegameId))

	if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
		print("    Savegame not found! Please select savegame manually!")

		return
	end

	g_careerScreen.savegameList.selectedIndex = tonumber(savegameId)

	g_careerScreen:onStartAction()

	if g_gui.currentGuiName == "ModSelectionScreen" then
		g_modSelectionScreen:onClickOk()
	end

	g_autoDevMP = {
		serverName = "InternalTest_" .. getUserName()
	}

	g_createGameScreen.serverNameElement:setText(g_autoDevMP.serverName)

	g_createGameScreen.autoAccept = true

	g_createGameScreen:onClickOk()
end

function startDevClient(uniqueUserId)
	print("Start developer mp client")
	g_mainScreen:onMultiplayerClick()

	g_autoDevMP = {
		serverName = "InternalTest_" .. getUserName()
	}

	g_multiplayerScreen:onContinue()
end

function autoStartLocalSavegame(savegameId)
	print("Auto start local savegame (Id: " .. tostring(savegameId) .. ")")
	g_gui:setIsMultiplayer(false)
	g_gui:showGui("CareerScreen")
	g_careerScreen.savegameList:setSelectedIndex(tonumber(savegameId), true)

	local savegameController = g_careerScreen.savegameController
	local savegame = savegameController:getSavegame(tonumber(savegameId))

	if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
		print("    Savegame not found! Please select savegame manually!")

		return
	end

	g_careerScreen.currentSavegame = savegame

	g_careerScreen:onStartAction()

	if g_gui.currentGuiName == "ModSelectionScreen" then
		g_modSelectionScreen:onClickOk()
	end
end

function connectToServer(platformServerId)
	if storeHaveDlcsChanged() or haveModsChanged() or g_forceNeedsDlcsAndModsReload then
		g_forceNeedsDlcsAndModsReload = false

		reloadDlcsAndMods()
	end

	if storeAreDlcsCorrupted() then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_dlcsCorruptRedownload"),
			callback = g_mainScreen.onDlcCorruptClick,
			target = g_mainScreen
		})
	else
		g_deepLinkingInfo = {
			platformServerId = platformServerId
		}

		g_masterServerConnection:disconnectFromMasterServer()
		g_connectionManager:shutdownAll()
		g_gui:changeScreen(nil, CareerScreen)
		g_mainScreen:onMultiplayerClick()
		g_multiplayerScreen:onClickJoinGame()
	end
end

source("dataS/scripts/debug/ConsoleSimulator.lua")
source("dataS/scripts/debug/MobileSimulator.lua")
source("dataS/scripts/debug/StadiaSimulator.lua")
source("dataS/scripts/debug/MemoryLeaks.lua")
