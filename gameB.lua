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
	
	tetrikind = {}
	
	tetrifixtures = {}
	tetribodies = {}
	tetrishapes = {}
	
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
	tetribodies[1]:setLinearVelocity(0, difficulty_speed)
	
	--RANDOMIZE
	nextpiece = math.random(7)
end

function createtetriB(i, uniqueid, x, y)
	tetriimages[uniqueid] = newTintedImage( "graphics/pieces/"..i..".png", scale )
	tetrikind[uniqueid] = i
	tetribodies[uniqueid], tetrishapes[uniqueid], tetrifixtures[uniqueid] = newpiecebody(world, i, x, y, density)

	for i, v in pairs(tetrifixtures[uniqueid]) do
		v:setUserData(uniqueid)
	end
end

function gameB_draw()
	--FULLSCREEN OFFSET
	if fullscreen then
		love.graphics.translate(fullscreenoffsetX, fullscreenoffsetY)
		
		--scissor
		love.graphics.setScissor(fullscreenoffsetX, fullscreenoffsetY, 160*scale, 144*scale)
	end
	
	--background--
	love.graphics.draw(gamebackground, 0, 0, 0, scale)
	---------------
	--tetrifixtures--
	for i,v in pairs(tetribodies) do
		if pause == false then
			love.graphics.draw( tetriimages[i], v:getX()*physicsscale, v:getY()*physicsscale, v:getAngle(), 1, 1, piececenter[tetrikind[i]][1]*scale, piececenter[tetrikind[i]][2]*scale)
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
	
	--FULLSCREEN OFFSET
	if fullscreen then
		love.graphics.translate(-fullscreenoffsetX, -fullscreenoffsetY)
		
		--scissor
		love.graphics.setScissor()
	end
	
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
		steerpiece(tetribodies[1], dt, "", difficulty_speed*5)
	end
	
	world:update(dt)
	
	if gamestate == "failingB" then
		clearcheck = true
		for i,v in pairs(tetribodies) do
			if v:getY() < 648 then
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
	if tetribodies[1]:getY() < losingY then
		--LOSE--
		gamestate = "failingB"
		if musicno < 4 then
			love.audio.stop(music[musicno])
		end
		love.audio.stop(gameover1)
		love.audio.play(gameover1)

		wallfixtures[2]:destroy()
		wallfixtures[2] = nil
	else
		--Transfer block from 1 to end of tetribodies
		tetrikind[highestbody()+1] = tetrikind[1]
		
		tetriimages[highestbody()+1] = tetriimages[1]
		tetribodies[highestbody()+1] = tetribodies[1]
		
		tetrifixtures[highestbody()] = {}
		tetrishapes[highestbody()] = {}
		
		for i, v in pairs(tetrifixtures[1]) do
			tetrishapes[highestbody()][i] = tetrishapes[1][i]
			tetrishapes[1][i] = nil
			
			tetrifixtures[highestbody()][i] = tetrifixtures[1][i]
			tetrifixtures[highestbody()][i]:setUserData({highestbody()})
			tetrifixtures[1][i] = nil
		end
		
		tetribodies[1] = nil
		---------------------------
		linesscore = linesscore + 1
		scorescore = linesscore * 100
		
		love.audio.stop(blockfall)
		love.audio.play(blockfall)
		
		newblock = true
	end
end

registerscreen({"gameB", "failingB"}, {update = gameB_update, draw = gameB_draw, keypressed = singleplayer_keypressed})
