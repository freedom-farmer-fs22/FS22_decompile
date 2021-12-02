AnimationValueFloat = {}
local AnimationValueFloat_mt = Class(AnimationValueFloat)
AnimationValueFloat.TANGENT_TYPE_LINEAR = 0
AnimationValueFloat.TANGENT_TYPE_SPLINE = 1
AnimationValueFloat.TANGENT_TYPE_STEP = 2

function AnimationValueFloat.new(vehicle, animation, part, startName, endName, name, initialUpdate, get, set, extraLoad, customMt)
	local self = setmetatable({}, customMt or AnimationValueFloat_mt)
	self.vehicle = vehicle
	self.animation = animation
	self.part = part
	self.startName = startName
	self.endName = endName
	self.name = name
	self.initialUpdate = initialUpdate
	self.get = get
	self.set = set
	self.extraLoad = extraLoad
	self.warningInfo = self.name
	self.compareParams = {}
	self.oldCurValues = {}
	self.oldSpeed = {}
	self.curValue = nil
	self.speed = nil

	return self
end

function AnimationValueFloat:load(xmlFile, key)
	if self.startName ~= "" then
		self.startValue = xmlFile:getValue(key .. "#" .. self.startName, nil, true)

		if type(self.startValue) == "number" then
			self.startValue = {
				self.startValue
			}
		elseif type(self.startValue) == "boolean" then
			self.startValue = {
				self.startValue and 1 or 0
			}
		end
	end

	if self.endName ~= "" then
		self.endValue = xmlFile:getValue(key .. "#" .. self.endName, nil, true)

		if type(self.endValue) == "number" then
			self.endValue = {
				self.endValue
			}
		elseif type(self.endValue) == "boolean" then
			self.endValue = {
				self.endValue and 1 or 0
			}
		end
	end

	if self.endValue ~= nil or self.endName == "" then
		self.warningInfo = key
		self.xmlFile = xmlFile
		local success = self:extraLoad(xmlFile, key)

		if success then
			local tangentTypeStr = xmlFile:getValue(key .. "#tangentType", "linear")
			tangentTypeStr = "TANGENT_TYPE_" .. tangentTypeStr:upper()

			if AnimationValueFloat[tangentTypeStr] ~= nil then
				self.tangentType = AnimationValueFloat[tangentTypeStr]
			else
				self.tangentType = AnimationValueFloat.TANGENT_TYPE_LINEAR
			end

			self.curStartValue = {}
			self.curRealValue = {}

			for i = 1, #(self.startValue or self.endValue) do
				self.curStartValue[i] = 0
				self.curRealValue[i] = 0
			end

			return true
		end
	end

	return false
end

function AnimationValueFloat:addCompareParameters(...)
	for _, parameter in pairs({
		...
	}) do
		table.insert(self.compareParams, parameter)
	end
end

function AnimationValueFloat:setWarningInformation(info)
	self.warningInfo = info
end

function AnimationValueFloat:init(index, numParts)
	for j = index + 1, numParts do
		local part2 = self.animation.parts[j]

		if self.part.direction == part2.direction then
			local animationValue2 = nil

			for secondIndex = 1, #part2.animationValues do
				local secondAnimValue = part2.animationValues[secondIndex]

				if secondAnimValue.endName == self.endName then
					local allowed = true

					for paramIndex = 1, #self.compareParams do
						local param = self.compareParams[paramIndex]

						if secondAnimValue[param] ~= self[param] then
							allowed = false
						end
					end

					if allowed then
						animationValue2 = secondAnimValue
					end
				end
			end

			if animationValue2 ~= nil then
				if self.part.startTime + self.part.duration > part2.startTime + 0.001 then
					Logging.xmlWarning(self.xmlFile, "Overlapping %s parts for '%s' in animation '%s'", self.name, self.warningInfo, self.animation.name)
				end

				self.nextPart = animationValue2.part
				animationValue2.prevPart = self.part

				if animationValue2.startValue == nil then
					animationValue2.startValue = {
						unpack(self.endValue)
					}
				end

				break
			end
		end
	end
end

function AnimationValueFloat:postInit()
	if self.endValue ~= nil and self.startValue == nil then
		self.startValue = {
			self:get()
		}
	end
end

function AnimationValueFloat:reset()
	self.oldCurValues = self.curValue or self.oldCurValues
	self.oldSpeed = self.speed or self.oldSpeed
	self.curValue = nil
	self.speed = nil
end

function AnimationValueFloat:initValues(targetValue, durationToEnd, fixedTimeUpdate, ...)
	self.curValue = self.curValue or self.oldCurValues
	local numValues = select("#", ...)

	for i = 1, numValues do
		self.curValue[i] = select(i, ...)
	end

	local invDuration = 1 / math.max(durationToEnd, 0.001)
	self.speed = {}

	for i = 1, #self.curValue do
		self.speed[i] = (targetValue[i] - self.curValue[i]) * invDuration
		self.curStartValue[i] = self.curValue[i]
		self.curRealValue[i] = self.curValue[i]
	end

	if fixedTimeUpdate == true then
		if self.animation.currentSpeed < 0 then
			for i = 1, numValues do
				self.curStartValue[i] = self.endValue[i]
			end
		else
			for i = 1, numValues do
				self.curStartValue[i] = self.startValue[i]
			end
		end
	end

	self.curTargetValue = targetValue

	return self.initialUpdate
end

local function getSplineAlpha(alpha)
	return 1 - math.pow(math.cos(math.pi * alpha / 2), 2)
end

function AnimationValueFloat:update(durationToEnd, dtToUse, realDt, fixedTimeUpdate)
	if self.startValue ~= nil and (durationToEnd > 0 or AnimatedVehicle.getNextPartIsPlaying(self.nextPart, self.prevPart, self.animation, true)) then
		local targetValue = self.endValue

		if self.animation.currentSpeed < 0 then
			targetValue = self.startValue
		end

		local forceUpdate = false

		if self.curValue == nil then
			forceUpdate = self:initValues(targetValue, durationToEnd, fixedTimeUpdate, self:get())
		end

		if AnimatedVehicle.setMovedLimitedValuesN(#self.curValue, self.curValue, targetValue, self.speed, realDt) or forceUpdate then
			if self.tangentType == AnimationValueFloat.TANGENT_TYPE_LINEAR then
				self:set(unpack(self.curValue))
			elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_SPLINE then
				for i = 1, #self.curValue do
					local alpha = (self.curValue[i] - self.curStartValue[i]) / (self.curTargetValue[i] - self.curStartValue[i])

					if fixedTimeUpdate == true then
						alpha = 1 - MathUtil.clamp((durationToEnd - realDt) / self.part.duration, 0, 1)
					end

					if alpha >= 0 and alpha <= 1 then
						self.curRealValue[i] = getSplineAlpha(alpha) * (self.curTargetValue[i] - self.curStartValue[i]) + self.curStartValue[i]
					else
						self.curRealValue[i] = self.curValue[i]
					end
				end

				self:set(unpack(self.curRealValue))
			elseif self.tangentType == AnimationValueFloat.TANGENT_TYPE_STEP then
				for i = 1, #self.curValue do
					local alpha = (self.curValue[i] - self.curStartValue[i]) / (self.curTargetValue[i] - self.curStartValue[i])

					if alpha >= 1 then
						self.curRealValue[i] = self.curValue[i]
					else
						self.curRealValue[i] = self.curStartValue[i]
					end
				end

				self:set(unpack(self.curRealValue))
			end

			return true
		end
	end

	return false
end
