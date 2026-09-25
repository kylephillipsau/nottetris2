function gameA_load()
	gamestate = "gameA"
	
	pause = false
	skipupdate = true
	
	difficulty_speed = 100

	cuttingtimer = lineclearduration
	
	scorescore = 0
	levelscore = 0
	linesscore = 0
	
	linescleared = 0
	lastscoreadd = 0
	scoreaddtimer = scoreaddtime
	densityupdatetimer = 0
	nextpiecerot = 0
	newlevelbeep = false
	
	--PHYSICS--
	meter = 30
	world = love.physics.newWorld(0, 500, true )

	tetris = {} --pieces: {kind, body, shapes, fixtures, image, imagedata}. 1 is the falling piece
	local wallbodies, wallshapes
	wallbodies, wallshapes, wallfixtures = newwalls(world, {
		{points = {-8,-64, -8,672, 24,672, 24,-64}, data = {"left"}, friction = 0.00001},
		{points = {352,-64, 352,672, 384,672, 384,-64}, data = {"right"}, friction = 0.00001},
		{points = {24,640, 24,672, 352,672, 352,640}, data = {"ground"}},
		{points = {-8,-96, 384,-96, 384,-64, -8,-64}, data = {"ceiling"}},
	})

	world:setCallbacks(collideA, nil, nil, nil)
	-----------
	
	--FIRST "nextpiece"-
	nextpiece = math.random(7)
	
	checklinedensity(false)
	game_addTetriA()
	nextpiece = math.random(7)
	----------------
end

function game_addTetriA() --creates new block (using createtetriA) at 1 and sets its velocity
	--NEW BLOCK--
	randomblock = nextpiece
	createtetriA(randomblock, 1, 224, blockstartY)
	tetris[1].body:setLinearVelocity(0, difficulty_speed)
end	

function createtetriA(i, uniqueid, x, y) --creates block, including body, shapes, image, imagedata and whatnot.
	local piece = newpiece(world, i, x, y, 1)
	piece.imagedata = newImageData( "graphics/pieces/"..i..".png", scale)
	piece.image = love.graphics.newImage( piece.imagedata )
	tetris[uniqueid] = piece

	for i, v in pairs(tetris[uniqueid].fixtures) do
		v:setUserData({1})
	end
end

function gameA_draw()
	
	--background--
	love.graphics.draw(gamebackgroundcutoff, 0, 0, 0, scale, scale)
	---------------
	--pieces--
	if cuttingtimer == lineclearduration then
		for i, piece in pairs(tetris) do
			if pause == false then
				drawpiece(piece, physicsscale, scale)
			end
		end
	else
		for i = 1, #tetricutimg do
			if pause == false then
				love.graphics.draw( tetricutimg[i], tetricutpos[i*2-1]*physicsscale, tetricutpos[i*2]*physicsscale, tetricutang[i], 1, 1, piececenter[tetricutkind[i]][1]*scale, piececenter[tetricutkind[i]][2]*scale)
			end
		end
		
		--blinky lines
		
		local section = math.ceil(cuttingtimer/(lineclearduration/lineclearblinks))
		if math.mod(section, 2) == 1 or cuttingtimer == 0 then

			local rr, rg, rb = unpack(getrainbowcolor(hue))
			local r = (145 + rr*64)/255
			local g = (145 + rg*64)/255
			local b = (145 + rb*64)/255

			for i = 1, 18 do
				if linesremoved[i] == true then
					love.graphics.setColor(r, g, b)

					love.graphics.rectangle("fill", 14*scale, (i-1)*8*scale, 82*scale, 8*scale)
				end
			end
		end
	end

	love.graphics.setColor(1, 1, 1)
	--Next piece
	if pause == false then
		love.graphics.draw(nextpieceimg[nextpiece], 136*scale, 120*scale, nextpiecerot, 1, 1, piececenterpreview[nextpiece][1]*scale, piececenterpreview[nextpiece][2]*scale)
	end
	
	----------------
	--Last score
	if scoreaddtimer < scoreaddtime then
		love.graphics.push("all")
		local x, y = love.graphics.transformPoint(105*scale, 35*scale)
		love.graphics.intersectScissor(x, y, 55*scale, 9*scale)
		love.graphics.setFont(whitefont)
		printrightaligned("+" .. lastscoreadd, 144, 36-scoreaddtimer/scoreaddtime*8)
		love.graphics.pop()
	end
	
	
	--line density counter
	for i = 1, 18 do
		local fullness = linearea[i]/1024/linecleartreshold
		if fullness > 1 then
			fullness = 1
		end

		local color
		if fullness == 1 then
			color = 0
		else
			color = (235-(fullness/1)*180)/255
		end

		love.graphics.setColor(color, color, color)
		love.graphics.rectangle("fill", 0, (i-1)*8*scale, math.floor(6*scale*fullness), 8*scale)
	end

	love.graphics.setColor(1, 1, 1)
	
	---------
	--start--
	if pause == true then
		love.graphics.draw(pausegraphiccutoff, 14*scale, 0, 0, scale, scale)
	end
	---------
	
	--SCORES---------------------------------------
	drawscorepanel()
	-----------------------------------------------
	
	
