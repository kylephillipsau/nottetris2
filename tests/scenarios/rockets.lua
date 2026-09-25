-- Game A to game over twice with rigged scores, to watch a small rocket (2) and the space shuttle (4) launch.
local scenario = {{state="title", timeout=20}, {press="return"}, {state="menu"}}
local function launch(tag, score, shots)
	for _, s in ipairs({
		{press="return"}, {state="gameA"}, {hold="down"}, {state="failed", timeout=400}, {release="down"},
		{call=function(log) scorescore = score end}, {wait=0.5}, {press="return"}, {wait=0.1},
		{call=function(log) log(tag, "state", gamestate) end},
	}) do table.insert(scenario, s) end
	local t = 0
	for _, at in ipairs(shots) do
		table.insert(scenario, {wait=at - t}); table.insert(scenario, {shot=string.format("%s_%04.1f", tag, at)})
		t = at
	end
	table.insert(scenario, {wait=0.1}) -- a shot is taken after the frame is drawn, so let it happen before skipping
	table.insert(scenario, {press="return"}) -- skip the rest
	table.insert(scenario, {wait=0.5}); table.insert(scenario, {press="return"}) -- leave highscore entry
	table.insert(scenario, {state="menu"})
end
launch("rocket2", 7500, {2, 5, 8.2, 8.6, 12})
launch("rocket4", 16000, {4, 10, 12.5, 13.2, 20, 36.3, 37})
table.insert(scenario, {quit=true})
return scenario
