BitmapUtil = {
	FORMAT = {}
}
BitmapUtil.FORMAT.BITMAP = 0
BitmapUtil.FORMAT.GREYMAP = 1
BitmapUtil.FORMAT.PIXELMAP = 2
BitmapUtil.FORMAT_TO_PNM = {
	[BitmapUtil.FORMAT.BITMAP] = {
		extension = "pbm",
		getHeader = function (width, height, maxBrightness)
			return string.format("P1\n%d %d\n", width, height)
		end,
		getPixel = function (pixelTable)
			return string.format("%d", pixelTable[1])
		end
	},
	[BitmapUtil.FORMAT.GREYMAP] = {
		extension = "pgm",
		getHeader = function (width, height, maxBrightness)
			return string.format([[
P2
%d %d
%d
]], width, height, maxBrightness)
		end,
		getPixel = function (pixelTable)
			return string.format("%d", pixelTable[1])
		end
	},
	[BitmapUtil.FORMAT.PIXELMAP] = {
		extension = "ppm",
		getHeader = function (width, height, maxBrightness)
			return string.format([[
P3
%d %d
%d
]], width, height, maxBrightness)
		end,
		getPixel = function (pixelTable)
			return string.format("%d %d %d", pixelTable[1], pixelTable[2], pixelTable[3])
		end
	}
}

function BitmapUtil.writeBitmapToFile(rowsCols, filepath, imageFormat)
	if type(rowsCols[1]) ~= "table" then
		Logging.error("Given pixel data has invalid format, should be: rows{ cols{ {r,g,b}} }")
	end

	local width, height, maxBrightness = nil
	width = #rowsCols[1]
	height = #rowsCols
	maxBrightness = 255
	local pnmFormat = BitmapUtil.FORMAT_TO_PNM[imageFormat]

	if pnmFormat == nil then
		Logging.error("Invalid image format '%s'. Use one of BitmapUtil.FORMAT", imageFormat)

		return false
	end

	filepath = string.format("%s.%s", filepath, pnmFormat.extension or "pnm")
	local file = createFile(filepath, FileAccess.WRITE)

	if file == 0 then
		Logging.error("BitmapUtil.writeBitmapToFile(): Unable to create file '%s'", filepath)

		return false
	end

	fileWrite(file, pnmFormat.getHeader(width, height, maxBrightness))

	for rowIndex = 1, #rowsCols do
		local pixels = {}
		local row = rowsCols[rowIndex]

		for colIndex = 1, #row do
			local pixel = row[colIndex]
			pixels[#pixels + 1] = pnmFormat.getPixel(pixel)
		end

		fileWrite(file, table.concat(pixels), " ")
		fileWrite(file, "\n")
	end

	delete(file)
	Logging.info("Wrote bitmap (width=%d, height=%d) to '%s'", width, height, filepath)

	return true
end

function BitmapUtil.writeBitmapToFileFromIterator(iterator, width, height, filepath, imageFormat)
	local pnmFormat = BitmapUtil.FORMAT_TO_PNM[imageFormat]

	if pnmFormat == nil then
		Logging.error("Invalid image format '%s'. Use one of BitmapUtil.FORMAT", imageFormat)

		return false
	end

	filepath = string.format("%s.%s", filepath, pnmFormat.extension or "pnm")
	local file = createFile(filepath, FileAccess.WRITE)

	if file == 0 then
		Logging.error("BitmapUtil.writeBitmapToFileFromIterator(): Unable to create file '%s'", filepath)

		return false
	end

	local maxBrightness = 255

	fileWrite(file, pnmFormat.getHeader(width, height, maxBrightness))

	local pixels = {}
	local colIndex = 0

	for pixel in iterator() do
		pixels[#pixels + 1] = pnmFormat.getPixel(pixel)

		if colIndex == width then
			colIndex = 0

			fileWrite(file, table.concat(pixels, " "))
			fileWrite(file, "\n")
			table.clear(pixels)
		end

		colIndex = colIndex + 1
	end

	delete(file)
	Logging.info("Wrote bitmap (width=%d, height=%d) to '%s'", width, height, filepath)

	return true
end
