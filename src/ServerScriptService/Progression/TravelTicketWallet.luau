--!strict
--[[
	TravelTicketWallet (V2 P2) — สกุลเงิน "ตั๋วโดยสาร" สำหรับค่าขนส่งสาธารณะ
	แยกจาก Prism Key → จ่ายค่าโดยสารแล้ว "ไม่กระทบ progression/level"

	v1: เก็บใน attribute "TravelTickets" + แจกตั้งต้นต่อ session (STARTER)
	TODO(P3): persist ลง DataStore + ระบบหาตั๋วจากกิจกรรม/เควส/รายวัน
]]
local Players = game:GetService("Players")

local TravelTicketWallet = {}

local ATTR = "TravelTickets"
local STARTER = 5 -- ตั๋วเริ่มต้นให้ผู้เล่นใหม่ (พอเดินทางได้ระยะแรก)

function TravelTicketWallet.get(player: Player): number
	local v = player:GetAttribute(ATTR)
	return if typeof(v) == "number" then v else 0
end

function TravelTicketWallet.add(player: Player, amount: number)
	player:SetAttribute(ATTR, TravelTicketWallet.get(player) + amount)
end

function TravelTicketWallet.trySpend(player: Player, amount: number): boolean
	if amount <= 0 then
		return true
	end
	local cur = TravelTicketWallet.get(player)
	if cur < amount then
		return false
	end
	player:SetAttribute(ATTR, cur - amount)
	return true
end

function TravelTicketWallet.ensureStarter(player: Player)
	if player:GetAttribute(ATTR) == nil then
		player:SetAttribute(ATTR, STARTER)
	end
end

function TravelTicketWallet.init()
	Players.PlayerAdded:Connect(function(player)
		TravelTicketWallet.ensureStarter(player)
	end)
	for _, player in Players:GetPlayers() do
		TravelTicketWallet.ensureStarter(player)
	end
end

return TravelTicketWallet
