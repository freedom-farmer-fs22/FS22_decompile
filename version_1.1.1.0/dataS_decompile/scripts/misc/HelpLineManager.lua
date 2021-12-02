HelpLineManager = {}
local HelpLineManager_mt = Class(HelpLineManager, AbstractManager)
HelpLineManager.ITEM_TYPE = {
	TEXT = "text",
	IMAGE = "image"
}

function HelpLineManager.new(customMt)
	local self = AbstractManager.new(customMt or HelpLineManager_mt)

	return self
end

function HelpLineManager:initDataStructures()
	self.categories = {}
	self.categoryNames = {}
end

function HelpLineManager:loadMapData(xmlFile, missionInfo)
	HelpLineManager:superClass().loadMapData(self)

	local filename = Utils.getFilename(getXMLString(xmlFile, "map.helpline#filename"), g_currentMission.baseDirectory)

	if filename == nil or filename == "" then
		print("Error: Could not load helpline config file '" .. tostring(filename) .. "'!")

		return false
	end

	self:loadFromXML(filename, missionInfo)

	return true
end

function HelpLineManager:loadFromXML(filename, missionInfo)
	local xmlFile = XMLFile.load("helpLineViewContentXML", filename)

	xmlFile:iterate("helpLines.category", function (index, key)
		local category = self:loadCategory(xmlFile, key, missionInfo)

		if category ~= nil then
			table.insert(self.categories, category)
		end
	end)
	xmlFile:delete()
end

function HelpLineManager:loadCategory(xmlFile, key, missionInfo)
	local category = {
		title = xmlFile:getString(key .. "#title"),
		pages = {}
	}

	xmlFile:iterate(key .. ".page", function (index, key)
		local page = self:loadPage(xmlFile, key, missionInfo)

		table.insert(category.pages, page)
	end)

	return category
end

function HelpLineManager:loadPage(xmlFile, key, missionInfo)
	local page = {
		title = xmlFile:getString(key .. "#title"),
		paragraphs = {}
	}

	xmlFile:iterate(key .. ".paragraph", function (index, key)
		local paragraph = {
			text = xmlFile:getString(key .. ".text#text")
		}
		local filename = xmlFile:getString(key .. ".image#filename")

		if filename ~= nil then
			local heightScale = xmlFile:getFloat(key .. ".image#heightScale", 1)
			local aspectRatio = xmlFile:getFloat(key .. ".image#aspectRatio", 1)
			local size = GuiUtils.get2DArray(xmlFile:getString(key .. ".image#size"), {
				1024,
				1024
			})
			local uvs = GuiUtils.getUVs(xmlFile:getString(key .. ".image#uvs", "0 0 1 1"), size)
			paragraph.image = {
				filename = filename,
				uvs = uvs,
				size = size,
				heightScale = heightScale,
				aspectRatio = aspectRatio
			}
		end

		table.insert(page.paragraphs, paragraph)
	end)

	return page
end

function HelpLineManager:convertText(text)
	local translated = g_i18n:convertText(text)

	return string.gsub(translated, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
end

function HelpLineManager:getCategories()
	return self.categories
end

function HelpLineManager:getCategory(categoryIndex)
	if categoryIndex ~= nil then
		return self.categories[categoryIndex]
	end

	return nil
end

g_helpLineManager = HelpLineManager.new()
