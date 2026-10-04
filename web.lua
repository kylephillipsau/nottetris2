--The web version (love.js). The page sizes the canvas to the box it gives the game, in device pixels, and
--the game draws at the largest whole scale that fits, centred as in fullscreen: the pixel art stays crisp
--at any size, and the vector pieces are drawn at the screen's full resolution instead of being blown up.
--The game also tells the page what it is doing through the window title (which love.js shows as the page
--title), so the page's touch controls can switch between menus, play and typing a name.
WEB = love.system.getOS() == "Web"

local PAGECOLOUR = {21/255, 18/255, 15/255} --around the game, as on the page
local PLAYING = {gameA = true, gameB = true, failingA = true, failingB = true, gameBmulti = true, failingBmulti = true, failedBmulti = true}
local TITLES = {menu = "Not Tetris 2", playing = "Not Tetris 2 · Playing", name = "Not Tetris 2 · New high score"}
local webmode

function web_load()
	fullscreen = true --drawn centred, and the game never resizes the window itself
	love.window.setMode(800, 720, {resizable = true, highdpi = true, vsync = vsync, msaa = 4})
	web_fit()
end

function web_fit() --the largest whole scale that fits the canvas, and where the game goes in it
	desktopwidth, desktopheight = love.graphics.getPixelDimensions()
	computescales()
	scale = math.max(1, maxscale)
	physicsscale = scale/4
	fullscreenoffsetX = math.floor((desktopwidth - 160*scale)/2)
	fullscreenoffsetY = math.floor((desktopheight - 144*scale)/2)
	if mpscale then
		fitversus()
	end
end

function love.resize()
	if WEB then
		web_fit()
	end
end

function web_drawframe(x, y, w, h) --the page colour around the game; then draws in device pixels, in the game's area
	local dpi = love.graphics.getDPIScale()
	local r, g, b = love.graphics.getBackgroundColor()
	love.graphics.clear(PAGECOLOUR)
	love.graphics.scale(1/dpi)
	love.graphics.setColor(r, g, b)
	love.graphics.rectangle("fill", x, y, w, h)
	love.graphics.setColor(1, 1, 1)
	love.graphics.translate(x, y)
	love.graphics.setScissor(x/dpi, y/dpi, w/dpi, h/dpi)
end

function web_reportstate() --menus, playing or typing a name, for the page's touch controls
	local mode = PLAYING[gamestate] and "playing" or (gamestate == "highscoreentry" and "name") or "menu"
	if mode ~= webmode then
		webmode = mode
		love.window.setTitle(TITLES[mode])
	end
end
