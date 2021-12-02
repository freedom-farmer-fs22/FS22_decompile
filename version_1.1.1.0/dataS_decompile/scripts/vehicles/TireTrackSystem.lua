TireTrackSystem = {}
local TireTrackSystem_mt = Class(TireTrackSystem)
TireTrackSystem.maxNumTracks = 512
TireTrackSystem.maxNumSegments = 4096

function TireTrackSystem.onCreateTireTrackSystem(_, id)
	if g_currentMission.tireTrackSystem ~= nil then
		return
	end

	local tireTrackSystem = TireTrackSystem.new()

	if tireTrackSystem:load(id) then
		g_currentMission.tireTrackSystem = tireTrackSystem
	else
		tireTrackSystem:delete()
	end
end

function TireTrackSystem.new(mt)
	local self = setmetatable({}, mt or TireTrackSystem_mt)
	self.systemId = 0

	return self
end

function TireTrackSystem:load(id)
	self.systemId = createTyreTrackSystem(getRootNode(0), id, TireTrackSystem.maxNumTracks, TireTrackSystem.maxNumSegments)

	if g_addTestCommands then
		addConsoleCommand("gsTireTracksRemoveAll", "Remove all tire tracks from terrain", "TireTrackSystem.consoleCommandRemoveAllTireTracks", nil)
	end

	if self.systemId ~= 0 then
		return true
	end

	return false
end

function TireTrackSystem:delete()
	if self.systemId ~= 0 then
		delete(self.systemId)
	end

	removeConsoleCommand("gsTireTracksRemoveAll")
end

function TireTrackSystem:createTrack(width, atlasIndex)
	return createTrack(self.systemId, width, atlasIndex)
end

function TireTrackSystem:destroyTrack(id)
	destroyTrack(self.systemId, id)
end

function TireTrackSystem:addTrackPoint(id, x, y, z, ux, uy, uz, r, g, b, a, uw, dtheta)
	addTrackPoint(self.systemId, id, x, y, z, ux, uy, uz, r, g, b, a, uw, dtheta)
end

function TireTrackSystem:cutTrack(id)
	cutTrack(self.systemId, id)
end

function TireTrackSystem:eraseParallelogram(x0, z0, dx1, dz1, dx2, dz2)
	eraseParallelogram(self.systemId, x0, z0, dx1, dz1, dx2, dz2)
end

function TireTrackSystem:consoleCommandRemoveAllTireTracks()
	if g_currentMission.tireTrackSystem ~= nil then
		local halfSize = g_currentMission.terrainSize / 2 + 1

		g_currentMission.tireTrackSystem:eraseParallelogram(-halfSize, -halfSize, halfSize, -halfSize, -halfSize, halfSize)

		return "Removed all tiretracks!"
	end

	return "Error: no tireTrackSystem found!"
end
