function love.conf(t)
	t.identity = "not_tetris_2"
	t.version = "11.5"
	t.window.title = "Not Tetris 2"
	t.window.width = 800
	t.window.height = 720
	t.window.msaa = 4 --smooth edges on the rotating vector pieces
	t.window.vsync = 1
end