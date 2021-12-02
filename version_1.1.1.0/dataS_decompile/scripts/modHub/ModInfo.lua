ModInfo = {}
local ModInfo_mt = Class(ModInfo)

function ModInfo.new(modId, postFix, priceString)
	local self = setmetatable({}, ModInfo_mt)
	self.modId = modId
	self.postFix = postFix
	self.priceString = priceString

	return self
end

function ModInfo:getId()
	return self.modId
end

function ModInfo:getName()
	return getModMetaAttributeString(self.modId, "title_" .. self.postFix)
end

function ModInfo:getAuthor()
	return getModMetaAttributeString(self.modId, "author")
end

function ModInfo:getDescription()
	return getModMetaAttributeString(self.modId, "description_" .. self.postFix)
end

function ModInfo:getHash()
	return getModMetaAttributeString(self.modId, "hash")
end

function ModInfo:getPriceString()
	return getModMetaAttributeString(self.modId, self.priceString)
end

function ModInfo:getVersionString()
	return getModMetaAttributeString(self.modId, "versionString")
end

function ModInfo:getDLCLink()
	return getModMetaAttributeString(self.modId, "DLCLink")
end

function ModInfo:getDLCSteamLink()
	return getModMetaAttributeString(self.modId, "DLCSteamLink")
end

function ModInfo:getIconFilename()
	return getModMetaAttributeString(self.modId, "iconImage")
end

function ModInfo:getScreenshot1Filename()
	return getModMetaAttributeString(self.modId, "screenshot0")
end

function ModInfo:getScreenshot2Filename()
	return getModMetaAttributeString(self.modId, "screenshot1")
end

function ModInfo:getScreenshot3Filename()
	return getModMetaAttributeString(self.modId, "screenshot2")
end

function ModInfo:getFilesize()
	return getModMetaAttributeInt(self.modId, "filesize")
end

function ModInfo:getFilename()
	return getModMetaAttributeString(self.modId, "filename")
end

function ModInfo:getRatingScore()
	return getModMetaAttributeInt(self.modId, "ratingScore")
end

function ModInfo:getDownloadedBytes()
	return getModMetaAttributeInt(self.modId, "downloaded")
end

function ModInfo:getIsDLC()
	return getModMetaAttributeBool(self.modId, "isDLC")
end

function ModInfo:getIsExternal()
	return getModMetaAttributeBool(self.modId, "isExternal")
end

function ModInfo:getIsNew()
	return getModMetaAttributeBool(self.modId, "isNew")
end

function ModInfo:getIsInstalled()
	return getModMetaAttributeBool(self.modId, "isInstalled")
end

function ModInfo:getIsUpdate()
	return getModMetaAttributeBool(self.modId, "isUpdate")
end

function ModInfo:getIsDownload()
	return getModMetaAttributeBool(self.modId, "isDownload")
end

function ModInfo:getIsDownloading()
	return getModMetaAttributeBool(self.modId, "isDownloading")
end

function ModInfo:getHasConflict()
	return getModMetaAttributeBool(self.modId, "isConflict")
end

function ModInfo:getIsFailed()
	return getModMetaAttributeBool(self.modId, "isFailed")
end

function ModInfo:getIsIconLocal()
	return getModMetaAttributeBool(self.modId, "isIconImageLocal")
end

function ModInfo:getIsTop()
	return not self:getIsExternal() and not getModMetaAttributeBool(self.modId, "isBeta")
end

function ModInfo:getNumUpdates()
	if self:getIsInstalled() and self:getIsUpdate() then
		return 1
	end

	return 0
end

function ModInfo:getNumConflicts()
	if self:getIsInstalled() and self:getHasConflict() then
		return 1
	end

	return 0
end

function ModInfo:getNumNew()
	if self:getIsNew() and not self:getIsInstalled() and not self:getIsDownload() and not self:getIsDownloading() then
		return 1
	end

	return 0
end
