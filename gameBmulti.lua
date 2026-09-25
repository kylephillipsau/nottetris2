function gameBmulti_load()
	if musicno < 4 then
		love.audio.stop(music[musicno])
	end
	
	gamestate = "gameBmulti"
	gamestarted = false
	
	beeped = {false, false, false}
	
	--figure out the multiplayer scale
	mpscale = scale
	while 274*mpscale > desktopwidth do
		mpscale = mpscale - 1
	end
	physicsmpscale = mpscale/4
	
	mpfullscreenoffsetX = (desktopwidth-274*mpscale)/2
	mpfullscreenoffsetY = (desktopheight-144*mpscale)/2
	
	if not fullscreen then
		love.window.setMode( 274*mpscale, 144*mpscale, {fullscreen=fullscreen, vsync=vsync, msaa=0} )
	end
	
	--nextpieces
	nextpieceimgmp = {}
	for i = 1, 7 do
		nextpieceimgmp[i] = newTintedImage( "graphics/pieces/"..i..".png", mpscale )
	end
	
	difficulty_speed = 100

	p1fail = false
	p2fail = false

	p1color = {1, 50/255, 50/255}
	p2color = {50/255, 1, 50/255}

	--p1color = {116/255, 92/255, 73/255}
	--p2color = {209/255, 174/255, 145/255}
	
	scorescorep1 = 0
	linesscorep1 = 0
	
	scorescorep2 = 0
	linesscorep2 = 0
	
	counterp1 = 0 --first piece is 1
	counterp2 = 0 --first piece is 1
	
	
	
	randomtable = {}
	nextpiecep1 = nil
	nextpiecep2 = nil
	
	nextpiecerot = 0
	
	--PHYSICS--
	meter = 30
	world = love.physics.newWorld(0, 500, true )


	multipieces = {{}, {}} --pieces of player 1 and 2, indexed by counterp1/counterp2

	--WALLS--
	local wallbodiesp1, wallshapesp1, wallbodiesp2, wallshapesp2
	wallbodiesp1, wallshapesp1, wallfxturesp1 = newwalls(world, {
		{points = {164,0, 164,672, 196,672, 196,0}, data = "leftp1", friction = 0.0001},
		{points = {516,0, 516,672, 548,672, 548,0}, data = "rightp1", friction = 0.0001, category = 2},
		{points = {196,640, 196,672, 516,672, 516,640}, data = "groundp1"},
	})
	wallbodiesp2, wallshapesp2, wallfxturesp2 = newwalls(world, {
		{points = {484,0, 484,672, 516,672, 516,0}, data = "leftp2", friction = 0.0001, category = 3},
		{points = {836,0, 836,672, 868,672, 868,0}, data = "rightp2", friction = 0.0001},
		{points = {516,640, 516,672, 836,672, 836,640}, data = "groundp2"},
	})
	-----------
	world:setCallbacks(collideBmulti, nil, nil, nil)
	-----------
	
	randomtable[1] = math.random(7)
	starttimer = love.timer.getTime()
	newtime = starttimer
	--first piece! hooray.
end

