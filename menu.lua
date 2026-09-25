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

function blinkdue(rate) --true once every rate seconds; drives the blinking selection and cursor
	local currenttime = love.timer.getTime()
	if currenttime - oldtime > rate then
		oldtime = currenttime
		return true
	end
	return false
end

function skiptotitle(key) --enter skips the intro
	if controls.check("return", key) then
		gamestate = "title"
		love.graphics.setBackgroundColor( 0, 0, 0)
		love.audio.play(musictitle)
		oldtime = love.timer.getTime()
	end
end

---------- LOGO & CREDITS ----------

function logo_update(dt)
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

function logo_draw()
	if logotime <= logoduration then
		love.graphics.draw(stabyourselflogo, 7*scale, math.floor(-22*scale + 80*(logotime/logoduration)*scale), 0, scale, scale)
	else
		love.graphics.draw(stabyourselflogo, 7*scale, math.floor(58*scale), 0, scale, scale)
	end
end

function credits_update(dt)
	if love.timer.getTime() - oldtime > creditsdelay then
		gamestate = "title"
		love.graphics.setBackgroundColor( 0, 0, 0)
		love.audio.play(musictitle)
	end
end

function credits_draw()
	for i, v in pairs(creditstext) do
		love.graphics.print( v, 0, i*8*scale, 0, scale)
	end
	love.graphics.draw(logo, 32*scale, 80*scale, 0, scale)
end

---------- TITLE ----------

function title_draw()
	love.graphics.draw(title, 0, 0, 0, scale)
	local cursorx = {1, 47, 93}
	love.graphics.print(">", cursorx[playerselection]*scale, 124*scale, 0, scale)
end

function title_keypressed(key)
	if controls.check("return", key) then
		if playerselection ~= 3 then
			love.audio.stop(musictitle)
			if musicno < 4 then
				love.audio.play(music[musicno])
			end
		end
		if playerselection == 1 then
			gamestate = "menu"
		elseif playerselection == 2 then
			gamestate = "multimenu"
		else
			gamestate = "options"
			love.audio.stop(musictitle)
			love.audio.play(musicoptions)
			optionsselection = 1
		end
	elseif controls.check("escape", key) then
		love.event.quit()
	elseif controls.check("left", key) and playerselection > 1 then
		playerselection = playerselection - 1
	elseif controls.check("right", key) and playerselection < 3 then
		playerselection = playerselection + 1
	end
end

---------- GAME TYPE MENUS ----------
--both menus are a 2x3 grid: game types in 1-2, music a/b/c/off in 3-6. {text, x, y} of each cell:
gamemenulabels = {
	{"normal", 24, 26}, {"stack ", 88, 26},
	{"a-type", 24, 60}, {"b-type", 88, 60},
	{"c-type", 24, 76}, {" off  ", 88, 76},
}
multimenulabels = {
	{"stack", 28, 47}, {"invade", 88, 47},
	{"a-type", 24, 81}, {"b-type", 88, 81},
	{"c-type", 24, 97}, {" off  ", 88, 97},
}

function drawgamemenulabels(labels) --shows the chosen game type and music; the cell under the cursor blinks
	local function printlabel(i)
		love.graphics.print(labels[i][1], labels[i][2]*scale, labels[i][3]*scale, 0, scale)
	end
	if selection > 2 then
		printlabel(gameno)
	else
		printlabel(musicno + 2)
	end
	if selectblink == true then
		printlabel(selection)
	end
end

function gamemenu_update(dt)
	if blinkdue(selectblinkrate) then
		selectblink = not selectblink
	end
end

function gamemenu_navigate(key) --moves the cursor on the game type/music grid shared by both game menus
	if controls.check("left", key) then
		if selection == 2 or selection == 4 or selection == 6 then
			selection = selection - 1
			selectblink = true
			oldtime = love.timer.getTime()
		end
	elseif controls.check("right", key) then
		if selection == 1 or selection == 3 or selection == 5 then
			selection = selection + 1
			selectblink = true
			oldtime = love.timer.getTime()
		end
	elseif controls.check("up", key) then
		if selection == 3 or selection == 4 or selection == 5 or selection == 6 then
			selection = selection - 2
			selectblink = true
			oldtime = love.timer.getTime()
			if selection < 3 then
				selection = gameno
				selectblink = false
				oldtime = love.timer.getTime()
			end
		elseif selection == 1 or selection == 2 then
			selection = musicno + 2
			selectblink = false
			oldtime = love.timer.getTime()
		end
	elseif controls.check("down", key) then
		if selection == 1 or selection == 2 or selection == 3 or selection == 4 then
			selection = selection + 2
			selectblink = true
			oldtime = love.timer.getTime()
			if selection > 2 and selection < 5 then
				selection = musicno + 2
				selectblink = false
				oldtime = love.timer.getTime()
			end
		elseif selection == 5 or selection == 6 then
			selection = gameno
			selectblink = false
			oldtime = love.timer.getTime()
		end
	end
