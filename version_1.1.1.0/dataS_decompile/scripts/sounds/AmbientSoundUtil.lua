AmbientSoundUtil = {
	onCreateSoundNode = function (_, id)
		Logging.warning("AmbientSoundUtil.onCreateSoundNode does not exist anymore. Use AudioSource and Visibility Conditions instead!")
	end,
	onCreateMovingSound = function (_, id)
		g_currentMission.ambientSoundSystem:addMovingSound(id)
	end
}
