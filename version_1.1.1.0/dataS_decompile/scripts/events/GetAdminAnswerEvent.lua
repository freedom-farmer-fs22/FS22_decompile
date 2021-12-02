GetAdminAnswerEvent = {}
local GetAdminAnswerEvent_mt = Class(GetAdminAnswerEvent, Event)

InitStaticEventClass(GetAdminAnswerEvent, "GetAdminAnswerEvent", EventIds.EVENT_GET_ADMIN_ANSWER)

GetAdminAnswerEvent.ACCESS_GRANTED = 0
GetAdminAnswerEvent.ACCESS_DENIED = 1
GetAdminAnswerEvent.NOT_SUPPORTED = 2
GetAdminAnswerEvent.sendNumBits = 2

function GetAdminAnswerEvent.emptyNew()
	local self = Event.new(GetAdminAnswerEvent_mt)

	return self
end

function GetAdminAnswerEvent.new(state)
	local self = GetAdminAnswerEvent.emptyNew()
	self.state = state

	return self
end

function GetAdminAnswerEvent:readStream(streamId, connection)
	self.state = streamReadUIntN(streamId, GetAdminAnswerEvent.sendNumBits)

	self:run(connection)
end

function GetAdminAnswerEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.state, GetAdminAnswerEvent.sendNumBits)
end

function GetAdminAnswerEvent:run(connection)
	if connection:getIsServer() then
		local text = g_i18n:getText("ui_adminLoginNotSupported")
		local dialogType = DialogElement.TYPE_WARNING

		if self.state == GetAdminAnswerEvent.ACCESS_GRANTED then
			text = g_i18n:getText("ui_adminLoginGranted")
			dialogType = DialogElement.TYPE_INFO
		elseif self.state == GetAdminAnswerEvent.ACCESS_DENIED then
			text = g_i18n:getText("ui_wrongPassword")
		end

		g_gui:showInfoDialog({
			text = text,
			dialogType = dialogType,
			callback = GetAdminAnswerEvent.onAnswerOk,
			args = {
				self.state == GetAdminAnswerEvent.ACCESS_GRANTED
			}
		})
	else
		print("This is a server to client event!")
	end
end

function GetAdminAnswerEvent.onAnswerOk(args)
	if args ~= nil and args[1] == true then
		g_messageCenter:publish(GetAdminAnswerEvent, true)
	end
end
