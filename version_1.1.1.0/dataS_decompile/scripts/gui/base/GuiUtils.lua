GuiUtils = {
	getNormalizedValues = function (data, refSize, defaultValue)
		if data ~= nil then
			local parts = data
			local isString = type(data) == "string"

			if isString then
				parts = data:split(" ")
			end

			local values = {}

			for k, part in pairs(parts) do
				local value = part

				if isString then
					local isPixelValue = false
					local isDisplayPixelValue = false

					if string.find(value, "px") ~= nil then
						isPixelValue = true
						value = string.gsub(value, "px", "")
					elseif string.find(value, "dp") ~= nil then
						isDisplayPixelValue = true
						value = string.gsub(value, "dp", "")
					end

					value = Utils.evaluateFormula(value)

					if isDisplayPixelValue then
						local s = (k + 1) % 2

						if s == 0 then
							value = value / g_screenWidth
						else
							value = value / g_screenHeight
						end
					elseif isPixelValue then
						value = value / refSize[(k + 1) % 2 + 1]
					end
				else
					value = value / refSize[(k + 1) % 2 + 1]
				end

				table.insert(values, value)
			end

			if defaultValue ~= nil and #defaultValue > #parts then
				local wrap = #parts

				for i = #parts + 1, #defaultValue do
					table.insert(values, values[(i - 1) % wrap + 1])
				end
			end

			return values
		end

		return defaultValue
	end,
	getNormalizedTextSize = function (str, refSize, defaultValue)
		if str ~= nil then
			local isPixelValue = false
			local isDisplayPixelValue = false

			if string.find(str, "px") ~= nil then
				isPixelValue = true
				str = string.gsub(str, "px", "")
			elseif string.find(str, "dp") ~= nil then
				isDisplayPixelValue = true
				str = string.gsub(str, "dp", "")
			end

			local value = tonumber(str)

			if value == nil then
				printCallstack()
			end

			if isPixelValue then
				return value / (refSize or g_screenHeight)
			elseif isDisplayPixelValue then
				return value / g_screenHeight
			end
		end

		return defaultValue
	end,
	get2DArray = function (str, defaultValue)
		if str ~= nil then
			local parts = str:split(" ")
			local x, y = unpack(parts)

			if x ~= nil and y ~= nil then
				return {
					Utils.evaluateFormula(x),
					Utils.evaluateFormula(y)
				}
			end
		end

		return defaultValue
	end,
	get4DArray = function (str, defaultValue)
		local data = string.getVectorN(str)

		if data ~= nil and #data == 4 then
			return data
		end

		return defaultValue
	end,
	getColorArray = function (colorStr, defaultValue)
		local data = string.getVectorN(colorStr)

		if data ~= nil and #data == 4 then
			return data
		end

		return defaultValue
	end,
	getColorGradientArray = function (colorStr, defaultValue)
		local data = string.getVectorN(colorStr)

		if data ~= nil and (#data == 4 or #data == 16) then
			return data
		end

		return defaultValue
	end
}

function GuiUtils.getUVs(str, ref, defaultValue, rotation)
	if str ~= nil then
		local uvs = GuiUtils.getNormalizedValues(str, ref or {
			1024,
			1024
		})

		if uvs[1] ~= nil then
			local result = {
				uvs[1],
				1 - uvs[2] - uvs[4],
				uvs[1],
				1 - uvs[2],
				uvs[1] + uvs[3],
				1 - uvs[2] - uvs[4],
				uvs[1] + uvs[3],
				1 - uvs[2]
			}

			if rotation ~= nil then
				GuiUtils.rotateUVs(result, rotation)
			end

			return result
		else
			Logging.devError("GuiUtils.getUVs() Unable to get uvs for '%s'", str)
		end
	end

	return defaultValue
end

function GuiUtils.checkOverlayOverlap(posX, posY, overlayX, overlayY, overlaySizeX, overlaySizeY, hotspot)
	if hotspot ~= nil and #hotspot == 4 then
		return posX >= overlayX + hotspot[1] and posX <= overlayX + overlaySizeX + hotspot[3] and posY >= overlayY + hotspot[2] and posY <= overlayY + overlaySizeY + hotspot[4]
	else
		return overlayX <= posX and posX <= overlayX + overlaySizeX and overlayY <= posY and posY <= overlayY + overlaySizeY
	end
end

function GuiUtils.rotateUVs(uvs, direction)
	local u1, v1, u2, v2, u3, v3, u4, v4 = unpack(uvs)

	if direction == 90 then
		uvs[1] = u3
		uvs[2] = v3
		uvs[3] = u1
		uvs[4] = v1
		uvs[5] = u4
		uvs[6] = v4
		uvs[7] = u2
		uvs[8] = v2
	elseif direction == -90 then
		uvs[1] = u2
		uvs[2] = v2
		uvs[3] = u4
		uvs[4] = v4
		uvs[5] = u1
		uvs[6] = v1
		uvs[7] = u3
		uvs[8] = v3
	elseif direction == 180 then
		uvs[1] = u4
		uvs[2] = v4
		uvs[3] = u3
		uvs[4] = v3
		uvs[5] = u2
		uvs[6] = v2
		uvs[7] = u1
		uvs[8] = v1
	end
end
