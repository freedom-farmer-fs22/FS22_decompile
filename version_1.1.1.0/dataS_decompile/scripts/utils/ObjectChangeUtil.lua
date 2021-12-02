ObjectChangeUtil = {}

function ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, objects, rootNode, parent)
	local i = 0

	while true do
		local nodeKey = string.format(key .. ".objectChange(%d)", i)

		if not xmlFile:hasProperty(nodeKey) then
			break
		end

		local i3dMappings = nil

		if parent ~= nil then
			i3dMappings = parent.i3dMappings
		end

		local node = xmlFile:getValue(nodeKey .. "#node", nil, rootNode, i3dMappings)

		if node ~= nil then
			local object = {
				node = node
			}

			ObjectChangeUtil.loadValuesFromXML(xmlFile, nodeKey, node, object, parent, rootNode, i3dMappings)
			table.insert(objects, object)
		end

		i = i + 1
	end
end

function ObjectChangeUtil.loadValueType(targetTable, xmlFile, key, name, getFunc, setFunc, interpolatable, ...)
	local entry = {
		active = xmlFile:getValue(key .. "#" .. name .. "Active", ...),
		inactive = xmlFile:getValue(key .. "#" .. name .. "Inactive", ...)
	}

	if entry.active ~= nil or entry.inactive ~= nil then
		entry.getFunc = getFunc
		entry.setFunc = setFunc

		if entry.active ~= nil and type(entry.active) ~= "table" then
			entry.active = {
				entry.active
			}
		end

		if entry.inactive ~= nil and type(entry.inactive) ~= "table" then
			entry.inactive = {
				entry.inactive
			}
		end

		entry.interpolatable = interpolatable
		entry.name = name

		table.insert(targetTable, entry)

		return entry
	end
end

function ObjectChangeUtil.loadValuesFromXML(xmlFile, key, node, object, parent, rootNode, i3dMappings)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "", key .. "#collisionActive", key .. "#compoundChildActive or #rigidBodyTypeActive")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "", key .. "#collisionInactive", key .. "#compoundChildInactive or #rigidBodyTypeInactive")

	object.parent = parent
	object.interpolation = xmlFile:getValue(key .. "#interpolation", false)
	object.interpolationTime = xmlFile:getValue(key .. "#interpolationTime", 1)
	object.values = {}
	local entry = ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "parentNode", nil, function (parentNode)
		local x, y, z = getWorldTranslation(node)
		local rx, ry, rz = getWorldRotation(node)

		link(parentNode, node)
		setWorldTranslation(node, x, y, z)
		setWorldRotation(node, rx, ry, rz)
	end, false, nil, rootNode, i3dMappings)

	if entry ~= nil then
		if entry.active == nil then
			entry.active = {
				getParent(object.node)
			}
		end

		if entry.inactive == nil then
			entry.inactive = {
				getParent(object.node)
			}
		end
	end

	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "translation", function ()
		return getTranslation(node)
	end, function (x, y, z)
		setTranslation(node, x, y, z)
	end, true, nil, true)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "rotation", function ()
		return getRotation(node)
	end, function (x, y, z)
		setRotation(node, x, y, z)
	end, true, nil, true)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "scale", function ()
		return getScale(node)
	end, function (x, y, z)
		setScale(node, x, y, z)
	end, true, nil, true)

	local shaderParameter = xmlFile:getValue(key .. "#shaderParameter")

	if shaderParameter ~= nil then
		if getHasShaderParameter(node, shaderParameter) then
			local sharedShaderParameter = xmlFile:getValue(key .. "#sharedShaderParameter", false)

			ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "shaderParameter", function ()
				return getShaderParameter(node, shaderParameter)
			end, function (x, y, z, w)
				setShaderParameter(node, shaderParameter, x, y, z, w, sharedShaderParameter)
			end, true, nil, true)
		else
			Logging.xmlWarning(xmlFile, "Missing shader parameter '%s' on object '%s' in '%s'", shaderParameter, getName(node), key)
		end
	end

	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "centerOfMass", function ()
		return getCenterOfMass(node)
	end, function (x, y, z)
		setCenterOfMass(node, x, y, z)
	end, true, nil, true)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "mass", function ()
		return getMass(node)
	end, function (value)
		setMass(node, value / 1000)

		if parent ~= nil and parent.components ~= nil then
			for _, component in ipairs(parent.components) do
				if component.node == object.node then
					component.defaultMass = object.massActive

					parent:setMassDirty()
				end
			end
		end
	end, true)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "visibility", nil, function (state)
		setVisibility(node, state)
	end, false)
	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "compoundChild", nil, function (state)
		setIsCompoundChild(node, state)
	end, false)

	local rigidBodyTypeActiveStr = xmlFile:getValue(key .. "#rigidBodyTypeActive")

	if rigidBodyTypeActiveStr ~= nil then
		object.rigidBodyTypeActive = RigidBodyType[rigidBodyTypeActiveStr:upper()]
		local t = object.rigidBodyTypeActive

		if t ~= RigidBodyType.STATIC and t ~= RigidBodyType.DYNAMIC and t ~= RigidBodyType.KINEMATIC and t ~= RigidBodyType.NONE then
			Logging.xmlWarning(xmlFile, "Invalid rigidBodyTypeActive '%s' for object change node '%s'. Use 'Static', 'Dynamic', 'Kinematic' or 'None'!", rigidBodyTypeActiveStr, key)

			object.rigidBodyTypeActive = nil
		end
	end

	local rigidBodyTypeInactiveStr = xmlFile:getValue(key .. "#rigidBodyTypeInactive")

	if rigidBodyTypeInactiveStr ~= nil then
		object.rigidBodyTypeInactive = RigidBodyType[rigidBodyTypeInactiveStr:upper()]
		local t = object.rigidBodyTypeInactive

		if t ~= RigidBodyType.STATIC and t ~= RigidBodyType.DYNAMIC and t ~= RigidBodyType.KINEMATIC and t ~= RigidBodyType.NONE then
			Logging.xmlWarning(xmlFile, "Invalid rigidBodyTypeInactive '%s' for object change node '%s'. Use 'Static', 'Dynamic', 'Kinematic' or 'None'!", rigidBodyTypeInactiveStr, key)

			object.rigidBodyTypeInactive = nil
		end
	end

	if parent ~= nil and parent.loadObjectChangeValuesFromXML ~= nil then
		parent:loadObjectChangeValuesFromXML(xmlFile, key, node, object)
	end
