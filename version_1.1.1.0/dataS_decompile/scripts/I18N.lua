I18N = {}
local I18N_mt = Class(I18N)
I18N.MONEY_MAX_DISPLAY_VALUE = 999999999
I18N.MONEY_MIN_DISPLAY_VALUE = -999999999

function I18N.new()
	local self = {}

	setmetatable(self, I18N_mt)

	self.texts = {}
	self.modEnvironments = {}

	if g_addTestCommands then
		addConsoleCommand("gsI18nVerify", "Checks all localization files for empty or 'TODO' texts, warns if placeholders mismatch between languages", "consoleCommandVerifyAll", self)
	end

	self.debugActive = StartParams.getIsSet("debugI18N")

	if self.debugActive then
		print("debugI18N active")

		self.usedTexts = {}
		self.printedWarnings = {}

		self:loadUsedKeysFromXML()
		addConsoleCommand("gsI18nSaveUsedKeysXml", "", "saveUsedKeysToXML", self)
		g_messageCenter:subscribe(MessageType.GUI_INGAME_OPEN, self.saveUsedKeysToXML, self)
		g_messageCenter:subscribe(MessageType.GUI_MAIN_SCREEN_OPEN, self.saveUsedKeysToXML, self)
	end

	return self
end

function I18N:load()
	self.texts = {}
	local baseXMLFile = nil

	if not g_isDevelopmentVersion and g_languageShort ~= "en" then
		baseXMLFile = loadXMLFile("l10n_en", "dataS/l10n_en.xml")
	end

	local xmlFile = loadXMLFile("l10n" .. g_languageSuffix, "dataS/l10n" .. g_languageSuffix .. ".xml")

	self:loadEntriesFromXML(xmlFile, baseXMLFile, "l10n.elements.e(%d)", self.texts, true)

	if baseXMLFile ~= nil then
		delete(baseXMLFile)
	end

	self.fluidFactor = Utils.getNoNil(getXMLFloat(xmlFile, "l10n.fluid#factor"), 1)
	self.powerFactorHP = Utils.getNoNil(getXMLFloat(xmlFile, "l10n.power#factor"), 1)
	self.powerFactorKW = 0.735499
	self.moneyUnit = GS_MONEY_EURO
	self.useMiles = false
	self.useFahrenheit = false
	self.useAcre = false
	self.thousandsGroupingChar = self:getText("unit_digitGroupingSymbol")

	if self.thousandsGroupingChar ~= " " and self.thousandsGroupingChar ~= "." and self.thousandsGroupingChar ~= "," then
		self.thousandsGroupingChar = " "
	end

	self.decimalSeparator = Utils.getNoNil(self:getText("unit_decimalSymbol"), ".")

	if g_gameSettings ~= nil then
		self.moneyUnit = g_gameSettings:getValue("moneyUnit")
		self.useMiles = g_gameSettings:getValue("useMiles")
	end

	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.setMoneyUnit, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_MILES], self.setUseMiles, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_ACRE], self.setUseAcre, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.setUseFahrenheit, self)
	delete(xmlFile)
end

