InGameMenuContractsFrame = {}
local InGameMenuContractsFrame_mt = Class(InGameMenuContractsFrame, TabbedMenuFrameElement)
InGameMenuContractsFrame.CONTROLS = {
	REWARD_TEXT = "rewardText",
	TITLE_TEXT = "titleText",
	CONTRACT_BOX = "contractBox",
	CONTRACT_TEXT = "contractDescriptionText",
	DETAILS_BOX = "detailsBox",
	FARMER_BOX = "farmerBox",
	FIELD_BIG_TEXT = "fieldBigText",
	VEHICLE_TEMPLATE = "vehicleTemplate",
	NPC_FIELD_BOX = "npcFieldBox",
	EXTRA_PROGRESS_TEXT = "extraProgressText",
	VEHICLES_BOX = "vehiclesBox",
	PROGRESS_BAR = "progressBar",
	TALLY_BOX = "tallyBox",
	CONTRACTS_LIST = "contractsList",
	PROGRESS_TEXT = "progressText",
	PROGRESS_BAR_BG = "progressBarBg",
	FARMER_NAME = "farmerName",
	CONTRACTS_LIST_ITEM_TEMPLATE = "contractsListItemTemplate",
	PROGRESS_TITLE_TEXT = "progressTitleText",
	USE_OWN_EQUIPMENT = "useOwnEquipementText",
	ACTION_TEXT = "actionText",
	CONTRACTS_CONTAINER = "contractsContainer",
	FARMER_TEXT = "farmerText",
	FARMER_IMAGE = "farmerImage",
	CONTRACTS_LIST_BOX = "contractsListBox",
	NO_CONTRACTS_BOX = "noContractsBox"
}
InGameMenuContractsFrame.LIST_ITEM_CONTRACT_NAME = "contract"
InGameMenuContractsFrame.LIST_ITEM_FIELD_NAME = "field"
InGameMenuContractsFrame.LIST_ITEM_REWARD_NAME = "reward"
InGameMenuContractsFrame.LIST_ITEM_INDICATOR_ACTIVE_NAME = "indicatorActive"
InGameMenuContractsFrame.LIST_ITEM_INDICATOR_FINISHED_NAME = "indicatorFinished"
InGameMenuContractsFrame.LIST_ITEM_INDICATOR_FAILED_NAME = "indicatorFailed"
InGameMenuContractsFrame.BUTTON_STATE = {
	FINISHED = 2,
	POSSIBLE = 0,
	ACTIVE = 1
}

function InGameMenuContractsFrame.new(subclass_mt, messageCenter, i18n, missionManager)
	local self = InGameMenuContractsFrame:superClass().new(nil, subclass_mt or InGameMenuContractsFrame_mt)

	self:registerControls(InGameMenuContractsFrame.CONTROLS)

	self.messageCenter = messageCenter
	self.i18n = i18n
	self.missionManager = missionManager
	self.hasCustomMenuButtons = true
	self.vehicleElements = {}
	self.contracts = {}
	self.sectionContracts = {}
	self.updateTime = 0

	return self
end

function InGameMenuContractsFrame:copyAttributes(src)
	InGameMenuContractsFrame:superClass().copyAttributes(self, src)

	self.messageCenter = src.messageCenter
	self.i18n = src.i18n
	self.missionManager = src.missionManager
end

function InGameMenuContractsFrame:onGuiSetupFinished()
	InGameMenuContractsFrame:superClass().onGuiSetupFinished(self)
	self.contractsList:setDataSource(self)
	self.contractsList:setDelegate(self)
end

function InGameMenuContractsFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.acceptButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.i18n:getText("button_acceptContract"),
		callback = function ()
			self:onButtonAccept()
		end
	}
	self.leaseButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = self.i18n:getText("button_borrowItems"),
		callback = function ()
			self:onButtonLease()
		end
	}
	self.dismissButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.i18n:getText("button_fieldJob_complete"),
		callback = function ()
			self:onButtonDismiss()
		end
	}
	self.cancelButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = self.i18n:getText("button_cancel"),
		callback = function ()
			self:onButtonCancel()
		end
	}

	self.vehicleTemplate:unlinkElement()
