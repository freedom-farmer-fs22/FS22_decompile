Wipers = {
	forcedState = -1,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Enterable, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("Wipers")
		schema:register(XMLValueType.STRING, "vehicle.wipers.wiper(?)#animName", "Animation name")
		schema:register(XMLValueType.FLOAT, "vehicle.wipers.wiper(?).state(?)#animSpeed", "Animation speed")
		schema:register(XMLValueType.FLOAT, "vehicle.wipers.wiper(?).state(?)#animPause", "Animation pause time (sec.)")
		schema:setXMLSpecializationType()
	end
}

function Wipers.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWiperFromXML", Wipers.loadWiperFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForWipers", Wipers.getIsActiveForWipers)
end

function Wipers.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wipers)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wipers)
end

function Wipers:onLoad(savegame)
	local spec = self.spec_wipers
	spec.wipers = {}
	local i = 0

	while true do
		local key = string.format("vehicle.wipers.wiper(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local wiper = {}

		if self:loadWiperFromXML(self.xmlFile, key, wiper) then
			table.insert(spec.wipers, wiper)
		end

		i = i + 1
	end

	spec.hasWipers = #spec.wipers > 0
	spec.lastRainScale = 0

	if not spec.hasWipers then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Wipers)
	end
end

function Wipers:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_wipers

	if self:getIsControlled() then
		spec.lastRainScale = g_currentMission.environment.weather:getRainFallScale()

		for _, wiper in pairs(spec.wipers) do
			local stateIdToUse = 0

			if self:getIsActiveForWipers() and spec.lastRainScale > 0 then
				for stateIndex, state in ipairs(wiper.states) do
					if spec.lastRainScale <= state.maxRainValue then
						stateIdToUse = stateIndex

						break
					end
				end
			end

			if Wipers.forcedState ~= -1 then
				stateIdToUse = MathUtil.clamp(Wipers.forcedState, 0, #wiper.states)
			end

			if stateIdToUse > 0 then
				local currentState = wiper.states[stateIdToUse]

				if self:getAnimationTime(wiper.animName) == 1 then
					self:playAnimation(wiper.animName, -currentState.animSpeed, 1, true)
				end

				if (wiper.nextStartTime == nil or wiper.nextStartTime < g_currentMission.time) and not self:getIsAnimationPlaying(wiper.animName) then
					self:playAnimation(wiper.animName, currentState.animSpeed, 0, true)

					wiper.nextStartTime = nil
				end

				if wiper.nextStartTime == nil then
					wiper.nextStartTime = g_currentMission.time + wiper.animDuration / currentState.animSpeed * 2 + currentState.animPause
				end
			end
		end
	end
end

function Wipers:loadWiperFromXML(xmlFile, key, wiper)
	local animName = xmlFile:getValue(key .. "#animName")

	if animName ~= nil then
		if self:getAnimationExists(animName) then
			wiper.animName = animName
			wiper.animDuration = self:getAnimationDuration(animName)
			wiper.states = {}
			local j = 0

			while true do
				local stateKey = string.format("%s.state(%d)", key, j)

				if not xmlFile:hasProperty(stateKey) then
					break
				end

				local state = {
					animSpeed = xmlFile:getValue(stateKey .. "#animSpeed"),
					animPause = xmlFile:getValue(stateKey .. "#animPause")
				}

				if state.animSpeed ~= nil and state.animPause ~= nil then
					state.animPause = state.animPause * 1000

					table.insert(wiper.states, state)
				end

				j = j + 1
			end
		else
			Logging.xmlWarning(self.xmlFile, "Animation '%s' not defined for wiper '%s'!", animName, key)

			return false
		end
	else
		Logging.xmlWarning(self.xmlFile, "Missing animation for wiper '%s'!", key)

		return false
	end

	local numStates = #wiper.states

	if numStates > 0 then
		local stepSize = 1 / numStates
		local curMax = stepSize

		for _, state in ipairs(wiper.states) do
			state.maxRainValue = curMax
			curMax = curMax + stepSize
		end

		wiper.nextStartTime = nil
	else
		Logging.xmlWarning(self.xmlFile, "No states defined for wiper '%s'!", key)

		return false
	end

	return true
end

function Wipers:getIsActiveForWipers()
	return true
end

function Wipers:consoleSetWiperState(state)
	local usage = "Usage: gsWiperStateSet <state> (-1 = use state from weather; 0..n = force specific wiper state)"

	if state == nil then
		return "Error: No arguments given! " .. usage
	end

	state = tonumber(state)

	if state == nil then
		return "Error: Argument is not a number! " .. usage
	end

	Wipers.forcedState = MathUtil.clamp(state, -1, 999)

	return Wipers.forcedState == -1 and " Reset global wiper state, now using weather state" or string.format("Set global wiper states to %d.", Wipers.forcedState)
end

addConsoleCommand("gsWiperStateSet", "Sets the given wiper state for all vehicles", "consoleSetWiperState", Wipers)