end

function gameA_update(dt)
	if pause then
		return
	end

	--NEXTPIECE ROTATION (rotating allday erryday)
	if cuttingtimer == lineclearduration then
		nextpiecerot = nextpiecerot + nextpiecerotspeed*dt
		while nextpiecerot > math.pi*2 do
			nextpiecerot = nextpiecerot - math.pi*2
		end
	end
	
	--CUTTING TIMER
	if cuttingtimer < lineclearduration then
		cuttingtimer = cuttingtimer + dt
		if cuttingtimer >= lineclearduration then
			--RANDOMIZE NEXT PIECE
			nextpiece = math.random(7)
			
			cuttingtimer = lineclearduration
			skipupdate = true
			scoreaddtimer = 0
		
			if newlevelbeep then
				love.audio.stop(newlevel)
				love.audio.play(newlevel)
				newlevelbeep = false
			end
		end
		return
	end
	
	--SCOREADD TIMER
	if cuttingtimer == lineclearduration then
		if scoreaddtimer < scoreaddtime then
			scoreaddtimer = scoreaddtimer + dt
			if scoreaddtimer > scoreaddtime then
				scoreaddtimer = scoreaddtime
			end
		end
	end
		
	if gamestate == "gameA" then
		steerpiece(tetris[1].body, dt, "", 500)
	end
	
	endblock = false

	world:update(dt)

	if endblock then
		endblockA()
	end

	
	--DENSITY UPDATE TIMER
	if densityupdatetimer >= densityupdateinterval then
		while densityupdatetimer >= densityupdateinterval and cuttingtimer == lineclearduration do
			checklinedensity(false)
			densityupdatetimer = densityupdatetimer - densityupdateinterval
		end
	end
	densityupdatetimer = densityupdatetimer + dt
	
	if gamestate == "failingA" then
		local clearcheck = true
		for i, piece in pairs(tetris) do
			if piece.body:getY() < 648 then
				clearcheck = false
			end
		end
		
		if clearcheck then
			failed_load()
		end
	end
end

function getintersectX(shape, y, body) --returns left and right collision points to a certain shape on a Y coordinate (or -1, -0.9 if no collision). Pass the body the shape is attached to, or nil for shapes in world coordinates.
	local tx, ty, tr = 0, 0, 0
	if body then
		tx, ty = body:getPosition()
		tr = body:getAngle()
	end
	local _, _, lefttime = shape:rayCast( 55, y, 385, y, 1, tx, ty, tr)
	local _, _, righttime = shape:rayCast( 385, y, 55, y, 1, tx, ty, tr)
	if lefttime ~= nil and righttime ~= nil then
		local leftx = 330 * lefttime + 55
		local rightx = 385 - 330 * righttime
		return leftx, rightx
	else
		return -1, -0.9
	end
end