end

function ObjectChangeUtil.setObjectChanges(objects, isActive, target, updateFunc, skipInterpolation)
	if objects ~= nil then
		for _, object in pairs(objects) do
			ObjectChangeUtil.setObjectChange(object, isActive, target, updateFunc, skipInterpolation)
		end
	end
end

function ObjectChangeUtil.setObjectChange(object, isActive, target, updateFunc, skipInterpolation)
	if isActive then
		for i = 1, #object.values do
			local value = object.values[i]

			if value.active ~= nil then
				if object.interpolation and value.interpolatable and not skipInterpolation then
					local interpolator = ValueInterpolator.new(object.node .. value.name, value.getFunc, value.setFunc, value.active, object.interpolationTime)

					if interpolator ~= nil then
						interpolator:setUpdateFunc(updateFunc, target, object.node)
						interpolator:setDeleteListenerObject(target or object.parent)
					end
				else
					if skipInterpolation then
						ValueInterpolator.removeInterpolator(object.node .. value.name)
					end

					value.setFunc(unpack(value.active))
				end
			end
		end

		if object.rigidBodyTypeActive ~= nil then
			setRigidBodyType(object.node, object.rigidBodyTypeActive)
		end
	else
		for i = 1, #object.values do
			local value = object.values[i]

			if value.inactive ~= nil then
				if object.interpolation and value.interpolatable and not skipInterpolation then
					local interpolator = ValueInterpolator.new(object.node .. value.name, value.getFunc, value.setFunc, value.inactive, object.interpolationTime)

					if interpolator ~= nil then
						interpolator:setUpdateFunc(updateFunc, target, object.node)
						interpolator:setDeleteListenerObject(target or object.parent)
					end
				else
					if skipInterpolation then
						ValueInterpolator.removeInterpolator(object.node .. value.name)
					end

					value.setFunc(unpack(value.inactive))
				end
			end
		end

		if object.rigidBodyTypeInactive ~= nil then
			setRigidBodyType(object.node, object.rigidBodyTypeInactive)
		end
	end

	if target ~= nil then
		if target.setObjectChangeValues ~= nil then
			target:setObjectChangeValues(object, isActive)
		end

		if updateFunc ~= nil then
			updateFunc(target, object.node)
		end
	end
