local function dump(log, tag)
	log(tag, "lines=", linesscore, "score=", scorescore, "bodies=", highestbody())
	for i = 2, highestbody() do
		local b = tetris[i].body
		local minx, miny, maxx, maxy = 1e9, 1e9, -1e9, -1e9
		for j, sh in pairs(tetris[i].shapes) do
			local pts = getPoints2table(sh, b)
			for k = 1, #pts, 2 do
				minx = math.min(minx, pts[k]); maxx = math.max(maxx, pts[k])
				miny = math.min(miny, pts[k+1]); maxy = math.max(maxy, pts[k+1])
			end
		end
		local nf = 0; for _ in pairs(tetris[i].fixtures) do nf = nf + 1 end
		log(string.format("  body %d kind %d shapes %d fixtures %d bbox x[%.0f,%.0f] y[%.0f,%.0f]", i, tetris[i].kind, #tetris[i].shapes, nf, minx, maxx, miny, maxy))
	end
end
local function place(kind, x, y)
	local id = highestbody() + 1
	createtetriA(kind, id, x, y)
	for _, f in pairs(tetris[id].fixtures) do f:setUserData({id}) end
	tetris[id].body:setLinearDamping(0.5)
end
return {
	{state="title", timeout=20}, {press="return"}, {press="return"}, {state="gameA"}, {wait=0.2},
	{call=function(log)
		place(1, 120, 560); place(1, 248, 560); place(4, 344, 544)
		tetris[1].body:setPosition(150, 380) -- land the falling piece on the left I piece
	end},
	{wait=0.3}, {call=function(log) dump(log, "before") end},
	{hold="down"}, {wait=0.02},
	{call=function(log) log("waiting for clear") end},
	{wait=1.5}, {release="down"}, {shot="lc01_during"}, {call=function(log) log("cuttingtimer", cuttingtimer) end},
	{wait=0.35}, {shot="lc015_scoreadd"}, {call=function(log) log("scoreaddtimer", scoreaddtimer) end},
	{wait=2.65}, {call=function(log) dump(log, "after") end}, {shot="lc02_after"}, {dump="lc_after"},
	{quit=true},
}
