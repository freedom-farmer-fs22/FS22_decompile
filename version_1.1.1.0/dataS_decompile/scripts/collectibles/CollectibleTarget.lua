CollectibleTarget = {}
local CollectibleTarget_mt = Class(CollectibleTarget)

function CollectibleTarget:onCreate(node)
	g_currentMission:addNonUpdateable(CollectibleTarget.new(node))
end

function CollectibleTarget.new(node)
	local self = setmetatable({}, CollectibleTarget_mt)
	self.node = node

	g_currentMission.collectiblesSystem:addCollectibleTarget(self)

	return self
end

function CollectibleTarget:delete()
	g_currentMission.collectiblesSystem:removeCollectibleTarget(self)
end

function CollectibleTarget:setState(itemName, visible)
	local node = getChild(self.node, itemName)

	if node ~= nil then
		setVisibility(node, visible)
	end
end
