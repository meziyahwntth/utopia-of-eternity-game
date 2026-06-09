--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local BackdoorScanner = {}

local DANGEROUS_PATTERNS = {
	"loadstring",
	"getfenv",
	"setfenv",
	"HttpGet",
	"discord.com/api/webhooks",
}

function BackdoorScanner:Scan()
	local securityFolder = ServerScriptService:FindFirstChild("Security")
	if not securityFolder then
		warn("[Utopia Shield] Security folder missing — scan skipped")
		return
	end
	local hits: { string } = {}
	for _, descendant in ServerScriptService:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then
			local source = descendant.Source
			for _, pattern in DANGEROUS_PATTERNS do
				if string.find(source, pattern, 1, true) then
					table.insert(hits, string.format("%s (%s)", descendant:GetFullName(), pattern))
				end
			end
			if string.find(source, "require(%d", 1, false) or string.find(source, 'require("%d', 1, false) then
				table.insert(hits, descendant:GetFullName() .. " (numeric require)")
			end
		end
	end
	if #hits > 0 then
		warn("[Utopia Shield] Backdoor scan flagged " .. #hits .. " issue(s):")
		for _, hit in hits do
			warn("  - " .. hit)
		end
	else
		print("[Utopia Shield] Backdoor scan clean.")
	end
end

return BackdoorScanner
