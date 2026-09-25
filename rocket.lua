function rocket_load()
	local rocketscores = {}
	if gameno == 1 then
		rocketscores[1] = 3000
		rocketscores[2] = 7000
		rocketscores[3] = 11000
		rocketscores[4] = 15000
	else
		rocketscores[1] = 3200
		rocketscores[2] = 3400
		rocketscores[3] = 3600
		rocketscores[4] = 3700
	end
	
	for i = 4, 1, -1 do
		if scorescore >= rocketscores[i] then
			if i < 4 then
				love.audio.stop(sfx.musicrocket1to3)
				love.audio.play(sfx.musicrocket1to3)
			else
				love.audio.stop(sfx.musicrocket4)
				love.audio.play(sfx.musicrocket4)
			end
			rockettimer = love.timer.getTime()
			gamestate = "rocket"..tostring(i)
			timelapsed = 0
			break
		end
	end

	if gamestate == "failed" then
		failed_checkhighscores()
	end
	
end

function rocket_update()
	timelapsed = love.timer.getTime() - rockettimer
	
	--sequence over?
	if gamestate == "rocket4" then
		if timelapsed > 41.1 then
			failed_checkhighscores()
		end
	else
		if timelapsed > 31.5 then
			failed_checkhighscores()
		end
	end
end

function flicker(rate) --alternates between true and false rate times per second
	return math.floor(timelapsed*rate) % 2 == 0
end

function rocket_draw()
	love.graphics.draw( rocketbackground, 0, 0, 0, scale, scale)
	if gamestate == "rocket4" then
		drawshuttle()
	else
		drawsmallrocket(tonumber(string.sub(gamestate, 7)))
	end
end

function drawshuttle() --the space shuttle for the best scores: lifts off at 12 seconds, then congratulations
	love.graphics.draw( bigrockettakeoffbackground, 54*scale, 60*scale, 0, scale, scale)
	local rocketpos = 112 - 112*((timelapsed-12)/18) --18 seconds for 112 pixels
	
	if timelapsed > 13 then
		if flicker(8) then
			love.graphics.draw( firebig1, 68*scale, round(rocketpos*scale), 0, scale, scale)
		else
			love.graphics.draw( firebig2, 68*scale, round(rocketpos*scale), 0, scale, scale)
		end
	end
	
	if timelapsed < 12 then
		love.graphics.draw( bigrocketbackground, 64*scale, 48*scale, 0, scale, scale)
	else
		love.graphics.draw( spaceshuttle, 64*scale, round(rocketpos*scale), 0, scale, scale, 0, 64)
	end
	
	if flicker(6) then
		if timelapsed > 3 and timelapsed < 8 then
			love.graphics.draw( smoke1left, 50*scale, 106*scale, 0, scale, scale)
			love.graphics.draw( smoke1right, 92*scale, 106*scale, 0, scale, scale)
		elseif timelapsed > 8 and timelapsed < 13 then
			love.graphics.draw( smoke2left, 44*scale, 98*scale, 0, scale, scale)
			love.graphics.draw( smoke2right, 92*scale, 98*scale, 0, scale, scale)
		end
	end
	
	--"congratulations!" appears letter by letter
	local symbolsnumber = 0
	for i = 16, 1, -1 do
		if timelapsed > 35.2 + 1.6*(i/16) then
			symbolsnumber = i
			break
		end
	end
	love.graphics.print(string.sub("congratulations!", 1, symbolsnumber), 16*scale, 32*scale, 0, scale)
	for i = 1, symbolsnumber do
		love.graphics.draw( congratsline, (9+(8*i-1))*scale, 40*scale, 0, scale, scale)
	end
end

--x, y on the launch pad and height of each small rocket
smallrockets = {
	{75, 84, 28},
	{76, 74, 38},
	{72, 56, 56},
}

function drawsmallrocket(n) --rockets 1 to 3 lift off at 8 seconds
	local image = ({rocket1, rocket2, rocket3})[n]
	local x, y, height = unpack(smallrockets[n])
	local rocketpos = 112 - 112*((timelapsed-8)/18)
	
	if timelapsed > 8.5 then
		if flicker(8) then
			love.graphics.draw( fire1, 77*scale, round(rocketpos*scale), 0, scale, scale)
		else
			love.graphics.draw( fire2, 76*scale, round(rocketpos*scale), 0, scale, scale)
		end
	end
	
	if timelapsed < 8 then
		love.graphics.draw( image, x*scale, y*scale, 0, scale, scale)
	else
		love.graphics.draw( image, x*scale, round(rocketpos*scale), 0, scale, scale, 0, height)
	end
	
	if timelapsed > 3 and timelapsed < 8.5 and flicker(6) then
		love.graphics.draw( smoke1left, 56*scale, 106*scale, 0, scale, scale)
		love.graphics.draw( smoke1right, 86*scale, 106*scale, 0, scale, scale)
	end
end

function rocket_keypressed(key)
	if controls.check("return", key) then
		love.audio.stop(sfx.musicrocket1to3)
		love.audio.stop(sfx.musicrocket4)
		failed_checkhighscores()
	end
end

registerscreen({"rocket1", "rocket2", "rocket3", "rocket4"}, {update = rocket_update, draw = rocket_draw, keypressed = rocket_keypressed})
