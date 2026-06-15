--!strict
--[[
	HudVisibilityManager (Mobile-UX audit) — auto-hide/collapsible HUD ตอนสู้
	เพื่อให้เห็นตัวละครชัดบนจอเล็ก. ฟัง CombatStateController.Changed:
	  inCombat=true  -> ซ่อน HUD ในรายการ HIDE (notification/social/event ที่ไม่จำเป็นกลางสู้)
	  inCombat=false -> คืนค่าเดิม (เฉพาะตัวที่เราซ่อน)

	หลักความปลอดภัย:
	  - ใช้ HIDE-list แบบ opt-in (ไม่ใช่ hide-all) → ไม่แตะ HUD combat/health/skill
	  - ToggleEnabled เท่านั้น (ไม่ยุ่ง layout ของ GUI ที่ไม่รู้จัก)
	  - mobile-only (TouchEnabled); PC คง HUD ครบ
	  - manual override (ปุ่ม 👁) ให้ peek กลับมาได้ระหว่างสู้
	  - opt-out ผ่าน attribute "MobileHudAutoHideOptOut" = true
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local CombatState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatStateController"))

-- config
local MOBILE_ONLY = true
local ATTR_OPT_OUT = "MobileHudAutoHideOptOut"

-- ScreenGui ที่ "ซ่อนได้ตอนสู้" (ambient/notification/social/event — ไม่ใช่ combat HUD)
-- (ชื่อยืนยันจาก src จริง 15 มิ.ย.)
local HIDE_NAMES: { [string]: boolean } = {
	ChatClient = true, -- แชท
	DailyQuestUI = true,
	DailyStreakUI = true,
	FashionShowUI = true,
	DropNotif = true,
	PetDropNotif = true,
	DeathValleyFriendPresenceToast = true,
	DeathValleySocialJoinDigest = true,
	DeathValleyGlobalLeaderboardUI = true,
	DeathValleyLeaderboardHUD = true,
	EmoteHUD = true,
	SkyTreasureHUD = true,
}
-- HUD ที่ "ห้ามซ่อน" (เพื่อความชัดเจน — ไม่อยู่ใน HIDE_NAMES ก็ไม่ถูกแตะอยู่แล้ว):
-- SkillBarGui, AutoBattleGui, TargetingGui, DeathValleyCombatHUD, LevelHUD, MvpBossHUD,
-- DeathValleyHorrorFX, DeathValleySurvivalHUD, DeathValleySpiritChamberHUD, DeathValleyWeeklyBossHUD ฯลฯ

local hiddenByUs: { [ScreenGui]: boolean } = {}
local peeking = false

local function isMobile(): boolean
	-- touch = มือถือ/แท็บเล็ต (รวม Studio Device Emulator). PC ปกติ TouchEnabled=false
	return UserInputService.TouchEnabled
end

local function applyHide(hide: boolean)
	if hide then
		for _, gui in playerGui:GetChildren() do
			if gui:IsA("ScreenGui") and HIDE_NAMES[gui.Name] and gui.Enabled then
				gui.Enabled = false
				hiddenByUs[gui] = true
			end
		end
	else
		for gui in hiddenByUs do
			if gui and gui.Parent then
				gui.Enabled = true
			end
		end
		table.clear(hiddenByUs)
	end
end

-- ───────── manual override (ปุ่ม peek) ─────────
local overlay = Instance.new("ScreenGui")
overlay.Name = "HudVisibilityManager"
overlay.ResetOnSpawn = false
overlay.IgnoreGuiInset = true
overlay.DisplayOrder = 50
overlay.Enabled = false
overlay.Parent = playerGui

local peekBtn = Instance.new("TextButton")
peekBtn.Name = "PeekToggle"
peekBtn.AnchorPoint = Vector2.new(0.5, 0)
peekBtn.Position = UDim2.new(0.5, 0, 0, 6)
peekBtn.Size = UDim2.fromScale(0.085, 0.05)
peekBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
peekBtn.BackgroundTransparency = 0.35
peekBtn.Text = "👁"
peekBtn.TextScaled = true
peekBtn.TextColor3 = Color3.fromRGB(235, 240, 255)
peekBtn.Parent = overlay
do
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 1
	ar.Parent = peekBtn
	local sz = Instance.new("UISizeConstraint")
	sz.MinSize = Vector2.new(40, 40)
	sz.MaxSize = Vector2.new(72, 72)
	sz.Parent = peekBtn
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.25, 0)
	c.Parent = peekBtn
end

peekBtn.Activated:Connect(function()
	peeking = not peeking
	if peeking then
		-- คืน HUD ที่ซ่อนชั่วคราว (ดูข้อมูล)
		for gui in hiddenByUs do
			if gui and gui.Parent then
				gui.Enabled = true
			end
		end
		peekBtn.BackgroundColor3 = Color3.fromRGB(60, 110, 70)
	else
		-- ซ่อนกลับ (ยังอยู่ในสู้)
		for gui in hiddenByUs do
			if gui and gui.Parent then
				gui.Enabled = false
			end
		end
		peekBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	end
end)

local function onCombatChanged(inCombat: boolean)
	if MOBILE_ONLY and not isMobile() then
		return
	end
	if localPlayer:GetAttribute(ATTR_OPT_OUT) == true then
		return
	end
	if inCombat then
		peeking = false
		peekBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
		applyHide(true)
		overlay.Enabled = true
	else
		applyHide(false)
		overlay.Enabled = false
	end
end

CombatState.Changed:Connect(onCombatChanged)
CombatState.Start()