function gameBmulti_draw()
	if gamestate == "gameBmulti_results" then
		love.graphics.draw(multiresults, 0, 0, 0, mpscale)
	else
		love.graphics.draw(gamebackgroundmulti, 0, 0, 0, mpscale)
	end
	
	if gamestarted == false then --countdown
		local numbers = {number3, number2, number1}
		local second = math.min(math.ceil(newtime - starttimer), 3)
		if second >= 1 then
			love.graphics.draw( numbers[second], 73*mpscale, 48*mpscale, 0, mpscale)
			love.graphics.draw( numbers[second], 153*mpscale, 48*mpscale, 0, mpscale)
		end
	end
	
	drawmultipieces(1, p1color)
	if p1fail == false and nextpiecep1 then
		love.graphics.draw(nextpieceimgmp[nextpiecep1], 24*mpscale, 120*mpscale, -nextpiecerot, 1, 1, piececenterpreview[nextpiecep1][1]*mpscale, piececenterpreview[nextpiecep1][2]*mpscale)
	end
	
	drawmultipieces(2, p2color)
	love.graphics.setColor(1, 1, 1)
	if p2fail == false and nextpiecep2 then
		love.graphics.draw(nextpieceimgmp[nextpiecep2], 250*mpscale, 120*mpscale, nextpiecerot, 1, 1, piececenterpreview[nextpiecep2][1]*mpscale, piececenterpreview[nextpiecep2][2]*mpscale)
	end
	
	--scores and tiles
	printrightaligned(scorescorep1, 36, 24, mpscale)
	printrightaligned(linesscorep1, 28, 80, mpscale)
	printrightaligned(scorescorep2, 262, 24, mpscale)
	printrightaligned(linesscorep2, 254, 80, mpscale)
	
	if gamestate == "gameBmulti_results" then
		drawresults()
	end
end

function versuscharacter(player) --mario for player 1, luigi for player 2: results screen sprites, physics and controls
	if player == 1 then
		return {name = "mario", x = 388, height = 108, mask = 3, left = "leftp1", right = "rightp1",
			idle = marioidle, jump = mariojump, cry1 = mariocry1, cry2 = mariocry2, originx = 12, originy = 13.5,
			cryx = 83, cryy = 66, drawx = 84, drawy = 69}
	else
		return {name = "luigi", x = 704, height = 124, mask = 2, left = "leftp2", right = "rightp2",
			idle = luigiidle, jump = luigijump, cry1 = luigicry1, cry2 = luigicry2, originx = 14, originy = 15.5,
			cryx = 162, cryy = 66, drawx = 162, drawy = 65}
	end
end

function drawresults() --win counters, the winner jumping and the loser crying (or both standing for a draw)
	love.graphics.print( string.format("%02d", p1wins), 111*mpscale, 128*mpscale, 0, mpscale)
	love.graphics.print( string.format("%02d", p2wins), 193*mpscale, 128*mpscale, 0, mpscale)
	
	if winner == 3 then
		local mario, luigi = versuscharacter(1), versuscharacter(2)
		love.graphics.draw( mario.idle, mario.drawx*mpscale, mario.drawy*mpscale, 0, mpscale, mpscale)
		if cryframe == false then
			love.graphics.print( "draw", 160*mpscale, 40*mpscale, 0, mpscale)
		end
		love.graphics.draw( luigi.idle, luigi.drawx*mpscale, luigi.drawy*mpscale, 0, mpscale, mpscale)
		if cryframe == false then
			love.graphics.print( "draw", 80*mpscale, 40*mpscale, 0, mpscale)
		end
		return
	end
	
	local won, lost = versuscharacter(winner), versuscharacter(3 - winner)
	local image = jumpframe and won.jump or won.idle
	love.graphics.draw( image, winnerbody:getX()*physicsmpscale, winnerbody:getY()*physicsmpscale, winnerbody:getAngle(), mpscale, mpscale, won.originx, won.originy)
	
	if cryframe == false then
		love.graphics.draw( lost.cry1, lost.cryx*mpscale, lost.cryy*mpscale, 0, mpscale, mpscale)
	else
		love.graphics.draw( lost.cry2, lost.cryx*mpscale, lost.cryy*mpscale, 0, mpscale, mpscale)
		love.graphics.print( won.name, 93*mpscale, 20*mpscale, 0, mpscale)
		love.graphics.print( "wins!", 141*mpscale, 20*mpscale, 0, mpscale)
		for i = 1, 5 do
			love.graphics.draw( congratsline, (86+(8*i-1))*mpscale, 28*mpscale, 0, mpscale, mpscale)
			love.graphics.draw( congratsline, (134+(8*i-1))*mpscale, 28*mpscale, 0, mpscale, mpscale)
		end
	end
