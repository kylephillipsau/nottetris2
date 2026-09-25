screens = {} --gamestate -> {update, draw, keypressed, textinput}

function registerscreen(states, screen) --each screen file registers the gamestates it handles
	for i, state in ipairs(states) do
		screens[state] = screen
	end
end

function love.load()
	gamestate = "boot"
	--requires--
	require "controls"
	require "game"
	require "gameB"
	require "gameBmulti"
	require "gameA"
	require "menu"
	require "failed"
	require "rocket"

	-- Set default filter to nearest-neighbor to prevent blurriness
	love.graphics.setDefaultFilter("nearest", "nearest", 0)

	vsync = true
	
	autosize()
	computescales()
	
	loadoptions()
	
	if fullscreen then
		togglefullscreen(true)
	elseif scale ~= 5 then --conf.lua opens the window at scale 5
		love.window.setMode( 160*scale, 144*scale, {vsync=vsync, msaa=0} )
	end
	
	physicsscale = scale/4
	
	
	--SOUND--
	loadsounds()
	changevolume(volume)
	
	--IMAGES THAT WON'T CHANGE HUE:
	rainbowgradient = love.graphics.newImage("graphics/rainbow.png")
	
	--Whitelist for highscorenames--
	whitelist = {}
	for i = 48, 57 do -- 0 - 9
		whitelist[i] = true
	end
	for i = 65, 90 do -- A - Z
		whitelist[i] = true
	end
	for i = 97, 122 do --a - z
		whitelist[i] = true
	end
	whitelist[32] = true -- space
	whitelist[44] = true -- ,
	whitelist[45] = true -- -
	whitelist[46] = true -- .
	whitelist[95] = true -- _
	
	-----------------------------
	
	math.randomseed( os.time() )
	math.random();math.random();math.random() --discarding some as they seem to tend to unrandomness.

	love.graphics.setBackgroundColor( 1, 1, 1 )

	p1wins = 0
	p2wins = 0

	skipupdate = true
	soundenabled = true
	startdelay = 1
	logoduration = 1.5
	logodelay = 1
	creditsdelay = 2
	selectblinkrate = 0.29
	cursorblinkrate = 0.14
	selectblink = true
	cursorblink = true
	playerselection = 1
	musicno = 1 --
	gameno = 1 --
	selection = 1 --
	colorizeduration = 3 --seconds
	lineclearduration = 1.2 --seconds
	lineclearblinks = 7 --i
	linecleartreshold = 8.1 --in blocks
	densityupdateinterval = 1/30 --in seconds
	nextpiecerotspeed = 1 --rad per seconnd
	minfps = 1/50 --dt doesn't go higher than this
	scoreaddtime = 0.5
	startdelaytime = 0
	density = 0.1
	
	blockstartY = -64 --where new blocks are created
	losingY = 0 --lose if block 1 collides above this line
	minmass = 1
	
	optionschoices = {"volume", "color", "scale", "fullscrn"}
	
	piececenter = {}
	piececenter[1] = {17, 5}
	piececenter[2] = {13, 9}
	piececenter[3] = {13, 9}
	piececenter[4] = { 9, 9}
	piececenter[5] = {13, 9}
	piececenter[6] = {13, 9}
	piececenter[7] = {13, 9}
	
	piececenterpreview = {}
	piececenterpreview[1] = {17, 5}
	piececenterpreview[2] = {15, 7}
	piececenterpreview[3] = {11, 7}
	piececenterpreview[4] = { 9, 9}
	piececenterpreview[5] = {13, 9}
	piececenterpreview[6] = {13, 7}
	piececenterpreview[7] = {13, 9}
	
	loadhighscores()
	
	loadimages()
	
	--all done!
	if startdelay == 0 then
		menu_load()
	end
end

function start()
	menu_load()
end

