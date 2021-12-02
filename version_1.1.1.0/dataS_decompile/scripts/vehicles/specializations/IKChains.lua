IKChains = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("IKChains")
		IKUtil.registerIKChainXMLPaths(schema, "vehicle.ikChains.ikChain(?)")
		schema:setXMLSpecializationType()
	end,
	registerEventListeners = function (vehicleType)
		SpecializationUtil.registerEventListener(vehicleType, "onLoad", IKChains)
		SpecializationUtil.registerEventListener(vehicleType, "onUpdate", IKChains)
	end,
	onLoad = function (self, savegame)
		local spec = self.spec_ikChains
		spec.chains = {}
		local i = 0

		while true do
			local key = string.format("vehicle.ikChains.ikChain(%d)", i)

			if not self.xmlFile:hasProperty(key) then
				break
			end

			IKUtil.loadIKChain(self.xmlFile, key, self.components, self.components, spec.chains, self.getParentComponent, self)

			i = i + 1
		end

		IKUtil.updateAlignNodes(spec.chains, self.getParentComponent, self, nil)

		if next(spec.chains) == nil then
			SpecializationUtil.removeEventListener(self, "onUpdate", IKChains)
		end
	end,
	onUpdate = function (self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
		IKUtil.updateIKChains(self.spec_ikChains.chains)
	end
}
