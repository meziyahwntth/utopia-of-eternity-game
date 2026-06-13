--!strict
--[[
	MercenaryConfig (P5+) — escort jobs + bounty limits
]]
local MercenaryConfig = {}

MercenaryConfig.EscortTimeoutSecs = 300
MercenaryConfig.EscortMinPay = 50
MercenaryConfig.EscortMaxPay = 5000
MercenaryConfig.MaxActiveEscorts = 3
MercenaryConfig.EscortProtectRadius = 30

MercenaryConfig.BountyMinAmount = 100
MercenaryConfig.BountyMaxAmount = 50000
MercenaryConfig.BountyExpiryDays = 7
MercenaryConfig.MaxBountiesPerPlayer = 5
MercenaryConfig.BountyKillProximity = 50

return MercenaryConfig
