AsyncTaskManager = {}
local AsyncTaskManager_mt = Class(AsyncTaskManager)

function AsyncTaskManager.new(customMt)
	local self = setmetatable({}, customMt or AsyncTaskManager_mt)

	self:initDataStructures()

	return self
end

function AsyncTaskManager:initDataStructures()
	self.firstTask = nil
	self.lastTask = nil
	self.currentRunningTask = nil
	self.enabled = true
	self.doTracing = false
	self.executeSubTasksImmediately = self.doTracing and false
	self.allowedTimeMsPerFrame = nil
end

function AsyncTaskManager:runLambda(lambda)
	if self.doTracing then
		traceOn(2)
		lambda()
		traceOff()
	else
		lambda()
	end
end

function AsyncTaskManager:addTask(lambda)
	if not self.enabled then
		self:runLambda(lambda)
	else
		local taskCb = {
			lambda = lambda,
			nextTask = nil,
			firstSubTask = nil,
			lastSubTask = nil
		}

		if self.currentRunningTask == nil then
			if self.doTracing then
				print("Deferred a lambda")
			end

			if self.firstTask == nil then
				self.firstTask = taskCb
				self.lastTask = taskCb
			else
				self.lastTask.nextTask = taskCb
				self.lastTask = taskCb
			end
		else
			if self.doTracing then
				print("Queued a sub-lambda")
			end

			if self.currentRunningTask.firstSubTask == nil then
				self.currentRunningTask.firstSubTask = taskCb
				self.currentRunningTask.lastSubTask = taskCb
			else
				self.currentRunningTask.lastSubTask.nextTask = taskCb
				self.currentRunningTask.lastSubTask = taskCb
			end
		end
	end
end

function AsyncTaskManager:addSubtask(lambda)
	if self.executeSubTasksImmediately then
		self:runLambda(lambda)
	elseif not self.enabled or self.currentRunningTask == nil then
		if self.enabled then
			print("Warning: addSubtask is *not* queuing the task, because not inside a task")
			printCallstack()
		end

		self:runLambda(lambda)
	else
		self:addTask(lambda)
	end
end

function AsyncTaskManager:hasTasks()
	return self.firstTask ~= nil
end

function AsyncTaskManager:flushAllTasks()
	self:initDataStructures()
	forceEndFrameRepeatMode()
end

function AsyncTaskManager:runTopTask()
	if self.firstTask ~= nil then
		local taskCb = self.firstTask
		self.firstTask = taskCb.nextTask

		if self.firstTask == nil then
			self.lastTask = nil
		end

		self.currentRunningTask = taskCb

		self:runLambda(taskCb.lambda)

		self.currentRunningTask = nil

		if taskCb.firstSubTask ~= nil then
			taskCb.lastSubTask.nextTask = self.firstTask
			self.firstTask = taskCb.firstSubTask

			if self.lastTask == nil then
				self.lastTask = taskCb.lastSubTask
			end
		end

		return true
	else
		return false
	end
end

function AsyncTaskManager:update(dt)
	if self:hasTasks() then
		local timer = openIntervalTimer()

		if timer == -1 then
			self:runTopTask()
		else
			local cnt = 0

			while self:hasTasks() do
				self:runTopTask()

				cnt = cnt + 1

				if self.allowedTimeMsPerFrame == nil or self.allowedTimeMsPerFrame < readIntervalTimerMs(timer) then
					break
				end
			end

			local finalTime = readIntervalTimerMs(timer)

			if finalTime > 1000 then
				Logging.devWarning("deferred loading task ran to %d ms", finalTime)
			end

			closeIntervalTimer(timer)
		end
	end
end

function AsyncTaskManager:setAllowedTimePerFrame(timePerFrameMs)
	self.allowedTimeMsPerFrame = timePerFrameMs
end

g_asyncTaskManager = AsyncTaskManager.new()
