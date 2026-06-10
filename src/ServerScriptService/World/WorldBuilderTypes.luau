--!strict
--[[
	WorldBuilderTypes — สัญญากลางระหว่าง BuildOrchestrator ↔ *WorldBuilder
	(Blueprint §4.1 — docs/MAP-CHARACTER-REBUILD-BLUEPRINT.md)

	กติกา:
	  - Builder เป็น "pure": สร้าง part แล้วคืน BuildResult เท่านั้น
	  - ห้าม builder เรียก WorldBuildState / ห่อ pcall รอบตัวเอง / แตะ CharacterAutoLoads
	  - BuildOrchestrator เป็นจุดเดียวที่ห่อ pcall และ set WorldBuildState
]]

local WorldBuilderTypes = {}

export type BuildResult = {
	ok: boolean,
	model: Model?, -- model ที่สร้าง (nil เมื่อ skip/fail)
	skipped: boolean, -- true = ไม่ใช่ place นี้ หรือสร้างไว้แล้ว
	reason: string?, -- ข้อความอธิบายเมื่อ ok=false หรือ skip
}

export type BuildContext = {
	placeKey: string, -- place key จาก PlaceRouter (WorldPlaceGuard)
}

-- Helper constructors — ให้ทุก builder คืนรูปเดียวกันเป๊ะ

function WorldBuilderTypes.success(model: Model?): BuildResult
	return { ok = true, model = model, skipped = false, reason = nil }
end

function WorldBuilderTypes.skip(reason: string?): BuildResult
	return { ok = true, model = nil, skipped = true, reason = reason }
end

function WorldBuilderTypes.fail(reason: string): BuildResult
	return { ok = false, model = nil, skipped = false, reason = reason }
end

return WorldBuilderTypes
