FoliageXmlUtil = {
	printFoliageCtor = function (ctor)
		local name = ctor:getName()
		local numChannels, numTypeIndexChannels = ctor:getDensityMapInfo()
		local numLayers = ctor:getNumLayers()

		print("Name: " .. name)
		print("Density Map: BPP " .. numChannels .. " TYPE " .. numTypeIndexChannels)
		print("Num layers: " .. numLayers)

		for i = 1, numLayers do
			local layerIndex = i - 1
			local layerName = ctor:getNameForLayer(layerIndex)
			local typeIndex = ctor:getTypeIndexForLayer(layerIndex)
			local shapeSource = ctor:getShapeSourceForLayer(layerIndex)
			local channelOffset, layerNumChannels = ctor:getDensityChannelsForLayer(layerIndex)
			local cellSize = ctor:getCellSizeForLayer(layerIndex)
			local objectMask = ctor:getObjectMaskForLayer(layerIndex)
			local decalLayer = ctor:getDecalLayerForLayer(layerIndex)
			local maxStates = ctor:getMaxNumStatesForLayer(layerIndex)
			local numStates = ctor:getNumStatesForLayer(layerIndex)

			print("Layer " .. layerIndex .. ":")
			print("  Name: " .. layerName)
			print("  Type index: " .. typeIndex)
			print("  Shape Source: " .. tostring(shapeSource))
			print("  Density map: CH off " .. channelOffset .. " BPP " .. layerNumChannels)
			print("  Cell size: " .. cellSize)
			print("  Object mask: " .. objectMask)
			print("  Decal layer: " .. decalLayer)
			print("  Max states: " .. maxStates)
			print("  Num states: " .. numStates)

			for j = 1, numStates do
				local stateIndex = j - 1
				local stateName = ctor:getNameForState(layerIndex, stateIndex)
				local filename, layer = ctor:getDistanceMapForState(layerIndex, stateIndex)
				local w, wv = ctor:getWidthAndVarianceForState(layerIndex, stateIndex)
				local h, hv = ctor:getHeightAndVarianceForState(layerIndex, stateIndex)
				local hpv = ctor:getPositionVarianceForState(layerIndex, stateIndex)
				local numShapes = ctor:getNumShapesForState(layerIndex, stateIndex)
				local blocksPerUnit = ctor:getBlocksPerUnitForState(layerIndex)

				print("  State " .. stateIndex .. ":")
				print("    Name: " .. stateName)
				print("    Distance map: " .. filename .. " layer " .. layer)
				print("    Width: " .. w .. " var " .. wv)
				print("    Height: " .. h .. " var " .. hv)
				print("    Pos var: " .. hpv)
				print("    Num shapes: " .. numShapes)
				print("    Blocks per unit " .. blocksPerUnit)

				for k = 1, numShapes do
					local shapeIndex = k - 1
					local numLods = ctor:getNumLodsForShape(layerIndex, stateIndex, shapeIndex)

					for l = 1, numLods do
						local lodIndex = l - 1
						local viewDistance = ctor:getViewDistanceForLod(layerIndex, stateIndex, shapeIndex, lodIndex)
						local shape = ctor:getShapeForLod(layerIndex, stateIndex, shapeIndex, lodIndex)
						local atlasSize = ctor:getAtlasSizeForLod(layerIndex, stateIndex, shapeIndex, lodIndex)
						local aoffx, aoffy = ctor:getAtlasOffsetForLod(layerIndex, stateIndex, shapeIndex, lodIndex)
						local u0, v0, u1, v1 = ctor:getTexCoordsForLod(layerIndex, stateIndex, shapeIndex, lodIndex)

						print("    Lod " .. lodIndex)
						print("      ViewDistance " .. tostring(viewDistance))
						print("      Shape " .. tostring(shape))
						print("      Atlas size: " .. atlasSize)
						print("      Atlas offset: " .. aoffx .. " " .. aoffy)
						print("      Tex coords: " .. u0 .. " " .. v0 .. " " .. u1 .. " " .. v1)
					end
				end
			end
		end
	end
}
