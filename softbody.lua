--Soft body pieces (the softbody option): each block of a piece is its own body, welded to its
--neighbours by springy joints, so pieces bend and wobble. A falling soft piece is a group
--{kind, soft = true, blocks = {...}, fixtures = {...}} whose blocks are ordinary one-block pieces
--{kind, body, shapes, fixtures, image, imagedata, center}. Once a soft piece lands its blocks are
--stored one by one, so measuring and cutting lines treats them like any other piece; a cut block
--gets a new body and with it loses the joints to its neighbours.

SOFTFREQUENCY = 4 --how stiff the joints between blocks are, in Hz; lower is wobblier
SOFTDAMPING = 0.3 --how quickly the wobbling dies down (0 to 1)
SOFTBLOCKSIZE = 10 --size of each block's cut-out of the piece sprite in game pixels: the 8px block plus its 1px outline

softgroupcounter = 0

function newsoftpiece(world, kind, x, y, density) --creates the bodies and joints of a soft piece; callers add its images with softpieceimages
	softgroupcounter = softgroupcounter % 32000 + 1
	local group = {kind = kind, soft = true, blocks = {}, fixtures = {}, joints = {}}
	for i, offset in ipairs(pieceblocks[kind]) do
		local block = {kind = kind, shapes = {}, fixtures = {}, offset = offset}
		block.body = love.physics.newBody(world, x + offset[1], y + offset[2], "dynamic")
		block.shapes[1] = love.physics.newRectangleShape(32, 32)
		block.fixtures[1] = newfixture(block.body, block.shapes[1], density)
		block.fixtures[1]:setGroupIndex(-softgroupcounter) --blocks of the same piece never collide with each other
		block.body:setLinearDamping(0.5)
		block.body:setBullet(true)
		group.blocks[i] = block
		group.fixtures[i] = block.fixtures[1]
	end

	--weld blocks that share an edge, at the middle of that edge
	for i = 1, #group.blocks do
		for j = i + 1, #group.blocks do
			local a, b = group.blocks[i], group.blocks[j]
			local dx, dy = b.offset[1] - a.offset[1], b.offset[2] - a.offset[2]
			if math.abs(dx) + math.abs(dy) == 32 then
				local joint = love.physics.newWeldJoint(a.body, b.body, x + a.offset[1] + dx/2, y + a.offset[2] + dy/2, false)
				joint:setFrequency(SOFTFREQUENCY)
				joint:setDampingRatio(SOFTDAMPING)
				table.insert(group.joints, joint)
			end
		end
	end
	return group
end

function softpieceimages(group, imagedata, s) --cuts each block's part out of the piece sprite (imagedata at scale s)
	local size = SOFTBLOCKSIZE*s
	for i, block in ipairs(group.blocks) do
		local centerx = (piececenter[group.kind][1] + block.offset[1]/4)*s
		local centery = (piececenter[group.kind][2] + block.offset[2]/4)*s
		block.imagedata = love.image.newImageData(size, size)
		block.imagedata:paste(imagedata, 0, 0, centerx - size/2, centery - size/2, size, size)
		block.image = love.graphics.newImage(block.imagedata)
		block.center = {SOFTBLOCKSIZE/2, SOFTBLOCKSIZE/2}
	end
end

function pieceparts(piece) --the separately simulated parts of a piece: its blocks if soft, else just itself
	return piece.blocks or {piece}
end

function piecey(piece) --height of a piece's centre
	local parts = pieceparts(piece)
	local y = 0
	for i, part in ipairs(parts) do
		y = y + part.body:getY()
	end
	return y / #parts
end

function setpiecevelocity(piece, vx, vy)
	for i, part in ipairs(pieceparts(piece)) do
		part.body:setLinearVelocity(vx, vy)
	end
end

function steersoftpiece(group, dt, player, maxfallspeed) --steerpiece for soft pieces: the same total force and torque, spread over the blocks
	local n = #group.blocks
	local cx, cy, cvx, cvy = 0, 0, 0, 0
	for i, block in ipairs(group.blocks) do
		local x, y = block.body:getWorldCenter()
		local vx, vy = block.body:getLinearVelocity()
		cx, cy, cvx, cvy = cx + x/n, cy + y/n, cvx + vx/n, cvy + vy/n
	end

	--how fast the piece as a whole turns, from the blocks' motion around its centre
	local spin, radii = 0, 0
	for i, block in ipairs(group.blocks) do
		local x, y = block.body:getWorldCenter()
		local vx, vy = block.body:getLinearVelocity()
		local rx, ry = x - cx, y - cy
		spin = spin + rx*(vy - cvy) - ry*(vx - cvx)
		radii = radii + rx*rx + ry*ry
	end
	local angularvelocity = radii > 0 and spin/radii or 0

	--turning: push each block sideways around the centre, so the pushes add up to the rigid piece's torque
	local torque = 0
	if controls.isDown("rotateright"..player) and angularvelocity < 3 then
		torque = torque + 70*TORQUESCALE
	end
	if controls.isDown("rotateleft"..player) and angularvelocity > -3 then
		torque = torque - 70*TORQUESCALE
	end
	if torque ~= 0 and radii > 0 then
		for i, block in ipairs(group.blocks) do
			local x, y = block.body:getWorldCenter()
			local rx, ry = x - cx, y - cy
			block.body:applyForce(-ry*torque/radii, rx*torque/radii, x, y)
		end
	end

	local push = 0
	if controls.isDown("left"..player) then
		push = push - 70*FORCESCALE
	end
	if controls.isDown("right"..player) then
		push = push + 70*FORCESCALE
	end

	for i, block in ipairs(group.blocks) do
		local x, y = block.body:getWorldCenter()
		if push ~= 0 then
			block.body:applyForce(push/n, 0, x, y)
		end
		local vx, vy = block.body:getLinearVelocity()
		if controls.isDown("down"..player) then
			if vy > maxfallspeed then
				block.body:setLinearVelocity(vx, maxfallspeed)
			else
				block.body:applyForce(0, 20*FORCESCALE/n, x, y)
			end
		elseif vy > difficulty_speed then
			block.body:setLinearVelocity(vx, vy-2000*dt)
		end
	end
end
