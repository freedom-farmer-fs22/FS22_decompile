GamingStationManager = {
	GAMEPAD_NAME = "JoyWarrior Gamepad 32",
	BRAND_CONFIGURATION_FILE = "dataS/gamingStation/brandConfig.xml",
	STANDALONE_CONFIGURATION_FILE = "data/gamingStation/standalone.xml",
	LOAD_NONE = 0,
	LOAD_GS = 1,
	LOAD_STANDALONE = 2,
	LOAD_ERROR_COULD_NOT_FIND_GS = 3,
	BIT_TO_BUTTON = {
		{
			button = 7
		},
		{
			button = 6
		},
		{
			button = 5
		},
		{
			button = 4
		},
		{
			button = 3
		},
		{
			button = 2
		},
		{
			button = 1
		},
		{
			button = 0
		},
		[15] = {
			button = 8
		},
		[16] = {
			button = 9
		},
		[17] = {
			button = 10
		}
	}
}
local GamingStationManager_mt = Class(GamingStationManager, AbstractManager)

function GamingStationManager.new(customMt)
	local self = AbstractManager.new(customMt or GamingStationManager_mt)
	self.loadState = GamingStationManager.LOAD_NONE
	self.gamepadId = self:getGamingStationGamepad()

	if self.loadState == GamingStationManager.LOAD_GS or self.loadState == GamingStationManager.LOAD_STANDALONE then
		self.brands = {}
		local xmlFile = loadXMLFile("gamingStationBrandConfig", GamingStationManager.BRAND_CONFIGURATION_FILE)

		self:loadConfigurationFile(xmlFile)
		delete(xmlFile)

		if self.loadState == GamingStationManager.LOAD_GS then
			self.loadedBrand = self:getCurrentBrand()
		else
			xmlFile = loadXMLFile("standaloneConfigConfig", GamingStationManager.STANDALONE_CONFIGURATION_FILE)
			self.loadedBrand = getXMLInt(xmlFile, "standalone#brandId")

			delete(xmlFile)

			if self.loadedBrand == nil then
				Logging.error("Could not find standalone brandId in '%s'", GamingStationManager.STANDALONE_CONFIGURATION_FILE)
			end
		end

		local oldGetIsDeviceSupported = InputDevice.getIsDeviceSupported

		function InputDevice.getIsDeviceSupported(engineDeviceId, deviceName)
			return GamingStationManager.getIsDeviceSupported(oldGetIsDeviceSupported, engineDeviceId, deviceName)
		end

		MissionManager.MAX_MISSIONS = 0
	end

	return self
end

function GamingStationManager:load()
	g_messageCenter:subscribe(MessageType.GUI_CAREER_SCREEN_OPEN, self.onOpenCareerScreen, self)
	g_messageCenter:subscribe(MessageType.GUI_CHARACTER_CREATION_SCREEN_OPEN, self.onOpenWardrobeScreen, self)

	MainScreen.onOpen = Utils.prependedFunction(MainScreen.onOpen, GamingStationManager.inj_mainScreen_onOpen)
	MainScreen.onClose = Utils.prependedFunction(MainScreen.onClose, GamingStationManager.inj_mainScreen_onClose)
end

function GamingStationManager:initBrand()
	if self.loadedBrand ~= nil then
		self:applyBrand(self.loadedBrand)

		self.loadedBrand = nil
	end
end

function GamingStationManager:update(dt)
	if self.loadState == GamingStationManager.LOAD_GS and g_gui.currentGuiName == "MainScreen" then
		local newBrandId = self:getCurrentBrand()

		if newBrandId ~= nil and self.brandId ~= newBrandId then
			self:applyBrand(newBrandId)
		end

		local brand = self.brands[self.brandId]

		if brand ~= nil then
			setTextColor(0, 0, 0, 0.75)
			renderText(0.01, 0.9585, 0.011, brand.name)
			setTextColor(1, 1, 1, 1)
			renderText(0.01, 0.96, 0.011, brand.name)
		end
	end
end

