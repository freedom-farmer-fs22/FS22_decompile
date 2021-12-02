InGameMenuHelpFrame = {}
local InGameMenuHelpFrame_mt = Class(InGameMenuHelpFrame, TabbedMenuFrameElement)
InGameMenuHelpFrame.CONTROLS = {
	"helpLineList",
	"helpLineTitleElement",
	"helpLineContentBox",
	"helpLineContentItem"
}

function InGameMenuHelpFrame.new(subclass_mt, l10n, helpLineManager)
	local self = InGameMenuHelpFrame:superClass().new(nil, subclass_mt or InGameMenuHelpFrame_mt)

	self:registerControls(InGameMenuHelpFrame.CONTROLS)

	self.l10n = l10n
	self.helpLineManager = helpLineManager
	self.baseDirectory = ""

	return self
end

function InGameMenuHelpFrame:copyAttributes(src)
	InGameMenuHelpFrame:superClass().copyAttributes(self, src)

	self.l10n = src.l10n
	self.helpLineManager = src.helpLineManager
end

function InGameMenuHelpFrame:onGuiSetupFinished()
	InGameMenuHelpFrame:superClass().onGuiSetupFinished(self)
	self.helpLineList:setDataSource(self)
	self.helpLineList:setDelegate(self)
end

function InGameMenuHelpFrame:delete()
	self.helpLineContentItem:delete()
	InGameMenuHelpFrame:superClass().delete(self)
end

function InGameMenuHelpFrame:onFrameOpen()
	InGameMenuHelpFrame:superClass().onFrameOpen(self)
	self.helpLineList:reloadData()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.helpLineList)
	self:setSoundSuppressed(false)
	self.helpLineContentBox:registerActionEvents()
end

function InGameMenuHelpFrame:onFrameClose()
	self.helpLineContentBox:removeActionEvents()
	InGameMenuHelpFrame:superClass().onFrameClose(self)
end

function InGameMenuHelpFrame:setMissionBaseDirectory(baseDirectory)
	self.baseDirectory = baseDirectory
end

function InGameMenuHelpFrame:updateContents(page)
	self.helpLineContentItem:unlinkElement()

	for i = #self.helpLineContentBox.elements, 1, -1 do
		self.helpLineContentBox.elements[i]:delete()
	end

	self.helpLineContentBox:invalidateLayout()

	if page == nil then
		return
	end

	self.helpLineTitleElement:setText(self.helpLineManager:convertText(page.title))

	for _, paragraph in ipairs(page.paragraphs) do
		local row = self.helpLineContentItem:clone(self.helpLineContentBox)
		local textElement = row:getDescendantByName("text")
		local textFullElement = row:getDescendantByName("textFullWidth")
		local imageElement = row:getDescendantByName("image")
		local textHeight = 0
		local textHeightFullHeight = 0

		if paragraph.image ~= nil then
			textFullElement:setVisible(false)

			if paragraph.text ~= nil then
				textElement:setText(self.helpLineManager:convertText(paragraph.text))

				textHeight = textElement:getTextHeight()

				textElement:setSize(nil, textHeight)
			end

			local filename = Utils.getFilename(paragraph.image.filename, self.baseDirectory)

			imageElement:setImageFilename(filename)
			imageElement:setImageUVs(nil, unpack(paragraph.image.uvs))

			if imageElement.originalWidth == nil then
				imageElement.originalWidth = imageElement.absSize[1]
			end

			if paragraph.text == nil then
				imageElement:setSize(row.absSize[1], row.absSize[1] * paragraph.image.aspectRatio * g_screenAspectRatio)
			else
				imageElement:setSize(imageElement.originalWidth, nil)
			end
		else
			textElement:setVisible(false)
			imageElement:setVisible(false)
			textFullElement:setText(self.helpLineManager:convertText(paragraph.text))

			textHeightFullHeight = textFullElement:getTextHeight()

			textFullElement:setSize(nil, textHeightFullHeight)
		end

		local imageHeight = paragraph.image ~= nil and imageElement.absSize[2] or 0

		row:setSize(nil, math.max(textHeight, textHeightFullHeight, imageHeight))
		row:invalidateLayout()
	end

	self.helpLineContentBox:invalidateLayout()
end

function InGameMenuHelpFrame:onListSelectionChanged(list, section, index)
	self:updateContents(self:getPage(section, index))
end

function InGameMenuHelpFrame:getNumberOfSections()
	return #self.helpLineManager.categories
end

function InGameMenuHelpFrame:getNumberOfItemsInSection(list, section)
	return #self.helpLineManager.categories[section].pages
end

function InGameMenuHelpFrame:getTitleForSectionHeader(list, section)
	return self.l10n:convertText(self.helpLineManager.categories[section].title)
end

function InGameMenuHelpFrame:populateCellForItemInSection(list, section, index, cell)
	local page = self:getPage(section, index)

	cell:getAttribute("title"):setText(self.l10n:convertText(page.title))
end

function InGameMenuHelpFrame:getPage(categoryIndex, pageIndex)
	local categories = self.helpLineManager:getCategories()

	return categories[categoryIndex].pages[pageIndex]
end
