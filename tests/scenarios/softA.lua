-- Game A with soft body pieces: an autopilot drops pieces where the stack is lowest and rows only need
-- to be half full to clear, so soft blocks land, wobble, get cut and fall apart.
local current, target = nil, 224

local function center(piece)
	return piece.body:getWorldCenter()
end

local function velocity(piece)
	return (piece.body:getLinearVelocity())
end

local function stacktop(x) --highest edge of a landed soft piece above x
	local top = 576
	for i = 2, table.maxn(tetris) do
		local b = tetris[i] and tetris[i].body
		if b then
			for e = 1, b.nbe do
				local ax, ay, bx, by = b.x[b.ba[e]], b.y[b.ba[e]], b.x[b.bb[e]], b.y[b.bb[e]]
				if (ax <= x) ~= (bx <= x) then
					top = math.min(top, ay + (x - ax)/(bx - ax)*(by - ay))
				end
			end
		end
	end
	return top
end

local function bestcolumn()
	local best, besttop = 224, -math.huge
	for c = 120, 320, 8 do
		local top = math.huge
		for x = c - 40, c + 40, 10 do
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
	held.left, held.right, held.down = nil, nil, nil
	if not piece or gamestate ~= "gameA" then
		return
	end
	if piece ~= current then
		current = piece
		target = bestcolumn()
	end
	local x = center(piece)
	local vx = velocity(piece)
	local wanted = math.max(-150, math.min(150, (target - x)*4))
	if vx < wanted - 10 then
		held.right = true
	elseif vx > wanted + 10 then
		held.left = true
	end
	held.down = math.abs(target - x) < 6 and math.abs(vx) < 20 or nil
end

return {
	{state="title", timeout=20}, {call=function(log) softbody = true end},
	{press="return"}, {state="menu"}, {press="return"}, {state="gameA"}, {wait=1.5}, {shot="sa01_falling"},
	{hold="x"}, {wait=0.6}, {release="x"}, {shot="sa02_turning"},
	{hold="left"}, {wait=0.5}, {release="left"}, {shot="sa03_moved"},
	{call=function(log) linecleartreshold = 5 end}, {hook=autopilot},
	{wait=12}, {shot="sa04_stack"}, {dump="sa_d1"},
	{wait=20}, {shot="sa05_later"}, {dump="sa_d2"},
	{call=function(log) linecleartreshold = 100 end}, {hook=false}, {hold="down"}, --no more clears, so the stack tops out
	{state="failed", timeout=600}, {release="down"}, {wait=1}, {shot="sa06_failed"},
	{call=function(log) log("final score", scorescore, "lines", linesscore) end},
	{quit=true},
}
