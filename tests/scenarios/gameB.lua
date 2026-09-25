return {
	{state="title", timeout=20},
	{press="return"}, {wait=0.3}, {press="right"}, {wait=0.3}, {shot="b01_menu"},
	{press="return"}, {state="gameB"}, {wait=2}, {shot="b02_start"},
	{hold="down"}, {press="z"}, {wait=6}, {shot="b03_mid"},
	{state="failed", timeout=400}, {release="down"}, {wait=1}, {shot="b04_failed"},
	{wait=3}, {press="return"}, {wait=3}, {shot="b05_after"},
	{call=function(log) log("state:", gamestate) end},
	{press="return"}, {wait=2}, {press="return"}, {wait=2}, {shot="b06_end"},
	{call=function(log) log("state:", gamestate) end}, {quit=true},
}
