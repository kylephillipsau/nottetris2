return {
	{state="title", timeout=20},
	{press="right"}, {press="return"}, {state="multimenu"}, {wait=0.5}, {shot="m01_menu"},
	{press="return"}, {state="gameBmulti"}, {wait=1}, {shot="m02_countdown"},
	{wait=5}, {shot="m03_started"},
	{hold="down"}, {hold="m"}, {press="z"}, {press="o"}, {wait=6}, {shot="m04_mid"},
	{state="gameBmulti_results", timeout=400}, {release="down"}, {release="m"}, {wait=2}, {shot="m05_results"},
	{wait=6}, {press="return"}, {state="multimenu"}, {wait=1}, {shot="m06_back"},
	{press="escape"}, {state="title"}, {press="escape"}, {wait=2},
	{call=function(log) log("STILL RUNNING after title escape, state:", gamestate) end}, {quit=true},
}
