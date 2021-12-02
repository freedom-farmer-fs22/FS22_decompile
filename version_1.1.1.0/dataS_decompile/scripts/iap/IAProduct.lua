IAProduct = {}
local IAProduct_mt = Class(IAProduct)

function IAProduct.new(productId, coins, imageFilename)
	local self = setmetatable({}, IAProduct_mt)
	self.productId = productId
	self.coins = coins
	self.imageFilename = imageFilename

	return self
end

function IAProduct:getId()
	return self.productId
end

function IAProduct:getCoins()
	return self.coins
end

function IAProduct:getPriceText()
	return inAppGetProductPrice(self.productId)
end

function IAProduct:getTitle()
	return inAppGetProductDescription(self.productId)
end

function IAProduct:getImageFilename()
	return self.imageFilename
end