function removeline(lineno) --clears a line: cuts every piece crossing it, splitting pieces that fall apart into separate bodies
	local upperline = (lineno - 1) * 32
	local lowerline = lineno * 32
	local numberofbodies = highestbody()
	local ioffset = 0
	tetris[1] = false --placeholder for the falling piece so table.remove below works
	for i = 2, numberofbodies do
		if i-ioffset > numberofbodies then
			break
		end
		if cutpiece(i-ioffset, upperline, lowerline) then --piece was entirely inside the line
			numberofbodies = numberofbodies - 1
			ioffset = ioffset + 1
		end
	end
end

function cutpiece(index, upperline, lowerline) --cuts the part of a piece between the lines away. returns true if nothing is left of it
	local piece = tetris[index]
	local newshapes, refined = splitshapes(piece, upperline, lowerline)
	local removed = false
	
	if refined then
		for i, fixture in pairs(piece.fixtures) do
			fixture:destroy()
		end
		piece.fixtures = {}
		piece.shapes = {}
		
		if #newshapes == 0 then
			piece.body:destroy()
			table.remove(tetris, index)
			removed = true
		else
			local shapegroups, numberofgroups = groupconnectedshapes(newshapes)
			rebuildpiece(index, newshapes, shapegroups, numberofgroups)
		end
	end
	
	for i, shape in pairs(newshapes) do
		shape:release()
	end
	return removed
end

