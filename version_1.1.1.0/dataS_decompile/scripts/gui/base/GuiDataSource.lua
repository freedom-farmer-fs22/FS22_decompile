GuiDataSource = {}
local GuiDataSource_mt = Class(GuiDataSource)
local NO_DATA = {}

local function NO_CALLBACK()
end

function GuiDataSource.new(subclass_mt)
	local self = setmetatable({}, subclass_mt or GuiDataSource_mt)
	self.data = NO_DATA
	self.changeListeners = {}

	return self
end

function GuiDataSource:setData(data)
	self.data = data or NO_DATA

	self:notifyChange()
end

function GuiDataSource:addChangeListener(target, callback)
	self.changeListeners[target] = callback or NO_CALLBACK
end

function GuiDataSource:removeChangeListener(target)
	self.changeListeners[target] = nil
end

function GuiDataSource:notifyChange()
	for target, callback in pairs(self.changeListeners) do
		callback(target)
	end
end

function GuiDataSource:getCount()
	return #self.data
end

function GuiDataSource:getItem(index)
	return self.data[index]
end

function GuiDataSource:setItem(index, value, needsNotification)
	if index > 0 and index <= #self.data then
		self.data[index] = value

		if needsNotification then
			self:notifyChange()
		end
	end
end

function GuiDataSource:iterateRange(startIndex, endIndex)
	local function iterator(data, iter)
		local item = data[iter]

		if iter <= endIndex and item ~= nil then
			return iter + 1, item
		else
			return nil, 
		end
	end

	return iterator, self.data, startIndex
end

GuiDataSource.EMPTY_SOURCE = GuiDataSource.new()
