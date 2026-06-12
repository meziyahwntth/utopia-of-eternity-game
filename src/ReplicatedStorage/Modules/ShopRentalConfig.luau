--!strict
--[[
	Player shop rental — Phase A config (lease tiers, zones, NPC copy).
	See docs/GDD-SHOP-RENTAL-COMMERCE.md
]]
local ShopRentalConfig = {}

export type ShopZone = "Clothing" | "Jewelry" | "Pets" | "Vehicles" | "Mounts" | "Weapons"
export type BuildingCode = "UP" | "ET"

export type RentTier = {
	days: number,
	productKey: string,
	robuxHint: number,
}

export type PromoterQA = {
	q: string,
	a: string,
}

ShopRentalConfig.DataStoreLease = "ShopLease_v1"
ShopRentalConfig.DataStoreReceipts = "ShopRentReceipts_v1"
ShopRentalConfig.DataStoreCompensation = "ShopRentCompensation_v1"

ShopRentalConfig.UPFloors = 4
ShopRentalConfig.UPSlotsPerFloor = 8
ShopRentalConfig.ETFloors = 4
ShopRentalConfig.ETSlotsPerFloor = 6

ShopRentalConfig.RentTiers = {
	{ days = 7, productKey = "shop_rent_7d", robuxHint = 99 },
	{ days = 30, productKey = "shop_rent_30d", robuxHint = 299 },
} :: { RentTier }

ShopRentalConfig.MaxLeasesPerBuilding = 1

-- Slot offsets relative to district base (avoid escalator/lift/stair openings)
ShopRentalConfig.UPSlotOffsets = {
	Vector3.new(-38, 0, 40),
	Vector3.new(18, 0, 42),
	Vector3.new(-38, 0, -14),
	Vector3.new(18, 0, -42),
	Vector3.new(-42, 0, 22),
	Vector3.new(-42, 0, -22),
	Vector3.new(24, 0, 14),
	Vector3.new(24, 0, -14),
}

ShopRentalConfig.ETSlotOffsets = {
	Vector3.new(-28, 0, 28),
	Vector3.new(0, 0, 28),
	Vector3.new(28, 0, 28),
	Vector3.new(-28, 0, -28),
	Vector3.new(0, 0, -28),
	Vector3.new(28, 0, -28),
}

ShopRentalConfig.PromoterLines = {
	"เช่าร้านในห้าง UtopiaPlaza และ EternityTower — เริ่มธุรกิจของคุณวันนี้!",
	"ห้องว่างพร้อมให้เช่า — กดป้าย FOR RENT หน้าร้านเพื่อดูรายละเอียด",
	"ขายเสื้อผ้า เครื่องประดับ สัตว์เลี้ยง ยานพาหนะ และอาวุธ PvE ตามโซนที่กำหนด",
	"ผู้ขายรับเครดิตในเกมเมื่อมีคนซื้อ — ไม่มีการโอน Robux ตรงถึงผู้เล่น",
	"ส่งดีไซน์ผ่านตู้ Decal ในเกม — อัปโหลดภาพบน Roblox แล้วกรอก asset id",
	"สัญญาเช่า 7 หรือ 30 วัน — หมดอายุแล้วร้านกลับเป็นห้องว่างอัตโนมัติ",
}

ShopRentalConfig.PromoterQA = {
	{ q = "ค่าเช่าเท่าไหร่?", a = "มี 2 แพ็กเกจ: 7 วัน และ 30 วัน ชำระด้วย Robux ผ่าน Developer Product ตอนกดเช่า — ดูราคาในหน้าห้องว่าง" },
	{ q = "เช่ายังไง?", a = "เดินไปหาป้าย FOR RENT หน้าร้าน → กด ProximityPrompt → เลือกแพ็กเกจ → ชำระ Robux ทันที" },
	{ q = "ขายอะไรได้บ้าง?", a = "ตามโซน: UtopiaPlaza ชั้น 1-2 เสื้อผ้า, ชั้น 3 เครื่องประดับ, ชั้น 4 สัตว์เลี้ยง · EternityTower ชั้น 1-2 ยานพาหนะ, ชั้น 3 สัตว์พาหนะ, ชั้น 4 อาวุธ PvE" },
	{ q = "ผู้ขายได้เงินอย่างไร?", a = "เมื่อมีคนซื้อสินค้าในร้าน คุณจะได้เครดิตในเกม (Shop Credit) ตามราคาขาย — ใช้ซื้อของในเกมได้" },
	{ q = "ส่งดีไซน์เองได้ไหม?", a = "ได้ — อัปโหลดภาพเป็น Decal บน Roblox แล้วกรอก asset id ที่ตู้ส่งดีไซน์ในเกม (เฟสถัดไป) ห้ามใช้อีเมลหรือช่องทางนอกแพลตฟอร์ม" },
	{ q = "เช่าได้กี่ร้าน?", a = "ได้ 1 ร้านต่ออาคาร (UtopiaPlaza 1 + EternityTower 1 สูงสุด 2 ร้าน)" },
	{ q = "หมดอายุแล้วเกิดอะไร?", a = "ร้านกลับเป็นห้องว่าง ป้ายแสดง FOR RENT อีกครั้ง สินค้าคืนเข้ากระเป๋าคุณอัตโนมัติ (เฟส B)" },
} :: { PromoterQA }

function ShopRentalConfig.formatRoomId(building: BuildingCode, floor: number, slot: number): string
	return string.format("%s-%d-%02d", building, floor, slot)
end

function ShopRentalConfig.getZone(building: BuildingCode, floor: number): ShopZone
	if building == "UP" then
		if floor <= 2 then
			return "Clothing"
		elseif floor == 3 then
			return "Jewelry"
		end
		return "Pets"
	end
	if floor <= 2 then
		return "Vehicles"
	elseif floor == 3 then
		return "Mounts"
	end
	return "Weapons"
end

function ShopRentalConfig.getBuildingFromRoomId(roomId: string): BuildingCode?
	if string.sub(roomId, 1, 3) == "UP-" then
		return "UP"
	end
	if string.sub(roomId, 1, 3) == "ET-" then
		return "ET"
	end
	return nil
end

function ShopRentalConfig.listAllRoomIds(): { string }
	local ids: { string } = {}
	for floor = 1, ShopRentalConfig.UPFloors do
		for slot = 1, ShopRentalConfig.UPSlotsPerFloor do
			table.insert(ids, ShopRentalConfig.formatRoomId("UP", floor, slot))
		end
	end
	for floor = 1, ShopRentalConfig.ETFloors do
		for slot = 1, ShopRentalConfig.ETSlotsPerFloor do
			table.insert(ids, ShopRentalConfig.formatRoomId("ET", floor, slot))
		end
	end
	return ids
end

return ShopRentalConfig
