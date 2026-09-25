function menu_load()
	gamestate = "logo"
	creditstext = {
	"'Tm and C2011 sy,not",
	"tetris 2 licensed to",
	"  stabyourself.net  ",
	"         and        ",
	"  sub-licensed to   ",
	"      maurice.      ",
	"                    ",
	" C2011 stabyourself ",
	"       dot net.     ",
	"                    ",
	"                    ",
	"all rights reserved.",
	"                    ",
	"  original concept, ",
	" design and program ",
	"by alexey pazhitnov#"
	}
	logotime = 0
	bootsoundplayed = false
	oldtime = love.timer.getTime()
end

function menu_draw()
	local offsetX
	--FULLSCREEN OFFSET
	if fullscreen then
		love.graphics.translate(fullscreenoffsetX, fullscreenoffsetY)
	end

	if gamestate == "logo" then		
		if logotime <= logoduration then
			love.graphics.draw(stabyourselflogo, 7*scale, math.floor(-22*scale + 80*(logotime/logoduration)*scale), 0, scale, scale)
		else
			love.graphics.draw(stabyourselflogo, 7*scale, math.floor(58*scale), 0, scale, scale)
		end

	elseif gamestate == "credits" then------------		
		for i, v in pairs(creditstext) do
			love.graphics.print( v, 0, i*8*scale, 0, scale)
		end
		love.graphics.draw(logo, 32*scale, 80*scale, 0, scale)
	------------------------------------------
	
	elseif gamestate == "title" then----------
		love.graphics.draw(title, 0, 0, 0, scale)
	if playerselection == 1 then
		love.graphics.print(">", 1*scale, 124*scale, 0, scale)
	elseif playerselection == 2 then
		love.graphics.print(">", 47*scale, 124*scale, 0, scale)
	else
		love.graphics.print(">", 93*scale, 124*scale, 0, scale)
	end
	------------------------------------------
	
	elseif gamestate == "menu" or gamestate == "highscoreentry" then
		love.graphics.draw(gametype, 0, 0, 0, scale)
		if selection > 2 then
			if gameno == 1 then
				love.graphics.print( "normal", 24*scale, 26*scale, 0, scale)
			else
				love.graphics.print( "stack ", 88*scale, 26*scale, 0, scale)
			end
		else
			if musicno == 1 then
				love.graphics.print( "a-type", 24*scale, 60*scale, 0, scale)
			elseif musicno == 2 then
				love.graphics.print( "b-type", 88*scale, 60*scale, 0, scale)
			elseif musicno == 3 then
				love.graphics.print( "c-type", 24*scale, 76*scale, 0, scale)
			else
				love.graphics.print( " off  ", 88*scale, 76*scale, 0, scale)
			end
		end
		
		if selectblink == true then
			if selection ==1 then
				love.graphics.print( "normal", 24*scale, 26*scale, 0, scale)
			elseif selection == 2 then
				love.graphics.print( "stack ", 88*scale, 26*scale, 0, scale)
			elseif selection == 3 then
				love.graphics.print( "a-type", 24*scale, 60*scale, 0, scale)
			elseif selection == 4 then
				love.graphics.print( "b-type", 88*scale, 60*scale, 0, scale)
			elseif selection == 5 then
				love.graphics.print( "c-type", 24*scale, 76*scale, 0, scale)
			elseif selection == 6 then
				love.graphics.print( " off  ", 88*scale, 76*scale, 0, scale)
			end
		end
	----------------------------------------------
	
	elseif gamestate == "multimenu" then
		love.graphics.draw(mpmenu, 0, 0, 0, scale)
		if selection > 2 then
			if gameno == 1 then
				love.graphics.print( "stack", 28*scale, 47*scale, 0, scale)
			else
				love.graphics.print( "invade", 88*scale, 47*scale, 0, scale)
			end
		else
			if musicno == 1 then
				love.graphics.print( "a-type", 24*scale, 81*scale, 0, scale)
			elseif musicno == 2 then
				love.graphics.print( "b-type", 88*scale, 81*scale, 0, scale)
			elseif musicno == 3 then
				love.graphics.print( "c-type", 24*scale, 97*scale, 0, scale)
			else
				love.graphics.print( " off  ", 88*scale, 97*scale, 0, scale)
			end
		end
		
		if selectblink == true then
			if selection ==1 then
				love.graphics.print( "stack", 28*scale, 47*scale, 0, scale)
			elseif selection == 2 then
				love.graphics.print( "invade", 88*scale, 47*scale, 0, scale)
			elseif selection == 3 then
				love.graphics.print( "a-type", 24*scale, 81*scale, 0, scale)
			elseif selection == 4 then
				love.graphics.print( "b-type", 88*scale, 81*scale, 0, scale)
			elseif selection == 5 then
				love.graphics.print( "c-type", 24*scale, 97*scale, 0, scale)
			elseif selection == 6 then
				love.graphics.print( " off  ", 88*scale, 97*scale, 0, scale)
			end
		end
		
		--win counter
		if p1wins < 10 then
			love.graphics.print( "0"..p1wins, 15*scale, 31*scale, 0, scale)
		else
			love.graphics.print( p1wins, 15*scale, 31*scale, 0, scale)
		end
		
		if p2wins < 10 then
			love.graphics.print( "0"..p2wins, 129*scale, 31*scale, 0, scale)
		else
			love.graphics.print( p2wins, 129*scale, 31*scale, 0, scale)
		end
	end
	
	if gamestate == "menu" or gamestate == "highscoreentry" then
		for i = 1, 3 do
			if tonumber(highscore[i]) > 0 then
				--name
				love.graphics.print(string.lower(string.sub(highscorename[i], 1, 6)), 33*scale, 110*scale+8*scale*(i-1), 0, scale)
				--score
				offsetX = 0
				for i = 1, string.sub(tostring(highscore[i]), 1, 6):len() - 1 do
					offsetX = offsetX - 8*scale
				end
				love.graphics.print(string.sub(tostring(highscore[i]), 1, 6), 137*scale+offsetX, 110*scale+8*scale*(i-1), 0, scale)
			end
		end
	end
	
	if gamestate == "highscoreentry" then
		if highscorename[highscoreno]:len() < 6 then
			offsetX = 0
			for i = 1, highscorename[highscoreno]:len() do
				offsetX = offsetX + 8*scale
			end
			if cursorblink == true then
				love.graphics.print("_", 33*scale+offsetX, 110*scale+8*scale*(highscoreno-1), 0, scale)
			else
				love.graphics.print(" ", 33*scale+offsetX, 110*scale+8*scale*(highscoreno-1), 0, scale)
			end
		else
			if cursorblink == true then
				love.graphics.print("_", 33*scale+8*scale*5, 110*scale+8*scale*(highscoreno-1), 0, scale)
			end
		end
	end
	
	if gamestate == "options" then
		love.graphics.draw(optionsmenu, 0, 0, 0, scale, scale)
		love.graphics.draw(rainbowgradient, 73*scale, 33*scale, 0, scale, scale)
		
		--volume slider
		love.graphics.draw(volumeslider, 71*scale+round(76*volume)*scale, 15*scale, 0, scale, scale)
		
		--hue slider
		love.graphics.draw(volumeslider, 71*scale+round(76*hue*scale), 31*scale, 0, scale, scale)
		
		--blend out unavailable scales
		for i = 2, 7 do
			if i > maxscale then
				love.graphics.print(" ", 75*scale+(i-1)*11*scale, 50*scale, 0, scale)
			end
		end
		
		--current scale
		if fullscreen == false then
			love.graphics.print(scale, 75*scale+(scale-1)*11*scale, 50*scale, 0, scale)
		end
		
		--fullscreen
		if fullscreen then
			love.graphics.print("yes", 96*scale, 66*scale, 0, scale)
		else
			love.graphics.print("no", 133*scale, 66*scale, 0, scale)
		end
		
		
		if selectblink then
			love.graphics.print(optionschoices[optionsselection], 19*scale, 18*scale+(optionsselection-1)*16*scale, 0, scale)
		end
		
	end
	------------------------------------------
