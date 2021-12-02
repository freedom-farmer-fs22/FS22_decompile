I3DManager = {
	VERBOSE_LOADING = true,
	DEBUG_LOADING_CHECKS = {}
}
local I3DManager_mt = Class(I3DManager)

function I3DManager.new(customMt)
	local self = setmetatable({}, customMt or I3DManager_mt)

	addConsoleCommand("gsI3DLoadingDelaySet", "Sets loading delay for i3d files", "consoleCommandSetLoadingDelay", self)
	addConsoleCommand("gsI3DShowCache", "Show active i3d cache", "consoleCommandShowCache", self)
	addConsoleCommand("gsI3DPrintActiveLoadings", "Print active loadings", "consoleCommandPrintActiveLoadings", self)

	return self
end

function I3DManager:init()
	local loadingDelay = tonumber(StartParams.getValue("i3dLoadingDelay"))

	if loadingDelay ~= nil and loadingDelay > 0 then
		self:setLoadingDelay(loadingDelay / 1000)
	end

	if StartParams.getIsSet("scriptDebug") then
		self:setupDebugLoading()
	end
end

function I3DManager:update(dt)
	if I3DManager.showCache then
		local data = {}
		local numSharedI3ds = getNumOfSharedI3DFiles()

		for i = 0, numSharedI3ds - 1 do
			local filename, numRefs = getSharedI3DFilesData(i)

			table.insert(data, {
				filename = filename,
				numRefs = numRefs
			})
		end

		table.sort(data, function (a, b)
			return a.filename < b.filename
		end)

		local posX = 0.01
		local posY = 0.99

		for _, item in ipairs(data) do
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(posX, posY, 0.01, "Refcount: " .. tostring(item.numRefs))
			renderText(posX + 0.04, posY, 0.01, "File: " .. tostring(item.filename))

			posY = posY - 0.011

			if posY < 0 then
				posX = posX + 0.3
				posY = 0.99
			end
		end
	end
end

function I3DManager:loadSharedI3DFile(filename, callOnCreate, addToPhysics)
	local verbose = true
	callOnCreate = Utils.getNoNil(callOnCreate, false)
	addToPhysics = Utils.getNoNil(addToPhysics, false)
	local node, sharedLoadRequestId, failedReason = loadSharedI3DFile(filename, addToPhysics, callOnCreate, verbose)

	return node, sharedLoadRequestId, failedReason
end

