Colorizer = {}
local Colorizer_mt = Class(Colorizer)

function Colorizer:onCreate(id)
	g_currentMission:addNonUpdateable(Colorizer.new(id))
	print("function Colorizer:onCreate(id)")
end

function Colorizer.new(name)
	local self = {}

	setmetatable(self, Colorizer_mt)

	self.me = name
	local colors = {}
	local xmlFileName = Utils.getNoNil(getUserAttribute(name, "xmlFile"), "")
	xmlFileName = Utils.getFilename(xmlFileName, g_currentMission.loadingMapBaseDirectory)

	if xmlFileName ~= "" then
		local xmlFile = loadXMLFile("colors.xml", xmlFileName)
		local i = 0

		while true do
			local key = string.format("colors.color(%d)", i)
			local colorName = getXMLString(xmlFile, key .. "#colorName")
			local rgb = getXMLString(xmlFile, key .. "#color")

			if rgb == nil then
				break
			end

			local r, g, b = rgb:getVector()

			if r ~= nil and g ~= nil and b ~= nil then
				table.insert(colors, {
					r = r,
					g = g,
					b = b,
					colorName = colorName
				})
			end

			i = i + 1
		end

		delete(xmlFile)

		local numberOfColorObjects = getNumOfChildren(name)

		for i = 1, numberOfColorObjects do
			local currentColorObject = getChildAt(name, i - 1)
			local colorIndex = math.random(1, table.getn(colors))

			setShaderParameter(currentColorObject, "colorTint", colors[colorIndex].r, colors[colorIndex].g, colors[colorIndex].b, 1, false)
		end
	end

	return self
end

function Colorizer:delete()
end
