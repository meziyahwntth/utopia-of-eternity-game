--!strict
--[[
	MercenaryService (P5+) — post/accept/complete escort jobs (session in-memory)
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MercenaryConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MercenaryConfig"))
local CurrencyService = require(script.Parent.Parent:WaitForChild("Commerce"):WaitForChild("CurrencyService"))

export type EscortJobStatus = "open" | "active" | "done" | "cancelled"

export type EscortJob = {
	jobId: string,
	clientId: number,
	mercId: number?,
	pay: number,
	postedAt: number,
	acceptedAt: number?,
	status: EscortJobStatus,
	destination: string,
}

export type PublicEscortJob = {
	jobId: string,
	clientId: number,
	pay: number,
	destination: string,
	postedAt: number,
}

local jobs: { [string]: EscortJob } = {}
local jobCounter = 0

local MercenaryService = {}

local function makeJobId(): string
	jobCounter += 1
	return string.format("job_%d_%d", os.time(), jobCounter)
end

local function getRoot(char: Model): BasePart?
	local root = char:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function MercenaryService.postEscort(client: Player, pay: number, destination: string): (boolean, string)
	if pay < MercenaryConfig.EscortMinPay or pay > MercenaryConfig.EscortMaxPay then
		return false,
			string.format("ค่าจ้างต้อง %d–%d credits", MercenaryConfig.EscortMinPay, MercenaryConfig.EscortMaxPay)
	end
	if destination == "" then
		return false, "ระบุปลายทาง"
	end

	local activeCount = 0
	for _, job in jobs do
		if job.clientId == client.UserId and job.status == "open" then
			activeCount += 1
		end
	end
	if activeCount >= MercenaryConfig.MaxActiveEscorts then
		return false, "โพสต์งานเกินจำนวนสูงสุด"
	end

	local jobId = makeJobId()
	jobs[jobId] = {
		jobId = jobId,
		clientId = client.UserId,
		mercId = nil,
		pay = pay,
		postedAt = os.time(),
		acceptedAt = nil,
		status = "open",
		destination = destination,
	}
	return true, jobId
end

function MercenaryService.acceptEscort(merc: Player, jobId: string): (boolean, string)
	local job = jobs[jobId]
	if not job then
		return false, "ไม่พบงาน"
	end
	if job.status ~= "open" then
		return false, "งานถูกรับแล้ว"
	end
	if job.clientId == merc.UserId then
		return false, "ไม่สามารถรับงานตัวเองได้"
	end

	job.mercId = merc.UserId
	job.acceptedAt = os.time()
	job.status = "active"

	task.delay(MercenaryConfig.EscortTimeoutSecs, function()
		local current = jobs[jobId]
		if current and current.status == "active" then
			current.status = "cancelled"
			jobs[jobId] = nil
			warn("[Mercenary] job timed out:", jobId)
		end
	end)

	return true, "รับงานสำเร็จ"
end

function MercenaryService.completeEscort(client: Player, jobId: string): (boolean, string)
	local job = jobs[jobId]
	if not job then
		return false, "ไม่พบงาน"
	end
	if job.clientId ~= client.UserId then
		return false, "ไม่ใช่งานของคุณ"
	end
	if job.status ~= "active" then
		return false, "งานไม่ได้ active"
	end
	if not job.mercId then
		return false, "ไม่มี Mercenary"
	end

	local clientChar = client.Character
	local merc = Players:GetPlayerByUserId(job.mercId)
	local mercChar = if merc then merc.Character else nil
	if clientChar and mercChar then
		local clientRoot = getRoot(clientChar)
		local mercRoot = getRoot(mercChar)
		if clientRoot and mercRoot then
			local dist = (clientRoot.Position - mercRoot.Position).Magnitude
			if dist > MercenaryConfig.EscortProtectRadius then
				return false,
					string.format("Mercenary ห่างเกิน %d studs", MercenaryConfig.EscortProtectRadius)
			end
		end
	end

	job.status = "done"
	jobs[jobId] = nil

	if merc then
		CurrencyService.addCredits(merc.UserId, job.pay)
	end

	return true, string.format("งานเสร็จ — โอน %d credits ให้ Mercenary", job.pay)
end

function MercenaryService.getOpenJobs(): { PublicEscortJob }
	local result: { PublicEscortJob } = {}
	for _, job in jobs do
		if job.status == "open" then
			table.insert(result, {
				jobId = job.jobId,
				clientId = job.clientId,
				pay = job.pay,
				destination = job.destination,
				postedAt = job.postedAt,
			})
		end
	end
	return result
end

return MercenaryService
