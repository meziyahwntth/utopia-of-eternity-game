--!strict
--[[
	Summer Music Festival Phase 1 — Stage C: Countdown Display (Client)
	Finds FestivalCountdownSign parts in workspace, reads CountdownTargetUnix attribute,
	displays real-time DD:HH:MM:SS countdown via BillboardGui CountdownText.
	Updates every 1 second via task.wait loop.
]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local function formatCountdown(remaining: number): string
	if remaining <= 0 then
		return "NOW LIVE!"
	end
	local days = math.floor(remaining / 86400)
	local hours = math.floor((remaining % 86400) / 3600)
	local minutes = math.floor((remaining % 3600) / 60)
	local secs = remaining % 60
	return string.format("%02d:%02d:%02d:%02d", days, hours, minutes, secs)
end

local function updateSigns()
	while true do
		for _, model in Workspace:GetDescendants() do
			if model:IsA("Model") or model:IsA("Folder") then
				local signPart = model:FindFirstChild("FestivalCountdownSign")
				if signPart and signPart:IsA("BasePart") then
					local targetUnix = signPart:GetAttribute("CountdownTargetUnix")
					if typeof(targetUnix) == "number" and targetUnix > 0 then
						local remaining = targetUnix - os.time()
						local text = formatCountdown(math.max(0, remaining))
						local gui = signPart:FindFirstChild("CountdownGui")
						if gui and gui:IsA("BillboardGui") then
							local frame = gui:FindFirstChild("Frame")
							if frame then
								local label = frame:FindFirstChild("CountdownText")
								if label and label:IsA("TextLabel") then
									label.Text = text
								end
							end
						end
					end
				end
			end
		end
		task.wait(1)
	end
end

-- Wait for world to be built (player character spawns)
player.CharacterAdded:Wait()
task.wait(3) -- extra buffer for post-build hooks

task.spawn(updateSigns)
print("[FestivalCountdown] Client countdown loop started")