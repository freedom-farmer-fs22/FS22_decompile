WardrobeScreen = {}
local WardrobeScreen_mt = Class(WardrobeScreen, TabbedMenuWithDetails)
WardrobeScreen.CAMERA_FOV = math.rad(40)
WardrobeScreen.BACKGROUND_PATH = "data/store/ui/wardrobe.i3d"
WardrobeScreen.CONTROLS = {
	"background",
	"fadeElement",
	"header",
	"buttonsPanel",
	"brandIcon",
	"lookGlyph",
	"pageCharacter",
	"pageHair",
	"pageBeard",
	"pageMoustache",
	"pageHeadgear",
	"pageFootwear",
	"pageTop",
	"pageBottom",
	"pageGloves",
	"pageGlasses",
	"pageOutfit",
	"pageColors",
	"loadingAnimation"
}

function WardrobeScreen.new(target, custom_mt, messageCenter, l10n, inputManager)
	local self = TabbedMenuWithDetails.new(target, custom_mt or WardrobeScreen_mt, messageCenter, l10n, inputManager)

	self:registerControls(WardrobeScreen.CONTROLS)

	self.scenePrepared = false

	return self
end

function WardrobeScreen:onOpen()
	WardrobeScreen:superClass().onOpen(self)
	g_messageCenter:publish(MessageType.GUI_CHARACTER_CREATION_SCREEN_OPEN)

	if g_currentMission.controlPlayer then
		self.didControlPlayer = true
		local player = g_currentMission.player
		self.lastPlayerX, self.lastPlayerY, self.lastPlayerZ = player:getPositionData()

		player:onLeave()
	end

	self.currentPlayerStyle = PlayerStyle.new()
	self.temporaryPlayerStyle = PlayerStyle.new()
	local playerStyle = g_currentMission.player.model.style

	if playerStyle == nil then
		playerStyle = g_currentMission.playerInfoStorage:getPlayerStyle(g_currentMission.player.userId)
	end

	if playerStyle ~= nil then
		self.currentPlayerStyle:copyFrom(playerStyle)
	else
		local newStyle = PlayerStyle.new()

		newStyle:loadConfigurationXML(g_characterModelManager.playerModels[1].xmlFilename)
		self.currentPlayerStyle:copyFrom(newStyle)
	end

	self.currentPlayerStyle:loadConfigurationIfRequired()
	self.temporaryPlayerStyle:copyFrom(self.currentPlayerStyle)
	self:updatePagePlayerStyle()
	g_currentMission.environment:setCustomLighting(self.lighting)
	self:updateCharacter(true)
	self:updateTabIcons()
	self:updateBrandIcon()

	self.rotY = 0
	self.inputHorizontal = 0
	self.isDragging = false
	self.accumDraggingInput = 0
	self.lastInputMode = -1
	self.lastInputHelpMode = -1
	self.mouseDragActive = false

	self:updateInputGlyphs()
	self:registerActionEvents()

	self.previousCamera = getCamera()

	setCamera(self.camera)
	self:showContent(true)
end

function WardrobeScreen:onClose()
	self:removeActionEvents()
	self:showContent(false)
	g_currentMission.environment:setCustomLighting(nil)
	setCamera(self.previousCamera)
	self.playerModel:delete()

	self.playerModel = nil

	if self.didControlPlayer then
		g_currentMission.player:onEnter(true)
		g_currentMission.player:moveTo(self.lastPlayerX, self.lastPlayerY, self.lastPlayerZ, true, true)

		self.didControlPlayer = false
	end

	WardrobeScreen:superClass().onClose(self)
end

function WardrobeScreen:onDetailClosed(detailPage)
	if self.colorDetailCallback ~= nil and not self.isPoppingDetailSafely then
		self.colorDetailCallback(false)

		self.colorDetailCallback = nil
	end
end

function WardrobeScreen:updatePagePlayerStyle()
	local style = self.temporaryPlayerStyle
	local savedStyle = self.currentPlayerStyle

	self.pageCharacter:setPlayerStyle(style, savedStyle)
	self.pageHair:setPlayerStyle(style, savedStyle)
	self.pageBeard:setPlayerStyle(style, savedStyle)
	self.pageMoustache:setPlayerStyle(style, savedStyle)
	self.pageHeadgear:setPlayerStyle(style, savedStyle)
	self.pageFootwear:setPlayerStyle(style, savedStyle)
	self.pageTop:setPlayerStyle(style, savedStyle)
	self.pageBottom:setPlayerStyle(style, savedStyle)
	self.pageGloves:setPlayerStyle(style, savedStyle)
	self.pageGlasses:setPlayerStyle(style, savedStyle)
	self.pageColors:setPlayerStyle(style, savedStyle)
	self.pageOutfit:setPlayerStyle(style, savedStyle)
