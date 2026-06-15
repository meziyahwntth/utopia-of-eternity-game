--!strict
--[[
	CombatStateController (Mobile-UX audit) — single source of truth (client)
	ว่าผู้เล่น "กำลังอยู่ในการต่อสู้" หรือไม่ เพื่อให้ HUD อื่น (HudVisibilityManager)
	ใช้ตัดสิน auto-hide/collapsible ตอนสู้.

	API:
	  CombatStateController.IsInCombat(): boolean
	  CombatStateController.Changed: RBXScriptSignal  -- ส่ง (inCombat: boolean) เมื่อค่าเปลี่ยนจริง
	  CombatStateController.EnterCombat(reason: string?)  -- ต่ออายุ timer; เรียกจาก combat actions
	  CombatStateController.Start()  -- idempotent; auto-detect (damage + target lock)

	ตรรกะ:
	  - เข้าสู่ combat เมื่อ: ยิงสกิล / เปิด Auto-Battle / ล็อกเป้า / ได้รับดาเมจ (เรียก EnterCombat)
	  - ออกจาก combat อัตโนมัติเมื่อไม่มี ping ต่อเนื่อง COMBAT_IDLE_SECONDS วินาที
	  - ยิง Changed เฉพาะตอนค่าเปลี่ยนจริง (กัน spam)

	Server-safe: auto-init ฝั่ง client เท่านั้น (guard ด้วย RunService:IsClient()).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CombatStateController = {}

-- ปรับได้จุดเดียว
local COMBAT_IDLE_SECONDS = 5

local inCombat = false
local lastPingAt = 0
local started = false

local changedBindable = Instance.new("BindableEvent")
CombatStateController.Changed = changedBindable.Event

function CombatStateController.IsInCombat(): boolean
	return inCombat
end

local function setInCombat(value: boolean)
	if value == inCombat then
		return
	end
	inCombat = value
	changedBindable:Fire(inCombat)
end

-- ต่ออายุ timer ทุกครั้งที่มี combat activity
function CombatStateController.EnterCombat(_reason: string?)
	lastPingAt = os.clock()
	if not inCombat then
		setInCombat(true)
	end
end

-- ───────── client auto-detection + idle loop ─────────
local function hookCharacter(character: Model)
	local hum = character:FindFirstChildOfClass("Humanoid")
		or character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hum then
		return
	end
	local lastHealth = hum.Health
	hum.HealthChanged:Connect(function(newHealth: number)
		if newHealth < lastHealth then
			-- ได้รับดาเมจ = อยู่ในสู้
			CombatStateController.EnterCombat("damage")
		end
		lastHealth = newHealth
	end)
end

function CombatStateController.Start()
	if started or not RunService:IsClient() then
		return
	end
	started = true

	local localPlayer = Players.LocalPlayer
	if localPlayer then
		if localPlayer.Character then
			hookCharacter(localPlayer.Character)
		end
		localPlayer.CharacterAdded:Connect(hookCharacter)
	end

	-- ล็อกเป้า = เข้าสู่ combat (subscribe โดยไม่แก้ TargetingController)
	local ok, Targeting = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TargetingController"))
	end)
	if ok and typeof(Targeting) == "table" and typeof(Targeting.onChanged) == "function" then
		Targeting.onChanged(function(_model, locked)
			if locked then
				CombatStateController.EnterCombat("lock")
			end
		end)
	end

	-- idle loop: ออกจาก combat เมื่อเงียบเกิน COMBAT_IDLE_SECONDS
	RunService.Heartbeat:Connect(function()
		if inCombat and (os.clock() - lastPingAt) > COMBAT_IDLE_SECONDS then
			setInCombat(false)
		end
	end)
end

return CombatStateController
