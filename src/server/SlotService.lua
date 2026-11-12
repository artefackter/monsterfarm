-- Graves and field zombies are placed freely now (PlacementRules), so the ground no longer shows cells,
-- closed tiles or brain crops. Places are bought from the upgrade boards. This keeps the old entry
-- points so callers and tests don't need to know, and clears any leftover cell folder.
local P = require(script.Parent.PlotService)
local M = { State = {} }

function M.Render(p)
	local plot = P.Assigned[p]
	if not plot or M.State[p] then
		return
	end
	M.State[p] = true
	local old = plot.Model:FindFirstChild("Slots")
	if old then
		old:Destroy()
	end
end

function M.Forget(p)
	M.State[p] = nil
end

return M
