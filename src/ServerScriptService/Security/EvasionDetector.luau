--!strict
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local EvasionDetector = {}

local profileStore: OrderedDataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore("UtopiaEvasionProfiles_v1")
	end)
	if ok then
		profileStore = result
	else
		warn("[Security] DataStore init failed (EvasionDetector):", result)
	end
end

export type SessionProfile = {
	userId: number,
	displayName: string,
	accountAge: number,
	localeId: string,
	membershipType: string,
	avatarHash: string,
	bannedAt: number,
	banReason: string,
}

local function levenshtein(a: string, b: string): number
	local la, lb = #a, #b
	local matrix: { { number } } = table.create(la + 1)
	for i = 0, la do
		matrix[i + 1] = table.create(lb + 1, 0)
		matrix[i + 1][1] = i
	end
	for j = 0, lb do
		matrix[1][j + 1] = j
	end
	for i = 1, la do
		for j = 1, lb do
			local cost = if string.sub(a, i, i) == string.sub(b, j, j) then 0 else 1
			matrix[i + 1][j + 1] = math.min(
				matrix[i][j + 1] + 1,
				matrix[i + 1][j] + 1,
				matrix[i][j] + cost
			)
		end
	end
	return matrix[la + 1][lb + 1]
end

local function hashAvatar(player: Player): string
	local parts: { string } = {}
	for _, item in player.Character:GetDescendants() do
		if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") then
			table.insert(parts, item.Name)
		end
	end
	table.sort(parts)
	return tostring(#parts) .. ":" .. table.concat(parts, ",")
end

function EvasionDetector:SaveProfile(player: Player, banReason: string)
	local profile: SessionProfile = {
		userId = player.UserId,
		displayName = player.DisplayName,
		accountAge = player.AccountAge,
		localeId = player.LocaleId,
		membershipType = tostring(player.MembershipType),
		avatarHash = if player.Character then hashAvatar(player) else "",
		bannedAt = os.time(),
		banReason = banReason,
	}
	local store = profileStore
	if store then
		pcall(function()
			store:SetAsync(tostring(player.UserId), profile)
		end)
	end
	return profile
end

function EvasionDetector:ScoreJoin(player: Player): number
	local score = 0
	local store = profileStore
	if not store then
		return score
	end
	local ok, profiles = pcall(function()
		return store:GetSortedAsync(false, 25):GetCurrentPage()
	end)
	if not ok or not profiles then
		return score
	end
	for _, entry in profiles do
		local profile = entry.value :: SessionProfile
		if profile.userId == player.UserId then
			continue
		end
		if player.AccountAge < 1 and (os.time() - profile.bannedAt) < 86400 then
			score += 40
		end
		if levenshtein(string.lower(player.DisplayName), string.lower(profile.displayName)) <= 3 then
			score += 25
		end
		if player.Character then
			local avatarHash = hashAvatar(player)
			if avatarHash == profile.avatarHash and profile.avatarHash ~= "" then
				score += 30
			end
		end
		if player.LocaleId == profile.localeId and player.AccountAge == profile.accountAge then
			score += 35
		end
	end
	return score
end

function EvasionDetector:ShouldBlock(score: number): boolean
	return score >= GameConfig.Security.EVASION_BLOCK
end

function EvasionDetector:ShouldFlag(score: number): boolean
	return score >= GameConfig.Security.EVASION_FLAG
end

return EvasionDetector
