--Pieces are drawn as vector art: coloured rectangles in a piece's own coordinates (32 units per block),
--following the original 8x8 pixel sprites (1 sprite pixel = 4 units). Each kind's art is one Mesh,
--rebuilt when the colour (hue) setting changes, so a rigid piece is a single draw call.
--Soft pieces bend, so their art is cut along their particle lattice and every vertex is tied to the
--particles around it; a vertex shader places it from where those particles are now (see drawsoftpiece).

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

--Soft pieces bend, and the black border around every block would show as a grid of double lines that
--pinch at each joint, making a piece look like hinged blocks. So they have one outline around the whole
--piece and their colour runs across the blocks, which keep the motif in their middle to show the shape
local softdesigns = {
	[2] = {"light", {"black", 2, 2, 6, 6}, {"white", 3, 3, 5, 5}}, --J
	[3] = {"dark", {"black", 3, 3, 5, 5}}, --L
	[4] = {"white", {"black", 2, 2, 6, 6}}, --O
	[5] = {"dark", {"black", 2, 2, 6, 6}, {"white", 3, 3, 5, 5}}, --S
	[6] = {"light", {"white", 2, 2, 6, 3}, {"white", 2, 3, 3, 5}, {"black", 5, 3, 6, 5}, {"black", 2, 5, 6, 6}}, --T
	[7] = {"light", {"black", 3, 3, 5, 5}}, --Z
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

function pieceartrects(kind, soft) --the art of a piece kind as a list of {colour, x1, y1, x2, y2} in piece coordinates (soft: the soft design)
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
	local blocks = pieceblocks[kind]
	for i, block in ipairs(blocks) do
		local x0, y0 = block[1] - 16, block[2] - 16
		table.insert(rects, {"black", x0, y0, x0 + 32, y0 + 32})
	end
	local layers = blockdesigns[kind]
	if soft then
		--the fill: each block inset by the outline, bridged to its neighbours, and filled where four blocks meet
		local design = softdesigns[kind]
		local fill = design[1]
		local function has(x, y)
			for j, block in ipairs(blocks) do
				if block[1] == x and block[2] == y then
					return true
				end
			end
			return false
		end
		for i, block in ipairs(blocks) do
			local x, y = block[1], block[2]
			table.insert(rects, {fill, x - 16 + p, y - 16 + p, x + 16 - p, y + 16 - p})
			if has(x + 32, y) then
				table.insert(rects, {fill, x + 16 - p, y - 16 + p, x + 16 + p, y + 16 - p})
			end
			if has(x, y + 32) then
				table.insert(rects, {fill, x - 16 + p, y + 16 - p, x + 16 - p, y + 16 + p})
			end
			if has(x + 32, y) and has(x, y + 32) and has(x + 32, y + 32) then
				table.insert(rects, {fill, x + 16 - p, y + 16 - p, x + 16 + p, y + 16 + p})
			end
		end
		layers = {unpack(design, 2)}
	end
	for i, block in ipairs(blocks) do
		local x0, y0 = block[1] - 16, block[2] - 16
		for j, layer in ipairs(layers) do
			table.insert(rects, {layer[1], x0 + layer[2]*p, y0 + layer[3]*p, x0 + layer[4]*p, y0 + layer[5]*p})
		end
	end
	return rects
end

local function rectmesh(rects, palette) --one Mesh of coloured triangles
	local vertices = {}
	for i, rect in ipairs(rects) do
		local c = palette[rect[1]]
		local x1, y1, x2, y2 = rect[2], rect[3], rect[4], rect[5]
		for j, corner in ipairs({{x1, y1}, {x2, y1}, {x2, y2}, {x1, y1}, {x2, y2}, {x1, y2}}) do
			table.insert(vertices, {corner[1], corner[2], 0, 0, c[1], c[2], c[3], 1})
		end
	end
	return love.graphics.newMesh(vertices, "triangles", "static")
end

function loadpieceart() --builds one Mesh of coloured triangles per piece kind, in the classic and the soft design
	local palette = piecepalette()
	pieceart, softpreviewart = {}, {}
	softpieceart = {} --built when first needed, as soft bodies of each kind are
	if not skinshader then
		skinshader = love.graphics.newShader(string.format(SKINSHADER, SOFTMAXPARTICLES))
	end
	for kind = 1, 7 do
		pieceart[kind] = rectmesh(pieceartrects(kind), palette)
		softpreviewart[kind] = rectmesh(pieceartrects(kind, true), palette)
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
function drawpieceart(kind, x, y, angle, s, clip)
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.rotate(angle)
	love.graphics.scale(s)
	if clip then
		love.graphics.stencil(stencilpolygons(clip), "replace", 1)
		love.graphics.setStencilTest("greater", 0)
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
	love.graphics.draw(softbody and softpreviewart[kind] or pieceart[kind]) --pieces look like what will fall
	love.graphics.pop()
end

---------------------------------------------------------------------------------------------------
--soft pieces

--each vertex is the particles SkinIndex (up to four) weighted by SkinWeight: bilinearly in a lattice cell, barycentrically in a triangle
SKINSHADER = [[
attribute vec4 SkinIndex;
attribute vec4 SkinWeight;
uniform vec2 Particles[%d];
vec4 position(mat4 transform_projection, vec4 vertex_position) {
	vec2 p = Particles[int(SkinIndex.x)]*SkinWeight.x + Particles[int(SkinIndex.y)]*SkinWeight.y
		+ Particles[int(SkinIndex.z)]*SkinWeight.z + Particles[int(SkinIndex.w)]*SkinWeight.w;
	return transform_projection*vec4(p, 0.0, 1.0);
}
]]
local SKINFORMAT = {{"VertexPosition", "float", 2}, {"VertexColor", "byte", 4}, {"SkinIndex", "float", 4}, {"SkinWeight", "float", 4}}

local function clipconvex(polygon, ax, ay, bx, by) --the part of a convex polygon {x1, y1, ...} on the inner side of the edge from a to b of a clockwise polygon
	local out = {}
	local n = #polygon/2
	local px, py = polygon[2*n - 1], polygon[2*n]
	local pside = (bx - ax)*(py - ay) - (by - ay)*(px - ax)
	for j = 1, n do
		local cx, cy = polygon[2*j - 1], polygon[2*j]
		local cside = (bx - ax)*(cy - ay) - (by - ay)*(cx - ax)
		if (cside >= 0) ~= (pside >= 0) then
			local t = pside/(pside - cside)
			out[#out + 1], out[#out + 2] = px + t*(cx - px), py + t*(cy - py)
		end
		if cside >= 0 then
			out[#out + 1], out[#out + 2] = cx, cy
		end
		px, py, pside = cx, cy, cside
	end
	return out
end

function buildsoftart(body) --a Mesh of the body's kind's art, cut along its elements in its rest shape
	local palette = piecepalette()
	local rx, ry = body.rx, body.ry
	local elements = body:elements()
	local vertices = {}
	local function vertex(x, y, colour, a, b, c, d, wa, wb, wc, wd)
		vertices[#vertices + 1] = {x, y, colour[1], colour[2], colour[3], 1, a - 1, b - 1, c - 1, d - 1, wa, wb, wc, wd}
	end
	for _, rect in ipairs(pieceartrects(body.kind, true)) do
		local colour = palette[rect[1]]
		local x1, y1, x2, y2 = rect[2], rect[3], rect[4], rect[5]
		for _, e in ipairs(elements) do
			if #e == 4 then --a lattice cell, a square in the rest shape: the rectangle's part in it, weighted bilinearly
				local ex1, ey1, ex2, ey2 = rx[e[1]], ry[e[1]], rx[e[3]], ry[e[3]]
				local cx1, cy1, cx2, cy2 = math.max(x1, ex1), math.max(y1, ey1), math.min(x2, ex2), math.min(y2, ey2)
				if cx1 < cx2 and cy1 < cy2 then
					for _, corner in ipairs({{cx1, cy1}, {cx2, cy1}, {cx2, cy2}, {cx1, cy1}, {cx2, cy2}, {cx1, cy2}}) do
						local u, v = (corner[1] - ex1)/(ex2 - ex1), (corner[2] - ey1)/(ey2 - ey1)
						vertex(corner[1], corner[2], colour, e[1], e[2], e[3], e[4], (1 - u)*(1 - v), u*(1 - v), u*v, (1 - u)*v)
					end
				end
			else --a triangle left by a cut: the rectangle clipped to it, weighted barycentrically
				local polygon = {x1, y1, x2, y1, x2, y2, x1, y2}
				for j = 1, 3 do
					local a, b = e[j], e[j % 3 + 1]
					polygon = clipconvex(polygon, rx[a], ry[a], rx[b], ry[b])
					if #polygon < 6 then
						break
					end
				end
				if #polygon >= 6 then
					local xa, ya, xb, yb, xc, yc = rx[e[1]], ry[e[1]], rx[e[2]], ry[e[2]], rx[e[3]], ry[e[3]]
					local det = (yb - yc)*(xa - xc) + (xc - xb)*(ya - yc)
					local function corner(j)
						local x, y = polygon[2*j - 1], polygon[2*j]
						local wa = ((yb - yc)*(x - xc) + (xc - xb)*(y - yc))/det
						local wb = ((yc - ya)*(x - xc) + (xa - xc)*(y - yc))/det
						vertex(x, y, colour, e[1], e[2], e[3], e[1], wa, wb, 1 - wa - wb, 0)
					end
					for j = 2, #polygon/2 - 1 do
						corner(1)
						corner(j)
						corner(j + 1)
					end
				end
			end
		end
	end
	if #vertices == 0 then
		return nil
	end
	return love.graphics.newMesh(SKINFORMAT, vertices, "triangles", "static")
end

--draws a soft body in the current colour, s screen pixels per unit
function drawsoftpiece(body, s)
	if body.art == nil then
		if body.cut then
			body.art = buildsoftart(body) or false
		else --uncut bodies of a kind have the same lattice, so they share their art
			softpieceart[body.kind] = softpieceart[body.kind] or buildsoftart(body)
			body.art = softpieceart[body.kind]
		end
	end
	if not body.art then
		return
	end
	local particles = body.drawbuffer
	if not particles then
		particles = {}
		for i = 1, body.n do
			particles[i] = {0, 0}
		end
		body.drawbuffer = particles
	end
	local x, y = body.x, body.y
	for i = 1, body.n do
		particles[i][1], particles[i][2] = x[i], y[i]
	end
	love.graphics.push()
	love.graphics.scale(s)
	love.graphics.setShader(skinshader)
	skinshader:send("Particles", unpack(particles, 1, body.n))
	love.graphics.draw(body.art)
	love.graphics.setShader()
	love.graphics.pop()
end
