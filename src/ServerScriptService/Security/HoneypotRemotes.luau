--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HoneypotRemotes = {}

local SuspicionTracker
local SentinelStrike
local SevereOffenseGate

local HONEYPOT_NAMES = {
	"AdminGiveCoins",
	"GiveAllItems",
	"SetLevel",
	"UnlockAllKeys",
}

function HoneypotRemotes:Init(deps: { SuspicionTracker: any, SentinelStrike: any, SevereOffenseGate: any? })
	SuspicionTracker = deps.SuspicionTracker
	SentinelStrike = deps.SentinelStrike
	SevereOffenseGate = deps.SevereOffenseGate
end

function HoneypotRemotes:Deploy()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in HONEYPOT_NAMES do
		if folder:FindFirstChild(name) then
			continue
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		remote.OnServerEvent:Connect(function(player: Player)
			if SevereOffenseGate then
				SevereOffenseGate:Handle(player, "HONEYPOT_" .. name, name)
			elseif SentinelStrike then
				SentinelStrike:PermanentBan(player, "HONEYPOT_" .. name, "HoneypotRemotes")
			else
				player:Kick("Utopia Shield: unauthorized remote access detected.")
			end
		end)
	end
end

return HoneypotRemotes
