return {
	{state="title", timeout=20},
	{press="right"}, {press="right"}, {press="return"}, {state="options"}, {wait=0.5}, {shot="o01_options"},
	{press="left"}, {press="left"}, {press="right"},
	{press="down"}, {hold="right"}, {wait=1}, {release="right"}, {wait=0.2}, {shot="o02_hue"},
	{press="down"}, {press="left"}, {wait=0.5}, {shot="o03_scale_down"}, {press="right"}, {press="right"}, {wait=0.5},
	{call=function(log) log("scale", scale, "window", love.graphics.getDimensions()) end},
	{press="down"}, {press="left"}, {wait=1}, {shot="o04_fullscreen"},
	{call=function(log) log("fullscreen", tostring(fullscreen), love.window.getFullscreen(), love.graphics.getDimensions()) end},
	{press="right"}, {wait=1},
	{call=function(log) log("fullscreen", tostring(fullscreen), love.window.getFullscreen(), love.graphics.getDimensions()) end},
	{press="escape"}, {state="title"}, {wait=0.5}, {shot="o05_title_after"}, {quit=true},
}