end

function WardrobeScreen:onGuiSetupFinished()
	WardrobeScreen:superClass().onGuiSetupFinished(self)
	self:initializePages()
	self:setupMenuPages()
end

function WardrobeScreen:initializePages()
	self.pageCharacter:initialize("faceConfig", self, "character_option_body")
	self.pageHair:initialize("hairStyleConfig", self, "character_option_hairStyle")
	self.pageBeard:initialize("beardConfig", self, "character_option_beardStyle")
	self.pageMoustache:initialize("mustacheConfig", self, "character_option_mustache")
	self.pageHeadgear:initialize("headgearConfig", self, "character_option_headGear")
	self.pageFootwear:initialize("footwearConfig", self, "character_option_footwear")
	self.pageTop:initialize("topConfig", self, "character_option_top")
	self.pageBottom:initialize("bottomConfig", self, "character_option_bottom")
	self.pageGloves:initialize("glovesConfig", self, "character_option_gloves")
	self.pageGlasses:initialize("glassesConfig", self, "character_option_glasses")
	self.pageOutfit:initialize(self, "character_option_outfits")
	self.pageColors:initialize(self)
end

function WardrobeScreen:setupMenuPages()
	local function rootPagePredicate()
		return not self:getIsDetailMode()
	end

	local function colorPagePredicate()
		return self:getIsDetailMode()
	end

	local orderedDefaultPages = {
		{
			self.pageCharacter,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.CHARACTER
		},
		{
			self.pageHair,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.HAIR
		},
		{
			self.pageBeard,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.BEARD
		},
		{
			self.pageMoustache,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.MOUSTACHE
		},
		{
			self.pageOutfit,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.OUTFIT
		},
		{
			self.pageTop,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.TOP
		},
		{
			self.pageBottom,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.BOTTOM
		},
		{
			self.pageFootwear,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.FOOTWEAR
		},
		{
			self.pageHeadgear,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.HEADGEAR
		},
		{
			self.pageGloves,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.GLOVES
		},
		{
			self.pageGlasses,
			rootPagePredicate,
			WardrobeScreen.TAB_UV.GLASSES
		},
		{
			self.pageColors,
			colorPagePredicate,
			WardrobeScreen.TAB_UV.HEADGEAR
		}
	}

	for i, pageDef in ipairs(orderedDefaultPages) do
		local page, predicate, iconUVs = unpack(pageDef)

		self:registerPage(page, i, predicate)

		local imageFilename = g_iconsUIFilename
		local normalizedUVs = GuiUtils.getUVs(iconUVs)

		self:addPageTab(page, imageFilename, normalizedUVs)
	end
end

function WardrobeScreen:setupMenuButtonInfo()
	WardrobeScreen:superClass().setupMenuButtonInfo(self)

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
		callback = self.clickBackCallback
	}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.backButtonInfo
	self.defaultButtonActionCallbacks[InputAction.MENU_BACK] = self.clickBackCallback
end

function WardrobeScreen:updateTabIcons()
	for page, tab in pairs(self.pageTabs) do
		local icon = tab.elements[1]

		if page.configName ~= nil then
			local mapping = self.currentPlayerStyle[page.configName].listMappingGetter(self.currentPlayerStyle)
			local disabled = #mapping == 0

			if disabled then
				icon.icon.color = {
					0.4,
					0.4,
					0.4,
					0.8
				}
				icon.icon.colorFocused = {
					1,
					1,
					1,
					0.5
				}
				icon.icon.colorSelected = {
					1,
					1,
					1,
					0.5
				}
			else
				icon.icon.color = {
					0.0003,
					0.5647,
					0.9822,
					1
				}
				icon.icon.colorFocused = {
					1,
					1,
					1,
					1
				}
				icon.icon.colorSelected = {
					1,
					1,
					1,
					1
				}
			end
		end
	end
end

function WardrobeScreen:onButtonBack()
	g_currentMission.player:setStyleAsync(self.currentPlayerStyle, function ()
		self:exitMenu()
	end)