end

function InGameMenuContractsFrame:delete()
	if self.vehicleTemplate ~= nil then
		self.vehicleTemplate:delete()
	end

	InGameMenuContractsFrame:superClass().delete(self)
	self.messageCenter:unsubscribeAll(self)
end

function InGameMenuContractsFrame:update(dt)
	InGameMenuContractsFrame:superClass().update(self, dt)

	if self.updateTime < g_currentMission.time then
		self.updateTime = g_currentMission.time + 5000
		local section, index = self.contractsList:getSelectedPath()

		self:updateDetailContents(section, index)
	end
end

function InGameMenuContractsFrame:onFrameOpen(element)
	InGameMenuContractsFrame:superClass().onFrameOpen(self)
	self.messageCenter:subscribe(MissionStartedEvent, self.updateList, self)
	self.messageCenter:subscribe(MissionDismissEvent, self.updateList, self)
	self.messageCenter:subscribe(MissionFinishedEvent, self.updateList, self)
	self.messageCenter:subscribe(MessageType.MISSION_GENERATED, self.updateList, self)
	self.messageCenter:subscribe(MessageType.MISSION_DELETED, self.updateList, self)
	self.messageCenter:subscribe(PlayerPermissionsEvent, self.updateButtonsForPermissions, self)
	self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.POSSIBLE)
	self:setSoundSuppressed(true)
	self:updateList()
	FocusManager:setFocus(self.contractsList)
	self:setSoundSuppressed(false)
end

function InGameMenuContractsFrame:onFrameClose(element)
	InGameMenuContractsFrame:superClass().onClose(self)

	self.contracts = {}

	self.messageCenter:unsubscribeAll(self)
end

function InGameMenuContractsFrame:updateButtonsForPermissions()
	local section, index = self.contractsList:getSelectedPath()

	self:updateDetailContents(section, index)
end

function InGameMenuContractsFrame:setButtonsForState(state, canLease)
	local info = {
		self.backButtonInfo
	}
	local hasPermission = g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_CONTRACTS)

	if state == InGameMenuContractsFrame.BUTTON_STATE.FINISHED then
		table.insert(info, self.dismissButtonInfo)

		self.dismissButtonInfo.disabled = not hasPermission
	elseif state == InGameMenuContractsFrame.BUTTON_STATE.ACTIVE then
		table.insert(info, self.cancelButtonInfo)

		self.cancelButtonInfo.disabled = not hasPermission
	elseif #self.contracts > 0 then
		table.insert(info, self.acceptButtonInfo)

		self.acceptButtonInfo.disabled = not hasPermission

		if canLease then
			table.insert(info, self.leaseButtonInfo)

			self.leaseButtonInfo.disabled = not hasPermission
		end
	end

	self.menuButtonInfo = info

	self:setMenuButtonInfoDirty()
end

function InGameMenuContractsFrame:onContractsChanged()
	self.contractsList:updateItemPositions()
end

function InGameMenuContractsFrame:updateList()
	local list = g_missionManager:getMissionsList(g_currentMission:getFarmId())
	local hasMissions = #list ~= 0

	self.contractsListBox:setVisible(hasMissions)
	self.detailsBox:setVisible(hasMissions)
	self.noContractsBox:setVisible(not hasMissions)

	local selectedContract = self:getSelectedContract()

	if selectedContract ~= nil then
		self.storedSelected = selectedContract.mission.generationTime
	else
		self.storedSelected = nil
	end

	self.contracts = {}

	for _, mission in ipairs(list) do
		local isActive = mission.status == AbstractMission.STATUS_RUNNING
		local isFinished = mission.status == AbstractMission.STATUS_FINISHED
		local isPossible = mission.status == AbstractMission.STATUS_STOPPED
		local missionInfo = mission:getData()
		local contract = {
			mission = mission,
			active = isActive,
			finished = isFinished,
			possible = isPossible,
			jobType = missionInfo.jobType
		}

		table.insert(self.contracts, contract)
	end

	self:sortList()
	self.contractsList:reloadData()