function I18N:loadEntriesFromXML(xmlFile, baseXMLFile, keyFormat, outputEntries, overwriteExistingText)
	if baseXMLFile ~= nil then
		local textI = 0

		while true do
			local key = string.format(keyFormat, textI)

			if not hasXMLProperty(baseXMLFile, key) then
				break
			end

			local name = getXMLString(baseXMLFile, key .. "#k")
			local text = getXMLString(baseXMLFile, key .. "#v")

			if name ~= nil and text ~= nil then
				outputEntries[name] = text:gsub("\r\n", "\n")
			end

			textI = textI + 1
		end
	end

	local textI = 0

	while true do
		local key = string.format(keyFormat, textI)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#k")
		local text = getXMLString(xmlFile, key .. "#v")

		if name ~= nil and text ~= nil and (baseXMLFile == nil or text ~= "TODO") then
			outputEntries[name] = text:gsub("\r\n", "\n")
		end

		textI = textI + 1
	end

	for key, text in pairs(outputEntries) do
		if GS_PLATFORM_PLAYSTATION then
			if GS_PLATFORM_ID == PlatformId.PS4 and outputEntries[key .. "_ps4"] ~= nil then
				outputEntries[key] = outputEntries[key .. "_ps4"]
			elseif GS_PLATFORM_ID == PlatformId.PS5 and outputEntries[key .. "_ps5"] ~= nil then
				outputEntries[key] = outputEntries[key .. "_ps5"]
			elseif outputEntries[key .. "_ps"] then
				outputEntries[key] = outputEntries[key .. "_ps"]
			end
		elseif GS_PLATFORM_XBOX then
			if GS_PLATFORM_ID == PlatformId.XBOX_ONE and outputEntries[key .. "_xboxone"] ~= nil then
				outputEntries[key] = outputEntries[key .. "_xboxone"]
			elseif GS_PLATFORM_ID == PlatformId.XBOX_SERIES and outputEntries[key .. "_xboxseries"] ~= nil then
				outputEntries[key] = outputEntries[key .. "_xboxseries"]
			elseif outputEntries[key .. "_xbox"] ~= nil then
				outputEntries[key] = outputEntries[key .. "_xbox"]
			end
		elseif GS_PLATFORM_GGP then
			if outputEntries[key .. "_ggp"] ~= nil then
				outputEntries[key] = outputEntries[key .. "_ggp"]
			end
		elseif GS_PLATFORM_SWITCH then
			if outputEntries[key .. "_switch"] ~= nil then
				outputEntries[key] = outputEntries[key .. "_switch"]
			elseif outputEntries[key .. "_mobile"] ~= nil then
				outputEntries[key] = outputEntries[key .. "_mobile"]
			end
		elseif GS_IS_MOBILE_VERSION and outputEntries[key .. "_mobile"] ~= nil then
			outputEntries[key] = outputEntries[key .. "_mobile"]
		end

		if outputEntries[key] ~= text then
			Logging.devInfo("I18N platform specific text %s: '%s'", key, outputEntries[key])
		end
	end
end

function I18N:saveUsedKeysToXML()
	local fileName = getUserProfileAppPath() .. "l10n_usedKeys.xml"
	local xmlFile = createXMLFile("l10n_usedKeys", fileName, "l10n")
	local usedCount = 0

	for key in pairs(self.usedTexts) do
		setXMLString(xmlFile, string.format("l10n.used(%d)#k", usedCount), key)

		usedCount = usedCount + 1
	end

	saveXMLFile(xmlFile)
	delete(xmlFile)

	local textsCount = table.size(self.texts)
	local unusedCount = textsCount - usedCount

	print(string.format("I18N debug: saved '%s': %i unused, %i used, %i total keys ", fileName, unusedCount, usedCount, textsCount))
end

function I18N:loadUsedKeysFromXML()
	local fileName = getUserProfileAppPath() .. "l10n_usedKeys.xml"
	local xmlFile = XMLFile.loadIfExists("l10n_usedKeys", fileName)

	if xmlFile then
		xmlFile:iterate("l10n.used", function (_, key)
			self.usedTexts[xmlFile:getString(key .. "#k")] = true
		end)
		print(string.format("I18N debug: loaded '%s': %i used keys ", fileName, table.size(self.usedTexts)))
		xmlFile:delete()
	else
		Logging.xmlDevWarning("I18N debug: Unable to load used loca keys file %s", fileName)
	end
end

function I18N:addModI18N(modName)
	local modi18n = {
		texts = {}
	}

	setmetatable(modi18n, {
		__index = self
	})
	setmetatable(modi18n.texts, {
		__index = self.texts
	})

	self.modEnvironments[modName] = modi18n

	function modi18n.setText(i18nInstance, name, value)
		i18nInstance.texts[name] = value
	end

	function modi18n.hasModText(i18nInstance, name)
		return i18nInstance.texts[name] ~= nil
	end

	return modi18n
end