end

function WardrobeScreen:update(dt)
	WardrobeScreen:superClass().update(self, dt)

	if self.updateAnimationCallback ~= nil and not self.updateAnimationCallback(dt) then
		self.updateAnimationCallback = nil

		if self.updateAnimationFinishedCallback ~= nil then
			local cb = self.updateAnimationFinishedCallback
			self.updateAnimationFinishedCallback = nil

			cb()
		end
	end

	if self.playerModel ~= nil then
		self.playerModel:updateAnimations(dt)
	end

	self:updateInput(dt)
	self:updateCamera(dt)
end

function WardrobeScreen:updateCamera(dt)
	if self.rotateNode ~= nil then
		setRotation(self.rotateNode, 0, self.rotY, 0)
	end
end

function WardrobeScreen:showContent(show)
	if show then
		self.header:setVisible(true)
		self.buttonsPanel:setVisible(true)
		self.background:setVisible(true)
		self.lookGlyph:setVisible(true)
		setVisibility(self.sceneRootNode, true)

		if not self.hasBlurApplied then
			g_depthOfFieldManager:pushArea(self.background.absPosition[1], self.background.absPosition[2], self.background.absSize[1], self.background.absSize[2])

			self.hasBlurApplied = true
		end
	else
		self.header:setVisible(false)
		self.buttonsPanel:setVisible(false)
		self.background:setVisible(false)
		self.lookGlyph:setVisible(false)
		setVisibility(self.sceneRootNode, false)

		if self.hasBlurApplied then
			self.hasBlurApplied = false

			g_depthOfFieldManager:popArea()
		end
	end
end

function WardrobeScreen:showLoadingDialog(show)
	self.loadingAnimation:setVisible(show)
end

function WardrobeScreen:runAnimation(duration, tick, finish)
	self.animationTime = duration

	function self.updateAnimationCallback(dt)
		self.animationTime = self.animationTime - dt
		local a = math.min(math.max(1 - self.animationTime / duration, 0), 1)

		tick(a)

		return self.animationTime > 0
	end

	self.updateAnimationFinishedCallback = finish
end

function WardrobeScreen:fadeOut(cb)
	self:runAnimation(150, function (t)
		self.fadeElement:setImageColor(nil, 0, 0, 0, Tween.CURVE.EASE_IN(t))
	end, cb)
end

function WardrobeScreen:fadeIn(cb)
	self:runAnimation(150, function (t)
		self.fadeElement:setImageColor(nil, 0, 0, 0, 1 - Tween.CURVE.EASE_OUT(t))
	end, cb)
end

function WardrobeScreen:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	self.sceneRootNode = createTransformGroup("CharacterArea")

	link(getRootNode(), self.sceneRootNode)
	setTranslation(self.sceneRootNode, 0, -100, 100)
	setVisibility(self.sceneRootNode, true)

	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(WardrobeScreen.BACKGROUND_PATH, false, true, self.onLoadedWardrobeScene, self, nil)
end

function WardrobeScreen:onLoadedWardrobeScene(node, failedReason, args)
	removeFromPhysics(node)
	link(self.sceneRootNode, node)
	addToPhysics(node)

	self.characterModelRoot = createTransformGroup("characterModelRoot")

	link(self.sceneRootNode, self.characterModelRoot)
	setWorldRotation(self.characterModelRoot, 0, math.rad(25), 0)

	self.rotateNode = createTransformGroup("rotateNode")

	link(self.sceneRootNode, self.rotateNode)
	setWorldRotation(self.rotateNode, 0, math.rad(25), 0)

	self.rotY = math.rad(25)
	local cameraTargetNode = createTransformGroup("finalCameraPosNode")

	link(self.rotateNode, cameraTargetNode)
	setTranslation(cameraTargetNode, -1.35, 0.8, 0)
	setRotation(cameraTargetNode, math.rad(-8), math.rad(55), 0)

	self.camera = createCamera("camera_ccscreen", WardrobeScreen.CAMERA_FOV, 2, 10000)

	link(cameraTargetNode, self.camera)
	setTranslation(self.camera, 0, 0, 4)

	self.lighting = LightingStatic.new()
	local xmlFile = loadXMLFile("shop", Utils.getFilename("$data/store/ui/wardrobe.xml"))

	self.lighting:load(xmlFile, "shop.lighting")
	delete(xmlFile)
	self.lighting:setEnvironment(g_currentMission)

	self.scenePrepared = true