end

function menu_update(dt)
	if gamestate == "logo" then
		logotime = logotime + dt
		
		if logotime >= logoduration and bootsoundplayed == false then			
			love.audio.stop(boot)
			love.audio.play(boot)
			
			bootsoundplayed = true
		end
		
		if logotime >= logoduration + logodelay then
			oldtime = love.timer.getTime()
			gamestate = "credits"
		end
	end

	if gamestate == "credits" then
		currenttime = love.timer.getTime()
		if currenttime - oldtime > creditsdelay then
			gamestate = "title"
			love.graphics.setBackgroundColor( 0, 0, 0)
			love.audio.play(musictitle)
		end
	end
	
	if gamestate == "menu" or gamestate == "multimenu" or gamestate == "options" then
		currenttime = love.timer.getTime()
		if currenttime - oldtime > selectblinkrate then
			selectblink = not selectblink
			oldtime = currenttime
		end
	end
	
	if gamestate == "options" then
		if optionsselection == 2 then
			if controls.isDown("left") then
				if hue > 0 then
					hue = hue - 0.5*dt
					if hue < 0 then
						hue = 0
					end
					loadoptionsimages()
				end
			elseif controls.isDown("right") then
				if hue < 1 then
					hue = hue + 0.5*dt
					if hue > 1 then
						hue = 1
					end
					loadoptionsimages()
				end
			end
		end
	end
	
	if gamestate == "highscoreentry" then
		currenttime = love.timer.getTime()
		if currenttime - oldtime > cursorblinkrate then
			cursorblink = not cursorblink
			oldtime = currenttime
		end
		if currenttime - highscoremusicstart > 1.2 then
			if musicchanged == false then
				musicchanged = true
				love.audio.stop(highscoreintro)
				love.audio.play(musichighscore)
			end
		end
	end