end
	
function gameBmulti_update(dt)
	--NEXTPIECE ROTATION (rotating allday erryday)
	nextpiecerot = nextpiecerot + nextpiecerotspeed*dt
	while nextpiecerot > math.pi*2 do
		nextpiecerot = nextpiecerot - math.pi*2
	end

	--collisions only flag finished blocks; bodies can't be created while the world is updating
	endblockp1pending = false
	endblockp2pending = false
	world:update(dt)
	if endblockp1pending then
		endblockp1()
	end
	if endblockp2pending then
		endblockp2()
	end
	newtime = love.timer.getTime()
	
	--landing a block can end the game, so pick the state's update only now
	if gamestarted == false then
		versuscountdown()
	elseif gamestate == "gameBmulti" then
		if p1fail == false then
			steerpiece(multipieces[1][counterp1].body, dt, "p1", difficulty_speed*5)
		end
		if p2fail == false then
			steerpiece(multipieces[2][counterp2].body, dt, "p2", difficulty_speed*5)
		end
	elseif gamestate == "failingBmulti" then
		if love.timer.getTime() - colorizetimer > colorizeduration then
			gamestate = "failedBmulti"

			wallfxturesp1[2]:destroy()
			wallfxturesp2[2]:destroy()

			love.audio.stop(sfx.gameover2)
			love.audio.play(sfx.gameover2)
		end
	elseif gamestate == "failedBmulti" then
		if piecesfallenout() then
			startresults()
		end
	elseif gamestate == "gameBmulti_results" then
		updateresults()
	end
end

function versuscountdown() --beeps on each second of the 3 second countdown, then starts the game
	if newtime - starttimer > 3 then
		if musicno < 4 then
			love.audio.play(music[musicno])
		end
		startgame()
		gamestarted = true
		return
	end
	local second = math.ceil(newtime - starttimer)
	if second >= 1 and beeped[second] == false then
		beeped[second] = true
		love.audio.stop(sfx.highscorebeep)
		love.audio.play(sfx.highscorebeep)
	end
end

function piecesfallenout() --true once both players' pieces have dropped out of the playfield
	for player = 1, 2 do
		for i, piece in pairs(multipieces[player]) do
			if piece.body:getY() < 162*mpscale then
				return false
			end
		end
	end
	return true
end

function startresults() --floor for the characters, and the winner's physics body
	gamestate = "gameBmulti_results"
	jumptimer = love.timer.getTime()
	crytimer = love.timer.getTime()
	
	love.audio.play(sfx.musicresults)

	local resultsfloorbody = love.physics.newBody(world, 32, -64, "static")
	local resultsfloorshape = love.physics.newPolygonShape(196,448, 196,480, 836,480, 836,448)
	local resultsfloorfixture = love.physics.newFixture(resultsfloorbody, resultsfloorshape)
	resultsfloorfixture:setUserData("resultsfloor")

	if winner ~= 3 then
		local won = versuscharacter(winner)
		winnerbody = love.physics.newBody(world, won.x, 320, "dynamic")
		local fixture = love.physics.newFixture(winnerbody, love.physics.newRectangleShape(64, won.height), 1)
		fixture:setMask(won.mask)
		fixture:setUserData(won.name)
		winnerbody:setLinearDamping(0.5)
		winnerbody:resetMassData()
		winnerjump()
	end
	jumpframe = true
end

function winnerjump()
	winnerbody:setY(winnerbody:getY()-1)
	local x, y = winnerbody:getLinearVelocity( )
	winnerbody:setLinearVelocity(x, -300)
end

