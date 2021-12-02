SavegameController = {}
local SavegameController_mt = Class(SavegameController)

if GS_PLATFORM_PC or GS_PLATFORM_GGP then
	SavegameController.NUM_SAVEGAMES = 20
	SavegameController.SAVING_DURATION = 0.5
elseif GS_IS_MOBILE_VERSION then
	SavegameController.NUM_SAVEGAMES = 3
	SavegameController.SAVING_DURATION = 1
else
	SavegameController.NUM_SAVEGAMES = 10
	SavegameController.SAVING_DURATION = 3
end

SavegameController.SAVE_STATE_NONE = 0
SavegameController.SAVE_STATE_VALIDATE_LIST = 1
SavegameController.SAVE_STATE_VALIDATE_LIST_DIALOG_WAIT = 2
SavegameController.SAVE_STATE_VALIDATE_LIST_WAIT = 3
SavegameController.SAVE_STATE_OVERWRITE_DIALOG = 4
SavegameController.SAVE_STATE_OVERWRITE_DIALOG_WAIT = 5
SavegameController.SAVE_STATE_NOP_WRITE = 6
SavegameController.SAVE_STATE_WRITE = 7
SavegameController.SAVE_STATE_WRITE_WAIT = 8
SavegameController.SAVE_TASK_DENSITY_MAP = 0
SavegameController.SAVE_TASK_TERRAIN_HEIGHT_MAP = 1
SavegameController.SAVE_TASK_TERRAIN_LOD_TYPE_MAP = 2
SavegameController.SAVE_TASK_COLLISION_MAP = 3
SavegameController.SAVE_TASK_PLACEMENT_BLOCKING_MAP = 4
SavegameController.SAVE_TASK_SPLIT_SHAPES = 5
SavegameController.SAVE_TASK_BITVECTOR_MAP = 6
SavegameController.SAVE_TASK_NAVIGATION_MAP = 7
SavegameController.INFO_INVALID_USER = "invalidUser"
SavegameController.INFO_CORRUPT_FILE = "corrupt"
SavegameController.NO_SAVEGAME = {}
local NO_TARGET = {
	NO_CALLBACK = function ()
	end
}

function SavegameController.new(subclass_mt)
	local mt = subclass_mt or SavegameController_mt
	local self = setmetatable({}, mt)
	self.savegames = {}
	self.isSavingGame = false
	self.waitingForSaveGameInfo = false
	self.savingErrorCode = Savegame.ERROR_OK
	self.onDeleteCallback = NO_TARGET.NO_CALLBACK
	self.onDeleteCallbackTarget = NO_TARGET
	self.onSaveCompleteCallback = NO_TARGET.NO_CALLBACK
	self.onSaveCompleteCallbackTarget = NO_TARGET
	self.onUpdateCompleteCallback = NO_TARGET.NO_CALLBACK
	self.onUpdateCompleteTarget = NO_TARGET

	saveSetCloudErrorCallback("onCloudError", self)

	return self
end

function SavegameController:loadSavegames()
	for k, missionInfo in pairs(self.savegames) do
		missionInfo:delete()

		self.savegames[k] = nil
	end

	local savegameFiles = Files.new(getUserProfileAppPath())

	for i = 1, SavegameController.NUM_SAVEGAMES do
		local savegame = FSCareerMissionInfo.new("", nil, i)

		if not Platform.isConsole then
			for _, info in ipairs(savegameFiles.files) do
				if info.filename == "savegame" .. i .. ".zip" and not info.isDirectory then
					Logging.warning("Savegame %d is loaded from a ZIP file, but saving happens in a directory.", i)

					break
				end
			end
		end

		savegame:loadDefaults()

		local metadata, conflictedMetadata, displayName, isSoftConflict = saveGetInfoById(i)
		local xmlFile = nil

		if metadata ~= "" then
			savegame.hasConflict = conflictedMetadata ~= ""
			savegame.isSoftConflict = isSoftConflict
			savegame.conflictedMetadata = conflictedMetadata
			savegame.uploadState = saveGetUploadState(i)

			if savegame.hasConflict and savegame.isSoftConflict then
				metadata = conflictedMetadata
			end

			if metadata == SavegameController.INFO_INVALID_USER then
				savegame.isInvalidUser = true
			elseif metadata == SavegameController.INFO_CORRUPT_FILE then
				savegame.isCorruptFile = true
			else
				xmlFile = loadXMLFileFromMemory("careerSavegameXML", metadata)
			end
		end

		if xmlFile ~= nil then
			if not savegame:loadFromXML(xmlFile) then
				savegame:loadDefaults()
			end

			delete(xmlFile)
		end

		table.insert(self.savegames, savegame)
	end

	g_messageCenter:publish(MessageType.SAVEGAMES_LOADED)
