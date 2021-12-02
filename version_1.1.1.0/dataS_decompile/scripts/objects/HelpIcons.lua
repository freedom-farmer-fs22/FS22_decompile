HelpIcons = {}
local HelpIcons_mt = Class(HelpIcons)

function HelpIcons:onCreate(id)
	local helpIcons = HelpIcons.new(id)

	g_currentMission:addNonUpdateable(helpIcons)

	g_currentMission.helpIconsBase = helpIcons
end

function HelpIcons.new(name)
	local self = {}

	setmetatable(self, HelpIcons_mt)

	self.me = name
	local num = getNumOfChildren(self.me)
	self.helpIcons = {}

	for i = 0, num - 1 do
		local helpIconTriggerId = getChildAt(self.me, i)
		local helpIconId = getChildAt(helpIconTriggerId, 0)
		local helpIconCustomNumber = Utils.getNoNil(getUserAttribute(helpIconTriggerId, "customNumber"), 0)

		addTrigger(helpIconTriggerId, "triggerCallback", self)

		local helpIcon = {
			helpIconTriggerId = helpIconTriggerId,
			helpIconId = helpIconId,
			helpIconCustomNumber = helpIconCustomNumber
		}

		table.insert(self.helpIcons, helpIcon)
	end

	self.visible = true

	return self
end

function HelpIcons:delete()
	for _, helpIcon in pairs(self.helpIcons) do
		removeTrigger(helpIcon.helpIconTriggerId)
	end
end

function HelpIcons:update(dt)
end

function HelpIcons:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter and (g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode and g_currentMission.controlPlayer or g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.nodeToObject[otherId]) then
		local missionInfo = g_currentMission.missionInfo

		for i, helpIcon in ipairs(self.helpIcons) do
			if helpIcon.helpIconTriggerId == triggerId and getVisibility(helpIcon.helpIconId) then
				setVisibility(helpIcon.helpIconId, false)
				setCollisionMask(helpIcon.helpIconTriggerId, 0)

				missionInfo.foundHelpIcons = ""

				for _, helpIcon in ipairs(self.helpIcons) do
					if getVisibility(helpIcon.helpIconId) then
						missionInfo.foundHelpIcons = missionInfo.foundHelpIcons .. "0"
					else
						missionInfo.foundHelpIcons = missionInfo.foundHelpIcons .. "1"
					end
				end

				local messageNumber = helpIcon.helpIconCustomNumber

				if messageNumber == 0 then
					messageNumber = i
				end

				g_currentMission.inGameMessage:showMessage(g_i18n:getText("helpIcon_title" .. messageNumber), g_i18n:getText("helpIcon_text" .. messageNumber), 0)
			end
		end
	end
end

function HelpIcons:showHelpIcons(visible, clearIconStates)
	self.visible = visible
	local oldStates = g_currentMission.missionInfo.foundHelpIcons

	for i, helpIcon in ipairs(self.helpIcons) do
		local isVisible = visible

		if clearIconStates == nil or not clearIconStates then
			isVisible = isVisible and string.sub(oldStates, i, i) == "0"
		end

		setVisibility(helpIcon.helpIconId, isVisible)

		if isVisible then
			setCollisionMask(helpIcon.helpIconTriggerId, 3145728)
		else
			setCollisionMask(helpIcon.helpIconTriggerId, 0)
		end
	end
end

function HelpIcons:deleteHelpIcon(i)
	if self.helpIcons[i] ~= nil then
		setVisibility(self.helpIcons[i].helpIconId, false)
		setCollisionMask(self.helpIcons[i].helpIconTriggerId, 0)
	end
end
