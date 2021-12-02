PlatformPrivilegeUtil = {}

function PlatformPrivilegeUtil.checkModDownload(callback, callbackTarget)
	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")

		return false
	end

	local availability, showsNativeGUI = getModDownloadAvailability()

	if availability ~= MultiplayerAvailability.AVAILABLE then
		if availability == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			g_gui:showMessageDialog({
				visible = true,
				text = g_i18n:getText("ui_connectingPleaseWait"),
				updateCallback = PlatformPrivilegeUtil.checkModDownloadUpdateCallback,
				updateArgs = {
					showsNativeGUI = showsNativeGUI,
					callback = callback,
					callbackTarget = callbackTarget
				}
			})
		elseif not showsNativeGUI then
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_missingUGCdownloadPrivilege")
			})
		end

		return false
	end

	return true
end

function PlatformPrivilegeUtil.checkModDownloadUpdateCallback(dt, args)
	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")

		return
	end

	local availability, showsNativeGUI = getModDownloadAvailability()
	args.showsNativeGUI = args.showsNativeGUI or showsNativeGUI

	if availability ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
		g_gui:showMessageDialog({
			visible = false
		})

		if availability == MultiplayerAvailability.AVAILABLE then
			if args.callback ~= nil then
				if args.callbackTarget ~= nil then
					args.callback(args.callbackTarget)
				else
					args.callback()
				end
			end
		elseif not args.showsNativeGUI then
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_missingUGCdownloadPrivilege")
			})
		end
	end
end

function PlatformPrivilegeUtil.checkModUse(callback, callbackTarget)
	local availability, showsNativeGUI = getModUseAvailability(true)

	if availability ~= MultiplayerAvailability.AVAILABLE then
		if availability == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			g_gui:showMessageDialog({
				visible = true,
				text = g_i18n:getText("ui_connectingPleaseWait"),
				updateCallback = PlatformPrivilegeUtil.checkModUseUpdateCallback,
				updateArgs = {
					showsNativeGUI = showsNativeGUI,
					callback = callback,
					callbackTarget = callbackTarget
				}
			})
		elseif not showsNativeGUI then
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_missingUGCdownloadPrivilege")
			})
		end

		return false
	end

	return true
end

function PlatformPrivilegeUtil.checkModUseUpdateCallback(dt, args)
	local availability, showsNativeGUI = getModUseAvailability(true)
	args.showsNativeGUI = args.showsNativeGUI or showsNativeGUI

	if availability ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
		g_gui:showMessageDialog({
			visible = false
		})

		if availability == MultiplayerAvailability.AVAILABLE then
			if args.callback ~= nil then
				if args.callbackTarget ~= nil then
					args.callback(args.callbackTarget)
				else
					args.callback()
				end
			end
		elseif not args.showsNativeGUI then
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_missingUGCdownloadPrivilege")
			})
		end
	end
end

function PlatformPrivilegeUtil.checkMultiplayer(callback, callbackTarget, callbackArgs, networkTimeout)
	local availability, showsNativeGUI = getMultiplayerAvailability()

	if getNetworkError() then
		if networkTimeout ~= nil then
			g_gui:showMessageDialog({
				visible = true,
				text = g_i18n:getText("ui_connectingPleaseWait"),
				updateCallback = PlatformPrivilegeUtil.checkMultiplayerUpdateCallback,
				updateArgs = {
					showsNativeGUI = showsNativeGUI,
					callback = callback,
					callbackTarget = callbackTarget,
					callbackArgs = callbackArgs,
					networkTimeout = networkTimeout
				}
			})
		else
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end

		return false
	end

	if availability ~= MultiplayerAvailability.AVAILABLE then
		if availability == MultiplayerAvailability.AVAILABILITY_UNKNOWN then
			g_gui:showMessageDialog({
				visible = true,
				text = g_i18n:getText("ui_connectingPleaseWait"),
				updateCallback = PlatformPrivilegeUtil.checkMultiplayerUpdateCallback,
				updateArgs = {
					showsNativeGUI = showsNativeGUI,
					callback = callback,
					callbackTarget = callbackTarget,
					callbackArgs = callbackArgs,
					networkTimeout = networkTimeout
				}
			})
		elseif not showsNativeGUI and GS_PLATFORM_XBOX then
			if availability == MultiplayerAvailability.NOT_AVAILABLE then
				g_gui:showInfoDialog({
					text = g_i18n:getText("ui_missingGoldForMultiplayer_xbox")
				})
			elseif availability == MultiplayerAvailability.NO_PRIVILEGES then
				g_gui:showInfoDialog({
					text = g_i18n:getText("ui_missingPrivilegeMultiplayerSession_xbox")
				})
			end
		end

		return false
	end

	return true
end

function PlatformPrivilegeUtil.checkMultiplayerUpdateCallback(dt, args)
	if args.networkTimeout ~= nil then
		args.networkTimeout = args.networkTimeout - dt

		if args.networkTimeout <= 0 then
			args.networkTimeout = nil
		end
	end

	if getNetworkError() then
		if args.networkTimeout == nil then
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end

		return
	end

	local availability, showsNativeGUI = getMultiplayerAvailability()
	args.showsNativeGUI = args.showsNativeGUI or showsNativeGUI

	if availability ~= MultiplayerAvailability.AVAILABILITY_UNKNOWN then
		g_gui:showMessageDialog({
			visible = false
		})

		if availability == MultiplayerAvailability.AVAILABLE then
			if args.callback ~= nil then
				if args.callbackTarget ~= nil then
					args.callback(args.callbackTarget, args.callbackArgs)
				else
					args.callback(args.callbackArgs)
				end
			end
		elseif not args.showsNativeGUI and GS_PLATFORM_XBOX then
			if availability == MultiplayerAvailability.NOT_AVAILABLE then
				g_gui:showInfoDialog({
					text = g_i18n:getText("ui_missingGoldForMultiplayer_xbox")
				})
			elseif availability == MultiplayerAvailability.NO_PRIVILEGES then
				g_gui:showInfoDialog({
					text = g_i18n:getText("ui_missingPrivilegeMultiplayerSession_xbox")
				})
			end
		end
	end
end

function PlatformPrivilegeUtil.getCanInvitePlayer(misson)
	return GS_IS_CONSOLE_VERSION or GS_PLATFORM_GGP
end
