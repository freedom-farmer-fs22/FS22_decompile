Brand = nil
BrandManager = {}
local BrandManager_mt = Class(BrandManager, AbstractManager)

function BrandManager.new(customMt)
	local self = AbstractManager.new(customMt or BrandManager_mt)

	return self
end

function BrandManager:initDataStructures()
	self.numOfBrands = 0
	self.nameToIndex = {}
	self.nameToBrand = {}
	self.indexToBrand = {}
	Brand = self.nameToIndex
end

function BrandManager:loadMapData(missionInfo)
	BrandManager:superClass().loadMapData(self)

	local xmlFile = loadXMLFile("brandsXML", "dataS/brands.xml")
	local i = 0

	while true do
		local baseXMLName = string.format("brands.brand(%d)", i)

		if not hasXMLProperty(xmlFile, baseXMLName) then
			break
		end

		local name = getXMLString(xmlFile, baseXMLName .. "#name")
		local title = getXMLString(xmlFile, baseXMLName .. "#title")
		local image = getXMLString(xmlFile, baseXMLName .. "#image")
		local imageShopOverview = getXMLString(xmlFile, baseXMLName .. "#imageShopOverview")
		local imageOffset = getXMLFloat(xmlFile, baseXMLName .. "#imageOffset")

		if title ~= nil and title:sub(1, 6) == "$l10n_" then
			title = g_i18n:getText(title:sub(7))
		end

		self:addBrand(name, title, image, "", false, imageShopOverview, imageOffset)

		i = i + 1
	end

	delete(xmlFile)

	return true
end

function BrandManager:addBrand(name, title, imageFilename, baseDir, isMod, imageShopOverview, imageOffset)
	if name == nil or name == "" then
		Logging.warning("Could not register brand. Name is missing or empty!")

		return false
	end

	if title == nil or title == "" then
		Logging.warning("Could not register brand '%s'. Title is missing or empty!", name)

		return false
	end

	if imageFilename == nil or imageFilename == "" then
		Logging.warning("Could not register brand '%s'. Image is missing or empty!", name)

		return false
	end

	if baseDir == nil then
		Logging.warning("Could not register brand '%s'. Base directory not defined!", name)

		return false
	end

	if imageShopOverview == nil then
		imageShopOverview = imageFilename
	end

	name = name:upper()

	if ClassUtil.getIsValidIndexName(name) then
		if self.nameToIndex[name] == nil then
			self.numOfBrands = self.numOfBrands + 1
			self.nameToIndex[name] = self.numOfBrands
			local brand = {
				index = self.numOfBrands,
				name = name,
				image = Utils.getFilename(imageFilename, baseDir),
				imageShopOverview = Utils.getFilename(imageShopOverview, baseDir),
				title = title,
				isMod = isMod,
				imageOffset = imageOffset or 0
			}
			self.nameToBrand[name] = brand
			self.indexToBrand[self.numOfBrands] = brand

			return brand
		end
	else
		Logging.warning("Invalid brand name '" .. tostring(name) .. "'! Only capital letters allowed!")
	end
end

function BrandManager:getBrandByIndex(brandIndex)
	if brandIndex ~= nil then
		return self.indexToBrand[brandIndex]
	end

	return nil
end

function BrandManager:getBrandIconByIndex(brandIndex)
	if brandIndex ~= nil and self.indexToBrand[brandIndex] ~= nil then
		return self.indexToBrand[brandIndex].image
	end

	return nil
end

function BrandManager:getBrandByName(brandName)
	if brandName ~= nil then
		return self.nameToBrand[brandName:upper()]
	end

	return nil
end

function BrandManager:getBrandIndexByName(brandName)
	if brandName ~= nil then
		if ClassUtil.getIsValidIndexName(brandName) then
			local brandIndex = self.nameToIndex[brandName:upper()]

			if brandIndex == nil then
				Logging.warning(brandName .. "' is an unknown brand! Using Lizard instead!")

				return Brand.LIZARD
			end

			return brandIndex
		else
			Logging.warning("Invalid brand name '" .. brandName .. "'! Only capital letters and underscores allowed. Using Lizard instead.")

			return Brand.LIZARD
		end
	end

	return nil
end

g_brandManager = BrandManager.new()
