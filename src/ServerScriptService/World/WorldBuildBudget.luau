--!strict
local WorldBuildBudget = {}

export type Budget = {
	count: number,
	max: number,
	warned: boolean,
}

function WorldBuildBudget:new(max: number): Budget
	return { count = 0, max = max, warned = false }
end

function WorldBuildBudget:canAdd(budget: Budget, n: number?): boolean
	n = n or 1
	return budget.count + n <= budget.max
end

function WorldBuildBudget:add(budget: Budget, n: number?)
	n = n or 1
	budget.count += n
	if not budget.warned and budget.count >= budget.max * 0.9 then
		budget.warned = true
		warn("[Utopia WorldBuild] Approaching part budget:", budget.count, "/", budget.max)
	end
end

function WorldBuildBudget:report(placeKey: string, budget: Budget)
	print(string.format("[Utopia WorldBuild] %s parts: %d / %d", placeKey, budget.count, budget.max))
end

return WorldBuildBudget
