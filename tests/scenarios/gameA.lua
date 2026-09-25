-- Plays game A to game over. An autopilot drops each piece where the stack is lowest, and a row only
-- needs to be half full to clear (the game needs 8.1 of 10 blocks), so lines get cleared all the time
-- and the line cutting is exercised heavily: pieces cut in half, split into several bodies, removed.
local current, target = nil, 224

local function stacktop(x) --y of the highest landed piece at x (bottom of the field if none)
	local top = 576
	world:rayCast(x, -200, x, 576, function(fixture, hx, hy, nx, ny, fraction)
		local data = fixture:getUserData()
		if type(data) == "table" and type(data[1]) == "number" and data[1] ~= 1 and hy < top then
			top = hy
		end
		return 1
	end)
	return top
end

local function bestcolumn(piece) --centre x where the stack under the piece's width is lowest
	local minx, maxx = math.huge, -math.huge
	for _, shape in pairs(piece.shapes) do
		local pts = {shape:getPoints()}
		for i = 1, #pts, 2 do
			minx, maxx = math.min(minx, pts[i]), math.max(maxx, pts[i])
		end
	end
	local best, besttop = 224, -math.huge
	for c = 56 - minx, 384 - maxx, 8 do
		local top = math.huge
		for x = c + minx + 6, c + maxx - 6, 10 do
			top = math.min(top, stacktop(x))
		end
		if top > besttop then
			best, besttop = c, top
		end
	end
	return best
end

local function autopilot(log, held)
	local piece = tetris and tetris[1]
	held.down = nil
	held.left, held.right = nil, nil
	if not piece or gamestate ~= "gameA" then
		return
	end
	if piece ~= current then
		current = piece
		target = bestcolumn(piece)
	end
	--steer towards a speed proportional to the distance left, and only drop fast once lined up
	local x = piece.body:getX()
	local vx = piece.body:getLinearVelocity()
	local wanted = math.max(-150, math.min(150, (target - x)*4))
	if vx < wanted - 10 then
		held.right = true
	elseif vx > wanted + 10 then
		held.left = true
	end
	held.down = math.abs(target - x) < 6 and math.abs(vx) < 20 or nil
end

return {
	{state="title", timeout=20}, {wait=0.5}, {shot="01_title"},
	{press="return"}, {wait=0.5}, {shot="02_menu"},
	{press="return"}, {state="gameA"}, {wait=2}, {shot="03_gameA_start"},
	{press="x"}, {press="left"}, {press="left"}, {wait=0.2},
	{press="return"}, {wait=0.5}, {shot="04_paused"}, {press="return"},
	{call=function(log) linecleartreshold = 5 end}, {hook=autopilot}, {wait=15}, {shot="05_gameA_mid"}, {dump="d05_gameA_mid"},
	{wait=30}, {dump="d06_gameA_late"}, {call=function(log) linecleartreshold = 8.1 end}, --back to normal so the stack tops out
	{state="failed", timeout=600}, {hook=false}, {release="down"}, {wait=1}, {shot="06_failed"},
	{call=function(log) log("final score", scorescore, "lines", linesscore) end},
	{wait=3}, {press="return"}, {wait=2}, {shot="07_after_failed"},
	{call=function(log) log("state after failed:", gamestate) end},
	{wait=10}, {shot="08_later"}, {press="return"}, {wait=2},
	{call=function(log) log("state:", gamestate) end},
	{press="a", text="a"}, {press="b", text="b"}, {press="backspace"}, {wait=0.5}, {shot="09_hs"},
	{press="return"}, {wait=1}, {shot="10_end"}, {quit=true},
}
