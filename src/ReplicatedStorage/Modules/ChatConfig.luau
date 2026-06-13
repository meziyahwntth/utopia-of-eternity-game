--!strict
--[[
	ChatConfig (P3-C) — ค่ากลางระบบ Custom Chat (Lineage II style)
	ใช้ทั้ง server (ChatService) และ client (ChatClient)
]]
local ChatConfig = {}

----------------------------------------------------------------
-- Channels
----------------------------------------------------------------
export type Channel = "General" | "Party" | "Clan" | "Alliance" | "Whisper" | "System"

ChatConfig.Channels = { "General", "Party", "Clan", "Alliance", "Whisper" } :: { Channel }

ChatConfig.ChannelLabel = {
	General = "ทั่วไป",
	Party = "ปาร์ตี้",
	Clan = "แคลน",
	Alliance = "พันธมิตร",
	Whisper = "กระซิบ",
	System = "ระบบ",
} :: { [Channel]: string }

-- สีชื่อช่องและข้อความใน history
ChatConfig.ChannelColor = {
	General = Color3.fromRGB(220, 220, 220),
	Party = Color3.fromRGB(100, 210, 255),
	Clan = Color3.fromRGB(100, 255, 150),
	Alliance = Color3.fromRGB(200, 130, 255),
	Whisper = Color3.fromRGB(255, 210, 100),
	System = Color3.fromRGB(255, 170, 70),
} :: { [Channel]: Color3 }

-- แท็บที่แสดงในช่อง input (ไม่รวม System)
ChatConfig.TabChannels = { "General", "Party", "Clan", "Alliance", "Whisper" } :: { Channel }

----------------------------------------------------------------
-- Alliance Chat Permission
-- Leader: อนุญาตอัตโนมัติ
-- Officer/Veteran/Member: ต้องได้รับสิทธิ์จาก Leader (canAllianceChat)
----------------------------------------------------------------
ChatConfig.AllianceAutoAllowRanks = {
	Leader = true,
} :: { [string]: boolean }

----------------------------------------------------------------
-- Voice
-- voice routing ตาม active channel
-- General = spatial default (Roblox), Party/Clan/Alliance = group access list
----------------------------------------------------------------
ChatConfig.VoiceChannels = {
	General = true,
	Party = true,
	Clan = true,
	Alliance = true,
	Whisper = false, -- voice whisper ไม่รองรับ (ใช้ spatial แทน)
	System = false,
} :: { [Channel]: boolean }

----------------------------------------------------------------
-- Admin
-- เพิ่ม UserId จริงตรงนี้
-- ตัวอย่าง: ChatConfig.AdminIds = { 12345678, 87654321 }
----------------------------------------------------------------
ChatConfig.AdminIds = {} :: { number }

-- Admin commands ที่รองรับ (server จะ validate + execute)
ChatConfig.AdminCommands = {
	fly = true,
	noclip = true,
	speed = true,
	kick = true,
	tp = true,
	heal = true,
	god = true,
} :: { [string]: boolean }

----------------------------------------------------------------
-- Chat limits
----------------------------------------------------------------
ChatConfig.MaxMessageLength = 200
ChatConfig.MaxHistoryLines = 100 -- จำนวน history ที่แสดง (client)
ChatConfig.RateLimitPerMinute = 20

----------------------------------------------------------------
-- UI geometry (ใช้ใน ChatClient)
----------------------------------------------------------------
ChatConfig.UI = {
	Width = 440,
	HistoryHeight = 200,
	InputHeight = 38,
	TabHeight = 28,
	PaddingH = 8,
	PaddingV = 6,
	CornerRadius = 8,
	BgColor = Color3.fromRGB(12, 18, 32),
	BgTransparency = 0.15,
	TabActiveColor = Color3.fromRGB(40, 60, 100),
	TabInactiveColor = Color3.fromRGB(20, 30, 55),
	FontBody = Enum.Font.Gotham,
	FontBold = Enum.Font.GothamBold,
	FontSize = 14,
}

return ChatConfig