function GamingStationManager:getGamingStationGamepad()
	if fileExists(GamingStationManager.BRAND_CONFIGURATION_FILE) then
		local numOfGamepads = getNumOfGamepads()

		for i = 0, numOfGamepads - 1 do
			local gamepadName = getGamepadName(i)

			if gamepadName == GamingStationManager.GAMEPAD_NAME then
				Logging.info("Found Gaming Station with gamepad '%s'", gamepadName)

				self.loadState = GamingStationManager.LOAD_GS

				return i
			end

			if GS_IS_CONSOLE_VERSION then
				Logging.info("Found Gaming Station config, and usual gamepad '%s'", gamepadName)

				self.loadState = GamingStationManager.LOAD_GS

				return i
			end
		end

		if fileExists(GamingStationManager.STANDALONE_CONFIGURATION_FILE) then
			self.loadState = GamingStationManager.LOAD_STANDALONE

			return nil
		end

		Logging.error("Unable to find GamingStation!")

		self.loadState = GamingStationManager.LOAD_ERROR_COULD_NOT_FIND_GS
	end

	return nil
end

function GamingStationManager:getCurrentBrand()
	for brandId, brand in ipairs(self.brands) do
		local isValid = true
		local bits = brand.bits

		if GS_IS_CONSOLE_VERSION then
			return brandId
		end

		for i, bit in ipairs(bits) do
			local button = GamingStationManager.BIT_TO_BUTTON[i]

			if button ~= nil then
				if button.button ~= nil then
					if getInputButton(button.button, self.gamepadId) ~= bit then
						isValid = false
					end
				elseif button.axis ~= nil then
					local target = bit == 1 and button.value or button.idleValue

					if bit == 0 and button.minIdleValue ~= nil then
						if getInputAxis(button.axis, self.gamepadId) < button.minIdleValue or target < getInputAxis(button.axis, self.gamepadId) then
							isValid = false

							break
						end
					elseif getInputAxis(button.axis, self.gamepadId) ~= target then
						isValid = false

						break
					end
				end
			end
		end

		if isValid then
			return brandId
		end
	end

	return nil
end

function GamingStationManager:applyBrand(brandId)
	if brandId ~= nil then
		local brand = self.brands[brandId]

		if brand ~= nil then
			if brand.savegame ~= nil then
				if GS_IS_CONSOLE_VERSION then
					saveSetFixedSavegame(brand.savegame)
				else
					local savegamePath = getUserProfileAppPath() .. "savegame1"

					deleteFolder(savegamePath)
					createFolder(savegamePath)

					local savegameSourcePath = getAppBasePath() .. brand.savegame
					local newFiles = Files.new(savegameSourcePath).files

					for _, file in ipairs(newFiles) do
						copyFile(savegameSourcePath .. "/" .. file.filename, savegamePath .. "/" .. file.filename, true)
					end

					if not fileExists(savegamePath .. "/careerSavegame.xml") then
						Logging.error("Failed to copy gamingStation savegame from '%s' to '%s'!", savegameSourcePath, savegamePath)
					end
				end
			elseif not GS_IS_CONSOLE_VERSION then
				local savegamePath = getUserProfileAppPath() .. "savegame1"

				deleteFolder(savegamePath)
			end

			self.brandId = brandId

			loadPresentationSettings(brand.presentationSettings)
			Logging.info("Brand for Gaming Station: '%s'", brand.name)

			if g_gui.currentGuiName == "MainScreen" then
				g_mainScreen:onOpen()
			end
		end
	else
		Logging.info("Could not find brand for Gaming Station! Do not touch the dip switches!")
	end
end

