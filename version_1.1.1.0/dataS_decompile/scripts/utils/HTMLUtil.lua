HTMLUtil = {
	encodeEntities = {
		["Ö"] = "&Ouml;",
		["è"] = "&egrave;",
		["ù"] = "&ugrave;",
		["œ"] = "&oelig;",
		["î"] = "&icirc;",
		["È"] = "&Egrave;",
		["Ô"] = "&Ocirc;",
		["à"] = "&agrave;",
		["»"] = "&raquo;",
		["©"] = "&copy;",
		["Œ"] = "&OElig;",
		["æ"] = "&aelig;",
		["Æ"] = "&AElig;",
		["®"] = "&reg;",
		["«"] = "&laquo;",
		["Ÿ"] = "&Yuml;",
		["Ç"] = "&Ccedil;",
		["ë"] = "&euml;",
		["ê"] = "&ecirc;",
		["ö"] = "&ouml;",
		["é"] = "&eacute;",
		[">"] = "&gt;",
		["<"] = "&lt;",
		["ô"] = "&ocirc;",
		["Â"] = "&Acirc;",
		["Î"] = "&Icirc;",
		["Ï"] = "&Iuml;",
		["Û"] = "&Ucirc;",
		["ç"] = "&ccedil;",
		["Ù"] = "&Ugrave;",
		["ÿ"] = "&yuml;",
		["À"] = "&Agrave;",
		["ä"] = "&auml;",
		["ü"] = "&uuml;",
		["Ê"] = "&Ecirc;",
		["Ë"] = "&Euml;",
		["â"] = "&acirc;",
		["É"] = "&Eacute;",
		["ï"] = "&iuml;",
		["û"] = "&ucirc;"
	},
	decodeEntities = {
		Ocirc = "Ô",
		auml = "ä",
		ugrave = "ù",
		acirc = "â",
		Ccedil = "Ç",
		ccedil = "ç",
		Iuml = "Ï",
		Euml = "Ë",
		Eacute = "É",
		Egrave = "È",
		Icirc = "Î",
		ecirc = "ê",
		Ugrave = "Ù",
		raquo = "»",
		ouml = "ö",
		laquo = "«",
		egrave = "è",
		Ucirc = "Û",
		aelig = "æ",
		yuml = "ÿ",
		OElig = "Œ",
		eacute = "é",
		Agrave = "À",
		agrave = "à",
		oelig = "œ",
		AElig = "Æ",
		iuml = "ï",
		reg = "®",
		icirc = "î",
		ocirc = "ô",
		ucirc = "û",
		copy = "©",
		amp = "&",
		euml = "ë",
		Acirc = "Â",
		uuml = "ü",
		Ecirc = "Ê",
		Ouml = "Ö",
		Yuml = "Ÿ"
	},
	encodeToHTML = function (str, inCData)
		local encodedString = str

		if inCData then
			encodedString = string.gsub(encodedString, "]]>", "]]]]><![CDATA[>")
		else
			encodedString = string.gsub(encodedString, "&", "&amp;")
			encodedString = string.gsub(encodedString, "\"", "&quot;")
			encodedString = string.gsub(encodedString, "]", "&#93;")
			encodedString = string.gsub(encodedString, "<", "&lt;")
			encodedString = string.gsub(encodedString, ">", "&gt;")
			encodedString = string.gsub(encodedString, "\n", "&#10;")
			encodedString = string.gsub(encodedString, "\r", "&#13;")
		end

		return encodedString
	end
}

function HTMLUtil.decodeFromHTML(str)
	local function ReplaceEntity(entity)
		return HTMLUtil.decodeEntities[string.sub(entity, 2, -2)] or entity
	end

	return string.gsub(str, "&%a+;", ReplaceEntity)
end