function updateresults() --the winner jumps every 2 seconds and can be pushed around; the loser's crying animates
	if love.timer.getTime() - jumptimer > 2 then
		jumptimer = love.timer.getTime()
		jumpframe = true
		if winner ~= 3 then
			winnerjump()
		end
	end
	
	if love.timer.getTime() - crytimer > 0.4 then
		cryframe = not cryframe
		crytimer = love.timer.getTime()
	end
	
	if winner ~= 3 then
		local won = versuscharacter(winner)
		if controls.isDown(won.left) then
			local x, y = winnerbody:getWorldCenter()
			winnerbody:applyForce( -30, 0, x, y-8 )
		end
		if controls.isDown(won.right) then
			local x, y = winnerbody:getWorldCenter()
			winnerbody:applyForce( 30, 0, x, y-8 )
		end
	end
end

function mirrorpiece(kind) --player 1 gets the mirror image of player 2's pieces: J<->L, S<->Z
	local mirrored = {[2] = 3, [3] = 2, [5] = 7, [7] = 5}
	return mirrored[kind] or kind
end

function startgame()
	--first "nextpiece" of each player, which gets used right away--
	nextpiecep1 = mirrorpiece(randomtable[1])
	nextpiecep2 = randomtable[1]
	
	game_addTetriBmultip1()
	game_addTetriBmultip2()
end

function game_addTetriBmultip1()
	counterp1 = counterp1 + 1
	--NEW BLOCK--
	createtetriBmulti(1, nextpiecep1, counterp1, 388, blockstartY)
	multipieces[1][counterp1].body:setLinearVelocity(0, difficulty_speed)
	
	--RANDOMIZE
	if counterp1 > #randomtable then
		table.insert(randomtable, math.random(7))
	end
	nextpiecep1 = mirrorpiece(randomtable[counterp1])
end

function game_addTetriBmultip2()
	counterp2 = counterp2 + 1
	--NEW BLOCK--
	createtetriBmulti(2, nextpiecep2, counterp2, 708, blockstartY)
	multipieces[2][counterp2].body:setLinearVelocity(0, difficulty_speed)
	
	--RANDOMIZE
	if counterp2 > #randomtable then
		table.insert(randomtable, math.random(7))
	end
	nextpiecep2 = randomtable[counterp2]
end

function createtetriBmulti(player, i, uniqueid, x, y)
	local piece = newpiece(world, i, x, y, 1)
	piece.image = newTintedImage( "graphics/pieces/"..i..".png", mpscale )
	multipieces[player][uniqueid] = piece

	for i, v in pairs(piece.fixtures) do
		v:setUserData("p"..player.."-"..uniqueid)
		v:setMask(player == 1 and 3 or 2) --don't collide with the other player's side of the shared middle wall
	end
end

function drawmultipieces(player, color) --draws a player's pieces, tinting those below the rising game over line
	for i, piece in pairs(multipieces[player]) do
		love.graphics.setColor(1, 1, 1)
		if gamestate == "failingBmulti" or gamestate == "failedBmulti" then
			local timepassed = love.timer.getTime() - colorizetimer
			if piece.body:getY() > 576 - (576*(timepassed/colorizeduration)) then
				love.graphics.setColor(unpack(color))
			end
		end
		drawpiece(piece, physicsmpscale, mpscale)
	end
end

function collideBmulti(a, b)
	-- Get user data from fixtures
	local aData = a:getUserData()
	local bData = b:getUserData()

	if (aData == "p1-"..counterp1 and bData ~= "p2-"..counterp2) or (bData == "p1-"..counterp1 and aData ~= "p2-"..counterp2) then --One of the pieces is the current piece and the other isn't the other player's one
		if p1fail == false and aData ~= "leftp1" and aData ~= "rightp1" and bData ~= "leftp1" and bData ~= "rightp1" then
			endblockp1pending = true
		end
	elseif (aData == "p2-"..counterp2 and bData ~= "p1-"..counterp1) or (bData == "p2-"..counterp2 and aData ~= "p1-"..counterp1) then
		if p2fail == false and aData ~= "leftp2" and aData ~= "rightp2" and bData ~= "leftp2" and bData ~= "rightp2" then
			endblockp2pending = true
		end
	elseif gamestate == "gameBmulti_results" then
		if (aData == "mario" or aData == "luigi" or bData == "mario" or bData == "luigi") and (aData == "resultsfloor" or bData == "resultsfloor") then
			jumpframe = false --the winner landed
		end
	end