end

function SavegameController:resetStorageDeviceSelection()
	saveResetStorageDeviceSelection()
end

function SavegameController:updateSavegames(callback, callbackTarget)
	if not self.waitingForSaveGameInfo then
		self.waitingForSaveGameInfo = true
		self.onUpdateCompleteCallback = callback or NO_TARGET.NO_CALLBACK
		self.onUpdateCompleteTarget = callbackTarget or NO_TARGET

		saveUpdateList("onSaveGameUpdateComplete", self)
	end
end

function SavegameController:cancelSavegameUpdate()
	saveCancelUpdateList()
end

function SavegameController:onSaveGameUpdateComplete(errorCode)
	self.waitingForSaveGameInfo = false

	self.onUpdateCompleteCallback(self.onUpdateCompleteTarget, errorCode)
end

function SavegameController:onSaveGameUpdateCompleteCloudError(errorCode)
	self.waitingForSaveGameInfo = false

	self:loadSavegames()
	self:tryToResolveConflict(self.cloudErrorConflictedSavegame)

	self.cloudErrorConflictedSavegame = nil
end

function SavegameController:onCloudError(errorCode, savegameId)
	savegameId = tonumber(savegameId)

	if errorCode == Savegame.ERROR_CLOUD_CONFLICT then
		self:updateSavegames(self.onSaveGameUpdateCompleteCloudError, self)

		self.cloudErrorConflictedSavegame = savegameId
	end
end

function SavegameController:tryToResolveConflict(savegameId, startCallback, savegameScreenCallback, showKeepBoth)
	local savegame = self:getSavegame(savegameId)

	if savegame ~= SavegameController.NO_SAVEGAME and savegame.hasConflict then
		if savegame.isSoftConflict then
			self:resolveConflict(savegameId, SaveGameResolvePolicy.KEEP_REMOTE)

			savegame.hasConflict = false
		else
			self.conflictDialog = g_gui:showDialog("SavegameConflictDialog")

			self.conflictDialog.target:setSavegame(true, savegame)
			self.conflictDialog.target:setCloudSavegame(savegame.conflictedMetadata)
			self.conflictDialog.target:setSavegameId(savegameId)
			self.conflictDialog.target:setFinishedCallback(startCallback, savegameScreenCallback)
			self.conflictDialog.target:setShowKeepBoth(showKeepBoth == nil and true or showKeepBoth)
		end
	end
end

function SavegameController:resolveConflict(savegameId, resolvePolicy)
	if resolvePolicy == SaveGameResolvePolicy.KEEP_BOTH and self:getNumValidSavegames() == SavegameController.NUM_SAVEGAMES then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_savegameConflictResolveKeepBothFailed"),
			callback = self.savegameConflictResolveKeepBothFailed,
			target = self,
			args = {
				savegameId = savegameId
			}
		})

		return false
	end

	if g_currentMission ~= nil then
		if resolvePolicy == SaveGameResolvePolicy.KEEP_BOTH then
			self:executeResolveConflict(savegameId, resolvePolicy)
			self:returnToSavegameSelection()

			return true
		end

		if resolvePolicy == SaveGameResolvePolicy.KEEP_REMOTE then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_savegameConflictKeepRemoteYesNo"),
				callback = self.onYesNoConflictKeepRemote,
				target = self,
				args = {
					savegameId = savegameId
				},
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})

			return true
		end
	end

	self:executeResolveConflict(savegameId, resolvePolicy)

	return true
end

