-- Walks the game type/music grid of both menus and the credits/title intro.
local scenario = {
	{state="credits", timeout=20}, {wait=0.3}, {shot="n01_credits"},
	{state="title", timeout=20}, {press="right"}, {wait=0.1}, {shot="n02_title_cursor"}, {press="left"},
	{press="return"}, {state="menu"},
	{press="down"}, {wait=0.1}, {shot="n03_music_a"},
	{press="right"}, {wait=0.1}, {shot="n04_music_b"},
	{press="down"}, {wait=0.1}, {shot="n05_music_off"},
	{press="left"}, {wait=0.4}, {shot="n06_music_c_blink"},
	{press="down"}, {wait=0.1}, {shot="n07_back_to_game"},
	{press="up"}, {press="up"}, {wait=0.1}, {shot="n08_up"},
	{press="escape"}, {state="title"}, {press="right"}, {press="return"}, {state="multimenu"},
	{press="down"}, {press="right"}, {press="down"}, {wait=0.1}, {shot="n09_multi_off"},
	{press="up"}, {press="up"}, {press="right"}, {wait=0.1}, {shot="n10_multi_invade"},
	{press="left"}, {wait=0.1}, {quit=true},
}
return scenario