end

function endblockp1()
	if gameno == 2 then
		for i, v in pairs(multipieces[1][counterp1].fixtures) do --make fixtures pass through the center
			v:setMask(3, 2)
		end
	end
	
	if multipieces[1][counterp1].body:getY() < losingY then --P1 hit the top
		--FAIL P1--
		p1fail = true
		
		
		if p2fail == true then --Both players have hit the top
			endgame()
		end
	else --P1 didn't hit the top yet
		love.audio.stop(sfx.blockfall)
		love.audio.play(sfx.blockfall)
		linesscorep1 = linesscorep1 + 1
		scorescorep1 = linesscorep1 * 100
		game_addTetriBmultip1()
	end
end

function endblockp2()
	if gameno == 2 then
		for i, v in pairs(multipieces[2][counterp2].fixtures) do --make fixtures pass through the center
			v:setMask(2, 3)
		end
	end
	
	if multipieces[2][counterp2].body:getY() < losingY then --P2 hit the top
		--FAIL P2--
		p2fail = true
		
		if p1fail == true then --Both players have hit the top
			endgame()
		end
	else --P2 didn't hit the top yet
		love.audio.stop(sfx.blockfall)
		love.audio.play(sfx.blockfall)
		linesscorep2 = linesscorep2 + 1
		scorescorep2 = linesscorep2 * 100
		game_addTetriBmultip2()
	end
end

function endgame()
	colorizetimer = love.timer.getTime()
	gamestate = "failingBmulti"
	
	if musicno < 4 then
		love.audio.stop(music[musicno])
	end
	
	love.audio.stop(sfx.gameover1)
	love.audio.play(sfx.gameover1)
	
	if scorescorep1 > scorescorep2 then
		p1wins = p1wins + 1
		winner = 1
	elseif scorescorep1 < scorescorep2 then
		p2wins = p2wins + 1
		winner = 2
	else
		winner = 3
	end
	if p1wins > 99 then
		p1wins = math.mod(p1wins, 100)
	end
	if p2wins > 99 then
		p2wins = math.mod(p2wins, 100)
	end
end

function gameBmulti_keypressed(key)
	if gamestate == "gameBmulti" and gamestarted == false then
	if controls.check("escape", key) then
		restorewindow()
		gamestate = "multimenu"
		if musicno < 4 then
			love.audio.play(music[musicno])
		end
	end
	elseif gamestate == "gameBmulti" and gamestarted == true then
	if controls.check("escape", key) then
		restorewindow()
		gamestate = "multimenu"
	end
	if controls.check("leftp1", key) or controls.check("rightp1", key) or controls.check("leftp2", key) or controls.check("rightp2", key) then
		love.audio.stop(sfx.blockmove)
		love.audio.play(sfx.blockmove)
	elseif controls.check("rotateleftp1", key) or controls.check("rotaterightp1", key) or controls.check("rotateleftp2", key) or controls.check("rotaterightp2", key) then
		love.audio.stop(sfx.blockturn)
		love.audio.play(sfx.blockturn)
	end
	
	elseif gamestate == "gameBmulti_results" then
	if controls.check("return", key) or controls.check("escape", key) then
		if musicno < 4 then
			love.audio.stop(sfx.musicresults)
			love.audio.play(music[musicno])
		end
		restorewindow()
		gamestate = "multimenu"
	end
	
	end
end

registerscreen({"gameBmulti", "failingBmulti", "failedBmulti", "gameBmulti_results"},
	{update = gameBmulti_update, draw = gameBmulti_draw, keypressed = gameBmulti_keypressed,
	viewport = function() return mpfullscreenoffsetX, mpfullscreenoffsetY, 274*mpscale, 144*mpscale end})
