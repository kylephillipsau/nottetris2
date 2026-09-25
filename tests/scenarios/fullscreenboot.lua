-- Starts with fullscreen saved in the options, plays briefly, then returns to windowed mode.
local scenario = {
	{state="title", timeout=20}, {wait=0.5}, {shot="f01_title"},
	{call=function(log) log("scale", scale, "suggested", suggestedscale, "max", maxscale, "fullscreen", fullscreen, love.graphics.getDimensions()) end},
	{press="return"}, {press="return"}, {state="gameA"}, {wait=1}, {shot="f02_gameA"},
	{press="escape"}, {state="menu"}, {press="escape"}, {state="title"},
	{press="right"}, {press="return"}, {state="multimenu"}, {press="return"}, {state="gameBmulti"}, {wait=1}, {shot="f03_versus"},
	{press="escape"}, {state="multimenu"}, {press="escape"}, {state="title"},
	{press="right"}, {press="return"}, {state="options"},
	{press="down"}, {press="down"}, {press="down"}, {press="right"}, {wait=0.5}, {shot="f04_windowed"},
	{call=function(log) log("scale", scale, "fullscreen", fullscreen, love.graphics.getDimensions()) end},
	{quit=true},
}
scenario.setup = function()
	love.filesystem.write("options.txt", "volume=1\nhue=0.08\nscale=3\nfullscreen=true\n")
end
return scenario