end

function gamemenu_select(oldmusicno) --applies the game type or music under the cursor
	if selection > 2 then
		musicno = selection - 2
		if oldmusicno ~= musicno and oldmusicno ~= 4 then
			love.audio.stop(music[oldmusicno])
		end
		if musicno < 4 then
			love.audio.play(music[musicno])
		end
	else
		gameno = selection
		loadhighscores()
	end
end

function menu_draw()
	love.graphics.draw(gametype, 0, 0, 0, scale)
	drawgamemenulabels(gamemenulabels)
	
	--highscores
	for i = 1, 3 do
		if tonumber(highscore[i]) > 0 then
			love.graphics.print(string.lower(string.sub(highscorename[i], 1, 6)), 33*scale, 110*scale+8*scale*(i-1), 0, scale)
			printrightaligned(string.sub(tostring(highscore[i]), 1, 6), 137, 110+8*(i-1))
		end
	end
end

function menu_keypressed(key)
	local oldmusicno = musicno
	if controls.check("escape", key) then
		if musicno < 4 then
			love.audio.stop(music[musicno])
		end
		gamestate = "title"
		love.audio.stop(musictitle)
		love.audio.play(musictitle)
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
end

function multimenu_draw()
	love.graphics.draw(mpmenu, 0, 0, 0, scale)
	drawgamemenulabels(multimenulabels)
	
	--win counter
	love.graphics.print( string.format("%02d", p1wins), 15*scale, 31*scale, 0, scale)
	love.graphics.print( string.format("%02d", p2wins), 129*scale, 31*scale, 0, scale)
end

function multimenu_keypressed(key)
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
end

---------- HIGHSCORE ENTRY ----------

function highscoreentry_update(dt)
	if blinkdue(cursorblinkrate) then
		cursorblink = not cursorblink
	end
	if love.timer.getTime() - highscoremusicstart > 1.2 then
		if musicchanged == false then
			musicchanged = true
			love.audio.stop(highscoreintro)
			love.audio.play(musichighscore)
		end
	end
end

function highscoreentry_draw()
	menu_draw()
	
	local namelength = highscorename[highscoreno]:len()
	local y = 110*scale+8*scale*(highscoreno-1)
	if namelength < 6 then
		if cursorblink == true then
			love.graphics.print("_", 33*scale+namelength*8*scale, y, 0, scale)
		else
			love.graphics.print(" ", 33*scale+namelength*8*scale, y, 0, scale)
		end
	elseif cursorblink == true then
		love.graphics.print("_", 33*scale+8*scale*5, y, 0, scale)
	end
end

function highscoreentry_textinput(text)
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

function highscoreentry_keypressed(key)
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

---------- OPTIONS ----------

function options_update(dt)
	if blinkdue(selectblinkrate) then
		selectblink = not selectblink
	end
	
	--hue changes continuously while left/right is held
	if optionsselection == 2 then
		if controls.isDown("left") then
			if hue > 0 then
				hue = math.max(hue - 0.5*dt, 0)
				loadoptionsimages()
			end
		elseif controls.isDown("right") then
			if hue < 1 then
				hue = math.min(hue + 0.5*dt, 1)
				loadoptionsimages()
			end
		end
	end
end

function options_draw()
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

function options_keypressed(key)
	if controls.check("escape", key) then
		love.audio.stop(musicoptions)
		love.audio.stop(musictitle)
		love.audio.play(musictitle)
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
end

registerscreen({"boot"}, {keypressed = skiptotitle})
registerscreen({"logo"}, {update = logo_update, draw = logo_draw, keypressed = skiptotitle})
registerscreen({"credits"}, {update = credits_update, draw = credits_draw, keypressed = skiptotitle})
registerscreen({"title"}, {draw = title_draw, keypressed = title_keypressed})
registerscreen({"menu"}, {update = gamemenu_update, draw = menu_draw, keypressed = menu_keypressed})
registerscreen({"multimenu"}, {update = gamemenu_update, draw = multimenu_draw, keypressed = multimenu_keypressed})
registerscreen({"highscoreentry"}, {update = highscoreentry_update, draw = highscoreentry_draw, keypressed = highscoreentry_keypressed, textinput = highscoreentry_textinput})
registerscreen({"options"}, {update = options_update, draw = options_draw, keypressed = options_keypressed})
