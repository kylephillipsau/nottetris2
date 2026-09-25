function failed_load()
	gamestate = "failed"
	tetris = {} --clear all pieces
	love.audio.play(sfx.gameover2)
end

function failed_draw()
	
	if gameno == 1 then
		love.graphics.draw(gamebackgroundcutoff, 0, 0, 0, scale)
		love.graphics.draw(gameovercutoff, 14*scale, 0, 0, scale)
	else
		love.graphics.draw(gamebackground, 0, 0, 0, scale)
		love.graphics.draw(gameover, 16*scale, 0, 0, scale)
	end
	
	--SCORES---------------------------------------
	drawscorepanel()
	-----------------------------------------------
	
	
end

function failed_checkhighscores()
	highscoreno = 0
	selectblink = true
	oldtime = love.timer.getTime()
	for i = 1, 3 do
		if scorescore > highscore[i] then
			if i == 1 then
				highscore[3] = highscore[2]
				highscore[2] = highscore[1]
				highscorename[3] = highscorename[2]
				highscorename[2] = highscorename[1]
			elseif i == 2 then
				highscore[3] = highscore[2]
				highscorename[3] = highscorename[2]
			end
				
			highscoreno = i
			highscorename[i] = ""
			highscore[i] = scorescore
			cursorblink = true
			love.audio.play(sfx.highscoreintro)
			highscoremusicstart = love.timer.getTime()
			musicchanged = false
			gamestate = "highscoreentry"
			break
		end
	end
	if highscoreno == 0 then--no new highscore
		gamestate = "menu"
		if musicno < 4 then
			love.audio.play(music[musicno])
		end
	end
end

function failed_keypressed(key)
	if gamestate == "failed" then
	if controls.check("return", key) or controls.check("escape", key) then 
		love.audio.stop(sfx.gameover2)
		rocket_load()
	end
	end
end

registerscreen({"failed"}, {draw = failed_draw, keypressed = failed_keypressed})