end

function InGameMenuContractsFrame:updateProgressBar(value)
	local fullWidth = self.progressBarBg.size[1] - self.progressBar.margin[1] * 2

	self.progressBar:setSize(fullWidth * math.min(value, 1), nil)
end

function InGameMenuContractsFrame:updateDetailContents(section, index)
	local contract = nil
	local sectionContracts = self.sectionContracts[section]

	if sectionContracts ~= nil then
		contract = sectionContracts.contracts[index]
	end

	for _, elem in pairs(self.vehicleElements) do
		elem:delete()
	end

	self.vehicleElements = {}

	if contract ~= nil then
		if contract.active or contract.possible then
			local mission = contract.mission

			self.contractBox:setVisible(true)
			self.tallyBox:setVisible(false)
			self:updateFarmersBox(mission.field, mission:getNPC())

			if contract.mission:isa(TransportMission) then
				self:updateTransportContractInfo(mission)
			else
				self:updateFieldContractInfo(mission)
			end

			self.useOwnEquipementText:setVisible(false)
			self.vehiclesBox:setVisible(contract.possible)
			self.progressText:setVisible(contract.active)
			self.progressTitleText:setVisible(contract.active)
			self.extraProgressText:setVisible(contract.active)
			self.progressBarBg:setVisible(contract.active)

			if contract.active then
				self.progressText:setText(string.format("%.0f%%", mission.completion * 100))
				self.extraProgressText:setText(mission:getExtraProgressText())
				self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.ACTIVE)
				self:updateProgressBar(mission.completion)
			else
				local hasLeasing = mission:hasLeasableVehicles()

				if hasLeasing then
					self.useOwnEquipementText:setVisible(true)

					local leaseCost = g_i18n:formatMoney(mission.vehicleUseCost, 0, true, true)
					local vehicleText = string.format(self.i18n:getText("fieldJob_desc_useOwnEquipment"), leaseCost)
					local missionInfo = mission:getData()

					if missionInfo.extraText ~= nil then
						vehicleText = vehicleText .. " " .. missionInfo.extraText
					end

					self.useOwnEquipementText:setText(vehicleText)

					local vehicles = mission.vehiclesToLoad

					for i, v in ipairs(vehicles) do
						local storeItem = g_storeManager:getItemByXMLFilename(v.filename)

						if storeItem == nil then
							Logging.error("Mission uses non-existing vehicle at '%s'", v.filename)

							break
						end

						local element = self.vehicleTemplate:clone(self.vehiclesBox)

						table.insert(self.vehicleElements, element)

						if i == 4 and #vehicles > 4 then
							local moreText = element:getDescendantByName("more")

							moreText:setText("+" .. tostring(#vehicles - 3))
							moreText:setVisible(true)
							element:setImageColor(nil, , , , 0)

							break
						else
							element:setImageFilename(storeItem.imageFilename)
							element:setImageColor(nil, , , , 1)
						end
					end

					self.vehiclesBox:invalidateLayout()
				end

				self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.POSSIBLE, hasLeasing)
			end
		elseif contract.finished then
			local mission = contract.mission

			self.farmerBox:setVisible(false)
			self.contractBox:setVisible(false)
			self.tallyBox:setVisible(true)

			local reward = 0
			local reimbursement = 0
			local leaseCost = 0
			local stealCost = 0

			if mission.success then
				reward = mission:getReward()

				if mission:hasLeasableVehicles() and mission.spawnedVehicles then
					leaseCost = -1 * mission.vehicleUseCost
					reimbursement = mission:calculateReimbursement()
				end
			end

			if mission.stealingCost ~= nil then
				stealCost = -1 * mission.stealingCost
			end

			local total = reward + leaseCost + reimbursement + stealCost

			self.tallyBox:getDescendantByName("reward"):setText(g_i18n:formatMoney(reward, 0, true, true))
			self.tallyBox:getDescendantByName("leaseCost"):setText(g_i18n:formatMoney(leaseCost, 0, true, true))
			self.tallyBox:getDescendantByName("reimburse"):setText(g_i18n:formatMoney(reimbursement, 0, true, true))
			self.tallyBox:getDescendantByName("stealing"):setText(g_i18n:formatMoney(stealCost, 0, true, true))
			self.tallyBox:getDescendantByName("total"):setText(g_i18n:formatMoney(total, 0, true, true))
			self:setButtonsForState(InGameMenuContractsFrame.BUTTON_STATE.FINISHED)
		end
	end
end

function InGameMenuContractsFrame:updateFieldContractInfo(mission)
	local missionInfo = mission:getData()

	self.titleText:setText(g_i18n:getText("fieldJob_contract") .. ": " .. missionInfo.jobType)
	self.actionText:setText(missionInfo.action)
	self.rewardText:setText(g_i18n:formatMoney(mission:getReward(), 0, true, true))
	self.fieldBigText:setText(string.format(self.i18n:getText("fieldJob_number"), mission.field.fieldId))
	self.contractDescriptionText:setText(missionInfo.description)
end

function InGameMenuContractsFrame:updateTransportContractInfo(mission)
	local missionInfo = mission:getData()

	self.titleText:setText(g_i18n:getText("fieldJob_contract") .. ": " .. missionInfo.jobType)
	self.actionText:setText(missionInfo.action)
	self.rewardText:setText(g_i18n:formatMoney(mission:getReward(), 0, true, true))
	self.fieldBigText:setText("")
	self.contractDescriptionText:setText(missionInfo.description)
end

function InGameMenuContractsFrame:updateFarmersBox(field, npc)
	self.farmerBox:setVisible(npc ~= nil)

	if npc ~= nil then
		self.farmerName:setText(npc.title)
		self.farmerImage:setImageFilename(npc.imageFilename)
		self.farmerText:setVisible(field ~= nil)

		if field ~= nil then
			self.farmerText:setText(string.format("%s %s (%s)", self.i18n:getText("ui_fieldOwnerOf"), string.format(self.i18n:getText("fieldJob_number"), field.fieldId), self.i18n:formatArea(field.fieldArea, 2)))
		end
	end
end

function InGameMenuContractsFrame:getSelectedContract()
	local section, index = self.contractsList:getSelectedPath()
	local sectionContracts = self.sectionContracts[section]

	if sectionContracts == nil then
		return nil
	end

	return sectionContracts.contracts[index]
end

function InGameMenuContractsFrame:startContract(leaseVehicles)
	local contract = self:getSelectedContract()
	local farmId = g_currentMission:getFarmId()

	if g_missionManager:hasFarmReachedMissionLimit(farmId) then
		g_gui:showInfoDialog({
			visible = true,
			text = g_i18n:getText("ui_farmAlreadyHasActiveMission"),
			dialogType = DialogElement.TYPE_INFO
		})

		return
	end

	if leaseVehicles and not contract.mission:isSpawnSpaceAvailable() then
		g_gui:showInfoDialog({
			visible = true,
			text = g_i18n:getText("warning_noFreeMissionSpace"),
			dialogType = DialogElement.TYPE_WARNING
		})
	else
		local result = g_missionManager:startMission(contract.mission, farmId, leaseVehicles)

		if result ~= false and leaseVehicles and g_currentMission.missionInfo.difficulty == 1 and not g_currentMission.missionDynamicInfo.isMultiplayer then
			g_gui:showInfoDialog({
				visible = true,
				text = g_i18n:getText("ui_missionVehiclesAtShop"),
				dialogType = DialogElement.TYPE_INFO
			})
		end
	end
end

function InGameMenuContractsFrame:sortList()
	local function sortFunc(a, b)
		if a.active == b.active then
			if a.finished == b.finished then
				if a.mission.type == b.mission.type then
					local fieldA = a.mission.field ~= nil and a.mission.field.fieldId or 0
					local fieldB = b.mission.field ~= nil and b.mission.field.fieldId or 0

					return fieldA < fieldB
				end

				return a.jobType < b.jobType
			end

			return (a.finished and 1 or 0) > (b.finished and 1 or 0)
		end

		return (a.active and 1 or 0) > (b.active and 1 or 0)
	end

	table.sort(self.contracts, sortFunc)

	self.sectionContracts = {
		{
			title = g_i18n:getText("fieldJob_active"),
			contracts = {}
		},
		{
			title = g_i18n:getText("fieldJob_finished"),
			contracts = {}
		}
	}
	local lastType = nil

	for _, contract in ipairs(self.contracts) do
		if contract.active then
			table.insert(self.sectionContracts[1].contracts, contract)
		elseif contract.finished then
			table.insert(self.sectionContracts[2].contracts, contract)
		else
			if lastType ~= contract.mission.type then
				table.insert(self.sectionContracts, {
					title = contract.jobType,
					contracts = {}
				})

				lastType = contract.mission.type
			end

			table.insert(self.sectionContracts[#self.sectionContracts].contracts, contract)
		end
	end

	if #self.sectionContracts[2].contracts == 0 then
		table.remove(self.sectionContracts, 2)
	end

	if #self.sectionContracts[1].contracts == 0 then
		table.remove(self.sectionContracts, 1)
	end
end

function InGameMenuContractsFrame:getNumberOfSections()
	return #self.sectionContracts
end

function InGameMenuContractsFrame:getNumberOfItemsInSection(list, section)
	return #self.sectionContracts[section].contracts
end

function InGameMenuContractsFrame:getTitleForSectionHeader(list, section)
	return self.sectionContracts[section].title
end

function InGameMenuContractsFrame:populateCellForItemInSection(list, section, index, cell)
	local contract = self.sectionContracts[section].contracts[index]
	local mission = contract.mission
	local missionInfo = mission:getData()

	cell:getAttribute("contract"):setText(missionInfo.jobType)
	cell:getAttribute("reward"):setText(g_i18n:formatMoney(mission:getReward(), 0, true, true))
	cell:getAttribute("field"):setText(missionInfo.location)
	cell:getAttribute("indicatorActive"):setVisible(contract.active)
	cell:getAttribute("indicatorFinished"):setVisible(contract.finished and contract.mission.success)
	cell:getAttribute("indicatorFailed"):setVisible(contract.finished and not contract.mission.success)
end

function InGameMenuContractsFrame:onButtonAccept()
	self:startContract(false)
end

function InGameMenuContractsFrame:onButtonLease()
	self:startContract(true)
end

function InGameMenuContractsFrame:onButtonDismiss()
	local contract = self:getSelectedContract()

	g_missionManager:dismissMission(contract.mission)
end

function InGameMenuContractsFrame:onButtonCancel()
	g_gui:showYesNoDialog({
		text = self.i18n:getText("fieldJob_endContract"),
		callback = self.onCancelDialog,
		target = self
	})
end

function InGameMenuContractsFrame:onCancelDialog(yes)
	if yes then
		local contract = self:getSelectedContract()

		g_missionManager:cancelMission(contract.mission)
	end
end

function InGameMenuContractsFrame:onListSelectionChanged(list, section, index)
	local sectionContracts = self.sectionContracts[section]

	if sectionContracts ~= nil and sectionContracts.contracts[index] ~= nil then
		self:updateDetailContents(section, index)
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
	end
end
