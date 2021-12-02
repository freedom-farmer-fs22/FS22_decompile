DebugText = {}
local DebugText_mt = Class(DebugText)

function DebugText.new(customMt)
	local self = setmetatable({}, customMt or DebugText_mt)
	self.z = 0
	self.y = 0
	self.x = 0
	self.rotZ = 0
	self.rotY = 0
	self.rotX = 0
	self.alignment = RenderText.ALIGN_LEFT
	self.verticalAlignment = RenderText.VERTICAL_ALIGN_MIDDLE
	self.a = 1
	self.b = 1
	self.g = 1
	self.r = 1
	self.size = 0.1
	self.text = nil
	self.alignToGround = false
	self.alignToCamera = false

	return self
end

function DebugText:delete()
end

function DebugText:update(dt)
	if self.alignToCamera then
		self.rotY = self:getRotationToCamera(self.x, self.y, self.z)
	end
end

function DebugText:draw()
	setTextDepthTestEnabled(false)
	setTextAlignment(self.alignment)
	setTextVerticalAlignment(self.verticalAlignment)
	setTextColor(self.r, self.g, self.b, self.a)
	renderText3D(self.x, self.y, self.z, self.rotX, self.rotY, self.rotZ, self.size, self.text)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	setTextDepthTestEnabled(true)
end

function DebugText:createWithNode(node, text, size)
	local x, y, z = getWorldTranslation(node)
	local rotX, rotY, rotZ = getWorldRotation(node)

	self:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, text, size)
end

function DebugText:createWithNodeToCamera(node, yOffset, text, size)
	self.alignToCamera = true
	local x, y, z = localToWorld(node, 0, yOffset, 0)

	self:createWithWorldPosAndRot(x, y, z, 0, self:getRotationToCamera(x, y, z), 0, text, size)
end

function DebugText:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, text, size)
	self.z = z
	self.y = y
	self.x = x
	self.rotZ = rotZ
	self.rotY = rotY
	self.rotX = rotX
	self.text = text
	self.size = size
end

function DebugText:getRotationToCamera(x, y, z)
	local cx, cy, cz = getWorldTranslation(getCamera())
	local dirX, _, dirZ = MathUtil.vector3Normalize(cx - x, cy - y, cz - z)

	return MathUtil.getYRotationFromDirection(dirX, dirZ)
end
