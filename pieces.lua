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

function steerpiece(body, dt, player, maxfallspeed) --applies the rotate/move/drop controls of player ("", "p1" or "p2") to a falling piece
	player = player or ""
	if controls.isDown("rotateright"..player) then
		if body:getAngularVelocity() < 3 then
			body:applyTorque( 70 )
		end
	end
	if controls.isDown("rotateleft"..player) then
		if body:getAngularVelocity() > -3 then
			body:applyTorque( -70 )
		end
	end

	if controls.isDown("left"..player) then
		local x, y = body:getWorldCenter()
		body:applyForce( -70, 0, x, y )
	end
	if controls.isDown("right"..player) then
		local x, y = body:getWorldCenter()
		body:applyForce( 70, 0, x, y )
	end

	local x, y = body:getLinearVelocity()
	if controls.isDown("down"..player) then
		if y > maxfallspeed then
			body:setLinearVelocity(x, maxfallspeed)
		else
			local cx, cy = body:getWorldCenter()
			body:applyForce( 0, 20, cx, cy )
		end
	else
		if y > difficulty_speed then
			body:setLinearVelocity(x, y-2000*dt)
		end
	end
end

function newwalls(world, walls) --creates the static walls of a playfield. each wall is {points, data, friction, category}; returns body, shapes, fixtures (indexed from 0)
	local body = love.physics.newBody(world, 32, -64, "static")
	local shapes = {}
	local fixtures = {}
	for i, wall in ipairs(walls) do
		shapes[i-1] = love.physics.newPolygonShape(unpack(wall.points))
		fixtures[i-1] = love.physics.newFixture(body, shapes[i-1])
		fixtures[i-1]:setUserData(wall.data)
		if wall.category then
			fixtures[i-1]:setCategory(wall.category)
		end
		if wall.friction then
			fixtures[i-1]:setFriction(wall.friction)
		end
	end
	return body, shapes, fixtures
end