function GamingStationManager:loadConfigurationFile(xmlFile)
	local i = 0

	while true do
		local key = string.format("brands.brand(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		self:loadBrandFromXML(xmlFile, key)

		i = i + 1
	end
end

function GamingStationManager:loadBrandFromXML(xmlFile, key)
	local name = getXMLString(xmlFile, key .. "#name")
	local bits = {}
	local bitsStr = getXMLString(xmlFile, key .. "#bits")

	for i = 1, bitsStr:len() do
		local bit = bitsStr:sub(i, i)

		if bit ~= " " then
			table.insert(bits, tonumber(bit))
		end
	end

	local savegame = getXMLString(xmlFile, key .. ".savegame#path")
	local presentationSettings = getXMLString(xmlFile, key .. ".presentationSettings#path")

	table.insert(self.brands, {
		name = name,
		bits = bits,
		savegame = savegame,
		presentationSettings = presentationSettings
	})
end

function GamingStationManager:onOpenCareerScreen(canStart)
	if canStart then
		return
	end

	if self.loadState ~= GamingStationManager.LOAD_NONE then
		if self:getIsActive() then
			local brand = self.brands[self.brandId]

			if brand ~= nil then
				g_careerScreen.selectedIndex = 1
				local savegameController = g_careerScreen.savegameController
				local savegame = savegameController:getSavegame(g_careerScreen.selectedIndex)

				if brand.savegame ~= nil then
					if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
						g_careerScreen:onClickBack()
						g_gui:showInfoDialog({
							text = "Could not find savegame for selected brand!",
							dialogType = DialogElement.TYPE_WARNING
						})

						return
					end
				elseif not GS_IS_CONSOLE_VERSION then
					local savegamePath = getUserProfileAppPath() .. "savegame1"

					deleteFolder(savegamePath)
				end

				g_careerScreen.currentSavegame = savegame
			end

			g_careerScreen:onStartAction()

			if g_gui.currentGuiName == "DifficultyScreen" then
				g_difficultyScreen:onClickOk()
			end

			if g_gui.currentGuiName == "ModSelectionScreen" then
				g_modSelectionScreen:onClickOk()
			end
		else
			g_careerScreen:onClickBack()
			g_gui:showInfoDialog({
				text = "Could not find savegame for selected brand! Do not touch the dip switches!",
				dialogType = DialogElement.TYPE_WARNING
			})
		end
	end

	if self.loadState == GamingStationManager.LOAD_ERROR_COULD_NOT_FIND_GS then
		g_careerScreen:onClickBack()
		g_gui:showInfoDialog({
			text = "No gamingStation connected!",
			dialogType = DialogElement.TYPE_WARNING
		})
	end
end

function GamingStationManager:onOpenMainScreen()
	if self:getIsActive() then
		self:applyBrand(self.brandId)
	end
end

function GamingStationManager:onOpenWardrobeScreen()
	if self:getIsActive() and g_gui.currentGuiName == "ModSelectionScreen" then
		g_modSelectionScreen:onClickOk()
	end
end

function GamingStationManager.getIsDeviceSupported(superFunc, engineDeviceId, deviceName)
	if not superFunc(engineDeviceId, deviceName) then
		return false
	end

	if deviceName == GamingStationManager.GAMEPAD_NAME then
		return false
	end

	return true
end

function GamingStationManager:getIsActive()
	return self.brandId ~= nil
end

function GamingStationManager.inj_mainScreen_onClose(screen)
	if screen.toggleLanguageEventId ~= nil then
		g_inputBinding:removeActionEvent(screen.toggleLanguageEventId)

		screen.toggleLanguageEventId = nil
	end
end

function GamingStationManager.inj_mainScreen_onOpen(screen)
	if screen.toggleLanguageEventId ~= nil then
		g_inputBinding:removeActionEvent(screen.toggleLanguageEventId)

		screen.toggleLanguageEventId = nil
	end

	if g_isPresentationVersion and not GS_IS_CONSOLE_VERSION then
		local function onToggleLanguage()
			if g_gui.currentGuiName == "MainScreen" then
				local currentLanguage = getLanguage()
				local nextIndex = nil

				for k, v in ipairs(g_availableLanguagesTable) do
					if v == currentLanguage then
						nextIndex = k + 1
					end
				end

				if nextIndex == nil or nextIndex > #g_availableLanguagesTable then
					nextIndex = 1
				end

				currentLanguage = g_availableLanguagesTable[nextIndex]
				g_isPresentationVersionNextLanguageIndex = currentLanguage
				g_isPresentationVersionNextLanguageTimer = g_time + 5000

				setLanguage(currentLanguage)
			end
		end

		local eventAdded, eventId = g_inputBinding:registerActionEvent(InputAction.GAMING_STATION_TOGGLE_LANGUAGE, InputBinding.NO_EVENT_TARGET, onToggleLanguage, false, true, false, true)
		screen.toggleLanguageEventId = eventId

		if eventAdded then
			g_inputBinding:setActionEventTextVisibility(eventId, false)
		end
	end
end

g_gamingStationManager = GamingStationManager.new()
