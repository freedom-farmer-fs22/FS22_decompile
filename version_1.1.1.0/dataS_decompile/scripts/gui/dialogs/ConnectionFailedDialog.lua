ConnectionFailedDialog = {}
local ConnectionFailedDialog_mt = Class(ConnectionFailedDialog, InfoDialog)
local localRemoveActivation = removeActivation
removeActivation = nil

function ConnectionFailedDialog.new(target, custom_mt)
	local self = InfoDialog.new(target, custom_mt or ConnectionFailedDialog_mt)

	return self
end

function ConnectionFailedDialog:setText(text)
	ConnectionFailedDialog:superClass().setText(self, text)

	if g_dedicatedServer ~= nil then
		print("Error: " .. text)
	end
end

function ConnectionFailedDialog:onWrongVersion(args)
	openWebFile("fs2019Update.php", "")

	if args ~= nil then
		g_gui:showGui(args[1])
	end
end

function ConnectionFailedDialog:onInvalidKey(args)
	openWebFile("fs2019Purchase.php", "")

	if args ~= nil then
		g_gui:showGui(args[1])
	end
end

function ConnectionFailedDialog:onOkCallback(args)
	if args ~= nil then
		g_gui:showGui(args[1])
	end
end

function ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, nextScreenName)
	print("Error: Failed to connect: " .. reason)

	local networkError = nil

	if GS_PLATFORM_PLAYSTATION then
		networkError = getNetworkError()

		if networkError then
			networkError = string.gsub(networkError, "Network", "dialog_network")
			nextScreenName = "MainScreen"
		end
	end

	if MasterServerConnection.FAILED_NONE == reason then
		print("Error: reason is none, this should never happen.")
	elseif MasterServerConnection.FAILED_WRONG_VERSION == reason then
		g_gui:showConnectionFailedDialog({
			text = g_i18n:getText("ui_outdatedGameVersion"),
			callback = g_connectionFailedDialog.onWrongVersion,
			target = g_connectionFailedDialog,
			args = {
				nextScreenName
			}
		})
	elseif MasterServerConnection.FAILED_PERMANENT_BAN == reason then
		if g_dedicatedServer ~= nil then
			localRemoveActivation()
		end

		g_gui:showConnectionFailedDialog({
			text = g_i18n:getText("ui_permanentBan"),
			callback = g_connectionFailedDialog.onInvalidKey,
			target = g_connectionFailedDialog,
			args = {
				nextScreenName
			}
		})
	else
		local text = ""

		if MasterServerConnection.FAILED_UNKNOWN == reason then
			text = g_i18n:getText(networkError or "ui_connectionFailed")
		elseif MasterServerConnection.FAILED_MAINTENANCE == reason then
			text = g_i18n:getText("ui_serverMaintenance")
		elseif MasterServerConnection.FAILED_TEMPORARY_BAN == reason then
			if g_dedicatedServer ~= nil then
				localRemoveActivation()
			end

			text = g_i18n:getText("ui_temporaryBan")
		elseif MasterServerConnection.FAILED_CONNECTION_LOST == reason then
			text = g_i18n:getText(networkError or "ui_masterServerConnectionLost")
		elseif MasterServerConnection.FAILED_WRONG_PASSWORD == reason then
			text = g_i18n:getText(networkError or "ui_wrongPassword")
		elseif MasterServerConnection.FAILED_CONSOLE_USER_FAILED_AUTHENTICATION == reason then
			text = g_i18n:getText(networkError or "ui_connectionFailed")
		end

		g_gui:showConnectionFailedDialog({
			text = text,
			callback = g_connectionFailedDialog.onOkCallback,
			target = g_connectionFailedDialog,
			args = {
				nextScreenName
			}
		})
	end

	g_deepLinkingInfo = nil

	if g_dedicatedServer ~= nil then
		doExit()
	end
end
