GameStateManager = {}
local GameStateManager_mt = Class(GameStateManager)

function GameStateManager.new(customMt)
	local self = {}

	setmetatable(self, customMt or GameStateManager_mt)

	self.gameStateChangeListeners = {}
	self.gameState = GameState.STARTING

	return self
end

function GameStateManager:getGameStateIndexByName(name)
	if name ~= nil then
		name = name:upper()

		return GameState[name]
	end

	return nil
end

function GameStateManager:setGameState(newState)
	if newState ~= nil and self.gameState ~= newState then
		g_messageCenter:publish(MessageType.GAME_STATE_CHANGED, newState, self.gameState)

		self.gameState = newState
	end
end

function GameStateManager:getGameState()
	return self.gameState
end

g_gameStateManager = GameStateManager.new()