function I18N:getText(name, customEnv)
	local ret = nil

	if customEnv ~= nil then
		local modEnv = self.modEnvironments[customEnv]

		if modEnv ~= nil then
			ret = modEnv.texts[name]
		end
	end

	if ret == nil then
		ret = self.texts[name]

		if ret == nil then
			ret = string.format("Missing '%s' in l10n%s.xml", name, g_languageSuffix)

			if g_showDevelopmentWarnings then
				Logging.devWarning(ret)
			end
		end
	end

	if self.debugActive then
		self.usedTexts[name] = true
	end

	if ret:upper():trim() == "TODO" then
		if self.debugActive and self.printedWarnings[name] == nil then
			Logging.devWarning("TODO:" .. name)

			self.printedWarnings[name] = true
		end

		return "TODO:" .. name
	end

	return ret
end

function I18N:hasText(name, customEnv)
	if name == nil then
		return false
	end

	local ret = nil

	if customEnv ~= nil then
		local modEnv = self.modEnvironments[customEnv]

		if modEnv ~= nil then
			ret = modEnv.texts[name]
		end
	end

	if ret == nil then
		ret = self.texts[name]
	end

	return ret ~= nil
end

function I18N:setText(name, value)
	self.texts[name] = value
end

function I18N:setMoneyUnit(unit)
	self.moneyUnit = unit
end

function I18N:setUseMiles(useMiles)
	self.useMiles = useMiles
end

function I18N:setUseFahrenheit(useFahrenheit)
	self.useFahrenheit = useFahrenheit
end

function I18N:setUseAcre(useAcre)
	self.useAcre = useAcre
end

function I18N:getCurrency(currency)
	return currency * self:getCurrencyFactor()
end

function I18N:getCurrencyFactor()
	if self.moneyUnit == GS_MONEY_EURO then
		return 1
	elseif self.moneyUnit == GS_MONEY_POUND then
		return 0.79
	else
		return 1.34
	end
end

function I18N:getMeasuringUnit(useLongName)
	local postfix = "Short"

	if useLongName then
		postfix = ""
	end

	if self.useMiles then
		return self.texts["unit_miles" .. postfix]
	end

	return self.texts["unit_km" .. postfix]
end

function I18N:getVolumeUnit(useLongName)
	local postfix = not useLongName and "Short" or ""

	return self.texts["unit_liter" .. postfix]
end

function I18N:getVolume(liters)
	return liters
end

function I18N:getSpeedMeasuringUnit()
	if self.useMiles then
		return self.texts.unit_mph
	end

	return self.texts.unit_kmh
end

function I18N:getSpeed(speed)
	if self.useMiles then
		return speed * 0.62137
	end

	return speed
end

function I18N:getTemperature(temperature)
	if self.useFahrenheit then
		return temperature * 1.8 + 32
	end

	return temperature
end

function I18N:formatTemperature(temperatureCelsius, precision, useLongName)
	local temperature = self:getTemperature(temperatureCelsius)
	local str = self:getTemperatureUnit(useLongName)

	return string.format("%1." .. (precision or 0) .. "f%s", temperature, str)
end

function I18N:getTemperatureUnit(useLongName)
	local postfix = "Short"

	if useLongName then
		postfix = ""
	end

	if self.useFahrenheit then
		return self.texts["unit_fahrenheit" .. postfix]
	end

	return self.texts["unit_celsius" .. postfix]
end

function I18N:getAreaUnit(useLongName)
	local postfix = "Short"

	if useLongName then
		postfix = ""
	end

	if self.useAcre then
		return self.texts["unit_acre" .. postfix]
	end

	return self.texts["unit_ha" .. postfix]
end

function I18N:getArea(ha)
	if self.useAcre then
		return ha * 2.4711
	end

	return ha
end

function I18N:formatArea(areaInHa, precision, useLongName)
	local area = self:getArea(areaInHa)
	local str = self:getAreaUnit(useLongName)

	return tostring(MathUtil.round(area, precision) .. str)
end

function I18N:getDistance(distance)
	if self.useMiles then
		return distance * 0.62137
	end

	return distance
end

function I18N:getFluid(fluid)
	return fluid * self.fluidFactor
end

function I18N:formatFluid(liters)
	return string.format("%s %s", self:formatNumber(self:getFluid(liters)), g_i18n:getText("unit_literShort"))
end

function I18N:formatVolume(liters, precision, unit)
	return string.format("%s %s", self:formatNumber(self:getVolume(liters), precision), unit or self:getVolumeUnit())
end