end

function ObjectChangeUtil.updateObjectChanges(xmlFile, key, configKey, rootNode, parent)
	local i = 0
	local activeI = configKey - 1

	while true do
		local objectChangeKey = string.format(key .. "(%d)", i)

		if not xmlFile:hasProperty(objectChangeKey) then
			break
		end

		if i ~= activeI then
			local objects = {}

			ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, objectChangeKey, objects, rootNode, parent)
			ObjectChangeUtil.setObjectChanges(objects, false, parent)
		end

		i = i + 1
	end

	if activeI < i then
		local objectChangeKey = string.format(key .. "(%d)", activeI)
		local objects = {}

		ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, objectChangeKey, objects, rootNode, parent)
		ObjectChangeUtil.setObjectChanges(objects, true, parent)
	end
end

function ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("ObjectChange_single", basePath)
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration()
end

function ObjectChangeUtil.registerObjectChangesXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("ObjectChange_multiple", basePath)
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath .. ".objectChanges")
	schema:setXMLSharedRegistration()
end

function ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
	schema:addDelayedRegistrationPath(basePath .. ".objectChange(?)", "ObjectChange")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectChange(?)#node", "Object change node")
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#interpolation", "Value will be interpolated", false)
	schema:register(XMLValueType.TIME, basePath .. ".objectChange(?)#interpolationTime", "Time for interpolation", 1)

	local positivStr = "%s if object change is active"
	local negativeStr = "%s if object change is in active"

	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#visibilityActive", string.format(positivStr, "visibility"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#visibilityInactive", string.format(negativeStr, "visibility"))
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".objectChange(?)#translationActive", string.format(positivStr, "translation"))
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".objectChange(?)#translationInactive", string.format(negativeStr, "translation"))
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".objectChange(?)#rotationActive", string.format(positivStr, "rotation"))
	schema:register(XMLValueType.VECTOR_ROT, basePath .. ".objectChange(?)#rotationInactive", string.format(negativeStr, "rotation"))
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".objectChange(?)#scaleActive", string.format(positivStr, "scale"))
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".objectChange(?)#scaleInactive", string.format(negativeStr, "scale"))
	schema:register(XMLValueType.STRING, basePath .. ".objectChange(?)#shaderParameter", "Shader parameter name")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".objectChange(?)#shaderParameterActive", string.format(positivStr, "shaderParameter"))
	schema:register(XMLValueType.VECTOR_4, basePath .. ".objectChange(?)#shaderParameterInactive", string.format(negativeStr, "shaderParameter"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#sharedShaderParameter", "Shader parameter is applied on all objects with the same material", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".objectChange(?)#massActive", string.format(positivStr, "mass"))
	schema:register(XMLValueType.FLOAT, basePath .. ".objectChange(?)#massInactive", string.format(negativeStr, "mass"))
	schema:register(XMLValueType.VECTOR_3, basePath .. ".objectChange(?)#centerOfMassActive", string.format(positivStr, "center of mass"))
	schema:register(XMLValueType.VECTOR_3, basePath .. ".objectChange(?)#centerOfMassInactive", string.format(negativeStr, "center of mass"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#compoundChildActive", string.format(positivStr, "compound child state"))
	schema:register(XMLValueType.BOOL, basePath .. ".objectChange(?)#compoundChildInactive", string.format(negativeStr, "compound child state"))
	schema:register(XMLValueType.STRING, basePath .. ".objectChange(?)#rigidBodyTypeActive", string.format(positivStr, "rigid body type"))
	schema:register(XMLValueType.STRING, basePath .. ".objectChange(?)#rigidBodyTypeInactive", string.format(negativeStr, "rigid body type"))
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectChange(?)#parentNodeActive", string.format(positivStr, "parent node"))
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".objectChange(?)#parentNodeInactive", string.format(negativeStr, "parent node"))
end

function ObjectChangeUtil.addAdditionalObjectChangeXMLPaths(schema, func)
	schema:addDelayedRegistrationFunc("ObjectChange", func)
end
