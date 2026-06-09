--!strict
local MessagingService = game:GetService("MessagingService")

local BanBroadcast = {}

local TOPIC = "UtopiaGlobalBan_v1"

export type BanMessage = {
	userId: number,
	reason: string,
	durationSeconds: number?,
	by: string,
	profile: { [string]: any }?,
}

local BanRegistry
local handlers: { (BanMessage) -> () } = {}

function BanBroadcast:Init(deps: { BanRegistry: any })
	BanRegistry = deps.BanRegistry
end

function BanBroadcast:Subscribe(callback: (BanMessage) -> ())
	table.insert(handlers, callback)
end

function BanBroadcast:StartListening()
	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(message)
			local data = message.Data :: BanMessage
			if BanRegistry then
				BanRegistry:Ban(data.userId, data.reason, data.durationSeconds, data.by)
			end
			for _, handler in handlers do
				task.spawn(handler, data)
			end
		end)
	end)
end

function BanBroadcast:Publish(payload: BanMessage)
	pcall(function()
		MessagingService:PublishAsync(TOPIC, payload)
	end)
end

return BanBroadcast
