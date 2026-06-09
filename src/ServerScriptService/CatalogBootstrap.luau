--!strict
--[[
	Apply CatalogSecrets → PrismCatalogAssets.registerProduct (P0 publish).
	Called from BridgeBootstrap before commerce / preset pack services start.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PrismCatalogAssets = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PrismCatalogAssets"))
local PublishRequirements = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PublishRequirements"))

local CatalogBootstrap = {}
local applied = false

local function tryRequireCatalogSecrets(): { [string]: number }?
	local secretsFolder = ServerScriptService:FindFirstChild("Secrets")
	if not secretsFolder then
		return nil
	end
	local inst = secretsFolder:FindFirstChild("CatalogSecrets")
	if not inst or not inst:IsA("ModuleScript") then
		return nil
	end
	local ok, value = pcall(require, inst)
	if ok and typeof(value) == "table" then
		return value
	end
	warn("[Utopia] Failed to load CatalogSecrets:", value)
	return nil
end

function CatalogBootstrap:Apply()
	if applied then
		return
	end
	applied = true

	local catalogSecrets = tryRequireCatalogSecrets()
	if not catalogSecrets then
		return
	end

	local registered = 0
	for itemId, productId in catalogSecrets do
		if typeof(itemId) == "string" and typeof(productId) == "number" and productId > 0 then
			PrismCatalogAssets.registerProduct(itemId, productId)
			registered += 1
		end
	end

	if registered > 0 then
		print(string.format("[Utopia] CatalogBootstrap registered %d developer products", registered))
	end

	local missingP0: { string } = {}
	for _, key in PublishRequirements.P0DeveloperProductKeys do
		if PrismCatalogAssets.getProductId(key) <= 0 then
			table.insert(missingP0, key)
		end
	end
	if #missingP0 > 0 and not game:GetService("RunService"):IsStudio() then
		warn("[Utopia] P0 developer products missing (live server):", table.concat(missingP0, ", "))
	end
end

return CatalogBootstrap
