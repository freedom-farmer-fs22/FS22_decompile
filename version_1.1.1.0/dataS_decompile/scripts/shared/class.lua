function Class(members, baseClass)
	members = members or {}
	local __index = members
	local mt = {
		__metatable = members,
		__index = __index
	}

	if baseClass ~= nil then
		setmetatable(members, {
			__index = baseClass
		})
	end

	local function new(_, init)
		return setmetatable(init or {}, mt)
	end

	local function copy(obj, ...)
		local newobj = obj.new(unpack(arg))

		for n, v in pairs(obj) do
			newobj[n] = v
		end

		return newobj
	end

	function members:class()
		return members
	end

	function members:superClass()
		return baseClass
	end

	function members:isa(other)
		local curClass = members

		while curClass ~= nil do
			if curClass == other then
				return true
			else
				curClass = curClass:superClass()
			end
		end

		return false
	end

	members.new = members.new or new
	members.copy = members.copy or copy

	return mt
end