end

function menu_textinput(text)
	if gamestate == "highscoreentry" then
		local unicode = string.byte(text)
		if whitelist[unicode] == true then
			if highscorename[highscoreno]:len() < 6 then
				cursorblink = true
				highscorename[highscoreno] = highscorename[highscoreno] .. text
				love.audio.stop(highscorebeep)
				love.audio.play(highscorebeep)
			end
		end
	end
end

function menu_keypressed(key)
	if gamestate == "boot" then
	if controls.check("return", key) then
		gamestate = "title"
		love.graphics.setBackgroundColor( 0, 0, 0)
		love.audio.play(musictitle)
		oldtime = love.timer.getTime()
	end
	
	elseif gamestate == "logo" then
	if controls.check("return", key) then
		gamestate = "title"
		love.graphics.setBackgroundColor( 0, 0, 0)
		love.audio.play(musictitle)
		oldtime = love.timer.getTime()
	end
	
	elseif gamestate == "credits" then
	if controls.check("return", key) then
		gamestate = "title"
		love.graphics.setBackgroundColor( 0, 0, 0)
		love.audio.play(musictitle)
		oldtime = love.timer.getTime()
	end
	
	elseif gamestate == "title" then
	if controls.check("return", key) then
		if playerselection ~= 3 then
			if soundenabled then
				love.audio.stop(musictitle)
				if musicno < 4 then
					love.audio.play(music[musicno])
				end
			end
		end
		if playerselection == 1 then
			gamestate = "menu"
		elseif playerselection == 2 then
			gamestate = "multimenu"
		else
			gamestate = "options"
			if soundenabled then
			love.audio.stop(musictitle)
			love.audio.play(musicoptions)
			end
			optionsselection = 1
		end
	elseif controls.check("escape", key) then
		love.event.quit()
	elseif controls.check("left", key) and playerselection > 1 then
		playerselection = playerselection - 1
	elseif controls.check("right", key) and playerselection < 3 then
		playerselection = playerselection + 1
	end
	
	elseif gamestate == "menu" then
	local oldmusicno = musicno
	if controls.check("escape", key) then
		if musicno < 4 then
			love.audio.stop(music[musicno])
		end
		gamestate = "title"
		if soundenabled then
		love.audio.stop(musictitle)
		love.audio.play(musictitle)
		end
	elseif key == "backspace" then
		newhighscores()
	elseif controls.check("return", key) then
		if gameno == 1 then
			gameA_load()
		else
			gameB_load()
		end
	else
		gamemenu_navigate(key)
	end
	if not controls.check("escape", key) then
		gamemenu_select(oldmusicno)
	end

	elseif gamestate == "options" then
	if controls.check("escape", key) then
		if soundenabled then
			love.audio.stop(musicoptions)
			love.audio.stop(musictitle)
			love.audio.play(musictitle)
		end
		saveoptions()
		loadimages()
		gamestate = "title"
	elseif controls.check("down", key) then
		optionsselection = optionsselection + 1
		if optionsselection > #optionschoices then
			optionsselection = 1
		end
		selectblink = true
		oldtime = love.timer.getTime()
		
	elseif controls.check("up", key) then
		optionsselection = optionsselection - 1
		if optionsselection == 0 then
			optionsselection = #optionschoices
		end
		selectblink = true
		oldtime = love.timer.getTime()
		
	elseif controls.check("left", key) then
		if optionsselection == 1 then
			if volume >= 0.1 then
				volume = volume - 0.1
				if volume < 0.1 then
					volume = 0
				end
				changevolume(volume)
			end
			
		elseif optionsselection == 3 then
			if fullscreen == false then
				if scale > 1 then
					scale = scale - 1
					changescale(scale)
				end
			end
			
		elseif optionsselection == 4 then
			if fullscreen == false then
				togglefullscreen(true)
			end
		
		end
		
	elseif controls.check("right", key) then
		if optionsselection == 1 then
			if volume <= 0.9 then
				volume = volume + 0.1
				changevolume(volume)
			end
			
		elseif optionsselection == 3 then
			if fullscreen == false then
				if scale < maxscale then
					scale = scale + 1
					changescale(scale)
				end
			end
			
		elseif optionsselection == 4 then
			if fullscreen == true then
				togglefullscreen(false)
			end
			
		end
		
	elseif controls.check("return", key) then
		if optionsselection == 1 then
			volume = 1
			changevolume(volume)
		elseif optionsselection == 2 then
			hue = 0.08
			loadoptionsimages()
		elseif optionsselection == 3 then
			if fullscreen == false then
				if scale ~= suggestedscale then
					scale = suggestedscale
					changescale(scale)
				end
			end
		elseif optionsselection == 4 then
			if fullscreen == true then
				togglefullscreen(false)
			end
		end
		
	end

	elseif gamestate == "multimenu" then
	local oldmusicno = musicno
	if controls.check("escape", key) then
		if musicno < 4 then
			love.audio.stop(music[musicno])
		end
		gamestate = "title"
		love.audio.stop(musictitle)
		love.audio.play(musictitle)
	elseif controls.check("return", key) then
		gameBmulti_load()
	else
		gamemenu_navigate(key)
	end
	if not controls.check("return", key) and not controls.check("escape", key) then
		gamemenu_select(oldmusicno)
	end
		
	elseif gamestate == "highscoreentry" then
	if controls.check("return", key) then
		gamestate = "menu"
		savehighscores()
		if musicchanged == true then
			love.audio.stop(musichighscore)
		else
			love.audio.stop(highscoreintro)
		end
		if musicno < 4 then
			love.audio.play(music[musicno])
		end
	elseif key == "backspace" then
		if highscorename[highscoreno]:len() > 0 then
			cursorblink = true
			highscorename[highscoreno] = string.sub(highscorename[highscoreno], 1, highscorename[highscoreno]:len()-1)
		end
	end
	end
end

registerscreen({"boot"}, {keypressed = menu_keypressed})
registerscreen({"logo", "credits", "title", "menu", "multimenu", "options", "highscoreentry"},
	{update = menu_update, draw = menu_draw, keypressed = menu_keypressed, textinput = menu_textinput})
