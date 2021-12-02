StartParams = {}
local params = {}

function StartParams.init(args)
	local argValues = args:split(" ")
	local currentKey = "exe"

	for _, arg in pairs(argValues) do
		if arg:startsWith("-") then
			currentKey = string.sub(arg, 2)
			params[currentKey] = ""
		else
			if params[currentKey] == nil then
				params[currentKey] = ""
			end

			if params[currentKey] ~= "" then
				params[currentKey] = params[currentKey] .. " "
			end

			params[currentKey] = params[currentKey] .. arg
		end
	end

	StartParams.printAll()
end

function StartParams.getValue(name)
	return params[name]
end

function StartParams.getIsSet(name)
	return params[name] ~= nil
end

function StartParams.printAll()
	log("Used Start Parameters:")

	for name, value in pairs(params) do
		log("  ", name, value)
	end
end
