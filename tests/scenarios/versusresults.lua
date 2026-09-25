-- Three quick versus rounds ending in a P1 win, a P2 win and a draw, to cover every results screen.
local scenario = {
	{state="title", timeout=20}, {press="right"}, {press="return"}, {state="multimenu"},
}
local function round(tag, rig)
	local steps = {
		{press="return"}, {state="gameBmulti"}, {wait=4.5},
		{hold="s"}, {hold="down"},
	}
	if rig.lines then
		table.insert(steps, {call=function(log) linesscorep1, linesscorep2 = rig.lines[1], rig.lines[2] end})
	end
	table.insert(steps, {state="failingBmulti", timeout=300})
	if rig.winner then
		table.insert(steps, {call=function(log) winner = rig.winner end})
	end
	for _, s in ipairs({
		{release="s"}, {release="down"},
		{state="gameBmulti_results", timeout=300}, {wait=0.5}, {shot=tag .. "_a"},
		{hold="a"}, {hold="left"}, {wait=0.7}, {release="a"}, {release="left"}, {shot=tag .. "_b"},
		{wait=1.6}, {shot=tag .. "_c"},
		{call=function(log) log(tag, "winner", winner, "wins", p1wins, p2wins) end},
		{press="return"}, {state="multimenu"}, {wait=0.2}, {shot=tag .. "_menu"},
	}) do table.insert(steps, s) end
	for _, s in ipairs(steps) do table.insert(scenario, s) end
end
round("r1_mario", {lines = {40, 0}})
round("r2_luigi", {lines = {0, 40}})
round("r3_draw", {winner = 3})
table.insert(scenario, {quit=true})
return scenario
