PlayerStateCrouch = {}
local PlayerStateCrouch_mt = Class(PlayerStateCrouch, PlayerStateBase)
PlayerStateCrouch.PROGRESS_STATES = {
	CROUCHING = 1,
	CROUCH = 2,
	UP = 4,
	STANDING = 3
}

function PlayerStateCrouch.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateCrouch_mt)
	self.crouchTime = 0.25
	self.crouchFactor = 0
	self.crouchYOffset = 0.8
	self.cameraY = 0
	self.crouchCameraY = 0
	self.progress = PlayerStateCrouch.PROGRESS_STATES.UP
	self.toggleMode = false

	return self
end

function PlayerStateBase:load()
	self.cameraY = self.player.camY
end

function PlayerStateCrouch:isAvailable()
	if self.player.baseInformation.isInWater then
		return false
	end

	if self.player:hasHandtoolEquipped() and self.player.baseInformation.currentHandtool:isBeingUsed() then
		return false
	end

	return true
end

function PlayerStateCrouch:deactivate()
	PlayerStateCrouch:superClass().deactivate(self)
	setTranslation(self.player.cameraNode, 0, self.cameraY, 0)
end

function PlayerStateCrouch:update(dt)
	self:processInput()
	self:moveCamera(dt)

	if self.crouchFactor == 1 then
		self.progress = PlayerStateCrouch.PROGRESS_STATES.CROUCH
	elseif self.crouchFactor == 0 then
		self.progress = PlayerStateCrouch.PROGRESS_STATES.UP
	end
end

function PlayerStateCrouch:processInput()
	if self.player.baseInformation.currentHandtool == nil or self.player:hasHandtoolEquipped() and not self.player.baseInformation.currentHandtool:isBeingUsed() then
		local crouchState = self.progress
		local inputState = self.player.inputInformation.crouchState
		local isCrouching = crouchState == PlayerStateCrouch.PROGRESS_STATES.CROUCHING or crouchState == PlayerStateCrouch.PROGRESS_STATES.CROUCH
		local isStanding = crouchState == PlayerStateCrouch.PROGRESS_STATES.STANDING or crouchState == PlayerStateCrouch.PROGRESS_STATES.UP

		if self.toggleMode then
			if inputState == Player.BUTTONSTATES.PRESSED then
				if isCrouching then
					self.progress = PlayerStateCrouch.PROGRESS_STATES.STANDING
				elseif isStanding then
					self.progress = PlayerStateCrouch.PROGRESS_STATES.CROUCHING
				end
			end
		elseif inputState == Player.BUTTONSTATES.PRESSED and isStanding then
			self.progress = PlayerStateCrouch.PROGRESS_STATES.CROUCHING
		elseif inputState == Player.BUTTONSTATES.RELEASED and isCrouching then
			self.progress = PlayerStateCrouch.PROGRESS_STATES.STANDING
		end
	end
end

function PlayerStateCrouch:moveCamera(dt)
	if self.progress == PlayerStateCrouch.PROGRESS_STATES.CROUCHING then
		local dtInSec = dt * 0.001
		self.crouchFactor = math.min(1, self.crouchFactor + dtInSec / self.crouchTime)
	elseif self.progress == PlayerStateCrouch.PROGRESS_STATES.CROUCH then
		-- Nothing
	elseif self.progress == PlayerStateCrouch.PROGRESS_STATES.STANDING then
		local dtInSec = dt * 0.001
		self.crouchFactor = math.max(0, self.crouchFactor - dtInSec / self.crouchTime)
	elseif self.progress == PlayerStateCrouch.PROGRESS_STATES.UP then
		self:deactivate()
	end

	self.crouchCameraY = self.cameraY - self.crouchYOffset * self.crouchFactor
end
