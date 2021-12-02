PlatformIconElement = {}
local PlatformIconElement_mt = Class(PlatformIconElement, BitmapElement)

function PlatformIconElement.new(target, custom_mt)
	local self = PlatformIconElement:superClass().new(target, custom_mt or PlatformIconElement_mt)

	return self
end

function PlatformIconElement:delete()
	PlatformIconElement:superClass().delete(self)
end

function PlatformIconElement:copyAttributes(src)
	PlatformIconElement:superClass().copyAttributes(self, src)

	self.platformId = src.platformId
end

function PlatformIconElement:setPlatformId(platformId)
	local useOtherIcon = false

	if GS_PLATFORM_ID == PlatformId.PS4 or GS_PLATFORM_ID == PlatformId.PS5 then
		if platformId ~= PlatformId.PS4 and platformId ~= PlatformId.PS5 then
			useOtherIcon = true
		end
	elseif (GS_PLATFORM_ID == PlatformId.XBOX_ONE or GS_PLATFORM_ID == PlatformId.XBOX_SERIES) and platformId ~= PlatformId.XBOX_ONE and platformId ~= PlatformId.XBOX_SERIES then
		useOtherIcon = true
	end

	if useOtherIcon then
		platformId = 0
	end

	self:setImageUVs(nil, unpack(GuiUtils.getUVs(PlatformIconElement.UVS[platformId])))
end

PlatformIconElement.UVS = {
	[0] = {
		915,
		51,
		42,
		42
	},
	[PlatformId.WIN] = {
		963,
		51,
		42,
		42
	},
	[PlatformId.MAC] = {
		963,
		51,
		42,
		42
	},
	[PlatformId.GGP] = {
		771,
		51,
		42,
		42
	},
	[PlatformId.PS4] = {
		867,
		51,
		42,
		42
	},
	[PlatformId.PS5] = {
		867,
		51,
		42,
		42
	},
	[PlatformId.XBOX_ONE] = {
		723,
		51,
		42,
		42
	},
	[PlatformId.XBOX_SERIES] = {
		723,
		51,
		42,
		42
	}
}
