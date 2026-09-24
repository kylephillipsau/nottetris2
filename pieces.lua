--Centres of the four 32x32 blocks of each tetromino, relative to the piece's body.
pieceblocks = {
	{{-48,  0}, {-16,  0}, { 16,  0}, { 48,  0}}, --I
	{{-32,-16}, {  0,-16}, { 32,-16}, { 32, 16}}, --J
	{{-32,-16}, {  0,-16}, { 32,-16}, {-32, 16}}, --L
	{{-16,-16}, {-16, 16}, { 16, 16}, { 16,-16}}, --O
	{{-32, 16}, {  0,-16}, { 32,-16}, {  0, 16}}, --S
	{{-32,-16}, {  0,-16}, { 32,-16}, {  0, 16}}, --T
	{{  0, 16}, {  0,-16}, { 32, 16}, {-32,-16}}, --Z
}

function newpiecebody(world, kind, x, y, density) --creates the physics body of a piece. returns body, shapes, fixtures
	local body = love.physics.newBody(world, x, y, "dynamic")
	local shapes = {}
	local fixtures = {}
	for i, block in ipairs(pieceblocks[kind]) do
		shapes[i] = love.physics.newRectangleShape(block[1], block[2], 32, 32)
		fixtures[i] = love.physics.newFixture(body, shapes[i], density)
	end
	body:setLinearDamping(0.5)
	body:setBullet(true)
	return body, shapes, fixtures
end
