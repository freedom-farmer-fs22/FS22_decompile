GuiSoundPlayer = {}
local GuiSoundPlayer_mt = Class(GuiSoundPlayer)
GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_PATH = "dataS/gui/guiSoundSamples.xml"
GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_XML_ROOT = "GuiSoundSamples"
GuiSoundPlayer.NUM_SAMPLES_PER_SOUND = 3
GuiSoundPlayer.SAMPLE_REPLAY_TIMEOUT = 25
GuiSoundPlayer.SOUND_SAMPLES = {
	SUCCESS = "success",
	BACK = "back",
	TEXTBOX = "textbox",
	NO = "no",
	HOVER = "hover",
	CLICK = "click",
	CONFIG_WRENCH = "configWrench",
	SELECT = "select",
	ERROR = "error",
	ACHIEVEMENT = "achievement",
	QUERY = "query",
	FAIL = "fail",
	PAGING = "paging",
	NOTIFICATION = "notification",
	CONFIG_SPRAY = "configSpray",
	YES = "yes",
	TRANSACTION = "transaction",
	NONE = ""
}

function GuiSoundPlayer.new(soundManager)
	local self = setmetatable({}, GuiSoundPlayer_mt)
	self.soundManager = soundManager
	self.soundSamples = self:loadSounds(GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_PATH)

	return self
end

function GuiSoundPlayer:delete()
	for _, samples in pairs(self.soundSamples) do
		for _, sample in ipairs(samples) do
			self.soundManager:deleteSample(sample)
		end
	end

	self.soundSamples = {}
end

function GuiSoundPlayer:loadSounds(sampleDefinitionXmlPath)
	local samples = {}
	local xmlFile = loadXMLFile("GuiSampleDefinitions", sampleDefinitionXmlPath)

	if xmlFile ~= nil and xmlFile ~= 0 then
		for _, key in pairs(GuiSoundPlayer.SOUND_SAMPLES) do
			if key ~= GuiSoundPlayer.SOUND_SAMPLES.NONE then
				local sample = self.soundManager:loadSample2DFromXML(xmlFile, GuiSoundPlayer.SOUND_SAMPLE_DEFINITIONS_XML_ROOT, key, "", 1, AudioGroup.GUI)

				if sample ~= nil then
					local sampleList = {}
					samples[key] = sampleList

					table.insert(sampleList, sample)

					for i = 2, GuiSoundPlayer.NUM_SAMPLES_PER_SOUND do
						table.insert(sampleList, self.soundManager:cloneSample2D(sample))
					end
				else
					print("Warning: Could not load GUI sound sample [" .. tostring(key) .. "]")
				end
			end
		end

		delete(xmlFile)
	end

	return samples
end

function GuiSoundPlayer:playSample(sampleName)
	if sampleName == GuiSoundPlayer.SOUND_SAMPLES.NONE then
		return
	end

	local sampleList = self.soundSamples[sampleName]

	if sampleList ~= nil then
		if sampleList.lastTime ~= nil and g_time - sampleList.lastTime < GuiSoundPlayer.SAMPLE_REPLAY_TIMEOUT then
			return
		end

		local sample = nil

		for i = 1, #sampleList do
			if not self.soundManager:getIsSamplePlaying(sampleList[i]) then
				sample = sampleList[i]

				break
			end
		end

		if sample ~= nil then
			self.soundManager:playSample(sample)

			sampleList.lastTime = g_time
		end
	else
		print("Warning: Tried playing GUI sample [" .. tostring(sampleName) .. "] which has not been loaded.")
	end
end
