IngameMapLayoutNone = {}
local IngameMapLayoutNone_mt = Class(IngameMapLayoutNone, IngameMapLayout)

function IngameMapLayoutNone.new()
	return IngameMapLayoutNone:superClass().new(IngameMapLayoutNone_mt)
end

function IngameMapLayoutNone:getMapSize()
	return 0, 0
end

function IngameMapLayoutNone:getShowsToggleAction()
	return false
end

function IngameMapLayoutNone:getShowsToggleActionText()
	return true
end

function IngameMapLayoutNone:getMapObjectPosition(objectX, objectZ, width, height, rot, persistent)
	return 0, 0, 0, false
end
