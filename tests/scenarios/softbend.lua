-- Soft body pieces bending: an I bar dropped (with down held) across a single O block and a T landing on
-- its tip. Every third frame of the bottom of the field is tiled into one image, sbend.png, so the
-- whole impact, bend and wobble can be compared at a glance.
local S = 3 --window scale
local cols, rows, every = 6, 5, 3
local x0, y0, w, h = 14*S, 70*S, 82*S, 74*S --the part of the screen kept: the bottom of the field
local sheet, count, frame = nil, 0, 0

local function place(kind, x, y, angle, vy, falling) --a soft piece with its centre at x, y, turned by angle
	local index = falling and 1 or #tetris + 1
	local piece = newpiece(kind, x, y, 1)
	tetris[index] = piece
	setpiecedata(piece, {index})
	local body = piece.body
	local c, s = math.cos(angle), math.sin(angle)
	for i = 1, body.n do
		local dx, dy = body.x[i] - x, body.y[i] - y
		body.x[i], body.y[i] = x + c*dx - s*dy, y + s*dx + c*dy
		body.ox[i], body.oy[i] = body.x[i], body.y[i]
	end
	body:updatebounds()
	setpiecevelocity(piece, 0, vy)
end

local function setup(log)
	scale = S
	changescale(S)
	for i = #softworld.bodies, 1, -1 do --clear the field, keeping the walls
		if not softworld.bodies[i].static then
			table.remove(softworld.bodies, i)
		end
	end
	tetris = {false}
	place(4, 140, 544, 0, 0)
	place(1, 140, 380, 0, 400, true)
	place(6, 290, 420, math.pi/4, 300)
	sheet = love.image.newImageData(cols*w, rows*h)
end

local function capture(log, held)
	frame = frame + 1
	if frame % every == 0 and count < cols*rows then
		local index = count
		count = count + 1
		love.graphics.captureScreenshot(function(img)
			sheet:paste(img, (index % cols)*w, math.floor(index/cols)*h, x0, y0, w, h)
			if index == cols*rows - 1 then
				sheet:encode("png", "sbend.png")
				log("sheet done")
			end
		end)
	end
end

return {
	{state="title", timeout=20}, {call=function(log) softbody = true end},
	{press="return"}, {state="menu"}, {press="return"}, {state="gameA"}, {wait=0.2},
	{call=setup}, {hold="down"}, {hook=capture}, {wait=(cols*rows*every + 4)/60},
	{dump="sbend_d"}, {quit=true},
}