function I18N:formatMass(mass, maxMass, showKg)
	local unit = "unit_tonsShort"
	local precision = 1

	if showKg ~= false then
		if mass < 1 and (maxMass == nil or maxMass == 0) then
			unit = "unit_kg"
			mass = mass * 1000
			precision = 0
		elseif mass < 1 and maxMass ~= nil and maxMass ~= 0 then
			unit = "unit_kg"
			mass = mass * 1000
			maxMass = maxMass * 1000
			precision = 0
		end
	end

	if maxMass ~= nil and maxMass ~= 0 then
		return string.format("%s-%s %s", self:formatNumber(MathUtil.round(mass, precision), precision), self:formatNumber(MathUtil.round(maxMass, precision), precision), g_i18n:getText(unit))
	else
		return string.format("%s %s", self:formatNumber(MathUtil.round(mass, precision), precision), g_i18n:getText(unit))
	end
end

function I18N:getPower(power)
	return power * self.powerFactorHP, power * self.powerFactorKW
end

function I18N:formatNumber(number, precision, forcePrecision)
	precision = precision or 0

	if precision == 0 then
		if number == nil then
			printCallstack()
		end

		if number < 0 then
			number = math.ceil(number)
		else
			number = math.floor(number)
		end
	end

	local baseString = tostring(MathUtil.round(number, precision))
	local prefix, num, decimal = string.match(baseString, "^([^%d]*%d)(%d*)[.]?(%d*)")
	local currencyString = prefix .. num:reverse():gsub("(%d%d%d)", "%1" .. self.thousandsGroupingChar):reverse()

	if precision > 0 then
		local prec = decimal:len()

		if prec > 0 and (decimal ~= string.rep("0", prec) or forcePrecision) then
			currencyString = currencyString .. self.decimalSeparator .. decimal:sub(1, precision)
		end
	end

	return currencyString
end

function I18N:formatMoney(number, precision, addCurrency, prefixCurrencySymbol)
	local clampedDisplayMoney = MathUtil.clamp(number, I18N.MONEY_MIN_DISPLAY_VALUE, I18N.MONEY_MAX_DISPLAY_VALUE)
	local currencyString = self:formatNumber(clampedDisplayMoney, precision)

	if addCurrency == nil or addCurrency then
		if prefixCurrencySymbol == nil or not prefixCurrencySymbol then
			currencyString = currencyString .. " " .. self:getCurrencySymbol(true)
		else
			currencyString = self:getCurrencySymbol(true) .. " " .. currencyString
		end
	end

	return currencyString
end

function I18N:getCurrencySymbol(useShort)
	local postFix = ""

	if useShort then
		postFix = "Short"
	end

	if self.moneyUnit == GS_MONEY_EURO then
		return self:getText("unit_euro" .. postFix)
	elseif self.moneyUnit == GS_MONEY_POUND then
		return self:getText("unit_pound" .. postFix)
	else
		return self:getText("unit_dollar" .. postFix)
	end
end

function I18N:convertText(text, customEnv)
	if text == nil then
		Logging.warning("Text to convert is nil")
		printCallstack()

		return nil
	end

	if text:sub(1, 6) == "$l10n_" then
		text = g_i18n:getText(text:sub(7), customEnv)
	end

	return text
end

function I18N:getCurrentDate()
	local dateString = nil

	if g_languageShort == "en" then
		dateString = getDate("%Y-%m-%d")
	elseif g_languageShort == "de" then
		dateString = getDate("%d.%m.%Y")
	elseif g_languageShort == "jp" then
		dateString = getDate("%Y/%m/%d")
	else
		dateString = getDate("%d/%m/%Y")
	end

	return dateString
end