function loadimages()
	--IMAGES--
	--menu--
	stabyourselflogo = newTintedImage("graphics/stabyourselflogo.png")
	logo = newTintedImage("graphics/logo.png")
	title = newTintedImage("graphics/title.png")
	gametype = newTintedImage("graphics/gametype.png")
	mpmenu = newTintedImage("graphics/mpmenu.png")
	loadoptionsimages()
	--game--
	gamebackground = newTintedImage("graphics/gamebackground.png")
	gamebackgroundcutoff = newTintedImage("graphics/gamebackgroundgamea.png")
	gamebackgroundmulti = newTintedImage("graphics/gamebackgroundmulti.png")
	multiresults = newTintedImage("graphics/multiresults.png")
	
	number1 = newTintedImage("graphics/versus/number1.png")
	number2 = newTintedImage("graphics/versus/number2.png")
	number3 = newTintedImage("graphics/versus/number3.png")
	
	gameover = newTintedImage("graphics/gameover.png")
	gameovercutoff = newTintedImage("graphics/gameovercutoff.png")
	pausegraphic = newTintedImage("graphics/pause.png")
	pausegraphiccutoff = newTintedImage("graphics/pausecutoff.png")
	
	--figures--
	marioidle = newTintedImage("graphics/versus/marioidle.png")
	mariojump = newTintedImage("graphics/versus/mariojump.png")
	mariocry1 = newTintedImage("graphics/versus/mariocry1.png")
	mariocry2 = newTintedImage("graphics/versus/mariocry2.png")
	
	luigiidle = newTintedImage("graphics/versus/luigiidle.png")
	luigijump = newTintedImage("graphics/versus/luigijump.png")
	luigicry1 = newTintedImage("graphics/versus/luigicry1.png")
	luigicry2 = newTintedImage("graphics/versus/luigicry2.png")
	
	--rockets--
	rocket1 = newTintedImage("graphics/rocket1.png")
	rocket2 = newTintedImage("graphics/rocket2.png")
	rocket3 = newTintedImage("graphics/rocket3.png")
	spaceshuttle = newTintedImage("graphics/spaceshuttle.png")
	
	rocketbackground = newTintedImage("graphics/rocketbackground.png")
	bigrocketbackground = newTintedImage("graphics/bigrocketbackground.png")
	bigrockettakeoffbackground = newTintedImage("graphics/bigrockettakeoffbackground.png")
	
	
	smoke1left = newTintedImage("graphics/smoke1left.png")
	smoke1right = newTintedImage("graphics/smoke1right.png")
	smoke2left = newTintedImage("graphics/smoke2left.png")
	smoke2right = newTintedImage("graphics/smoke2right.png")
	
	fire1 = newTintedImage("graphics/fire1.png")
	fire2 = newTintedImage("graphics/fire2.png")
	firebig1 = newTintedImage("graphics/firebig1.png")
	firebig2 = newTintedImage("graphics/firebig2.png")
	
	congratsline = newTintedImage("graphics/congratsline.png")
	
	--nextpiece
	nextpieceimg = {}
	for i = 1, 7 do
		nextpieceimg[i] = newTintedImage( "graphics/pieces/"..i..".png", scale )
	end
	
	--font--
	tetrisfont = newTintedImageFont("graphics/font.png", "0123456789abcdefghijklmnopqrstTuvwxyz.,'C-#_>:<! ")
	whitefont = newTintedImageFont("graphics/fontwhite.png", "0123456789abcdefghijklmnopqrstTuvwxyz.,'C-#_>:<!+ ")
	love.graphics.setFont(tetrisfont)
end

function love.update(dt)
	if gamestate == "boot" then
		startdelaytime = startdelaytime + dt
		if startdelaytime >= startdelay then
			start()
		end
	end

	if skipupdate then
		skipupdate = false
		return
	end
	
	if cuttingtimer ~= 0 then
		dt = math.min(dt, minfps)
	end
	
	local screen = screens[gamestate]
	if screen and screen.update then
		screen.update(dt)
	end
end

function love.draw()
	local screen = screens[gamestate]
	if screen and screen.draw then
		screen.draw()
	end
end

function printrightaligned(value, x, y, s) --prints value so that its last character starts at x, y (unscaled pixels; s defaults to scale)
	s = s or scale
	love.graphics.print(value, x*s - (tostring(value):len()-1)*8*s, y*s, 0, s)
end

function newImageData(path, s)
	local imagedata = love.image.newImageData( path )
	
	if s then
		imagedata = scaleImagedata(imagedata, s)
	end
	
	local width, height = imagedata:getWidth(), imagedata:getHeight()
	
	local rr, rg, rb = unpack(getrainbowcolor(hue))
	
	for y = 0, height-1 do
		for x = 0, width-1 do
			local oldr, oldg, oldb, olda = imagedata:getPixel(x, y)

			if olda ~= 0 then
				if oldr > 0.796 and oldr < 0.835 then --lightgrey (203-213/255)
					local r = (145 + rr*64) / 255
					local g = (145 + rg*64) / 255
					local b = (145 + rb*64) / 255
					imagedata:setPixel(x, y, r, g, b, olda)
				elseif oldr > 0.419 and oldr < 0.458 then --darkgrey (107-117/255)
					local r = (73 + rr*43) / 255
					local g = (73 + rg*43) / 255
					local b = (73 + rb*43) / 255
					imagedata:setPixel(x, y, r, g, b, olda)
				end
			end
		end
	end
	
	return imagedata
