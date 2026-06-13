--!strict
--[[
	GuildStore (P3-B) — persistence แคลน/กิลด์ (DataStore + pcall)
	  • guildStore  : guildId -> GuildData
	  • memberStore : "u_"<userId> -> guildId  (รู้ว่าผู้เล่นอยู่แคลนไหน)
	บน local-file Studio (ไม่ publish) DataStore ใช้ไม่ได้ → pcall + fallback (แคลนชั่วคราวใน memory)
]]
local DataStoreService = game:GetService("DataStoreService")

local GuildStore = {}

export type GuildData = {
	id: string,
	name: string,
	leaderId: number,
	members: { [string]: string }, -- userId(เป็น string) -> rank ("Leader"|"Officer"|"Veteran"|"Member")
	level: number,
	reputation: number,
	allianceId: string?,
	createdAt: number,
}

local guildStore: GlobalDataStore? = nil
local memberStore: GlobalDataStore? = nil
pcall(function()
	guildStore = DataStoreService:GetDataStore("UtopiaGuilds_v1")
end)
pcall(function()
	memberStore = DataStoreService:GetDataStore("UtopiaGuildMembers_v1")
end)
if guildStore == nil or memberStore == nil then
	warn("[Social] GuildStore DataStore unavailable (publish place to persist clans)")
end

function GuildStore.loadGuild(guildId: string): GuildData?
	if guildStore == nil then
		return nil
	end
	local ok, data = pcall(function()
		return (guildStore :: GlobalDataStore):GetAsync(guildId)
	end)
	if ok and typeof(data) == "table" then
		return data :: GuildData
	end
	return nil
end

function GuildStore.saveGuild(g: GuildData): boolean
	if guildStore == nil then
		return false
	end
	local ok = pcall(function()
		(guildStore :: GlobalDataStore):SetAsync(g.id, g)
	end)
	return ok
end

function GuildStore.deleteGuild(guildId: string)
	if guildStore == nil then
		return
	end
	pcall(function()
		(guildStore :: GlobalDataStore):RemoveAsync(guildId)
	end)
end

function GuildStore.getPlayerGuildId(userId: number): string?
	if memberStore == nil then
		return nil
	end
	local ok, data = pcall(function()
		return (memberStore :: GlobalDataStore):GetAsync("u_" .. userId)
	end)
	if ok and typeof(data) == "string" then
		return data
	end
	return nil
end

function GuildStore.setPlayerGuildId(userId: number, guildId: string?)
	if memberStore == nil then
		return
	end
	pcall(function()
		if guildId then
			(memberStore :: GlobalDataStore):SetAsync("u_" .. userId, guildId)
		else
			(memberStore :: GlobalDataStore):RemoveAsync("u_" .. userId)
		end
	end)
end

return GuildStore