function SavegameController:onYesNoConflictKeepRemote(yes, args)
	if yes then
		self:executeResolveConflict(args.savegameId, SaveGameResolvePolicy.KEEP_REMOTE)
		self:returnToSavegameSelection()
	else
		self:tryToResolveConflict(args.savegameId)
	end
end

function SavegameController:savegameConflictResolveKeepBothFailed(args)
	self:tryToResolveConflict(args.savegameId, nil, , false)
end

function SavegameController:executeResolveConflict(savegameId, resolvePolicy)
	self.currentSavegameToResolve = savegameId

	saveResolveConflict(savegameId, resolvePolicy, "onResolveConflictComplete", self)
end

function SavegameController:onResolveConflictComplete(errorCode, newSavegameId)
	local resolvedSavegameId = self.currentSavegameToResolve
	self.currentSavegameToResolve = nil

	if errorCode == Savegame.ERROR_RESOLVE_FAILED then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_savegameConflictResolveFailed"),
			callback = self.returnToSavegameSelection,
			target = self
		})

		return
	end

	if resolvedSavegameId ~= nil then
		local savegame = self:getSavegame(resolvedSavegameId)

		if savegame ~= SavegameController.NO_SAVEGAME then
			savegame.hasConflict = false
		end
	end
end

function SavegameController:returnToSavegameSelection()
	OnInGameMenuMenu()

	if g_gui.currentGuiName == "MainScreen" then
		g_mainScreen:onCareerClick(g_mainScreen.careerButton)
	end
end

function SavegameController:locateBackups(backupBasePath, backupDirBase)
	local foundBackups = {}
	local files = Files.new(backupBasePath)

	for _, v in pairs(files.files) do
		if v.isDirectory and v.filename:startsWith(backupDirBase) then
			local timeStr = v.filename:sub(backupDirBase:len() + 1)
			local year, month, day, hour, minute = timeStr:match("^(%d%d%d%d)-(%d%d)-(%d%d)_(%d%d)-(%d%d)$")
			minute = tonumber(minute)
			hour = tonumber(hour)
			day = tonumber(day)
			month = tonumber(month)
			year = tonumber(year)

			if year ~= nil and month ~= nil and day ~= nil and hour ~= nil and minute ~= nil then
				table.insert(foundBackups, {
					toDelete = true,
					filename = v.filename,
					time = {
						year,
						month,
						day,
						hour,
						minute
					}
				})
			end
		end
	end

	return foundBackups
end