end

function WardrobeScreen:unloadMapData()
	if self.sceneRootNode ~= nil then
		delete(self.sceneRootNode)

		self.sceneRootNode = nil
		self.rotateNode = nil
	end

	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	if self.lighting ~= nil then
		self.lighting:delete()

		self.lighting = nil
	end

	self.scenePrepared = false
end

function WardrobeScreen:updateCharacter(isCreatingScene)
	if not self.scenePrepared then
		return
	end

	if self.playerModel == nil or self.playerModel.xmlFilename ~= self.temporaryPlayerStyle.xmlFilename then
		if self.playerModel ~= nil then
			self.playerModel:delete()
		end

		self.playerModel = PlayerModel.new()
		self.isModelLoading = true

		self.loadingAnimation:setVisible(true)
		self.playerModel:load(self.temporaryPlayerStyle.xmlFilename, false, false, true, self.loadCharacterFinished, self, {
			isCreatingScene
		})
	elseif not self.isModelLoading then
		self.loadingAnimation:setVisible(true)
		self.playerModel:setStyle(self.temporaryPlayerStyle, true, function (finished)
			if finished then
				self.loadingAnimation:setVisible(false)
			end
		end)
		self:updateTabIcons()
		self:updateBrandIcon()
	end
end

function WardrobeScreen:loadCharacterFinished(success, arguments)
	self.loadingAnimation:setVisible(false)

	self.isModelLoading = false

	if not success then
		self.playerModel:delete()

		self.playerModel = nil

		return
	end

	local isCreatingScene = arguments[1]

	link(self.characterModelRoot, self.playerModel:getRootNode())
	setRotation(self.playerModel:getRootNode(), 0, math.rad(-15), 0)
	self.playerModel:setAnimationParameters(true, false, false, false, 0, 0, 0)

	local currentStyle = g_currentMission.player:getStyle()

	if isCreatingScene and currentStyle ~= nil and currentStyle.xmlFilename == self.currentPlayerStyle.xmlFilename then
		self.currentPlayerStyle:copyFrom(currentStyle)
		self.temporaryPlayerStyle:copyFrom(currentStyle)
	end

	self.loadingAnimation:setVisible(true)
	self.playerModel:setStyle(self.temporaryPlayerStyle, true, function (finished)
		if finished then
			self.loadingAnimation:setVisible(false)
		end
	end)
	self:updateTabIcons()
	self:updateBrandIcon()
end

function WardrobeScreen:updateBrandIcon()
	local brandImage = nil
	local configName = self.currentPage.configName
	local fallbackConfigName = nil

	if self.currentPage:isa(WardrobeOutfitsFrame) then
		configName = "onepieceConfig"
		fallbackConfigName = "topConfig"
	end

	if configName ~= nil then
		local index = self.temporaryPlayerStyle[configName].selection
		local item = self.temporaryPlayerStyle[configName].items[index]

		if item ~= nil and item.brand ~= nil then
			brandImage = item.brand.image
		elseif fallbackConfigName ~= nil then
			index = self.temporaryPlayerStyle[fallbackConfigName].selection
			item = self.temporaryPlayerStyle[fallbackConfigName].items[index]

			if item ~= nil and item.brand ~= nil then
				brandImage = item.brand.image
			end
		end
	end

	self.brandIcon:setVisible(brandImage ~= nil)

	if brandImage ~= nil then
		self.brandIcon:setImageFilename(brandImage)
	end
end

function WardrobeScreen:onItemSelectionStart()
	if self.temporaryPlayerStyle == nil then
		return
	end

	self.temporaryPlayerStyle:copyFrom(self.currentPlayerStyle)
	self:updateCharacter()
end

function WardrobeScreen:onItemSelectionChanged()
	self:updateCharacter()
end

function WardrobeScreen:onItemSelectionConfirmed()
	self.currentPlayerStyle:copyFrom(self.temporaryPlayerStyle)
end

function WardrobeScreen:onItemSelectionCancelled()
	if self.temporaryPlayerStyle == nil then
		return
	end

	self.temporaryPlayerStyle:copyFrom(self.currentPlayerStyle)
	self:updateCharacter()
end

function WardrobeScreen:onItemShowColors(configName, item, itemsCallback)
	self.colorDetailCallback = itemsCallback

	self.pageColors:setConfigAndItem(configName, item)
	self:pushDetail(self.pageColors)
