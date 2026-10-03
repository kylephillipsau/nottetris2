-- Game B (stack) with soft body pieces, nudging pieces around until the stack tops out.
local scenario = {
	{state="title", timeout=20}, {call=function(log) softbody = true end},
	{press="return"}, {state="menu"}, {press="right"}, {press="return"}, {state="gameB"}, {wait=1}, {shot="sb01_falling"},
	{hold="down"},
}
for round = 1, 6 do
	for _, nudge in ipairs({{"left", 0.3}, {"right", 0.5}, {"x", 0.4}, {"left", 0.2}}) do
		table.insert(scenario, {hold=nudge[1]}); table.insert(scenario, {wait=nudge[2]}); table.insert(scenario, {release=nudge[1]}); table.insert(scenario, {wait=0.6})
	end
end
for _, s in ipairs({
	{shot="sb02_stack"}, {dump="sb_d1"},
	{state="failed", timeout=400}, {release="down"}, {wait=1}, {shot="sb03_failed"},
	{call=function(log) log("final score", scorescore) end},
	{quit=true},
}) do table.insert(scenario, s) end
return scenario
