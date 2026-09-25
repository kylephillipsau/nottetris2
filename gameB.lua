function gameB_load()
	gamestate = "gameB"
	
	pause = false
	
	difficulty_speed = 100

	scorescore = 0
	levelscore = 0
	linesscore = 40
	nextpiecerot = 0
	
	--PHYSICS--
	meter = 30
	world = love.physics.newWorld(0, 500, true )
	
	tetris = {}
	
	local wallbodies, wallshapes
	wallbodies, wallshapes, wallfixtures = newwalls(world, {
		{points = {0,-64, 0,672, 32,672, 32,-64}, data = "left", friction = 0.00001},
		{points = {352,-64, 352,672, 384,672, 384,-64}, data = "right", friction = 0.00001},
		{points = {24,640, 24,672, 352,672, 352,640}, data = "ground"},
		{points = {-8,-96, 384,-96, 384,-64, -8,-64}, data = "ceiling"},
	})

	world:setCallbacks(collideB, nil, nil, nil)
	-----------
	
	--FIRST "nextpiece"-
	nextpiece = 1--math.random(7)
	
	game_addTetriB()
	----------------
end

function game_addTetriB()
	--NEW BLOCK--
	randomblock = nextpiece
	createtetriB(randomblock, 1, 224, blockstartY)
	tetris[1].body:setLinearVelocity(0, difficulty_speed)
	
	--RANDOMIZE
	nextpiece = math.random(7)
end

function createtetriB(i, uniqueid, x, y)
	tetris[uniqueid] = newpiece(world, i, x, y, density)
	tetris[uniqueid].image = newTintedImage( "graphics/pieces/"..i..".png", scale )

	for i, v in pairs(tetris[uniqueid].fixtures) do
		v:setUserData(uniqueid)
	end
end

function gameB_draw()
	
	--background--
	love.graphics.draw(gamebackground, 0, 0, 0, scale)
	---------------
	--pieces--
	for i, piece in pairs(tetris) do
		if pause == false then
			drawpiece(piece, physicsscale, scale)
		end
	end
	
	--Next piece
	if pause == false then
		love.graphics.draw(nextpieceimg[nextpiece], 136*scale, 120*scale, nextpiecerot, 1, 1, piececenterpreview[nextpiece][1]*scale, piececenterpreview[nextpiece][2]*scale)
	end
	----------------
	--start--
	if pause == true then
		love.graphics.draw(pausegraphic, 16*scale, 0, 0, scale)
	end
	---------
	
	--SCORES---------------------------------------
	drawscorepanel()
	-----------------------------------------------

	love.graphics.setColor(1, 1, 1)
	
	
end
	
function gameB_update(dt)
	if pause then
		return
	end

	if newblock then
		game_addTetriB()
		newblock = false
	end

	--NEXTPIECE ROTATION (rotating allday erryday)
	nextpiecerot = nextpiecerot + nextpiecerotspeed*dt
	while nextpiecerot > math.pi*2 do
		nextpiecerot = nextpiecerot - math.pi*2
	end

	if gamestate == "gameB" then
		steerpiece(tetris[1].body, dt, "", difficulty_speed*5)
	end
	
	world:update(dt)
	
	if gamestate == "failingB" then
		local clearcheck = true
		for i, piece in pairs(tetris) do
			if piece.body:getY() < 648 then
				clearcheck = false
			end
		end
		
		if clearcheck then
			failed_load()
		end
	end
end

function collideB(a, b)
	a, b = a:getUserData(), b:getUserData()
	if a == 1 or b == 1 then
		if a ~= "left" and a ~= "right" and b ~= "left" and b ~= "right" then 
			if gamestate == "gameB" then
				endblockB()
			end
		end
	end
end

function endblockB()
	if tetris[1].body:getY() < losingY then
		--LOSE--
		gamestate = "failingB"
		if musicno < 4 then
			love.audio.stop(music[musicno])
		end
		love.audio.stop(sfx.gameover1)
		love.audio.play(sfx.gameover1)

		wallfixtures[2]:destroy()
		wallfixtures[2] = nil
	else
		--Transfer block from 1 to the end of tetris
		local n = highestbody()+1
		tetris[n] = tetris[1]
		tetris[1] = nil
		for i, v in pairs(tetris[n].fixtures) do
			v:setUserData({n})
		end
		---------------------------
		linesscore = linesscore + 1
		scorescore = linesscore * 100
		
		love.audio.stop(sfx.blockfall)
		love.audio.play(sfx.blockfall)
		
		newblock = true
	end
end

registerscreen({"gameB", "failingB"}, {update = gameB_update, draw = gameB_draw, keypressed = singleplayer_keypressed})
