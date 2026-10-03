-- Versus with soft body pieces, through to the results screen.
return {
	{state="title", timeout=20}, {call=function(log) softbody = true end},
	{press="right"}, {press="return"}, {state="multimenu"}, {press="return"}, {state="gameBmulti"}, {wait=4.5},
	{hold="s"}, {hold="down"}, {hold="h"}, {wait=0.4}, {release="h"}, {hold="kp1"}, {wait=0.4}, {release="kp1"},
	{wait=3}, {shot="sv01_playing"}, {dump="sv_d1"},
	{state="gameBmulti_results", timeout=300}, {release="s"}, {release="down"}, {wait=1}, {shot="sv02_results"},
	{press="return"}, {state="multimenu"}, {quit=true},
}