end

function newTintedImage(filename, s) --loads an image tinted with the current hue, optionally scaled by s
	return love.graphics.newImage(newImageData(filename, s))
end

function newTintedImageFont(filename, glyphs)
	return love.graphics.newImageFont(newImageData(filename), glyphs)
end

function loadoptionsimages() --the options screen previews the hue, so reload its images when it changes
	optionsmenu = newTintedImage("graphics/options.png")
	volumeslider = newTintedImage("graphics/volumeslider.png")
end

function scaleImagedata(imagedata, i)
	local width, height = imagedata:getWidth(), imagedata:getHeight()
	local scaled = love.image.newImageData(width*i, height*i)
	
	for y = 0, height*i-1 do
		for x = 0, width*i-1 do
			local r, g, b, a = imagedata:getPixel(math.floor(x/i), math.floor(y/i))
			scaled:setPixel(x, y, r, g, b, a)
		end
	end	
	
	return scaled
end

--every sound: global name, file in sounds/, volume at full volume, looping. music[1..3] are the game themes.
sounds = {
	{"music1", "themeA", 0.6, true},
	{"music2", "themeB", 0.6, true},
	{"music3", "themeC", 0.6, true},
	{"musictitle", "titlemusic", 0.6, true},
	{"musichighscore", "highscoremusic", 0.6, true},
	{"musicrocket4", "rocket4", 0.6},
	{"musicrocket1to3", "rocket1to3", 0.6},
	{"musicresults", "resultsmusic", 1},
	{"highscoreintro", "highscoreintro", 0.6},
	{"musicoptions", "musicoptions", 1, true},
	{"boot", "boot", 1},
	{"blockfall", "blockfall", 1},
	{"blockturn", "turn", 1},
	{"blockmove", "move", 1},
	{"lineclear", "lineclear", 1},
	{"fourlineclear", "4lineclear", 1},
	{"gameover1", "gameover1", 1},
	{"gameover2", "gameover2", 1},
	{"pausesound", "pause", 1},
	{"highscorebeep", "highscorebeep", 1},
	{"newlevel", "newlevel", 0.6},
}

function loadsounds()
	for i, sound in ipairs(sounds) do
		local name, file, vol, looping = unpack(sound)
		local source = love.audio.newSource("sounds/"..file..".ogg", name == "boot" and "static" or "stream")
		source:setLooping(looping == true)
		_G[name] = source
	end
	music = {music1, music2, music3}
end

function changevolume(i)
	for j, sound in ipairs(sounds) do
		_G[sound[1]]:setVolume(sound[3]*i)
	end
end
function loadoptions()
	if love.filesystem.getInfo("options.txt") then
		local s = love.filesystem.read("options.txt")
		local split1 = s:split("\n")
		for i = 1, #split1 do
			local split2 = split1[i]:split("=")
			if split2[1] == "volume" then
				local v = tonumber(split2[2])
				--clamp and round
				if v < 0 then
					v = 0
				elseif v > 1 then
					v = 1
				end
				v = math.floor(v*10)/10
				
				volume = v
				
			elseif split2[1] == "hue" then
				hue = tonumber(split2[2])
			
			elseif split2[1] == "scale" then
				scale = tonumber(split2[2])
			
			elseif split2[1] == "fullscreen" then
				if split2[2] == "true" then
					fullscreen = true
				else
					fullscreen = false
				end	
			end
		end
		
		if volume == nil then
			volume = 1
		end
		if hue == nil then
			hue = 0.08
		end
		if fullscreen == nil then
			fullscreen = false
		end
		
		if scale == nil then
			scale = suggestedscale
		end
		
		
	else
		volume = 1
		hue = 0.08
		autosize()
		scale = suggestedscale
		fullscreen = false
	end
	
	saveoptions()
end

function saveoptions()
	local s = ""
	
	s = s .. "volume=" .. volume .. "\n"
	s = s .. "hue=" .. hue .. "\n"
	s = s .. "scale=" .. scale .. "\n"
	s = s .. "fullscreen=" .. tostring(fullscreen) .. "\n"
	
	love.filesystem.write("options.txt", s)
end

function autosize()
	desktopwidth, desktopheight = love.window.getDesktopDimensions(1)
end