function SavegameController:assignBackupDeleteFlags(dateNow, backups)
	table.sort(backups, SavegameController.backupSortFunction)

	for i = 1, math.min(4, #backups) do
		backups[i].toDelete = false
	end

	local year, month, day, hour, _ = dateNow:match("(%d%d%d%d)-(%d%d)-(%d%d)_(%d%d)-(%d%d)")
	hour = tonumber(hour)
	day = tonumber(day)
	month = tonumber(month)
	year = tonumber(year)

	for _, offset in pairs(self.BACKUP_DATE_OFFSETS) do
		local dateWithOffset = getDateAt("%Y-%m-%d_%H-%M", year, month, day, hour, 0, 0, -offset[1] * 60 * 60, offset[2] * 60 * 60)
		local year1, month1, day1, hour1, minute1 = dateWithOffset:match("(%d%d%d%d)-(%d%d)-(%d%d)_(%d%d)-(%d%d)")
		minute1 = tonumber(minute1)
		hour1 = tonumber(hour1)
		day1 = tonumber(day1)
		month1 = tonumber(month1)
		year1 = tonumber(year1)
		local minTimeDiff = 0
		local minTimeDiffBackup = nil

		for _, backup in pairs(backups) do
			local timeDiff = getDateDiffSeconds(backup.time[1], backup.time[2], backup.time[3], backup.time[4], backup.time[5], 0, year1, month1, day1, hour1, minute1, 0)
			timeDiff = math.abs(timeDiff)

			if minTimeDiffBackup == nil or timeDiff < minTimeDiff then
				minTimeDiffBackup = backup
				minTimeDiff = timeDiff
			end
		end

		if minTimeDiffBackup ~= nil then
			minTimeDiffBackup.toDelete = false
		end
	end
end

function SavegameController:createBackup(savegame, backupBasePath, backupDirFull, backupDir)
	createFolder(backupBasePath)
	createFolder(backupDirFull)

	local files = Files.new(savegame.savegameDirectory)

	for _, file in pairs(files.files) do
		if not file.isDirectory then
			copyFile(savegame.savegameDirectory .. "/" .. file.filename, backupDirFull .. "/" .. file.filename, true)
		end
	end

	local latestFile = io.open(backupBasePath .. "/" .. savegame:getSavegameAutoBackupLatestFilename(savegame.savegameIndex), "w")

	if latestFile ~= nil then
		latestFile:write("Latest auto backup directory: " .. backupDir)
		latestFile:close()
	end
end

function SavegameController:backupSavegame(savegame)
	if savegame.isValid then
		local dateNow = getDate("%Y-%m-%d_%H-%M")
		local backupBasePath = savegame:getSavegameAutoBackupBasePath()
		local backupDirBase = savegame:getSavegameAutoBackupDirectoryBase(savegame.savegameIndex)
		local backupDir = backupDirBase .. dateNow
		local backupDirFull = backupBasePath .. "/" .. backupDir
		local foundBackups = self:locateBackups(backupBasePath, backupDirBase)

		if #foundBackups > 0 then
			self:assignBackupDeleteFlags(dateNow, foundBackups)

			for _, backup in pairs(foundBackups) do
				if backup.toDelete then
					deleteFolder(backupBasePath .. "/" .. backup.filename)
				end
			end
		end

		self:createBackup(savegame, backupBasePath, backupDirFull, backupDir)
	end
end

function SavegameController:addSaveTask(taskType, taskParam)
	local taskData = {
		type = taskType,
		param = taskParam
	}

	table.insert(self.saveTasks, taskData)
end

function SavegameController:executeSaveTask()
	if self.currentSaveTask > #self.saveTasks then
		self:onSaveTaskComplete(true)

		return
	end

	local taskData = self.saveTasks[self.currentSaveTask]
	self.currentSaveTask = self.currentSaveTask + 1

	if taskData.type == SavegameController.SAVE_TASK_DENSITY_MAP then
		savePreparedDensityMapToFile(taskData.param, "onSaveTaskComplete", self)
	elseif taskData.type == SavegameController.SAVE_TASK_TERRAIN_LOD_TYPE_MAP then
		savePreparedTerrainLodTypeMap(taskData.param, "onSaveTaskComplete", self)
	elseif taskData.type == SavegameController.SAVE_TASK_TERRAIN_HEIGHT_MAP then
		savePreparedTerrainHeightMap(taskData.param, "onSaveTaskComplete", self)
	elseif taskData.type == SavegameController.SAVE_TASK_COLLISION_MAP then
		g_densityMapHeightManager:savePreparedCollisionMap("onSaveTaskComplete", self)
	elseif taskData.type == SavegameController.SAVE_TASK_PLACEMENT_BLOCKING_MAP then
		g_densityMapHeightManager:savePreparedPlacementCollisionMap("onSaveTaskComplete", self)
	elseif taskData.type == SavegameController.SAVE_TASK_SPLIT_SHAPES then
		savePreparedSplitShapesToFile("onSaveTaskComplete", self)
	elseif taskData.type == SavegameController.SAVE_TASK_BITVECTOR_MAP then
		savePreparedBitVectorMapToFile(taskData.param, "onSaveTaskComplete", self)
	elseif taskData.type == SavegameController.SAVE_TASK_NAVIGATION_MAP then
		savePreparedVehicleNavigationCostMapToFile(taskData.param, "onSaveTaskComplete", self)
	end
end

function SavegameController:onSaveTaskComplete(success)
	if self.currentSaveTask > #self.saveTasks then
		saveWriteSavegameFinish(self.savegameMetadata, self.savegameDisplayDesc, "onSaveComplete", self)
	else
		self:executeSaveTask()
	end
end

function SavegameController:onSaveStartComplete(errorCode, savegameDirectory)
	self.savingErrorCode = errorCode

	if errorCode == Savegame.ERROR_OK and savegameDirectory ~= nil then
		local startedRepeat = false

		if self.isSavingBlocking then
			startedRepeat = startFrameRepeatMode()
		end

		self.saveTasks = {}
		self.currentSaveTask = 1
		local savegame = self.currentSavegame

		savegame:setSavegameDirectory(savegameDirectory)
		savegame:saveToXMLFile()

		local playTimeHoursF = savegame.playTime / 60 + 0.0001
		local playTimeHours = math.floor(playTimeHoursF)
		local playTimeMinutes = math.floor((playTimeHoursF - playTimeHours) * 60)
		self.savegameDisplayDesc = savegame.map.title .. "\n" .. g_i18n:formatMoney(0) .. "\n" .. string.format("%02d:%02d", playTimeHours, playTimeMinutes)
		local dir = savegame.savegameDirectory
		local savedDensityMaps = {}

		for _, fruitTypeDesc in pairs(g_fruitTypeManager:getFruitTypes()) do
			local id = fruitTypeDesc.terrainDataPlaneId
			local preparingId = fruitTypeDesc.terrainDataPlaneIdPreparing

			if id ~= nil then
				local filename = getDensityMapFilename(id)

				if savedDensityMaps[filename] == nil then
					savedDensityMaps[filename] = true

					if self.isSavingBlocking then
						saveDensityMapToFile(id, dir .. "/" .. filename)
					else
						g_asyncTaskManager:addTask(function ()
							prepareSaveDensityMapToFile(id, dir .. "/" .. filename)
							self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, id)
						end)
					end
				end
			end

			if preparingId ~= nil then
				local filename = getDensityMapFilename(preparingId)

				if savedDensityMaps[filename] == nil then
					savedDensityMaps[filename] = true

					if self.isSavingBlocking then
						saveDensityMapToFile(preparingId, dir .. "/" .. filename)
					else
						g_asyncTaskManager:addTask(function ()
							prepareSaveDensityMapToFile(preparingId, dir .. "/" .. filename)
							self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, preparingId)
						end)
					end
				end
			end
		end

		local weedMapId = g_currentMission.weedSystem:getDensityMapData()

		if weedMapId ~= nil then
			local filename = getDensityMapFilename(weedMapId)
			local path = dir .. "/" .. filename

			if savedDensityMaps[filename] == nil then
				savedDensityMaps[filename] = true

				if self.isSavingBlocking then
					saveDensityMapToFile(weedMapId, path)
				else
					g_asyncTaskManager:addTask(function ()
						prepareSaveDensityMapToFile(weedMapId, path)
						self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, weedMapId)
					end)
				end
			end
		end

		local infoLayer = g_currentMission.weedSystem:getInfoLayer()

		if infoLayer ~= nil then
			local filename = infoLayer.filename
			local path = dir .. "/" .. filename

			if savedDensityMaps[filename] == nil then
				savedDensityMaps[filename] = true

				if self.isSavingBlocking then
					saveBitVectorMapToFile(infoLayer.map, path)
				else
					g_asyncTaskManager:addTask(function ()
						prepareSaveBitVectorMapToFile(infoLayer.map, path)
						self:addSaveTask(SavegameController.SAVE_TASK_BITVECTOR_MAP, infoLayer.map)
					end)
				end
			end
		end

		local navigationCostMap = g_currentMission.aiSystem:getNavigationMap()

		if navigationCostMap ~= nil then
			local filename = g_currentMission.aiSystem:getNavigationMapFilename()
			local path = dir .. "/" .. filename

			if savedDensityMaps[filename] == nil then
				savedDensityMaps[filename] = true

				if self.isSavingBlocking then
					saveVehicleNavigationCostMapToFile(navigationCostMap, path)
				else
					g_asyncTaskManager:addTask(function ()
						prepareSaveVehicleNavigationCostMapToFile(navigationCostMap, path)
						self:addSaveTask(SavegameController.SAVE_TASK_NAVIGATION_MAP, navigationCostMap)
					end)
				end
			end
		end

		local stoneMapId = g_currentMission.stoneSystem:getDensityMapData()

		if stoneMapId ~= nil then
			local filename = getDensityMapFilename(stoneMapId)

			if savedDensityMaps[filename] == nil then
				savedDensityMaps[filename] = true

				if self.isSavingBlocking then
					saveDensityMapToFile(stoneMapId, dir .. "/" .. filename)
				else
					g_asyncTaskManager:addTask(function ()
						prepareSaveDensityMapToFile(stoneMapId, dir .. "/" .. filename)
						self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, stoneMapId)
					end)
				end
			end
		end

		local densityMaps = g_currentMission.fieldGroundSystem:getDensityMaps()

		for _, densityMap in ipairs(densityMaps) do
			local filename = densityMap.filename
			local path = dir .. "/" .. filename

			if savedDensityMaps[filename] == nil then
				savedDensityMaps[filename] = true

				if self.isSavingBlocking then
					if densityMap.isBitVector then
						saveBitVectorMapToFile(densityMap.map, path)
					else
						saveDensityMapToFile(densityMap.map, path)
					end
				else
					g_asyncTaskManager:addTask(function ()
						if densityMap.isBitVector then
							prepareSaveBitVectorMapToFile(densityMap.map, path)
							self:addSaveTask(SavegameController.SAVE_TASK_BITVECTOR_MAP, densityMap.map)
						else
							prepareSaveDensityMapToFile(densityMap.map, path)
							self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, densityMap.map)
						end
					end)
				end
			end
		end

		for i = 1, table.getn(g_currentMission.dynamicFoliageLayers) do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local filename = getDensityMapFilename(id)

			if savedDensityMaps[filename] == nil then
				savedDensityMaps[filename] = true

				if self.isSavingBlocking then
					saveDensityMapToFile(id, dir .. "/" .. filename)
				else
					g_asyncTaskManager:addTask(function ()
						prepareSaveDensityMapToFile(id, dir .. "/" .. filename)
						self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, id)
					end)
				end
			end
		end

		local terrainDetailHeightMapFilename = getDensityMapFilename(g_currentMission.terrainDetailHeightId)

		if terrainDetailHeightMapFilename ~= nil and savedDensityMaps[terrainDetailHeightMapFilename] == nil then
			savedDensityMaps[terrainDetailHeightMapFilename] = true

			if self.isSavingBlocking then
				saveDensityMapToFile(g_currentMission.terrainDetailHeightId, dir .. "/" .. terrainDetailHeightMapFilename)
			else
				g_asyncTaskManager:addTask(function ()
					prepareSaveDensityMapToFile(g_currentMission.terrainDetailHeightId, dir .. "/" .. terrainDetailHeightMapFilename)
					self:addSaveTask(SavegameController.SAVE_TASK_DENSITY_MAP, g_currentMission.terrainDetailHeightId)
				end)
			end
		end

		if self.isSavingBlocking then
			g_currentMission.growthSystem:saveState(dir)
			g_currentMission.snowSystem:saveState(dir)
		else
			g_asyncTaskManager:addTask(function ()
				g_currentMission.growthSystem:saveState(dir)
			end)
			g_asyncTaskManager:addTask(function ()
				g_currentMission.snowSystem:saveState(dir)
			end)
		end

		if not GS_IS_MOBILE_VERSION then
			if self.isSavingBlocking then
				g_densityMapHeightManager:saveCollisionMap(dir)
			else
				g_asyncTaskManager:addTask(function ()
					g_densityMapHeightManager:prepareSaveCollisionMap(dir)
					self:addSaveTask(SavegameController.SAVE_TASK_COLLISION_MAP, 0)
				end)
			end

			if self.isSavingBlocking then
				g_densityMapHeightManager:savePlacementCollisionMap(dir)
			else
				g_asyncTaskManager:addTask(function ()
					g_densityMapHeightManager:prepareSavePlacementCollisionMap(dir)
					self:addSaveTask(SavegameController.SAVE_TASK_PLACEMENT_BLOCKING_MAP, 0)
				end)
			end

			if self.isSavingBlocking then
				saveSplitShapesToFile(dir .. "/splitShapes.gmss")
			else
				g_asyncTaskManager:addTask(function ()
					prepareSaveSplitShapesToFile(dir .. "/splitShapes.gmss")
					self:addSaveTask(SavegameController.SAVE_TASK_SPLIT_SHAPES, 0)
				end)
			end

			if self.isSavingBlocking then
				saveTerrainLodTypeMap(g_currentMission.terrainRootNode, dir .. "/" .. getTerrainLodTypeMapFilename(g_currentMission.terrainRootNode))
			else
				g_asyncTaskManager:addTask(function ()
					prepareSaveTerrainLodTypeMap(g_currentMission.terrainRootNode, dir .. "/" .. getTerrainLodTypeMapFilename(g_currentMission.terrainRootNode))
					self:addSaveTask(SavegameController.SAVE_TASK_TERRAIN_LOD_TYPE_MAP, g_currentMission.terrainRootNode)
				end)
			end

			if self.isSavingBlocking then
				saveTerrainLodNormalMap(g_currentMission.terrainRootNode, dir .. "/" .. getTerrainLodNormalMapFilename(g_currentMission.terrainRootNode))
			else
				g_asyncTaskManager:addTask(function ()
					saveTerrainLodNormalMap(g_currentMission.terrainRootNode, dir .. "/" .. getTerrainLodNormalMapFilename(g_currentMission.terrainRootNode))
				end)
			end

			if self.isSavingBlocking then
				saveTerrainHeightMap(g_currentMission.terrainRootNode, dir .. "/" .. getTerrainHeightMapFilename(g_currentMission.terrainRootNode))
			else
				g_asyncTaskManager:addTask(function ()
					prepareSaveTerrainHeightMap(g_currentMission.terrainRootNode, dir .. "/" .. getTerrainHeightMapFilename(g_currentMission.terrainRootNode))
					self:addSaveTask(SavegameController.SAVE_TASK_TERRAIN_HEIGHT_MAP, g_currentMission.terrainRootNode)
				end)
			end

			if self.isSavingBlocking then
				saveTerrainOccludersCache(g_currentMission.terrainRootNode, dir .. "/" .. getTerrainOccludersCacheFilename(g_currentMission.terrainRootNode))
			else
				g_asyncTaskManager:addTask(function ()
					saveTerrainOccludersCache(g_currentMission.terrainRootNode, dir .. "/" .. getTerrainOccludersCacheFilename(g_currentMission.terrainRootNode))
				end)
			end
		end

		if self.isSavingBlocking then
			self.savegameMetadata = saveXMLFileToMemory(savegame.xmlFile)
		else
			g_asyncTaskManager:addTask(function ()
				self.savegameMetadata = saveXMLFileToMemory(savegame.xmlFile)
			end)
		end

		if self.isSavingBlocking and #self.saveTasks > 0 then
			print("Warning: Blocking saving has async tasks")
		end

		if self.isSavingBlocking then
			self:executeSaveTask()
		else
			g_asyncTaskManager:addTask(function ()
				self:executeSaveTask()
			end)
		end

		if startedRepeat then
			endFrameRepeatMode()
		end

		return
	end

	self:onSaveComplete(errorCode)
