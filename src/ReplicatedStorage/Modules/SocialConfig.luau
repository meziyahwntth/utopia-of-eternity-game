--!strict
--[[
	SocialConfig (P3-A) — ค่ากลางระบบสังคม: ปาร์ตี้ · แคลน · พันธมิตร · กระซิบ · เสียง
	ดู docs/MASTER-BLUEPRINT.md §8 สำหรับเหตุผลค่าต่าง ๆ
]]
local SocialConfig = {}

-- ปาร์ตี้
SocialConfig.Party = {
	MaxMembers = 12, -- Praphan (เท่า Ragnarok)
	RaidMaxMembers = 24, -- รวม 2 ปาร์ตี้ ล่า MVP boss
	TeleportToJoinCooldownSeconds = 1800, -- 30 นาที/คน (กันใช้แทนเครื่องบิน P2)
	InviteTimeoutSeconds = 60,
}

-- แคลน / กิลด์
SocialConfig.Clan = {
	BaseMembers = 20, -- Lv1
	MembersPerLevel = 5, -- +5 ต่อเลเวล
	MaxLevel = 10, -- → สูงสุด 20 + 5*9 = 65
	MinPlayerLevelToCreate = 16, -- ต้อง Apprentice ขึ้นไป
	CreateCostCredits = 500, -- ค่าในเกม (กันสแปม) · robux = ทางเลือกเสริม
	NameMaxLength = 18,
	Ranks = { "Leader", "Officer", "Veteran", "Member" }, -- Officer ≤3
	MaxOfficers = 3,
}

function SocialConfig.clanMemberCap(clanLevel: number): number
	local lvl = math.clamp(clanLevel, 1, SocialConfig.Clan.MaxLevel)
	return SocialConfig.Clan.BaseMembers + (lvl - 1) * SocialConfig.Clan.MembersPerLevel
end

-- พันธมิตร = มิตรภาพระหว่างแคลน (Praphan)
SocialConfig.Alliance = {
	MaxClans = 3, -- แบบ Lineage II
	-- สิทธิ์: แชทพันธมิตรร่วม · ไม่ friendly-fire ใน war · ร่วม siege
}

-- Clan War / ชิงเขต
SocialConfig.ClanWar = {
	DayOfWeek = 7, -- เสาร์ (1=อาทิตย์ ... 7=เสาร์)
	HourLocal = 20, -- 20:00 server time
	DurationSeconds = 45 * 60,
	MinClanLevelToRegister = 3,
	Districts = { "Marina", "Aurora", "Canal" }, -- เขตใน Eternity City
	ShopTaxPercent = 10, -- % รายได้ค่าเช่าร้านในเขตที่ผู้ชนะได้
}

-- กระซิบ
SocialConfig.Whisper = {
	MaxLength = 200,
	RateLimitPerMinute = 20, -- กันสแปม
}

-- ช่องแชท (TextChatService custom channels)
SocialConfig.Channels = {
	Party = "RBXParty",
	Clan = "RBXClan",
	Alliance = "RBXAlliance",
	Whisper = "RBXWhisper",
}

-- เสียง (SoundGroup categories — AudioSettings)
SocialConfig.Audio = {
	Groups = { "Music", "SFX", "Notify", "Voice" },
	DefaultVolume = { Music = 0.6, SFX = 0.8, Notify = 0.8, Voice = 1.0 },
}

return SocialConfig
