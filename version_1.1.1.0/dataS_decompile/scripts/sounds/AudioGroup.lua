AudioGroup = {
	groups = {}
}

function AudioGroup.getAudioGroupIndexByName(name)
	if name ~= nil then
		name = name:upper()

		return AudioGroup[name]
	end

	return nil
end

function AudioGroup.getAudioGroupNameByIndex(index)
	if index ~= nil then
		for name, id in pairs(AudioGroup) do
			if index == id then
				return name
			end
		end
	end

	return nil
end

function AudioGroup.getIsValidAudioGroup(audioGroupIndex)
	for _, index in pairs(AudioGroup) do
		if index == audioGroupIndex then
			return true
		end
	end

	return false
end

function AudioGroup.registerAudioGroup(name)
	name = name:upper()

	if AudioGroup[name] == nil then
		AudioGroup[name] = #AudioGroup.groups + 1

		table.insert(AudioGroup.groups, AudioGroup[name])
	end
end

AudioGroup.registerAudioGroup("DEFAULT")
AudioGroup.registerAudioGroup("VEHICLE")
AudioGroup.registerAudioGroup("ENVIRONMENT")
AudioGroup.registerAudioGroup("RADIO")
AudioGroup.registerAudioGroup("MENU_MUSIC")
AudioGroup.registerAudioGroup("GUI")
