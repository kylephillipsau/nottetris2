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

function newpiece(world, kind, x, y, density) --creates a piece {kind, body, shapes, fixtures}; callers add its image
	local piece = {kind = kind, shapes = {}, fixtures = {}}
	piece.body = love.physics.newBody(world, x, y, "dynamic")
	for i, block in ipairs(pieceblocks[kind]) do
		piece.shapes[i] = love.physics.newRectangleShape(block[1], block[2], 32, 32)
		piece.fixtures[i] = love.physics.newFixture(piece.body, piece.shapes[i], density)
	end
	piece.body:setLinearDamping(0.5)
	piece.body:setBullet(true)
	return piece
end

function drawpiece(piece, physicsscale, scale) --draws a piece's image at its body
	local body = piece.body
	love.graphics.draw( piece.image, body:getX()*physicsscale, body:getY()*physicsscale, body:getAngle(), 1, 1, piececenter[piece.kind][1]*scale, piececenter[piece.kind][2]*scale)
end

function highestbody() --index of the last landed piece in tetris. tetris[1] is the falling piece and may be missing, so # can't be trusted
	local i = 2
	while tetris[i] ~= nil do
		i = i + 1
	end
	return i-1
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
			love.audio.stop(pausesound)
			love.audio.play(pausesound)
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
				love.audio.stop(blockmove)
				love.audio.play(blockmove)
			elseif controls.check("rotateleft", key) or controls.check("rotateright", key) then
				love.audio.stop(blockturn)
				love.audio.play(blockturn)
			end
		end
	end
	end
end
