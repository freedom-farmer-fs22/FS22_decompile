AnimationElement = {}
local AnimationElement_mt = Class(AnimationElement, BitmapElement)
AnimationElement.MODE = {
	UV_SHIFT = 1,
	ROTATE = 2
}

function AnimationElement.new(target, custom_mt)
	local self = BitmapElement.new(target, custom_mt or AnimationElement_mt)
	self.animationMode = AnimationElement.MODE.UV_SHIFT
	self.animationOffset = -1
	self.animationFrames = 8
	self.animationTimer = 0
	self.animationSpeed = 120
	self.animationFrameSize = 0
	self.animationStartPos = 0
	self.animationUVOffset = 0
	self.animationRotation = 0

	return self
end

function AnimationElement:loadFromXML(xmlFile, key)
	AnimationElement:superClass().loadFromXML(self, xmlFile, key)

	self.animationOffset = Utils.getNoNil(getXMLInt(xmlFile, key .. "#animationOffset"), self.animationOffset)
	self.animationFrames = Utils.getNoNil(getXMLInt(xmlFile, key .. "#animationFrames"), self.animationFrames)
	self.animationSpeed = Utils.getNoNil(getXMLInt(xmlFile, key .. "#animationSpeed"), self.animationSpeed)
	local animationUVOffset = getXMLString(xmlFile, key .. "#animationUVOffset")

	if animationUVOffset ~= nil then
		animationUVOffset = GuiUtils.getNormalizedValues(animationUVOffset, self.imageSize)
		self.animationUVOffset = animationUVOffset[1]
	end

	local uvs = GuiOverlay.getOverlayUVs(self.overlay, self:getOverlayState())
	self.animationDefaultUVs = table.copy(uvs)
	local mode = getXMLString(xmlFile, key .. "#animationMode")

	if mode ~= nil then
		if mode:lower() == "uvshift" then
			self.animationMode = AnimationElement.MODE.UV_SHIFT
		else
			self.animationMode = AnimationElement.MODE.ROTATE
		end
	end

	self:setAnimationData()
end

function AnimationElement:loadProfile(profile, applyProfile)
	AnimationElement:superClass().loadProfile(self, profile, applyProfile)

	self.animationOffset = profile:getNumber("animationOffset", self.animationOffset)
	self.animationFrames = profile:getNumber("animationFrames", self.animationFrames)
	self.animationSpeed = profile:getNumber("animationSpeed", self.animationSpeed)
	local animationUVOffset = profile:getValue("animationUVOffset")

	if animationUVOffset ~= nil then
		animationUVOffset = GuiUtils.getNormalizedValues(animationUVOffset, self.imageSize)
		self.animationUVOffset = animationUVOffset[1]
	end

	local mode = profile:getValue("animationMode")

	if mode ~= nil then
		if mode:lower() == "uvshift" then
			self.animationMode = AnimationElement.MODE.UV_SHIFT
		else
			self.animationMode = AnimationElement.MODE.ROTATE
		end
	end
end

function AnimationElement:copyAttributes(src)
	AnimationElement:superClass().copyAttributes(self, src)

	self.animationDefaultUVs = table.copy(src.animationDefaultUVs)
	self.animationOffset = src.animationOffset
	self.animationFrames = src.animationFrames
	self.animationSpeed = src.animationSpeed
	self.animationUVOffset = src.animationUVOffset
	self.animationMode = src.animationMode

	self:setImageUVs(nil, unpack(self.animationDefaultUVs))
	self:setAnimationData()
end

function AnimationElement:update(dt)
	AnimationElement:superClass().update(self, dt)

	if self.animationMode == AnimationElement.MODE.UV_SHIFT then
		self.animationTimer = self.animationTimer - dt

		if self.animationTimer < 0 then
			self.animationTimer = self.animationSpeed
			self.animationOffset = self.animationOffset + 1

			if self.animationOffset > self.animationFrames - 1 then
				self.animationOffset = 0
			end

			self:updateAnimationUVs()
		end
	elseif self.animationMode == AnimationElement.MODE.ROTATE then
		self.animationRotation = self.animationRotation - 2 * math.pi * dt / self.animationSpeed

		self:updateRotation()
	end
end

function AnimationElement:updateAnimationUVs()
	if self.animationMode == AnimationElement.MODE.UV_SHIFT then
		local frameOffset = self.animationStartPos + (self.animationFrameSize + self.animationUVOffset) * self.animationOffset

		self:setImageUVs(nil, frameOffset, nil, frameOffset, nil, frameOffset + self.animationFrameSize, nil, frameOffset + self.animationFrameSize, nil)
	end
end

function AnimationElement:updateRotation()
	local x = self.absSize[1] * self.pivot[1]
	local y = self.absSize[2] * self.pivot[2]

	GuiOverlay.setRotation(self.overlay, self.animationRotation, x, y)
end

function AnimationElement:setAnimationData()
	if self.overlay ~= nil then
		local uvs = GuiOverlay.getOverlayUVs(self.overlay, self:getOverlayState())
		self.animationFrameSize = (uvs[5] - uvs[1] - self.animationUVOffset * (self.animationFrames - 1)) / self.animationFrames
		self.animationStartPos = uvs[1]

		self:updateAnimationUVs()
	end
end