function I3DManager:loadSharedI3DFileAsync(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	assert(filename ~= nil, "I3DManager:loadSharedI3DFileAsync - missing filename")
	assert(asyncCallbackFunction ~= nil, "I3DManager:loadSharedI3DFileAsync - missing callback function")
	assert(type(asyncCallbackFunction) == "function", "I3DManager:loadSharedI3DFileAsync - Callback value is not a function")

	callOnCreate = Utils.getNoNil(callOnCreate, false)
	addToPhysics = Utils.getNoNil(addToPhysics, false)
	local arguments = {
		asyncCallbackFunction = asyncCallbackFunction,
		asyncCallbackObject = asyncCallbackObject,
		asyncCallbackArguments = asyncCallbackArguments
	}
	local sharedLoadRequestId = streamSharedI3DFile(filename, "loadSharedI3DFileAsyncFinished", self, arguments, addToPhysics, callOnCreate, I3DManager.VERBOSE_LOADING)

	return sharedLoadRequestId
end

function I3DManager:loadSharedI3DFileAsyncFinished(nodeId, failedReason, arguments)
	local asyncCallbackFunction = arguments.asyncCallbackFunction
	local asyncCallbackObject = arguments.asyncCallbackObject
	local asyncCallbackArguments = arguments.asyncCallbackArguments

	asyncCallbackFunction(asyncCallbackObject, nodeId, failedReason, asyncCallbackArguments)
end

function I3DManager:loadI3DFile(filename, callOnCreate, addToPhysics)
	callOnCreate = Utils.getNoNil(callOnCreate, false)
	addToPhysics = Utils.getNoNil(addToPhysics, false)
	local node = loadI3DFile(filename, addToPhysics, callOnCreate, I3DManager.VERBOSE_LOADING)

	return node
end

function I3DManager:loadI3DFileAsync(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	assert(filename ~= nil, "I3DManager:loadI3DFileAsync - missing filename")
	assert(asyncCallbackFunction ~= nil, "I3DManager:loadI3DFileAsync - missing callback function")
	assert(type(asyncCallbackFunction) == "function", "I3DManager:loadI3DFileAsync - Callback value is not a function")

	callOnCreate = Utils.getNoNil(callOnCreate, false)
	addToPhysics = Utils.getNoNil(addToPhysics, false)
	local arguments = {
		asyncCallbackFunction = asyncCallbackFunction,
		asyncCallbackObject = asyncCallbackObject,
		asyncCallbackArguments = asyncCallbackArguments
	}
	local loadRequestId = streamI3DFile(filename, "loadSharedI3DFileFinished", self, arguments, addToPhysics, callOnCreate, I3DManager.VERBOSE_LOADING)

	return loadRequestId
end

function I3DManager:loadSharedI3DFileFinished(nodeId, failedReason, arguments)
	local asyncCallbackFunction = arguments.asyncCallbackFunction
	local asyncCallbackObject = arguments.asyncCallbackObject
	local asyncCallbackArguments = arguments.asyncCallbackArguments

	asyncCallbackFunction(asyncCallbackObject, nodeId, failedReason, asyncCallbackArguments)
end

function I3DManager:cancelStreamI3DFile(loadingRequestId)
	if loadingRequestId ~= nil then
		cancelStreamI3DFile(loadingRequestId)
	else
		Logging.error("I3DManager:cancelStreamedI3dFile - loadingRequestId is nil")
		printCallstack()
	end
end

function I3DManager:releaseSharedI3DFile(sharedLoadRequestId, warnIfInvalid)
	if sharedLoadRequestId ~= nil then
		warnIfInvalid = Utils.getNoNil(warnIfInvalid, false)

		releaseSharedI3DFile(sharedLoadRequestId, warnIfInvalid)
	else
		Logging.error("I3DManager:releaseSharedI3DFile - sharedLoadRequestId is nil")
		printCallstack()
	end
end

function I3DManager:pinSharedI3DFileInCache(filename)
	if filename ~= nil then
		if getSharedI3DFileRefCount(filename) < 0 then
			pinSharedI3DFileInCache(filename, true)
		end
	else
		Logging.error("I3DManager:pinSharedI3DFileInCache - Filename is nil")
		printCallstack()
	end
end

function I3DManager:unpinSharedI3DFileInCache(filename)
	if filename ~= nil then
		log("unpinSharedI3DFileInCache", filename)
		unpinSharedI3DFileInCache(filename)
	else
		Logging.error("I3DManager:unpinSharedI3DFileInCache - filename is nil")
		printCallstack()
	end
end

function I3DManager:clearEntireSharedI3DFileCache(verbose)
	if verbose == true then
		local numSharedI3ds = getNumOfSharedI3DFiles()

		Logging.devInfo("I3DManager: Deleting %s shared i3d files", numSharedI3ds)

		for i = 0, numSharedI3ds - 1 do
			local filename, numRefs = getSharedI3DFilesData(i)

			Logging.devWarning("    NumRef: %d - File: %s", numRefs, filename)
		end
	end

	Logging.devInfo("I3DManager: Deleted shared i3d files")
	clearEntireSharedI3DFileCache()
end

function I3DManager:setLoadingDelay(minDelaySeconds, maxDelaySeconds, minDelayCachedSeconds, maxDelayCachedSeconds)
	minDelaySeconds = minDelaySeconds or 0
	maxDelaySeconds = maxDelaySeconds or minDelaySeconds
	minDelayCachedSeconds = minDelayCachedSeconds or minDelaySeconds
	maxDelayCachedSeconds = maxDelayCachedSeconds or maxDelaySeconds

	setStreamI3DFileDelay(minDelaySeconds, maxDelaySeconds)
	setStreamSharedI3DFileDelay(minDelaySeconds, maxDelaySeconds, minDelayCachedSeconds, maxDelayCachedSeconds)
	Logging.info("Set new loading delay. MinDelay: %.2fs, MaxDelay: %.2fs, MinDelayCached: %.2fs, MaxDelayCached: %.2fs", minDelaySeconds, maxDelaySeconds, minDelayCachedSeconds, maxDelayCachedSeconds)
end

function I3DManager:consoleCommandSetLoadingDelay(minDelaySec, maxDelaySec, minDelayCachedSec, maxDelayCachedSec)
	minDelaySec = tonumber(minDelaySec) or 0
	maxDelaySec = tonumber(maxDelaySec) or minDelaySec
	minDelayCachedSec = tonumber(minDelayCachedSec) or minDelaySec
	maxDelayCachedSec = tonumber(maxDelayCachedSec) or maxDelaySec

	self:setLoadingDelay(minDelaySec, maxDelaySec, minDelayCachedSec, maxDelayCachedSec)
end

function I3DManager:consoleCommandShowCache(delay)
	I3DManager.showCache = not I3DManager.showCache
end

function I3DManager:consoleCommandPrintActiveLoadings()
	print("Non-Shared loading tasks:")

	local loadingRequestIds = getAllStreamI3DFileRequestIds()

	for k, loadingRequestId in ipairs(loadingRequestIds) do
		local progress, timeSec, filename, callback, target, args = getStreamI3DFileProgressInfo(loadingRequestId)
		local text = string.format("%03d: Progress: %s | Time %.3fs | File: %s | Callback: %s | Target: %s | Args: %s", k, progress, timeSec, filename, callback, tostring(target), tostring(args))

		print(text)
	end

	print("\n\n")
	print("Shared loading tasks:")

	local sharedLoadingRequestIds = getAllSharedI3DFileRequestIds()

	for k, sharedLoadingRequestId in ipairs(sharedLoadingRequestIds) do
		local progress, timeSec, filename, callback, target, args = getSharedI3DFileProgressInfo(sharedLoadingRequestId)
		local text = string.format("%03d: Progress: %s | Time %.3fs | File: %s | Callback: %s | Target: %s | Args: %s", k, progress, timeSec, filename, callback, tostring(target), tostring(args))

		print(text)
	end
end

g_i3DManager = I3DManager.new()

function I3DManager.addDebugLoadingCheck(name, checkFunc)
	table.insert(I3DManager.DEBUG_LOADING_CHECKS, {
		checkFunc = checkFunc,
		name = name
	})
end

function I3DManager:setupDebugLoading()
	print([[


  ##################   Warning: I3D-Manager Debug checks are active!   ##################

]])

	function I3DManager.checkRecursive(filename, node, delegate)
		local numMatches = 0

		if delegate(filename, node) then
			numMatches = numMatches + 1
		end

		for i = 0, getNumOfChildren(node) - 1 do
			numMatches = numMatches + I3DManager.checkRecursive(filename, getChildAt(node, i), delegate)
		end

		return numMatches
	end

	local oldLoadI3DFile = loadI3DFile

	function loadI3DFile(filename, ...)
		local nodeId, _, _ = oldLoadI3DFile(filename, ...)

		if nodeId > 0 then
			for _, data in ipairs(I3DManager.DEBUG_LOADING_CHECKS) do
				local numMatches = I3DManager.checkRecursive(filename, nodeId, data.checkFunc)

				if numMatches > 0 then
					Logging.devInfo("Finished '%s' check with %d matches for '%s'", data.name, numMatches, filename or "")
				end
			end
		end

		return nodeId
	end

	local oldLoadSharedI3dFile = loadSharedI3DFile

	function loadSharedI3DFile(filename, ...)
		local nodeId, sharedLoadRequestId, failedReason = oldLoadSharedI3dFile(filename, ...)

		if nodeId > 0 then
			for _, data in ipairs(I3DManager.DEBUG_LOADING_CHECKS) do
				local numMatches = I3DManager.checkRecursive(filename, nodeId, data.checkFunc)

				if numMatches > 0 then
					Logging.devInfo("Finished '%s' check with '%d' matches for '%s'", data.name, numMatches, filename or "")
				end
			end
		end

		return nodeId, sharedLoadRequestId, failedReason
	end

	local oldStreamI3DFile = streamI3DFile

	function streamI3DFile(filename, callbackFunc, target, params, ...)
		local newParams = {
			target = target,
			callbackFunc = callbackFunc,
			params = params,
			filename = filename
		}

		return oldStreamI3DFile(filename, "streamI3DCallback", nil, newParams, ...)
	end

	function streamI3DCallback(nodeId, failedReason, arguments)
		local target = arguments.target
		local callbackFunc = arguments.callbackFunc
		local params = arguments.params or {}

		if nodeId > 0 then
			for _, data in ipairs(I3DManager.DEBUG_LOADING_CHECKS) do
				local numMatches = I3DManager.checkRecursive(params[1] or "", nodeId, data.checkFunc)

				if numMatches > 0 then
					Logging.devInfo("Finished '%s' check with '%d' matches for '%s'", data.name, numMatches, arguments.filename or "")
				end
			end
		end

		target[callbackFunc](target, nodeId, failedReason, params)
	end

	local oldStreamSharedI3DFile = streamSharedI3DFile

	function streamSharedI3DFile(filename, callbackFunc, target, params, ...)
		local newParams = {
			target = target,
			callbackFunc = callbackFunc,
			params = params
		}

		return oldStreamSharedI3DFile(filename, "streamSharedI3DCallback", nil, newParams, ...)
	end

	function streamSharedI3DCallback(nodeId, failedReason, arguments)
		local target = arguments.target
		local callbackFunc = arguments.callbackFunc
		local params = arguments.params or {}

		if nodeId > 0 then
			for _, data in ipairs(I3DManager.DEBUG_LOADING_CHECKS) do
				local numMatches = I3DManager.checkRecursive(params[1] or "", nodeId, data.checkFunc)

				if numMatches > 0 then
					Logging.devWarning("Finished '%s' check with '%d' matches for '%s'", data.name, numMatches, params[1] or "")
				end
			end
		end

		target[callbackFunc](target, nodeId, failedReason, params)
	end
end

I3DManager.addDebugLoadingCheck("Directional-Lights", function (filename, node)
	if getHasClassId(node, ClassIds.LIGHT_SOURCE) and g_currentMission ~= nil and getLightType(node) == LightType.DIRECTIONAL and node ~= g_currentMission.environment.lighting.sunLightId then
		if getName(node) == "licensePlateCreationBoxLight" then
			return false
		end

		print(string.format("    Light-Check: Found directional light '%s'", I3DUtil.getNodePath(node)))

		return true
	end

	return false
end)
I3DManager.addDebugLoadingCheck("tip col properties", function (filename, node)
	local hasError = false

	if getHasClassId(node, ClassIds.SHAPE) then
		if string.contains(getName(node):upper(), "TIPCOL") then
			if not CollisionFlag.getHasFlagSet(node, CollisionFlag.GROUND_TIP_BLOCKING) then
				Logging.warning("tip col wrong mask %s", I3DUtil.getNodePath(node))

				hasError = true
			end

			if getRigidBodyType(node) ~= RigidBodyType.STATIC then
				Logging.warning("tip col not static %s", I3DUtil.getNodePath(node))

				hasError = true
			end
		elseif CollisionFlag.getHasFlagSet(node, CollisionFlag.GROUND_TIP_BLOCKING) and not string.contains(I3DUtil.getNodePath(node):upper(), "TIPCOL") then
			Logging.warning("node has tip col flag but is not named 'tipCollision' %s", I3DUtil.getNodePath(node))

			hasError = true
		end
	end

	return hasError
end)
I3DManager.addDebugLoadingCheck("LOD Checks", function (filename, node)
	local nodeName = getName(node)

	if string.contains(nodeName, "LOD") and (not getVisibility(node) or not getVisibility(getParent(node))) then
		Logging.warning("LOD not visisble - Node: %s", I3DUtil.getNodePath(node))

		return true
	end

	return false
end)
I3DManager.addDebugLoadingCheck("Occluder Checks", function (filename, node)
	local nodeName = getName(node)

	if getHasClassId(node, ClassIds.SHAPE) and (string.contains(nodeName:upper(), "OCCLUDER") or getIsOccluderMesh(node)) then
		local hasErrors = false

		if string.contains(nodeName:upper(), "OCCLUDER") and not getIsOccluderMesh(node) then
			Logging.warning("Mesh is named occluder but does not have the occluder mesh flag set - Node: %s", I3DUtil.getNodePath(node))

			hasErrors = true
		elseif not string.contains(nodeName:upper(), "OCCLUDER") and getIsOccluderMesh(node) then
			Logging.warning("Mesh has occluder flag set but is not named 'occluder' - Node: %s", I3DUtil.getNodePath(node))

			hasErrors = true
		end

		if not getVisibility(node) or not getVisibility(getParent(node)) then
			Logging.warning("Occluder mesh is not visible and will not function. Use 'non-renderable' flag for hiding instead - Node: %s", I3DUtil.getNodePath(node))

			hasErrors = true
		end

		local _, _, _, boundingRadius = getShapeBoundingSphere(node)

		if boundingRadius < 2 then
			Logging.warning("Occluder is very small , bounding radius %.3f - Node: %s", boundingRadius, I3DUtil.getNodePath(node))

			hasErrors = true
		end

		return hasErrors
	end

	return false
end)
