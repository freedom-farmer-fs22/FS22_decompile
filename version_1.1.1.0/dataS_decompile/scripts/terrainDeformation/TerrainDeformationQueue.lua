TerrainDeformationQueue = {}
local TerrainDeformationQueue_mt = Class(TerrainDeformationQueue)

function TerrainDeformationQueue.new()
	local self = {}

	setmetatable(self, TerrainDeformationQueue_mt)

	self.jobQueue = {}
	self.currentJob = nil
	self.cancelling = false

	return self
end

function TerrainDeformationQueue:queueJob(deformer, previewOnly, callbackFunc, callbackObject)
	local job = {
		deformer = deformer,
		previewOnly = previewOnly,
		callbackFunc = callbackFunc,
		callbackObject = callbackObject
	}

	table.insert(self.jobQueue, job)
	self:tryRunJob()
end

function TerrainDeformationQueue:tryRunJob()
	if not self.currentJob and self.jobQueue[1] then
		self.currentJob = self.jobQueue[1]

		table.remove(self.jobQueue, 1)

		if self.currentJob.deformer then
			self.currentJob.deformer:apply(self.currentJob.previewOnly, "onJobComplete", self)
		else
			self:onJobComplete(TerrainDeformation.STATE_SUCCESS, 0, "")
		end
	end
end

function TerrainDeformationQueue:onJobComplete(errorCode, displacedVolume, blockedObjectName)
	if self.currentJob.callbackObject then
		self.currentJob.callbackObject[self.currentJob.callbackFunc](self.currentJob.callbackObject, errorCode, displacedVolume, blockedObjectName)
	else
		_G[self.currentJob.callbackFunc](errorCode, displacedVolume, blockedObjectName)
	end

	self.currentJob = nil

	if not self.cancelling then
		self:tryRunJob()
	end
end

function TerrainDeformationQueue:cancelAllJobs()
	self.cancelling = true

	if self.currentJob then
		self.currentJob.deformer:cancel()
	end

	while self.jobQueue[1] do
		self.currentJob = self.jobQueue[1]

		table.remove(self.jobQueue, 1)
		self:onJobComplete(TerrainDeformation.STATE_CANCELLED, 0, "")
	end

	self.currentJob = nil
	self.cancelling = false
end

g_terrainDeformationQueue = TerrainDeformationQueue.new()
