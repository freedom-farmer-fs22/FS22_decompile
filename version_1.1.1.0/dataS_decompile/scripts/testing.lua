g_currentTest = nil
local tests = {
	TestAnimalCluster = {
		className = "TestAnimalCluster",
		filename = "dataS/scripts/animals/husbandry/cluster/TestAnimalCluster.lua"
	},
	TestI3DManager = {
		className = "TestI3DManager",
		filename = "dataS/scripts/i3d/TestI3DManager.lua"
	}
}

function initTesting()
	local testName = StartParams.getValue("test")

	if testName ~= nil then
		local data = tests[testName]

		if data ~= nil then
			source(data.filename)

			g_currentTest = ClassUtil.getClassObject(data.className)

			if g_currentTest ~= nil then
				g_currentTest.init()
				Logging.info("Started test '%s'", testName)

				return true
			else
				Logging.error("Test '%s' not defined", testName)
			end
		end
	end

	return false
end