function computescales() --largest scale that fits the desktop, and a comfortable default for windowed mode
	suggestedscale = math.min(math.floor((desktopheight-50)/144), math.floor((desktopwidth-10)/160))
	if suggestedscale > 5 then
		suggestedscale = 5
	end
	maxscale = math.min(math.floor(desktopheight/144), math.floor(desktopwidth/160))
end

function restorewindow() --back to the single player window size after versus mode
	if not fullscreen then
		love.window.setMode( 160*scale, 144*scale, {vsync=vsync, msaa=0} )
	end
end

function togglefullscreen(fullscr)
	fullscreen = fullscr
	love.mouse.setVisible( not fullscreen )
	if fullscr == false then
		scale = suggestedscale
		physicsscale = scale/4
		love.window.setMode( 160*scale, 144*scale, {vsync=vsync, msaa=0} )
	else
		love.window.setMode( 0, 0, {fullscreen=true, vsync=vsync, msaa=0} )
		desktopwidth, desktopheight = love.graphics.getDimensions()
		computescales()
		
		scale = maxscale
		physicsscale = scale/4
		
		fullscreenoffsetX = (desktopwidth-160*scale)/2
		fullscreenoffsetY = (desktopheight-144*scale)/2
	end
end

function loadhighscores()
	local fileloc, highdata
	if gameno == 1 then
		fileloc = "highscoresA.txt"
	else
		fileloc = "highscoresB.txt"
	end
	
	if love.filesystem.getInfo( fileloc ) then
		
		highdata = love.filesystem.read( fileloc )
		highdata = highdata:split(";")
		highscore = {}
		highscorename = {}
		for i = 1, 3 do
			highscore[i] = tonumber(highdata[i*2])
			highscorename[i] = string.lower(highdata[i*2-1])
		end
	else
		highscore = {}
		highscorename = {}
		highscore[1] = 0
		highscorename[1] = ""
		highscore[2] = 0
		highscorename[2] = ""
		highscore[3] = 0
		highscorename[3] = ""
		savehighscores()
	end
end

function newhighscores()
	highscore = {}
	highscorename = {}
	highscore[1] = 0
	highscorename[1] = ""
	highscore[2] = 0
	highscorename[2] = ""
	highscore[3] = 0
	highscorename[3] = ""
	savehighscores()
end

function savehighscores()
	local fileloc, highdata
	if gameno == 1 then
		fileloc = "highscoresA.txt"
	else
		fileloc = "highscoresB.txt"
	end
	
	highdata = ""
	for i = 1, 3 do
		highdata = highdata..highscorename[i]..";"..highscore[i]..";"
	end
	love.filesystem.write( fileloc, highdata.."\n" )
end

function changescale(i)
	love.window.setMode( 160*i, 144*i, {vsync=vsync, msaa=0} )
	nextpieceimg = {}
	for j = 1, 7 do
		nextpieceimg[j] = newTintedImage( "graphics/pieces/"..j..".png", i )
	end
	physicsscale = i/4
end

function string:split(delimiter)
	local result = {}
	local from  = 1
	local delim_from, delim_to = string.find( self, delimiter, from  )
	while delim_from do
		table.insert( result, string.sub( self, from , delim_from-1 ) )
		from  = delim_to + 1
		delim_from, delim_to = string.find( self, delimiter, from  )
	end
	table.insert( result, string.sub( self, from  ) )
	return result
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function getPoints2table(shape, body) --returns the shape's points; in world coordinates if the body it's attached to is given
	if body then
		return {body:getWorldPoints(shape:getPoints())}
	end
	return {shape:getPoints()}
end

function getrainbowcolor(i)
	local r, g, b
	if i < 1/6 then
		r = 1
		g = i*6
		b = 0
	elseif i >= 1/6 and i < 2/6 then
		r = (1/6-(i-1/6))*6
		g = 1
		b = 0
	elseif i >= 2/6 and i < 3/6 then
		r = 0
		g = 1
		b = (i-2/6)*6
	elseif i >= 3/6 and i < 4/6 then
		r = 0
		g = (1/6-(i-3/6))*6
		b = 1
	elseif i >= 4/6 and i < 5/6 then
		r = (i-4/6)*6
		g = 0
		b = 1
	else
		r = 1
		g = 0
		b = (1/6-(i-5/6))*6
	end
	
	return {r, g, b}
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

function love.keypressed( key, scancode, isrepeat )
	local screen = screens[gamestate]
	if screen and screen.keypressed then
		screen.keypressed(key)
	end
end

function love.textinput(text)
	local screen = screens[gamestate]
	if screen and screen.textinput then
		screen.textinput(text)
	end
end