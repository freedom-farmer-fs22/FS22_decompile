PlaceableWorkshop = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableWorkshop.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableWorkshop.setOwnerFarmId)
end

function PlaceableWorkshop.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWorkshop)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWorkshop)
end

function PlaceableWorkshop.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Workshop")
	VehicleSellingPoint.registerXMLPaths(schema, basePath .. ".workshop.sellingPoint")
	schema:setXMLSpecializationType()
end

function PlaceableWorkshop:onLoad(savegame)
	local spec = self.spec_workshop
	spec.sellingPoint = VehicleSellingPoint.new()

	spec.sellingPoint:load(self.components, self.xmlFile, "placeable.workshop.sellingPoint", self.i3dMappings)
	spec.sellingPoint:setOwnerFarmId(self:getOwnerFarmId())

	spec.sellingPoint.owningPlaceable = self
end

function PlaceableWorkshop:onDelete()
	local spec = self.spec_workshop

	if spec.sellingPoint ~= nil then
		spec.sellingPoint:delete()
	end
end

function PlaceableWorkshop:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
	local spec = self.spec_workshop

	superFunc(self, ownerFarmId, noEventSend)

	if spec.sellingPoint ~= nil then
		spec.sellingPoint:setOwnerFarmId(ownerFarmId)
	end
end
