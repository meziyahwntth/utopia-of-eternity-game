--!strict
--[[
	AirTransportConfig (V2 P2) — ระบบขนส่งสาธารณะ
	  • NeonToUtopia    : Neon Utopia → Utopia of Eternity (เครื่องบิน)
	  • UtopiaToHellbound: Utopia → Hellbound/หุบเขามรณะ (Hyper Space ข้ามมิติ — reuse HellboundTerminalService)
	ค่าโดยสาร: จ่ายด้วย "ตั๋วโดยสาร" (TravelTicket — แยกจาก prism key ไม่กระทบ level) หรือ "robux"
	TODO(Product): สร้าง Developer Product แล้วใส่ robuxProductId (ตอนนี้ 0 = robux ยังไม่เปิด, ใช้ตั๋วได้)
]]
local AirTransportConfig = {}

export type Route = {
	id: string,
	displayName: string,
	fromPlaceKey: string,
	toPlaceKey: string,
	kind: string, -- "air" | "hyperspace"
	fareTickets: number, -- จำนวนตั๋วโดยสารที่หัก (TravelTicket — ไม่กระทบ progression)
	fareRobux: number, -- ราคา robux (โชว์บนป้าย)
	robuxProductId: number, -- Developer Product id (0 = ยังไม่สร้าง)
}

AirTransportConfig.Routes = {
	NeonToUtopia = {
		id = "NeonToUtopia",
		displayName = "Neon Utopia \u{2192} Utopia of Eternity",
		fromPlaceKey = "NeonUtopia",
		toPlaceKey = "EternityCity",
		kind = "air",
		fareTickets = 1,
		fareRobux = 25,
		robuxProductId = 0, -- TODO
	},
	UtopiaToHellbound = {
		id = "UtopiaToHellbound",
		displayName = "Utopia \u{2192} Hellbound (Hyper Space)",
		fromPlaceKey = "EternityCity",
		toPlaceKey = "DeathValley",
		kind = "hyperspace",
		fareTickets = 1,
		fareRobux = 35,
		robuxProductId = 0, -- TODO
	},
} :: { [string]: Route }

return AirTransportConfig
