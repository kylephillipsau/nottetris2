--Pieces are drawn as vector art: coloured rectangles in a piece's own coordinates (32 units per block),
--following the original 8x8 pixel sprites (1 sprite pixel = 4 units). Each kind's art is one Mesh,
--rebuilt when the colour (hue) setting changes, so a rigid piece is a single draw call.

PIECEPIXEL = 4

--layers drawn over each block's black base, as {colour, x1, y1, x2, y2} in sprite pixels within the 8x8 block
local blockdesigns = {
	[2] = {{"light", 1, 1, 7, 7}, {"black", 2, 2, 6, 6}, {"white", 3, 3, 5, 5}}, --J
	[3] = {{"dark", 1, 1, 7, 7}}, --L
	[4] = {{"white", 1, 1, 7, 7}, {"black", 2, 2, 6, 6}}, --O
	[5] = {{"dark", 1, 1, 7, 7}, {"black", 2, 2, 6, 6}, {"white", 3, 3, 5, 5}}, --S
	[6] = {{"light", 1, 1, 7, 7}, {"white", 2, 2, 6, 3}, {"white", 2, 3, 3, 5}, {"black", 5, 3, 6, 5}, {"black", 2, 5, 6, 6}}, --T
	[7] = {{"light", 1, 1, 7, 7}, {"black", 3, 3, 5, 5}}, --Z
}

--the I piece is one bar without seams, speckled like its sprite
local ispeckles = { --dark pixels of the I sprite, in pixels from the bar's top left corner
	{2,1},{5,1},{8,1},{10,1},{12,1},{16,1},{18,1},{20,1},{24,1},{28,1},
	{14,2},{22,2},{26,2},
	{1,3},{4,3},{6,3},{10,3},{18,3},{29,3},
	{8,4},{13,4},{16,4},{21,4},{25,4},{27,4},
	{2,5},{6,5},{11,5},{15,5},{19,5},{23,5},{30,5},
	{4,6},{9,6},{13,6},{17,6},{21,6},{26,6},{28,6},
}
function piecepalette() --the four colours of the piece art, following the hue setting like the sprites did
	local rr, rg, rb = unpack(getrainbowcolor(hue))
	return {
		white = {1, 1, 1},
		black = {0, 0, 0},
		light = {(145 + rr*64)/255, (145 + rg*64)/255, (145 + rb*64)/255},
		dark = {(73 + rr*43)/255, (73 + rg*43)/255, (73 + rb*43)/255},
	}
end

function pieceartrects(kind) --the art of a piece kind as a list of {colour, x1, y1, x2, y2} in piece coordinates
	local rects = {}
	local p = PIECEPIXEL
	if kind == 1 then
		local x0, y0 = -64, -16 --top left of the bar
		table.insert(rects, {"black", x0, y0, x0 + 32*p, y0 + 8*p})
		table.insert(rects, {"light", x0 + p, y0 + p, x0 + 31*p, y0 + 7*p})
		for i, speckle in ipairs(ispeckles) do
			local x, y = x0 + speckle[1]*p, y0 + speckle[2]*p
			table.insert(rects, {"dark", x, y, x + p, y + p})
		end
		return rects
	end
	for i, block in ipairs(pieceblocks[kind]) do
		local x0, y0 = block[1] - 16, block[2] - 16
		table.insert(rects, {"black", x0, y0, x0 + 32, y0 + 32})
	end
	for i, block in ipairs(pieceblocks[kind]) do
		local x0, y0 = block[1] - 16, block[2] - 16
		for j, layer in ipairs(blockdesigns[kind]) do
			table.insert(rects, {layer[1], x0 + layer[2]*p, y0 + layer[3]*p, x0 + layer[4]*p, y0 + layer[5]*p})
		end
	end
	return rects
end

function loadpieceart() --builds one Mesh of coloured triangles per piece kind
	local palette = piecepalette()
	pieceart = {}
	for kind = 1, 7 do
		local vertices = {}
		for i, rect in ipairs(pieceartrects(kind)) do
			local c = palette[rect[1]]
			local x1, y1, x2, y2 = rect[2], rect[3], rect[4], rect[5]
			for j, corner in ipairs({{x1, y1}, {x2, y1}, {x2, y2}, {x1, y1}, {x2, y2}, {x1, y2}}) do
				table.insert(vertices, {corner[1], corner[2], 0, 0, c[1], c[2], c[3], 1})
			end
		end
		pieceart[kind] = love.graphics.newMesh(vertices, "triangles", "static")
	end
end

local function stencilpolygons(polygons)
	return function()
		for i, polygon in ipairs(polygons) do
			love.graphics.polygon("fill", polygon)
		end
	end
end

--draws a piece kind's art in the current colour with the piece origin at x, y (screen), rotated by angle, s screen pixels per unit.
--clip: optional list of polygons to clip the art to (cut pieces), in the same coordinates as x, y, angle place.
--offset: optional {x, y} where those coordinates' origin is in the piece (single blocks of soft pieces)
function drawpieceart(kind, x, y, angle, s, clip, offset)
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.rotate(angle)
	love.graphics.scale(s)
	if clip then
		love.graphics.stencil(stencilpolygons(clip), "replace", 1)
		love.graphics.setStencilTest("greater", 0)
	end
	if offset then
		love.graphics.translate(-offset[1], -offset[2])
	end
	love.graphics.draw(pieceart[kind])
	if clip then
		love.graphics.setStencilTest()
	end
	love.graphics.pop()
end

function piecepolygons(piece) --a piece's shapes as polygons in its body's coordinates
	local polygons = {}
	for i, shape in ipairs(piece.shapes) do
		polygons[i] = {shape:getPoints()}
	end
	return polygons
end

function drawpiecepreview(kind, x, y, angle, scale) --the rotating "next piece", centred like the old preview sprites at x, y (game pixels)
	local ox = (piececenterpreview[kind][1] - piececenter[kind][1])*PIECEPIXEL
	local oy = (piececenterpreview[kind][2] - piececenter[kind][2])*PIECEPIXEL
	love.graphics.push()
	love.graphics.translate(x*scale, y*scale)
	love.graphics.rotate(angle)
	love.graphics.scale(scale/PIECEPIXEL)
	love.graphics.translate(-ox, -oy)
	love.graphics.draw(pieceart[kind])
	love.graphics.pop()
end
