FindOverlayLeaks = {
	overlays = {},
	guiElements = {}
}

function FindOverlayLeaks.init()
	local oldOverlayCreate = createImageOverlay

	function createImageOverlay(filename, ...)
		local id = oldOverlayCreate(filename, ...)
		FindOverlayLeaks.overlays[id] = {
			trace = debug.traceback(),
			filename = filename
		}

		return id
	end

	local guiNew = GuiElement.new

	function GuiElement.new(...)
		local instance = guiNew(...)
		FindOverlayLeaks.guiElements[instance] = {
			trace = debug.traceback(),
			className = ClassUtil.getClassNameByObject(instance)
		}

		return instance
	end

	local guiDelete = GuiElement.delete

	function GuiElement.delete(instance, ...)
		FindOverlayLeaks.guiElements[instance] = nil

		guiDelete(instance, ...)
	end

	local oldDelete = delete

	function delete(id)
		oldDelete(id)

		FindOverlayLeaks.overlays[id] = nil
	end
end

function FindOverlayLeaks.printUndeletedOverlays()
	if next(FindOverlayLeaks.overlays) ~= nil then
		log("FindOverlayLeaks: Undeleted overlays\n\n")

		for id, data in pairs(FindOverlayLeaks.overlays) do
			log(id, data.filename)
			log(data.trace)
			log("\n\n")
		end
	end

	if next(FindOverlayLeaks.guiElements) ~= nil then
		log("FindOverlayLeaks: Undeleted gui elements\n\n")

		for ref, data in pairs(FindOverlayLeaks.guiElements) do
			log(ref, data.className)
			log(data.trace)
			log("\n\n")
		end
	end
end
