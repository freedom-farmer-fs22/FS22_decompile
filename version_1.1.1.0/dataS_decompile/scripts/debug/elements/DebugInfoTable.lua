DebugInfoTable = {}
local DebugInfoTable_mt = Class(DebugInfoTable)

function DebugInfoTable.new(customMt)
	local self = setmetatable({}, customMt or DebugInfoTable_mt)
	self.z = 0
	self.y = 0
	self.x = 0
	self.rotZ = 0
	self.rotY = 0
	self.rotX = 0
	self.a = 1
	self.b = 1
	self.g = 1
	self.r = 1
	self.size = 0.25
	self.text = nil
	self.alignToGround = false

	return self
end

function DebugInfoTable:delete()
end

function DebugInfoTable:update(dt)
end

function DebugInfoTable:draw()
	setTextDepthTestEnabled(false)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	setTextColor(self.r, self.g, self.b, self.a)
	setTextBold(false)

	local yOffset = 0

	for i = #self.information, 1, -1 do
		local info = self.information[i]
		local title = info.title
		local content = info.content

		for j = #content, 1, -1 do
			local pair = content[j]
			local key = pair.name
			local value = pair.value

			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText3D(self.x, self.y + yOffset, self.z, self.rotX, self.rotY, self.rotZ, self.size, key)
			setTextAlignment(RenderText.ALIGN_LEFT)

			if type(value) == "number" then
				renderText3D(self.x, self.y + yOffset, self.z, self.rotX, self.rotY, self.rotZ, self.size, " " .. string.format("%.4f", value))
			else
				renderText3D(self.x, self.y + yOffset, self.z, self.rotX, self.rotY, self.rotZ, self.size, " " .. tostring(value))
			end

			yOffset = yOffset + self.size
		end

		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		renderText3D(self.x, self.y + yOffset, self.z, self.rotX, self.rotY, self.rotZ, self.size, title)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)

		yOffset = yOffset + 2 * self.size
	end

	setTextDepthTestEnabled(true)
end

function DebugInfoTable:createWithNode(node, info, size)
	local x, y, z = getWorldTranslation(node)
	local rotX, rotY, rotZ = getWorldRotation(node)

	self:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, info, size)
end

function DebugInfoTable:createWithNodeToCamera(node, yOffset, info, size)
	local x, y, z = localToWorld(node, 0, yOffset, 0)
	local cx, cy, cz = getWorldTranslation(getCamera())
	local dirX, _, dirZ = MathUtil.vector3Normalize(cx - x, cy - y, cz - z)
	local rotY = MathUtil.getYRotationFromDirection(dirX, dirZ)

	self:createWithWorldPosAndRot(x, y, z, 0, rotY, 0, info, size)
end

function DebugInfoTable:createWithWorldPosAndRot(x, y, z, rotX, rotY, rotZ, info, size)
	self.z = z
	self.y = y
	self.x = x
	self.rotZ = rotZ
	self.rotY = rotY
	self.rotX = rotX
	self.information = info
	self.size = size * 2.5
end
