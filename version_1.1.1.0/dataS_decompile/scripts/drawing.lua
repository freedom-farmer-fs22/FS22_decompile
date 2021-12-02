local overlays = {}
local loadedOverlays = false
local PIXEL = 1
local TOUCH_SIDE = 2
local TOUCH_MIDDLE = 3
local PIXEL_X_SIZE, PIXEL_Y_SIZE, TOUCH_HEIGHT, TOUCH_SIDE_WIDTH = nil

function onProfileUiResolutionScalingChanged()
	local resScale = 1
	local screenWidth = resScale * g_screenWidth
	local screenHeight = resScale * g_screenHeight
	PIXEL_X_SIZE = 1 / screenWidth
	PIXEL_Y_SIZE = 1 / screenHeight
	TOUCH_HEIGHT = 0.0953125 * g_aspectScaleY
	TOUCH_SIDE_WIDTH = math.floor(0.029292929292929294 * g_aspectScaleX / PIXEL_X_SIZE) * PIXEL_X_SIZE
end

local function loadOverlays()
	overlays[PIXEL] = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

	if GS_IS_MOBILE_VERSION then
		overlays[TOUCH_SIDE] = createImageOverlay(g_baseUIFilename)

		setOverlayUVs(overlays[TOUCH_SIDE], unpack(GuiUtils.getUVs({
			438,
			485,
			58,
			122
		})))

		overlays[TOUCH_MIDDLE] = createImageOverlay(g_baseUIFilename)

		setOverlayUVs(overlays[TOUCH_MIDDLE], unpack(GuiUtils.getUVs({
			518,
			485,
			1,
			122
		})))
	end

	onProfileUiResolutionScalingChanged()

	loadedOverlays = true
end

function deleteDrawingOverlays()
	for _, overlay in pairs(overlays) do
		delete(overlay)
	end

	loadedOverlays = false
end

function drawFilledRect(x, y, width, height, r, g, b, a, clipX1, clipY1, clipX2, clipY2)
	if not loadedOverlays then
		loadOverlays()
	end

	local overlay = overlays[PIXEL]

	if width == 0 or height == 0 then
		return
	end

	width = math.max(width, PIXEL_X_SIZE)
	height = math.max(height, PIXEL_Y_SIZE)
	x = math.floor(x / PIXEL_X_SIZE) * PIXEL_X_SIZE
	y = math.floor(y / PIXEL_Y_SIZE) * PIXEL_Y_SIZE

	if clipX1 ~= nil then
		local posX2 = x + width
		local posY2 = y + height
		x = math.max(x, clipX1)
		y = math.max(y, clipY1)
		width = math.max(math.min(posX2, clipX2) - x, 0)
		height = math.max(math.min(posY2, clipY2) - y, 0)

		if width == 0 or height == 0 then
			return
		end
	end

	setOverlayColor(overlay, r, g, b, a)
	renderOverlay(overlay, x, y, width, height)
end

function drawOutlineRect(x, y, width, height, lineWidth, lineHeight, r, g, b, a)
	if not loadedOverlays then
		loadOverlays()
	end

	local overlay = overlays[PIXEL]

	setOverlayColor(overlay, r, g, b, a)
	renderOverlay(overlay, x, y, width, lineHeight)
	renderOverlay(overlay, x, y, lineWidth, height)
	renderOverlay(overlay, x + width - lineWidth, y, lineWidth, height)
	renderOverlay(overlay, x, y + height - lineHeight, width, lineHeight)
end

function drawPoint(x, y, width, height, r, g, b, a)
	if not loadedOverlays then
		loadOverlays()
	end

	local overlay = overlays[PIXEL]

	setOverlayColor(overlay, r, g, b, a)
	renderOverlay(overlay, x - width / 2, y - height / 2, width, height)
end

local function alignHorizontalToScreenPixels(x)
	return math.floor(x / PIXEL_X_SIZE) * PIXEL_X_SIZE
end

if GS_IS_MOBILE_VERSION then
	function drawTouchButton(x, y, width, isPressed)
		if not loadedOverlays then
			loadOverlays()
		end

		x = alignHorizontalToScreenPixels(x)
		width = alignHorizontalToScreenPixels(width)
		y = y - TOUCH_HEIGHT * 0.5

		if isPressed then
			setOverlayColor(overlays[TOUCH_SIDE], 0.718, 0.716, 0.715, 0.25)
			setOverlayColor(overlays[TOUCH_MIDDLE], 0.718, 0.716, 0.715, 0.25)
		else
			setOverlayColor(overlays[TOUCH_SIDE], 1, 1, 1, 1)
			setOverlayColor(overlays[TOUCH_MIDDLE], 1, 1, 1, 1)
		end

		setOverlayRotation(overlays[TOUCH_SIDE], 0, 0, 0)
		renderOverlay(overlays[TOUCH_SIDE], x, y, TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
		setOverlayRotation(overlays[TOUCH_SIDE], math.pi, TOUCH_SIDE_WIDTH * 0.5, TOUCH_HEIGHT * 0.5)
		renderOverlay(overlays[TOUCH_SIDE], x + width - TOUCH_SIDE_WIDTH, y, TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
		renderOverlay(overlays[TOUCH_MIDDLE], x + TOUCH_SIDE_WIDTH, y, width - 2 * TOUCH_SIDE_WIDTH, TOUCH_HEIGHT)
	end
end
