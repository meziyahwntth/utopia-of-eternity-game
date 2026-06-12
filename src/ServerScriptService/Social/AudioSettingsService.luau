--!strict
--[[
	AudioSettingsService (P3-A) — เก็บค่าตั้งเสียงต่อผู้เล่น (DataStore + pcall)
	prefs: { music, sfx, notify : boolean, masterVolume : number 0-1 }
	voice ไม่อยู่ในนี้ (คุมแยกที่ VoiceChannel — ผู้เล่นยังได้ยิน voice เสมอแม้ปิดเพลง/SFX)
]]
local DataStoreService = game:GetService("DataStoreService")

local AudioSettingsService = {}

local DEFAULT = { music = true, sfx = true, notify = true, masterVolume = 1 }

local store: GlobalDataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore("UtopiaAudioPrefs_v1")
end)
if store == nil then
	warn("[Social] AudioSettings DataStore unavailable (publish place to enable persistence)")
end

local function clean(prefs: any): { [string]: any }
	if typeof(prefs) ~= "table" then
		return table.clone(DEFAULT)
	end
	return {
		music = prefs.music ~= false,
		sfx = prefs.sfx ~= false,
		notify = prefs.notify ~= false,
		masterVolume = if typeof(prefs.masterVolume) == "number"
			then math.clamp(prefs.masterVolume, 0, 1)
			else 1,
	}
end

function AudioSettingsService.get(player: Player): { [string]: any }
	if store == nil then
		return table.clone(DEFAULT)
	end
	local ok, data = pcall(function()
		return (store :: GlobalDataStore):GetAsync("u_" .. player.UserId)
	end)
	if ok and typeof(data) == "table" then
		return clean(data)
	end
	return table.clone(DEFAULT)
end

function AudioSettingsService.set(player: Player, prefs: any)
	local c = clean(prefs)
	if store == nil then
		return
	end
	task.spawn(function()
		pcall(function()
			(store :: GlobalDataStore):SetAsync("u_" .. player.UserId, c)
		end)
	end)
end

return AudioSettingsService
