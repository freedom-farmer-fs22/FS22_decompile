g_globalsNameCheckDisabled = false
local allowlist = {
	modOnCreate = true,
	masterServerConnectFront = true,
	masterServerAddServerMod = true,
	debug = true,
	masterServerRequestConnectionToServer = true,
	netConnect = true,
	io = true,
	masterServerAddServerModEnd = true,
	masterServerAddServer = true,
	masterServerConnectBack = true,
	masterServerAddServerModStart = true
}

setmetatable(_G, {
	__newindex = function (t, key, value)
		if not g_globalsNameCheckDisabled and type(key) == "string" and type(value) ~= "function" and allowlist[key] == nil then
			local first = string.byte(key:sub(1, 1))

			if key:sub(1, 2) ~= "g_" and (first < string.byte("A") or string.byte("Z") < first) then
				print("Warning: Global variable name does not match naming convention: " .. key)
				printCallstack()
			end
		end

		rawset(t, key, value)
	end
})
print([[


  ##################   Warning: Globals name check active!   ##################

]])