end

function SavegameController:onSaveComplete(errorCode)
	self.savingErrorCode = errorCode
	self.isSavingGame = false

	if errorCode == Savegame.ERROR_OK then
		print("Game saved successfully.")
	else
		print("Game save failed. Error: " .. tostring(errorCode))
	end

	leaveCpuBoostMode()
	g_asyncTaskManager:setAllowedTimePerFrame(nil)
	self.onSaveCompleteCallback(self.onSaveCompleteCallbackTarget, errorCode)
end

function SavegameController:onSavegameDeleted(errorCode)
	self.onDeleteCallback(self.onDeleteCallbackTarget, errorCode)
end

function SavegameController:deleteSavegame(index, callback, callbackTarget)
	self.onDeleteCallback = callback or NO_TARGET.NO_CALLBACK
	self.onDeleteCallbackTarget = callbackTarget or NO_TARGET
	local savegame = self.savegames[index]

	saveDeleteSavegame(savegame.savegameIndex, "onSavegameDeleted", self)
end

function SavegameController:saveSavegame(savegame, blocking)
	if self.isSavingGame then
		print("Warning: Saving while already saving")
		self.onSaveCompleteCallback(self.onSaveCompleteCallbackTarget, Savegame.ERROR_OPERATION_IN_PROGRESS)

		return
	end

	self.isSavingGame = true
	self.hasSavingError = false
	self.isSavingBlocking = blocking

	enterCpuBoostMode()
	g_asyncTaskManager:setAllowedTimePerFrame(33.333333333333336)

	if savegame.isValid and not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
		self:backupSavegame(savegame)
	end

	savegame.isValid = true
	savegame.densityMapRevision = g_densityMapRevision
	savegame.terrainTextureRevision = g_terrainTextureRevision
	savegame.terrainLodTextureRevision = g_terrainLodTextureRevision
	savegame.splitShapesRevision = g_splitShapesRevision
	savegame.tipCollisionRevision = g_tipCollisionRevision
	savegame.placementCollisionRevision = g_placementCollisionRevision
	savegame.navigationCollisionRevision = g_navigationCollisionRevision
	savegame.resetVehicles = false

	savegame:loadFromMission(g_currentMission)

	self.currentSavegame = savegame

	saveWriteSavegameStart(savegame.savegameIndex, savegame.displayName, FSCareerMissionInfo.MaxSavegameSize, "onSaveStartComplete", self)