end

function WardrobeScreen:onColorSelectionChanged()
	self:updateCharacter()
end

function WardrobeScreen:onColorSelectionConfirmed(keepOpen)
	if not keepOpen then
		self.isPoppingDetailSafely = true

		self:popDetail()

		self.isPoppingDetailSafely = false
	end

	self.colorDetailCallback(true, keepOpen)
	self.currentPlayerStyle:copyFrom(self.temporaryPlayerStyle)

	if not keepOpen then
		self.colorDetailCallback = nil
	end
end

function WardrobeScreen:onColorSelectionCancelled(keepOpen)
	if not keepOpen then
		self.isPoppingDetailSafely = true

		self:popDetail()

		self.isPoppingDetailSafely = false
	end

	self.colorDetailCallback(false, keepOpen)

	if not keepOpen then
		self.colorDetailCallback = nil
	end
end

function WardrobeScreen:registerActionEvents()
	if self.eventIdLeftRightController ~= nil then
		g_inputBinding:removeActionEvent(self.eventIdLeftRightController)
	end

	local _ = nil
	_, self.eventIdLeftRightController = self.inputManager:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, self.onCameraLeftRight, false, false, true, true)
	self.lastInputMode = -1

	self:updateInputContext()
end

function WardrobeScreen:removeActionEvents()
	g_inputBinding:removeActionEvent(self.eventIdLeftRightController)

	self.eventIdLeftRightController = nil
end

function WardrobeScreen:onCameraLeftRight(actionName, inputValue, callbackState, isAnalog)
	self.inputHorizontal = inputValue * -2
end

function WardrobeScreen:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		if GuiUtils.checkOverlayOverlap(posX, posY, self.background.absPosition[1], self.background.absPosition[2], self.background.absSize[1], self.background.absSize[2]) then
			self.mouseDragActive = false

			return
		end

		if isDown then
			self.mouseDragActive = true
			self.lastMousePosX = posX
		end

		if isUp then
			self.mouseDragActive = false
		end

		if self.mouseDragActive then
			local dx = posX - self.lastMousePosX
			self.lastMousePosX = posX
			local dragValue = dx * 200
			self.inputHorizontal = self.inputHorizontal + dragValue
		end
	end
end

function WardrobeScreen:updateInput(dt)
	self:updateInputContext()

	if self.inputHorizontal ~= 0 then
		local value = self.inputHorizontal
		self.inputHorizontal = 0
		local rotSpeed = 0.001 * dt
		self.rotY = self.rotY - rotSpeed * value
	end

	local inputHelpMode = self.inputManager:getInputHelpMode()

	if inputHelpMode ~= self.lastInputHelpMode then
		self.lastInputHelpMode = inputHelpMode

		self:updateInputGlyphs()
	end

	self.inputDragging = false
end

function WardrobeScreen:updateInputContext()
	local currentInputMode = self.inputManager:getLastInputMode()

	if currentInputMode ~= self.lastInputMode then
		local isController = currentInputMode == GS_INPUT_HELP_MODE_GAMEPAD

		self.inputManager:setActionEventActive(self.eventIdLeftRightController, isController)

		self.lastInputMode = currentInputMode
		self.isDragging = false
	end
end

function WardrobeScreen:updateInputGlyphs()
	local platformActions = nil

	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		platformActions = {
			InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE
		}
	else
		platformActions = {
			InputAction.AXIS_LOOK_LEFTRIGHT_DRAG
		}
	end

	self.lookGlyph:setActions(platformActions)
end

WardrobeScreen.TAB_UV = {
	CHARACTER = {
		0,
		130,
		65,
		65
	},
	HAIR = {
		130,
		130,
		65,
		65
	},
	BEARD = {
		195,
		130,
		65,
		65
	},
	MOUSTACHE = {
		260,
		130,
		65,
		65
	},
	HEADGEAR = {
		325,
		130,
		65,
		65
	},
	FOOTWEAR = {
		455,
		130,
		65,
		65
	},
	TOP = {
		715,
		130,
		65,
		65
	},
	BOTTOM = {
		390,
		130,
		65,
		65
	},
	GLOVES = {
		520,
		130,
		65,
		65
	},
	GLASSES = {
		585,
		130,
		65,
		65
	},
	ONEPIECE = {
		650,
		130,
		65,
		65
	},
	OUTFIT = {
		65,
		130,
		65,
		65
	}
}
