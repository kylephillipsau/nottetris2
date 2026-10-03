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
	newphysics()
	
	tetris = {}
	
	wallfixtures = newwalls({
		{points = {0,-64, 0,672, 32,672, 32,-64}, data = "left", friction = 0.00001},
		{points = {352,-64, 352,672, 384,672, 384,-64}, data = "right", friction = 0.00001},
		{points = {24,640, 24,672, 352,672, 352,640}, data = "ground"},
		{points = {-8,-96, 384,-96, 384,-64, -8,-64}, data = "ceiling"},
	})

	setcollisioncallback(collideB)
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
	setpiecevelocity(tetris[1], 0, difficulty_speed)
	
	--RANDOMIZE
	nextpiece = math.random(7)
end

function createtetriB(i, uniqueid, x, y)
	tetris[uniqueid] = newpiece(i, x, y, density)
	setpiecedata(tetris[uniqueid], uniqueid)
end

function gameB_draw()
	
	--background--
	love.graphics.draw(gamebackground, 0, 0, 0, scale)
	---------------
	--pieces--
	for i, piece in pairs(tetris) do
		if pause == false then
			drawpiece(piece, physicsscale)
		end
	end
	
	--Next piece
	if pause == false then
		drawpiecepreview(nextpiece, 136, 120, nextpiecerot, scale)
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
		steerpiece(tetris[1], dt, "", difficulty_speed*5)
	end
	
	updatephysics(dt)
	
	if gamestate == "failingB" then
		local clearcheck = true
		for i, piece in pairs(tetris) do
			if piecey(piece) < 648 then
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
	if piecey(tetris[1]) < losingY then
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
		setpiecedata(tetris[n], {n})
		---------------------------
		linesscore = linesscore + 1
		scorescore = linesscore * 100
		
		love.audio.stop(sfx.blockfall)
		love.audio.play(sfx.blockfall)
		
		newblock = true
	end
end

registerscreen({"gameB", "failingB"}, {update = gameB_update, draw = gameB_draw, keypressed = singleplayer_keypressed})