end

function SavegameController:getCanStartGame(index, allowConflicted)
	local savegame = self:getSavegame(index)

	if not allowConflicted and savegame ~= SavegameController.NO_SAVEGAME and savegame.hasConflict then
		return false
	end

	if savegame ~= SavegameController.NO_SAVEGAME and savegame.isValid and savegame.map == nil then
		return false
	end

	return index > 0
end

function SavegameController:getIsSavegameConflicted(index)
	local savegame = self:getSavegame(index)

	if savegame ~= SavegameController.NO_SAVEGAME and savegame.hasConflict then
		return true
	end

	return false
end

function SavegameController:getCanDeleteGame(index)
	if not g_isPresentationVersion and index > 0 and self.savegames[index] ~= nil then
		local isValidSavegame = self.savegames[index].isValid
		local isInvalidUser = self.savegames[index].isInvalidUser
		local isCorruptSavegame = self.savegames[index].isCorruptFile

		return isValidSavegame or isInvalidUser or isCorruptSavegame
	else
		return false
	end
end

function SavegameController:getSavegame(index)
	return self.savegames[index] or SavegameController.NO_SAVEGAME
end

function SavegameController:getNumValidSavegames()
	local num = 0

	for i = 1, SavegameController.NUM_SAVEGAMES do
		local savegame = self:getSavegame(i)

		if savegame ~= SavegameController.NO_SAVEGAME and savegame.isValid then
			num = num + 1
		end
	end

	return num