function splitshapes(piece, upperline, lowerline) --returns the piece's shapes with the part between the lines removed (local to its body), and whether any shape was cut
	local body = piece.body
	local newshapes = {}
	local refined = false
	for j, shape in pairs(piece.shapes) do
		local above, inside, below = false, false, false
		local coordinates = getPoints2table(shape, body)
		for y = 2, #coordinates, 2 do
			if coordinates[y] < upperline then
				above = true
			elseif coordinates[y] <= lowerline then
				inside = true
			else
				below = true
			end
		end
		
		if inside or (above and below) then
			refined = true
			if above then
				newshapes[#newshapes+1] = refineshape(upperline, 1, body, shape)
			end
			if below then
				newshapes[#newshapes+1] = refineshape(lowerline, -1, body, shape)
			end
		else --untouched, copy it
			local cotable = getPoints2table(shape, body)
			for var = 1, #cotable, 2 do
				cotable[var], cotable[var+1] = body:getLocalPoint(cotable[var], cotable[var+1])
			end
			newshapes[#newshapes+1] = love.physics.newPolygonShape(unpack(cotable))
		end
	end
	return newshapes, refined
end

function groupconnectedshapes(shapes) --shapes sharing a corner belong to the same group. returns the group of each shape and the number of groups
	local shapegroups = {}
	local numberofgroups = 0
	for a, shape in pairs(shapes) do
		shapegroups[a] = 0
		local currentcoords = getPoints2table(shape)
		for shapecounter = 1, a - 1 do --through all previously grouped shapes
			local coords = getPoints2table(shapes[shapecounter])
			for currentcoordsvar = 1, #currentcoords/2 do
				for coordsvar = 1, #coords/2 do
					if math.abs(currentcoords[currentcoordsvar*2-1] - coords[coordsvar*2-1]) < 2 and math.abs(currentcoords[currentcoordsvar*2] - coords[coordsvar*2]) < 2 then
						shapegroups[a] = shapegroups[shapecounter]
					end
				end
			end
		end
		
		if shapegroups[a] == 0 then --create new group
			numberofgroups = numberofgroups + 1
			shapegroups[a] = numberofgroups
		end
	end
	return shapegroups, numberofgroups
end

function rebuildpiece(index, shapes, shapegroups, numberofgroups) --gives the piece a fresh body with the shapes of group 1; every further group becomes a new piece
	local piece = tetris[index]
	local oldbody = piece.body
	local rotation = oldbody:getAngle()
	local oldX, oldY = oldbody:getX(), oldbody:getY()
	oldbody:destroy()
	piece.body = love.physics.newBody(world, oldX, oldY, "dynamic")
	piece.body:setAngle(rotation)
	piece.shapes = {}
	piece.fixtures = {}
	addgroupfixtures(piece, index, shapes, shapegroups, 1)
	
	--keep the uncut image for the other groups before cutting this one
	local backupimagedata = love.image.newImageData(piece.imagedata:getWidth(), piece.imagedata:getHeight())
	backupimagedata:paste(piece.imagedata, 0, 0, 0, 0, piece.imagedata:getWidth(), piece.imagedata:getHeight())
	cutimage(index)
	enforceminmass(piece)
	
	for a = 2, numberofgroups do
		local n = highestbody()+1
		local newpiece = {kind = piece.kind, shapes = {}, fixtures = {}}
		tetris[n] = newpiece
		newpiece.body = love.physics.newBody(world, piece.body:getX(), piece.body:getY(), "dynamic")
		newpiece.body:setAngle(piece.body:getAngle())
		addgroupfixtures(newpiece, n, shapes, shapegroups, a)
		
		newpiece.body:setLinearVelocity(piece.body:getLinearVelocity())
		newpiece.body:setLinearDamping(0.5)
		newpiece.body:setBullet(true)
		newpiece.body:setAngularVelocity(piece.body:getAngularVelocity())
		
		newpiece.imagedata = love.image.newImageData(backupimagedata:getWidth(), backupimagedata:getHeight())
		newpiece.imagedata:paste(backupimagedata, 0, 0, 0, 0, backupimagedata:getWidth(), backupimagedata:getHeight())
		cutimage(n)
		enforceminmass(newpiece)
	end
end

function addgroupfixtures(piece, index, shapes, shapegroups, group) --attaches copies of the shapes in a group to the piece's body. the shapes are local to the old body, which had the same position and angle
	for b, shape in pairs(shapes) do
		if shapegroups[b] == group then
			local newshape = love.physics.newPolygonShape(shape:getPoints())
			local fixture = love.physics.newFixture(piece.body, newshape, 1)
			fixture:setUserData({index}) --set the fixture name for collision
			piece.shapes[#piece.shapes+1] = newshape
			piece.fixtures[#piece.fixtures+1] = fixture
		end
	end
end

function enforceminmass(piece) --tiny cut off bits get heavier so they don't fly around
	piece.body:resetMassData()
	
	local mass = piece.body:getMass()
	if mass < minmass then
		for i, fixture in pairs(piece.fixtures) do
			fixture:setDensity( minmass/mass )
		end
		piece.body:resetMassData()
		for i, fixture in pairs(piece.fixtures) do
			fixture:setDensity( 1 )
		end
	end
end

function cutimage(bodyid) --makes the pixels of a piece's image that aren't covered by its fixtures transparent
	local piece = tetris[bodyid]
	local width = piece.imagedata:getWidth()
	local height = piece.imagedata:getHeight()
	
	for y = 0, height-1 do
		for x = 0, width-1 do
			local worldx, worldy = piece.body:getWorldPoint((x-width/2+.5)*(4/scale), (y-height/2+.5)*(4/scale))
			local deletepixel = true
			
			for i, fixture in pairs(piece.fixtures) do
				if fixture:testPoint( worldx, worldy ) then
					deletepixel = false
					break
				end
			end
			
			if deletepixel then
				piece.imagedata:setPixel(x, y, 1, 1, 1, 0)
			end
		end
	end
	
	piece.image = love.graphics.newImage( piece.imagedata )
end

function refineshape(line, mult, body, shape) --cuts a shape at a line, keeping the part above it (mult 1) or below it (mult -1). returns the new shape local to body, or nil if too small
	local leftx, rightx = getintersectX(shape, line, body)
	if leftx ~= -1 then --Not sure what to do if not
		local coords = getPoints2table(shape, body)
		
		--remove all points inside the cutting zone
		local lastcutoff
		local i=2
		while i <= #coords do
			if coords[i]*mult > line*mult then
				table.remove(coords, i)
				table.remove(coords, i-1)
				lastcutoff = i
				i=0
			end
			i=i+2
		end
		
		--add new points (Only if they aren't identical to existing points)
		if lastcutoff then
			if mult == 1 then
				if samepos(coords, line, leftx) == false then
					table.insert(coords, lastcutoff-1,leftx)
					table.insert(coords, lastcutoff,line)
				end
				
				if samepos(coords, line, rightx) == false then
					table.insert(coords, lastcutoff-1,rightx)
					table.insert(coords, lastcutoff,line)
				end
			else
				if samepos(coords, line, rightx) == false then
					table.insert(coords, lastcutoff-1,rightx)
					table.insert(coords, lastcutoff,line)
				end
				
				if samepos(coords, line, leftx) == false then
					table.insert(coords, lastcutoff-1,leftx)
					table.insert(coords, lastcutoff,line)
				end
			end
		end
		
		--create the new shape
		if #coords/2 >= 3 and #coords/2 <= 8 then --shape still has 3 or more points, and not over 8.
			if largeenough(coords) then
				local newcoords={}
				for i=1,#coords,2 do
					newcoords[i],newcoords[i+1] = body:getLocalPoint(coords[i], coords[i+1])
				end
				return love.physics.newPolygonShape(unpack(newcoords))
			end
		end
	else
		local coords = getPoints2table(shape, body)
		local newcoords={}
		for i=1,#coords,2 do
			newcoords[i],newcoords[i+1] = body:getLocalPoint(coords[i], coords[i+1])
		end
		return love.physics.newPolygonShape(unpack(newcoords))
	end
end

function checklinedensity(active) --measures how full each line is; if active, also clears full lines. returns whether lines were cleared
	measurelines()
	if active then
		return clearfulllines()
	end
end

function measurelines() --linearea[line] = area covered by landed pieces in each of the 18 lines
	linearea = {}
	for i = 1, 18 do
		linearea[i] = 0
	end
	
	for i = 2, highestbody() do
		for j, shape in pairs(tetris[i].shapes) do
			addshapelineareas(shape, tetris[i].body)
		end
	end
end

function addshapelineareas(shape, body) --splits a shape into the lines it spans and adds each part's area to linearea
	local coords = getPoints2table(shape, body)
	--Get first and last involved line
	local firstline = 19
	local lastline =  0
	
	for point = 2, #coords, 2 do
		if math.ceil(round(coords[point]) / 32) < firstline then
			firstline = math.ceil(round(coords[point]) / 32)
		elseif math.ceil(round(coords[point]) / 32) > lastline then
			lastline = math.ceil(round(coords[point]) / 32)
		end
	end
	
	for line = firstline, lastline do
		if line >= 1 and line <= 18 then
			coords = getPoints2table(shape, body)
			
			if line > firstline then
				local leftx, rightx = findintersectX(shape, body, (line-1)*32, 1)
				cutpointsabove(coords, (line-1)*32, leftx, rightx)
			end
			
			if line < lastline then
				local leftx, rightx = findintersectX(shape, body, line*32, -1)
				cutpointsbelow(coords, line*32, leftx, rightx)
			end
			
			linearea[line] = linearea[line] + polygonarea(coords)
		end
	end
end

function findintersectX(shape, body, y, direction) --like getintersectX, but moves the line up to 32 pixels in direction until it hits the shape
	local leftx, rightx
	local offset = 0
	repeat
		leftx, rightx = getintersectX(shape, y + offset*direction, body)
		offset = offset + 1
	until leftx ~= -1 or offset >= 32
	return leftx, rightx
end

function cutpointsabove(coords, y, leftx, rightx) --removes the polygon's points above y, closing it along y between leftx and rightx
	local coi=2
	local lastcutoff = nil
	while coi <= #coords do
		if coords[coi] <= y then
			table.remove(coords, coi)
			table.remove(coords, coi-1)
			lastcutoff = coi
			coi=0
		end
		coi=coi+2
	end
	
	if lastcutoff then
		table.insert(coords, lastcutoff-1,rightx)
		table.insert(coords, lastcutoff,y)
		
		table.insert(coords, lastcutoff-1,leftx)
		table.insert(coords, lastcutoff,y)
	end
end

function cutpointsbelow(coords, y, leftx, rightx) --removes the polygon's points below y, closing it along y between leftx and rightx
	local coi=2
	local lastcutoff = nil
	while coi <= #coords do
		if coords[coi] >= y then
			table.remove(coords, coi)
			table.remove(coords, coi-1)
			lastcutoff = coi
			coi=0
		end
		coi=coi+2
	end
	
	if lastcutoff then
		table.insert(coords, lastcutoff-1,leftx)
		table.insert(coords, lastcutoff,y)
		
		table.insert(coords, lastcutoff-1,rightx)
		table.insert(coords, lastcutoff,y)
	end
end

function clearfulllines() --scores and removes every line that is full enough. returns whether any were
	local numberoflines = 0
	linesremoved = {}
	
	for i = 1, 18 do
		if linearea[i] > 1024*linecleartreshold then
			if numberoflines == 0 then
				cuttingtimer = 0
				snapshotpieces()
			end
			
			linesremoved[i] = true
			numberoflines = numberoflines + 1
			linesscore = linesscore + 1
		end
	end
	
	if numberoflines == 0 then
		love.audio.stop(blockfall)
		love.audio.play(blockfall)
		return false
	end
	
	if numberoflines >= 4 then
		love.audio.stop(fourlineclear)
		love.audio.play(fourlineclear)
	else
		love.audio.stop(lineclear)
		love.audio.play(lineclear)
	end
	
	scorelines(numberoflines)
	
	--Draw the screen before removing lines.
	love.graphics.clear()
	drawscreen()
	love.graphics.present( )
	
	for i = 1, 18 do
		if linesremoved[i] then
			removeline(i)
		end
	end
	return true
end

function snapshotpieces() --saves position, angle, kind and image of each piece so they can be drawn unchanged while the cleared lines blink
	tetricutpos = {}
	tetricutang = {}
	tetricutkind = {}
	tetricutimg = {}
	
	for i, piece in pairs(tetris) do
		if piece then
			table.insert(tetricutpos, piece.body:getX())
			table.insert(tetricutpos, piece.body:getY())
			table.insert(tetricutang, piece.body:getAngle())
			table.insert(tetricutkind, piece.kind)
			table.insert(tetricutimg, love.graphics.newImage(piece.imagedata))
		end
	end
end

function scorelines(numberoflines) --score depends on the number of lines and how full they were; also advances the level
	local averagearea = 0
	for i = 1, 18 do
		if linesremoved[i] then
			averagearea = averagearea + linearea[i]
		end
	end
	averagearea = averagearea / numberoflines / 10240
	
	local scoreadd = math.ceil((numberoflines*3)^(averagearea^10)*20+numberoflines^2*40)
	scorescore = scorescore + scoreadd
	
	lastscoreadd = scoreadd
	scoreaddtimer = 0
	
	linescleared = linescleared + numberoflines
	
	if math.floor(linescleared/10) > levelscore then
		levelscore = levelscore + 1
		difficulty_speed = 100 + levelscore*7
		newlevelbeep = true
	end
end

function polygonarea(coords) --calculates the area of a polygon
	--Also written by Adam (see below)
	local anchorX = coords[1]
	local anchorY = coords[2]

	local firstX = coords[3]
	local firstY = coords[4]

	local area = 0

	for i = 5, #coords - 1, 2 do
		local x = coords[i]
		local y = coords[i + 1]

		area = area + (math.abs(anchorX * firstY + firstX * y + x * anchorY
				- anchorX * y - firstX * anchorY - x * firstY) / 2)

		firstX = x
		firstY = y

	end
	return area
end

function largeenough(coords) --checks if a polygon is good enough for box2d's snobby standards.
	--Written by Adam/earthHunter

	-- Calculation of centroids of each triangle

	local centroids = {}

	local anchorX = coords[1]
	local anchorY = coords[2]

	local firstX = coords[3]
	local firstY = coords[4]

	for i = 5, #coords - 1, 2 do

		local x = coords[i]
		local y = coords[i + 1]

		local centroidX = (anchorX + firstX + x) / 3
		local centroidY = (anchorY + firstY + y) / 3

		local area = math.abs(anchorX * firstY + firstX * y + x * anchorY
				- anchorX * y - firstX * anchorY - x * firstY) / 2

		local index = 3 * (i - 3) / 2 - 2

		centroids[index] = area
		centroids[index + 1] = centroidX * area
		centroids[index + 2] = centroidY * area

		firstX = x
		firstY = y

	end

	-- Calculation of polygon's centroid

	local totalArea = 0
	local centroidX = 0
	local centroidY = 0

	for i = 1, #centroids - 2, 3 do

		totalArea = totalArea + centroids[i]
		centroidX = centroidX + centroids[i + 1]
		centroidY = centroidY + centroids[i + 2]

	end

	centroidX = centroidX / totalArea
	centroidY = centroidY / totalArea

	-- Calculation of normals

	local normals = {}

	for i = 1, #coords - 1, 2 do

		local i2 = i + 2

		if (i2 > #coords) then

			i2 = 1

		end

		local tangentX = coords[i2] - coords[i]
		local tangentY = coords[i2 + 1] - coords[i + 1]
		local tangentLen = math.sqrt(tangentX * tangentX + tangentY * tangentY)

		tangentX = tangentX / tangentLen
		tangentY = tangentY / tangentLen

		normals[i] = tangentY
		normals[i + 1] = -tangentX

	end

	-- Projection of vertices in the normal directions
	-- in order to obtain the distance from the centroid
	-- to each side

	-- If a side is too close, the polygon will crash the game

	for i = 1, #coords - 1, 2 do

		local projection = (coords[i] - centroidX) * normals[i]
				+ (coords[i + 1] - centroidY) * normals[i + 1]

		if (projection < 0.04*meter) then

			return false

		end

	end

	return true

end

function samepos(coords, y, x) --checks if any point in a table is identical to another point (THIS SEEMS FISHY, CHECK THIS OUT)
	for j = 1, #coords, 2 do
		if math.abs(coords[j+1]-y) + math.abs(coords[j]-x) == 0 then
			return true
		end
	end
	return false
end

function collideA(a, b, coll) --box2d callback. calls endblock.
	--Sometimes a is nil or something I have no idea why.
	if a == nil or b == nil then
		return
	end

	-- Get user data from fixtures
	local aData = a:getUserData()
	local bData = b:getUserData()

	if aData == nil or bData == nil then
		return
	end

	if aData[1] == 1 or bData[1] == 1 then
		if aData[1] ~= "left" and aData[1] ~= "right" and bData[1] ~= "left" and bData[1] ~= "right" then
			if gamestate == "gameA" then
				if tetris[1].body:getY() < losingY then
					gamestate = "failingA"
					if musicno < 4 then
						love.audio.stop(music[musicno])
					end
					love.audio.stop(gameover1)
					love.audio.play(gameover1)

					if wallfixtures[2] then
						wallfixtures[2]:destroy()
						wallfixtures[2] = nil
					end
				else
					--move the landed piece from 1 to the end of tetris
					local n = highestbody()+1
					tetris[n] = tetris[1]
					tetris[1] = nil
					tetris[n].body:setLinearDamping(0.5)
					for i, v in pairs(tetris[n].fixtures) do
						v:setUserData({n})
					end

					endblock = true
				end
			end
		end
	end
end

function endblockA() --handles failing, moving the current block to the end of the tables and calls checklinedensity in active mode
	if checklinedensity(true) then
		game_addTetriA()
	else
		game_addTetriA()
		--RANDOMIZE NEXT PIECE
		nextpiece = math.random(7)
	end
end

registerscreen({"gameA", "failingA"}, {update = gameA_update, draw = gameA_draw, keypressed = singleplayer_keypressed})
