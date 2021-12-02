PlaceableDeletedNodes = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEventListeners = function (placeableType)
		SpecializationUtil.registerEventListener(placeableType, "onLoadFinished", PlaceableDeletedNodes)
	end,
	registerXMLPaths = function (schema, basePath)
		schema:setXMLSpecializationType("DeletedNodes")
		schema:register(XMLValueType.NODE_INDEX, basePath .. ".deletedNodes.deletedNode(?)#node", "The node that should be deleted")
		schema:setXMLSpecializationType()
	end,
	onLoadFinished = function (self, savegame)
		if self.xmlFile ~= nil then
			local nodes = {}

			self.xmlFile:iterate("placeable.deletedNodes.deletedNode", function (_, key)
				local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

				table.insert(nodes, node)
			end)

			for _, node in ipairs(nodes) do
				delete(node)
			end
		end
	end
}
