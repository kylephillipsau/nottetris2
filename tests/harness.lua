-- Playtest harness. tests/run.sh appends `require "harness"` to a copy of
-- main.lua, so this runs after the game's callbacks are defined but before
-- love.load. It drives the game from a scenario script with a fixed clock,
-- fixed random seed and simulated keyboard, so every run renders identical
-- frames and screenshots can be compared against a baseline.
local scenario = require("scenarios." .. os.getenv("NT_SCENARIO"))
if scenario.setup then --runs before love.load, e.g. to write a saved options file
	scenario.setup()
end

local FRAME = 1/60
local clock = 0 --simulated seconds since start
local t = 0 --seconds since the last scenario step
local step = 1
local frames = 0
local held = {}
local hook = nil --function(log, held) run every frame, set by a {hook=...} step

local function log(...)
	local args = {...}
	for i = 1, select("#", ...) do
		args[i] = tostring(args[i])
	end
	io.stdout:write("[harness] ", table.concat(args, " "), "\n")
	io.stdout:flush()
end

love.timer.getTime = function() return clock end
love.keyboard.isDown = function(...)
	for _, k in ipairs({...}) do
		if held[k] then
			return true
		end
	end
	return false
end
local randomseed = math.randomseed
math.randomseed = function() randomseed(1234) end

love.errorhandler = function(msg)
	log("ERROR:", tostring(msg))
	log(debug.traceback("", 2))
	os.exit(1)
end

local gameupdate = love.update
love.update = function(dt)
	frames = frames + 1
	clock = clock + FRAME
	t = t + FRAME

	while step <= #scenario do
		local s = scenario[step]
		if s.wait and t < s.wait then
			break
		end
		if s.state and gamestate ~= s.state then
			if t > (s.timeout or 120) then
				log("TIMEOUT waiting for state", s.state, "in", gamestate)
				os.exit(2)
			end
			break
		end
		t = 0
		if s.press then
			love.keypressed(s.press, s.press, false)
			if s.text then
				love.textinput(s.text)
			end
		elseif s.hold then
			held[s.hold] = true
		elseif s.release then
			held[s.release] = nil
		elseif s.shot then --captured after this frame is drawn, i.e. after any later steps that run in the same update
			local name = s.shot
			love.graphics.captureScreenshot(function(img)
				img:encode("png", name .. ".png")
				log("shot", name)
			end)
		elseif s.dump then --exact physics state of every piece, compared like the screenshots
			local lines = {"gamestate " .. tostring(gamestate), "score " .. tostring(scorescore) .. " lines " .. tostring(linesscore)}
			for _, list in ipairs({tetris or {}, multipieces and multipieces[1] or {}, multipieces and multipieces[2] or {}}) do
				for i = 1, table.maxn(list) do
					local piece = list[i]
					if piece then
						local b = piece.body
						table.insert(lines, string.format("%d kind %d shapes %d pos %.6f %.6f angle %.6f vel %.6f %.6f",
							i, piece.kind, #piece.shapes, b:getX(), b:getY(), b:getAngle(), b:getLinearVelocity()))
					end
				end
				table.insert(lines, "--")
			end
			love.filesystem.write(s.dump .. ".txt", table.concat(lines, "\n") .. "\n")
			log("dump", s.dump, #lines, "lines")
		elseif s.hook ~= nil then --false clears it
			hook = s.hook or nil
		elseif s.call then
			s.call(log)
		elseif s.quit then
			log("DONE state=", gamestate, "frames=", frames)
			love.event.quit(0)
		end
		step = step + 1
	end

	if hook then
		hook(log, held)
	end
	gameupdate(FRAME)
end
