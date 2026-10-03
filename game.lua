--This game was tuned for LÖVE 0.7, which differs from LÖVE 11 in two ways that change how it plays:
--forces and torques were passed to Box2D as is (LÖVE 11 treats them as pixel units and divides them
--by the meter, twice for torques), and new shapes had friction 0.5 and restitution 0.1 (LÖVE 11: 0.2 and 0).
FORCESCALE = love.physics.getMeter()
TORQUESCALE = love.physics.getMeter()^2

function newfixture(body, shape, density) --a fixture with LÖVE 0.7's default friction and bounciness
	local fixture = love.physics.newFixture(body, shape, density)
	fixture:setFriction(0.5)
	fixture:setRestitution(0.1)
	return fixture
end

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

function newphysics() --fresh physics for a game: a Box2D world for rigid pieces and the walls, and a soft world too when pieces are soft
	world = love.physics.newWorld(0, 500, true)
	softworld = softbody and newsoftworld(500) or nil
end

function updatephysics(dt)
	world:update(dt)
	if softworld then
		softworld:update(dt)
	end
end

function setcollisioncallback(callback) --callback(a, b) runs when two things start touching. a and b are fixtures or soft bodies; both have getUserData
	world:setCallbacks(callback, nil, nil, nil)
	if softworld then
		softworld.callback = callback
	end
end

--creates a piece of kind with its centre at x, y: {kind, body, shapes, fixtures} with a Box2D body, or
--{kind, soft = true, body} with a soft body (which has the Box2D body methods the game uses) if pieces are soft
function newpiece(kind, x, y, density)
	if softworld then
		return {kind = kind, soft = true, body = softworld:newpiece(kind, x, y, density)}
	end
	local piece = {kind = kind, shapes = {}, fixtures = {}}
	piece.body = love.physics.newBody(world, x, y, "dynamic")
	for i, block in ipairs(pieceblocks[kind]) do
		piece.shapes[i] = love.physics.newRectangleShape(block[1], block[2], 32, 32)
		piece.fixtures[i] = newfixture(piece.body, piece.shapes[i], density)
	end
	piece.body:setLinearDamping(0.5)
	piece.body:setBullet(true)
	return piece
end

function setpiecedata(piece, data) --what collision callbacks get from getUserData for this piece
	if piece.soft then
		piece.body:setUserData(data)
	else
		for i, fixture in pairs(piece.fixtures) do
			fixture:setUserData(data)
		end
	end
end

function setpiecemask(piece, ...) --the collision categories the piece passes through
	if piece.soft then
		piece.body:setMask(...)
	else
		for i, fixture in pairs(piece.fixtures) do
			fixture:setMask(...)
		end
	end
end

function piecey(piece) --height of a piece: its body's origin, or a soft piece's centre
	return piece.body:getY()
end

function setpiecevelocity(piece, vx, vy)
	piece.body:setLinearVelocity(vx, vy)
end

function drawpiece(piece, physicsscale) --draws a piece in the current colour
	if piece.soft then
		drawsoftpiece(piece.body, physicsscale)
		return
	end
	local body = piece.body
	local clip = piece.cut and piecepolygons(piece) or nil --only what is left of cut pieces is drawn
	drawpieceart(piece.kind, body:getX()*physicsscale, body:getY()*physicsscale, body:getAngle(), physicsscale, clip)
end

function highestbody() --index of the last landed piece in tetris. tetris[1] is the falling piece and may be missing, so # can't be trusted
	local i = 2
	while tetris[i] ~= nil do
		i = i + 1
	end
	return i-1
end
function steerpiece(piece, dt, player, maxfallspeed) --applies the rotate/move/drop controls of player ("", "p1" or "p2") to a falling piece
	player = player or ""
	local body = piece.body
	if controls.isDown("rotateright"..player) then
		if body:getAngularVelocity() < 3 then
			body:applyTorque( 70*TORQUESCALE )
		end
	end
	if controls.isDown("rotateleft"..player) then
		if body:getAngularVelocity() > -3 then
			body:applyTorque( -70*TORQUESCALE )
		end
	end

	if controls.isDown("left"..player) then
		local x, y = body:getWorldCenter()
		body:applyForce( -70*FORCESCALE, 0, x, y )
	end
	if controls.isDown("right"..player) then
		local x, y = body:getWorldCenter()
		body:applyForce( 70*FORCESCALE, 0, x, y )
	end

	local x, y = body:getLinearVelocity()
	if controls.isDown("down"..player) then
		if y > maxfallspeed then
			body:setLinearVelocity(x, maxfallspeed)
		else
			local cx, cy = body:getWorldCenter()
			body:applyForce( 0, 20*FORCESCALE, cx, cy )
		end
	else
		if y > difficulty_speed then
			body:setLinearVelocity(x, y-2000*dt)
		end
	end
end

local function destroywall(wall)
	wall.fixture:destroy()
	if wall.soft then
		softworld:remove(wall.soft)
	end
end

--creates the static walls of a playfield, each {points, data, friction, category}, in Box2D and in the soft world
--if there is one. returns them indexed from 0; wall:destroy() takes one away
function newwalls(walls)
	local body = love.physics.newBody(world, 32, -64, "static")
	local result = {}
	for i, wall in ipairs(walls) do
		local fixture = newfixture(body, love.physics.newPolygonShape(unpack(wall.points)))
		fixture:setUserData(wall.data)
		if wall.category then
			fixture:setCategory(wall.category)
		end
		if wall.friction then
			fixture:setFriction(wall.friction)
		end
		result[i-1] = {fixture = fixture, destroy = destroywall}
		if softworld then --walls are boxes
			local x1, y1, x2, y2 = math.huge, math.huge, -math.huge, -math.huge
			for j = 1, #wall.points, 2 do
				x1, x2 = math.min(x1, wall.points[j]), math.max(x2, wall.points[j])
				y1, y2 = math.min(y1, wall.points[j+1]), math.max(y2, wall.points[j+1])
			end
			local bx, by = body:getPosition()
			result[i-1].soft = softworld:newwall(x1 + bx, y1 + by, x2 + bx, y2 + by, wall.data, wall.friction, wall.category)
		end
	end
	return result
end

function drawscorepanel() --score, level and lines in the single player sidebar
	printrightaligned(scorescore, 144, 24)
	printrightaligned(levelscore, 136, 56)
	printrightaligned(linesscore, 136, 80)
end

function singleplayer_keypressed(key)
	if gamestate == "gameA" or gamestate == "gameB" or gamestate == "failingA" or gamestate == "failingB" then

	if controls.check("return", key) then
		pause = not pause

		if pause == true then
			if musicno < 4 then
				music[musicno]:pause()
			end
			love.audio.stop(sfx.pausesound)
			love.audio.play(sfx.pausesound)
		else
			if musicno < 4 then
				music[musicno]:play()
			end
		end
	end
	if gamestate == "gameA" or gamestate == "gameB" then
		if controls.check("escape", key) then
			oldtime = love.timer.getTime()
			gamestate = "menu"
		end
		
		if pause == false and (cuttingtimer == lineclearduration or gamestate == "gameB") then
			--if key == "up" then --STOP ROTATION OF BLOCK (makes it too easy..)
			--	tetris[1].body:setAngularVelocity(0)
			--end
			if controls.check("left", key) or controls.check("right", key) then
				love.audio.stop(sfx.blockmove)
				love.audio.play(sfx.blockmove)
			elseif controls.check("rotateleft", key) or controls.check("rotateright", key) then
				love.audio.stop(sfx.blockturn)
				love.audio.play(sfx.blockturn)
			end
		end
	end
	end
end
