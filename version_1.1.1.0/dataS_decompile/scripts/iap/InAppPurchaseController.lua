InAppPurchaseController = {}
local InAppPurchaseController_mt = Class(InAppPurchaseController)
InAppPurchaseController.PENDING_DELAY = 1000

function InAppPurchaseController.new(messageCenter, l10n, gameSettings)
	local self = setmetatable({}, InAppPurchaseController_mt)
	self.l10n = l10n
	self.messageCenter = messageCenter
	self.gameSettings = gameSettings
	self.isLoaded = false
	self.isInitialized = false
	self.callbacks = {}
	self.pendingTimer = InAppPurchaseController.PENDING_DELAY
	self.lastNumOfPendingItems = 0
	self.xmlPath = "dataS/inAppProducts.xml"

	return self
end

function InAppPurchaseController:load()
	if not self.isLoaded then
		self:loadProductsFromXML()

		if inAppInit ~= nil then
			inAppInit(self.xmlPath)
		end

		self.isLoaded = true
	end
end

function InAppPurchaseController:loadProductsFromXML()
	self.products = {}
	self.productIdToProduct = {}
	local xmlFile = loadXMLFile("products", self.xmlPath)
	local i = 0

	while true do
		local key = string.format("inAppPurchases.inAppPurchase(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local productId = getXMLInt(xmlFile, key .. "#productId")
		local coins = getXMLInt(xmlFile, key .. "#coins")
		local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")

		if productId ~= nil and coins ~= nil then
			local product = IAProduct.new(productId, coins, imageFilename)

			table.insert(self.products, product)

			self.productIdToProduct[productId] = product
		end

		i = i + 1
	end

	delete(xmlFile)
end

function InAppPurchaseController:setMission(mission)
	self.mission = mission
end

function InAppPurchaseController:getIsAvailable()
	if not self.isInitialized then
		if inAppIsLoaded ~= nil and inAppIsLoaded() then
			self.isInitialized = true

			return true
		end

		return false
	end

	return true
end

function InAppPurchaseController:getProducts()
	return self.products
end

function InAppPurchaseController:purchase(product, callback)
	assert(product ~= nil and callback ~= nil)

	if self.mission ~= nil then
		self.callbacks[product] = callback

		inAppStartPurchase(product:getId(), "onPurchaseEnd", self)
	end
end

function InAppPurchaseController:onPurchaseEnd(error, productId)
	local product = self.productIdToProduct[productId]

	if error == InAppPurchase.ERROR_OK then
		if self.mission ~= nil then
			self:addPurchasedCoins(product)
			inAppFinishPurchase(productId)
			self.callbacks[product](true)
			self:onPendingPurchasesChanged()
		end
	else
		self.callbacks[product](false, error == InAppPurchase.ERROR_CANCELLED, InAppPurchaseController.ERROR_TEXTS[error])
	end
end

function InAppPurchaseController:getHasPendingPurchase(product)
	local numRecoverablePurchases = inAppGetNumPendingPurchases()
	local productId = product:getId()

	for i = 0, numRecoverablePurchases - 1 do
		local pendingProductId = inAppGetPendingPurchaseProductId(i)

		if pendingProductId == productId then
			return true
		end
	end

	return false
end

function InAppPurchaseController:getHasAnyPendingPurchases()
	return inAppGetNumPendingPurchases() > 0
end

function InAppPurchaseController:checkPendingPurchasesChanged()
	self.pendingTimer = InAppPurchaseController.PENDING_DELAY
	local num = inAppGetNumPendingPurchases()

	if num ~= self.lastNumOfPendingItems then
		self:onPendingPurchasesChanged()

		self.lastNumOfPendingItems = num
	end
end

function InAppPurchaseController:onPendingPurchasesChanged()
	if self.pendingPurchaseCallback ~= nil then
		self.pendingPurchaseCallback()
	end
end

function InAppPurchaseController:setPendingPurchaseCallback(callback)
	self.pendingPurchaseCallback = callback
end

function InAppPurchaseController:tryPerformPendingPurchase(product, callback)
	assert(product ~= nil and callback ~= nil)

	local numRecoverablePurchases = inAppGetNumPendingPurchases()
	local productId = product:getId()

	for i = 0, numRecoverablePurchases - 1 do
		local pendingProductId = inAppGetPendingPurchaseProductId(i)

		if pendingProductId == productId then
			self:addPurchasedCoins(product)
			inAppFinishPendingPurchase(i)
			callback()

			return true
		end
	end

	return false
end

function InAppPurchaseController:addPurchasedCoins(product)
	local coins = product:getCoins()

	self.mission:addPurchasedMoney(coins)
	self.mission:saveSavegame()
end

function InAppPurchaseController:update(dt)
	if self.isLoaded and self.isInitialized then
		self.pendingTimer = self.pendingTimer - dt

		if self.pendingTimer < 0 then
			self:checkPendingPurchasesChanged()
		end
	end
end

InAppPurchaseController.ERROR_TEXTS = {
	[InAppPurchase.ERROR_FAILED] = "ui_iap_errorFailed",
	[InAppPurchase.ERROR_NETWORK_UNAVAILABLE] = "ui_iap_errorNetworkUnavailable",
	[InAppPurchase.ERROR_CANCELLED] = "ui_iap_errorCancelled",
	[InAppPurchase.ERROR_PURCHASE_IN_PROGRESS] = "ui_iap_purchaseInProgress"
}
