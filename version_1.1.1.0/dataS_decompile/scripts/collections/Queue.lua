Queue = {}
local Queue_mt = Class(Queue)

function Queue.new()
	local self = setmetatable({}, Queue_mt)
	self.size = 0
	self.first = nil
	self.last = nil

	return self
end

function Queue:delete()
end

function Queue:push(value)
	if self.last then
		self.last._next = value
		value._prev = self.last
		self.last = value
	else
		self.first = value
		self.last = value
	end

	self.size = self.size + 1
end

function Queue:pop()
	if not self.first then
		return
	end

	local value = self.first

	if value._next then
		value._next._prev = nil
		self.first = value._next
		value._next = nil
	else
		self.first = nil
		self.last = nil
	end

	self.size = self.size - 1

	return value
end

function Queue:remove(value)
	if value._next then
		if value._prev then
			value._next._prev = value._prev
			value._prev._next = value._next
		else
			value._next._prev = nil
			self.first = value._next
		end
	elseif value._prev then
		value._prev._next = nil
		self.last = value._prev
	else
		self.first = nil
		self.last = nil
	end

	if mutateIterating ~= true then
		value._next = nil
		value._prev = nil
	end

	self.size = self.size - 1
end

function Queue:isEmpty()
	return self.first == nil
end

function Queue:iteratePushOrder(func)
	local i = 1
	local item = self.first

	while item ~= nil do
		if func(item, i) == true then
			break
		end

		i = i + 1
		item = item._next
	end
end

function Queue:iteratePopOrder(func)
	local i = 1
	local item = self.last

	while item ~= nil do
		if func(item, i) == true then
			break
		end

		i = i + 1
		item = item._prev
	end
end