end

function SavegameController:getIsSaving()
	return self.isSavingGame
end

function SavegameController:getSavingErrorCode()
	return self.savingErrorCode
end

function SavegameController:getIsWaitingForSavegameInfo()
	return self.waitingForSaveGameInfo
end

function SavegameController:getNumberOfSavegames()
	return saveGetNumOfSaveGames()
end

function SavegameController:getMaxNumberOfSavegames()
	return SavegameController.NUM_SAVEGAMES
end

function SavegameController:isStorageDeviceUnavailable()
	return saveGetNumOfSaveGames() < 0
end

function SavegameController.backupSortFunction(a, b)
	if a.time[1] ~= b.time[1] then
		return b.time[1] < a.time[1]
	end

	if a.time[2] ~= b.time[2] then
		return b.time[2] < a.time[2]
	end

	if a.time[3] ~= b.time[3] then
		return b.time[3] < a.time[3]
	end

	if a.time[4] ~= b.time[4] then
		return b.time[4] < a.time[4]
	end

	return b.time[5] < a.time[5]
end

SavegameController.BACKUP_DATE_OFFSETS = {
	{
		1,
		1
	},
	{
		2,
		1
	},
	{
		3,
		1
	},
	{
		4,
		1
	},
	{
		5,
		1
	},
	{
		6,
		6
	},
	{
		12,
		12
	},
	{
		24,
		24
	},
	{
		48,
		48
	},
	{
		96,
		96
	},
	{
		192,
		192
	}
}