function I18N:consoleCommandVerifyAll(ignoreTodos)
	ignoreTodos = Utils.stringToBoolean(ignoreTodos)

	print("Verifying i18n files:")
	setFileLogPrefixTimestamp(false)

	if ignoreTodos then
		print("Warning: Ignoring 'TODO' and '' texts")
	end

	local function formatsFromString(str)
		local result = ""

		for formatIdentifier, _ in str:gmatch("%%%a") do
			result = result .. formatIdentifier
		end

		if result == "" then
			return nil
		end

		return result
	end

	local langToKeys = {}
	local allKeysSet = {}
	local masterLang = nil

	print("loading lang files")

	local numL = getNumOfLanguages()

	for langIndex = 0, numL - 1 do
		local code = getLanguageCode(langIndex)
		local filenameShort = "l10n_" .. code .. ".xml"

		if code == "en" then
			masterLang = filenameShort
		end

		local xmlFilename = "dataS/" .. filenameShort

		if fileExists(xmlFilename) then
			local xmlFile = loadXMLFile(filenameShort, xmlFilename)
			local keys = {}

			self:loadEntriesFromXML(xmlFile, nil, "l10n.elements.e(%d)", keys)

			langToKeys[filenameShort] = keys

			for key, _ in pairs(keys) do
				allKeysSet[key] = true
			end

			print(string.format("loaded %d entries from %s", table.size(keys), xmlFilename))
			delete(xmlFile)
		else
			print(string.format("Warning: unable to find %s for langIndex %d", xmlFilename, langIndex))
		end
	end

	for key, _ in pairs(allKeysSet) do
		for lang, keys in pairs(langToKeys) do
			local text = keys[key]

			if text == nil then
				print(string.format("Warning: Missing text for %s in %s", key, lang))
			elseif not ignoreTodos and (text:trim() == "" or text:find("TODO")) then
				print(string.format("Warning: Empty or todo text for %s in %s", key, lang))
			end
		end
	end

	local enFormatStrings = {}

	for key, text in pairs(langToKeys[masterLang]) do
		local formatString = formatsFromString(text)

		if formatString ~= nil then
			enFormatStrings[key] = formatString
		end
	end

	for lang, keys in pairs(langToKeys) do
		if lang ~= masterLang then
			for key, text in pairs(keys) do
				if text:upper() ~= "TODO" and formatsFromString(text) ~= enFormatStrings[key] then
					local enText = langToKeys[masterLang][key]

					print(string.format("Error: Mismatching format strings for key '%s' in %s: '%s' <-> '%s'", key, lang, enFormatStrings[key] or "no placeholder", formatsFromString(text) or "no placeholder"))
					print(string.format("    %s: %s", masterLang, enText))
					print(string.format("    %s: %s", lang, text))
				end
			end
		end
	end

	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)

	return "Verified all i18n files"
end

function I18N:formatMinutes(minutes)
	if minutes ~= nil then
		local hours = math.floor(minutes / 60)
		local mins = minutes - hours * 60

		return string.format(self:getText("ui_hours"), hours, mins)
	else
		return self:getText("ui_hours_none")
	end
end

function I18N:formatPeriod(period, useShort)
	local isSouthern = false

	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		isSouthern = g_currentMission.environment.daylight.latitude < 0

		if period == nil then
			period = g_currentMission.environment.currentPeriod
		end
	end

	if period == nil then
		return nil
	end

	local month = period + 2

	if isSouthern then
		month = month + 6
	end

	month = (month - 1) % 12 + 1

	return self:getText("ui_month" .. month .. (useShort and "_short" or ""))
end

function I18N:formatDayInPeriod(dayInPeriod, period, useShort)
	if g_currentMission == nil or g_currentMission.environment == nil then
		return nil
	end

	if dayInPeriod == nil then
		dayInPeriod = g_currentMission.environment.currentDayInPeriod
	end

	if period == nil then
		period = g_currentMission.environment.currentPeriod
	end

	local period = self:formatPeriod(period, useShort)
	local daysPerPeriod = g_currentMission.environment.daysPerPeriod

	if daysPerPeriod == 1 then
		return period
	else
		local dateEquivalent = 1 + 30 / daysPerPeriod * (dayInPeriod - 1)

		return string.format("%s %d", period, dateEquivalent)
	end
end

function I18N:formatNumMonth(numMonth)
	local locaMonth = "ui_month"

	if numMonth > 1 then
		locaMonth = "ui_months"
	end

	return string.format("%d %s", numMonth, self:getText(locaMonth))
end

function I18N:formatNumDay(numDay)
	local locaDay = "ui_day"

	if numDay > 1 then
		locaDay = "ui_days"
	end

	return string.format("%d %s", numDay, self:getText(locaDay))
end
