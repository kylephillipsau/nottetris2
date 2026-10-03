--Soft body physics for the Softbody option. A soft piece is one rubbery body: a lattice of particles
--(SOFTCELLS cells along each block edge) held in shape by compliant constraints on the cells' edges,
--diagonals and areas. It is simulated with XPBD (extended position based dynamics) in small substeps,
--which stays stable however hard pieces hit, so they bend, squash and wobble as a whole instead of
--hinging between blocks. Bodies collide particle against edge, with friction, and walls are static
--bodies of the same kind. Bodies that come to rest fall asleep and cost nothing until something hits
--them. Clearing a line cuts the lattice along the line (SoftWorld:cut).
--
--Units are the game's: pixels at physics scale, and masses as Box2D gives them (density per square
--meter), so the forces steerpiece applies move soft pieces like rigid ones. A SoftBody has the few
--Box2D body methods the game uses (getX, getLinearVelocity, applyForce, ...), so it can stand in for one.

SOFTCELLS = 2 --lattice cells along each block edge; more bend more smoothly but cost more (at most 3, see SOFTMAXPARTICLES)
SOFTSUBSTEPS = 5 --solver substeps per step
SOFTSTIFFNESS = 1500 --how hard the rubber resists stretching, per unit of density; lower is floppier
SOFTBULK = 4 --how much harder it resists being squashed than stretched
SOFTVISCOSITY = 0.01 --how much the rubber resists changing shape quickly (seconds): absorbs impacts and stops fast jiggling
SOFTWOBBLE = 0.05 --share of the wobble (motion other than moving and turning as a whole) damped each step
SOFTFRICTION = 0.5 --like the rigid pieces
SOFTSLEEPSPEED = 5 --a body slower than this everywhere (pixels per second) for SOFTSLEEPTIME falls asleep
SOFTSLEEPTIME = 0.5
SOFTWAKESPEED = 20 --a sleeping body wakes when something moves into it faster than this, or overlaps it by more than SOFTWAKEDEPTH
SOFTWAKEDEPTH = 1
SOFTMAXSEPARATION = 60 --bodies that overlap (say a piece made inside another) are pushed apart at most this fast (pixels per second)
SOFTTOUCH = 0.5 --bodies closer than this touch, for the contact callback
SOFTEDGETOL = 1 --a particle that slides this far past the end of the edge it was paired with is let go
SOFTCUTSNAP = 0.1 --a cut this close to a particle (as a share of the edge) goes through the particle instead of making a new one
SOFTMINAREA = 24 --cut off bits smaller than this (square pixels) disappear
SOFTFREEZEY = 1200 --bodies that fall below this are frozen
SOFTMAXPARTICLES = 64 --the most particles a body can have (the drawing shader's limit)

local sqrt, huge = math.sqrt, math.huge
local METER2 = love.physics.getMeter()^2 --Box2D masses are per square meter

local SoftWorld = {}
SoftWorld.__index = SoftWorld
local SoftBody = {}
SoftBody.__index = SoftBody

function newsoftworld(gravity)
	return setmetatable({gravity = gravity, bodies = {}, nextid = 0, touching = {}, callback = nil,
		--contact candidates of the current step as parallel arrays: particle ci of body cp against
		--the edge from particle ca to cb of body ce, with friction cf, for the pair with key ck
		nc = 0, cp = {}, ci = {}, ce = {}, ca = {}, cb = {}, cf = {}, ck = {}}, SoftWorld)
end

local function newbody(world, kind, density)
	world.nextid = world.nextid + 1
	return setmetatable({world = world, id = world.nextid, kind = kind, density = density or 0,
		n = 0, x = {}, y = {}, vx = {}, vy = {}, ox = {}, oy = {}, m = {}, w = {}, rx = {}, ry = {}, --particles: position, velocity, position before the substep, mass, inverse mass, rest position
		ne = 0, e1 = {}, e2 = {}, e3 = {}, e4 = {}, earea = {}, ealpha = {}, --elements: quads (e4 > 0) or triangles, with rest area and compliance
		nd = 0, da = {}, db = {}, dl = {}, --distance constraints: particles and rest length
		nbe = 0, ba = {}, bb = {}, nbp = 0, bp = {}, --boundary edges (outside on their left, seen from above) and boundary particles
		mass = 0, awake = true, sleeptime = 0, static = false,
		fx = 0, fy = 0, torque = 0, friction = SOFTFRICTION, category = 1, mask = {}, data = nil,
		minx = 0, miny = 0, maxx = 0, maxy = 0}, SoftBody)
end

local function addparticle(body, x, y, rx, ry, vx, vy)
	local i = body.n + 1
	body.n = i
	body.x[i], body.y[i], body.ox[i], body.oy[i] = x, y, x, y
	body.vx[i], body.vy[i] = vx or 0, vy or 0
	body.rx[i], body.ry[i] = rx, ry
	return i
end

local function addelement(body, a, b, c, d) --d is 0 for triangles. corners go clockwise on screen
	local k = body.ne + 1
	body.ne = k
	body.e1[k], body.e2[k], body.e3[k], body.e4[k] = a, b, c, d
end

local function elementcorners(body, k)
	local d = body.e4[k]
	if d > 0 then
		return {body.e1[k], body.e2[k], body.e3[k], d}
	end
	return {body.e1[k], body.e2[k], body.e3[k]}
end

local function restarea(body, corners) --area of a polygon of particles in the rest shape, positive for clockwise
	local rx, ry = body.rx, body.ry
	local area = 0
	for j = 1, #corners do
		local a, b = corners[j], corners[j % #corners + 1]
		area = area + rx[a]*ry[b] - rx[b]*ry[a]
	end
	return area/2
end

local function pairkey(a, b)
	if a.id < b.id then
		return a.id*1048576 + b.id
	end
	return b.id*1048576 + a.id
end

--masses, constraints and boundary of a body, from its particles and elements
local function finalize(body)
	local m, w = body.m, body.w
	for i = 1, body.n do
		m[i] = 0
	end
	local stiffness = SOFTSTIFFNESS*body.density
	body.alpha = stiffness > 0 and 1/stiffness or 0
	local rx, ry = body.rx, body.ry
	local edges, directed = {}, {}
	local nd = 0
	local function constrain(a, b)
		local key = a < b and a*65536 + b or b*65536 + a
		if not edges[key] then
			edges[key] = true
			nd = nd + 1
			body.da[nd], body.db[nd] = a, b
			local dx, dy = rx[a] - rx[b], ry[a] - ry[b]
			body.dl[nd] = sqrt(dx*dx + dy*dy)
		end
	end
	local total = 0
	for k = 1, body.ne do
		local corners = elementcorners(body, k)
		local area = restarea(body, corners)
		body.earea[k] = area
		body.ealpha[k] = stiffness > 0 and area/(stiffness*SOFTBULK) or 0
		total = total + area
		for j = 1, #corners do
			local a, b = corners[j], corners[j % #corners + 1]
			constrain(a, b)
			directed[a*65536 + b] = true
			m[a] = m[a] + area*body.density/METER2/#corners
		end
		if #corners == 4 then --diagonals keep quads from shearing flat
			constrain(corners[1], corners[3])
			constrain(corners[2], corners[4])
		end
	end
	body.nd = nd
	body.area = total
	body.mass = 0
	for i = 1, body.n do
		w[i] = m[i] > 0 and 1/m[i] or 0
		body.mass = body.mass + m[i]
	end

	--an element edge is on the boundary if no other element has it (the other way round)
	local nbe, nbp, onboundary = 0, 0, {}
	for k = 1, body.ne do
		local corners = elementcorners(body, k)
		for j = 1, #corners do
			local a, b = corners[j], corners[j % #corners + 1]
			if not directed[b*65536 + a] then
				nbe = nbe + 1
				body.ba[nbe], body.bb[nbe] = a, b
				for _, p in ipairs({a, b}) do
					if not onboundary[p] then
						onboundary[p] = true
						nbp = nbp + 1
						body.bp[nbp] = p
					end
				end
			end
		end
	end
	body.nbe, body.nbp = nbe, nbp
	body:updatebounds()
end

function SoftBody:updatebounds()
	local x, y, bp = self.x, self.y, self.bp
	local minx, miny, maxx, maxy = huge, huge, -huge, -huge
	for k = 1, self.nbp do
		local i = bp[k]
		local px, py = x[i], y[i]
		if px < minx then minx = px end
		if px > maxx then maxx = px end
		if py < miny then miny = py end
		if py > maxy then maxy = py end
	end
	self.minx, self.miny, self.maxx, self.maxy = minx, miny, maxx, maxy
end

--a soft tetromino of kind with its centre at x, y, from the same blocks as the rigid pieces
function SoftWorld:newpiece(kind, x, y, density)
	local body = newbody(self, kind, density)
	local cell = 32/SOFTCELLS
	local particles = {}
	local function particle(gx, gy) --the particle at a lattice point, shared by the cells around it
		local key = (gx + 100)*1000 + gy + 100
		if not particles[key] then
			particles[key] = addparticle(body, x + gx*cell, y + gy*cell, gx*cell, gy*cell)
		end
		return particles[key]
	end
	for _, block in ipairs(pieceblocks[kind]) do
		local gx0, gy0 = (block[1] - 16)/32*SOFTCELLS, (block[2] - 16)/32*SOFTCELLS
		for j = 0, SOFTCELLS - 1 do
			for i = 0, SOFTCELLS - 1 do
				local gx, gy = gx0 + i, gy0 + j
				addelement(body, particle(gx, gy), particle(gx + 1, gy), particle(gx + 1, gy + 1), particle(gx, gy + 1))
			end
		end
	end
	finalize(body)
	table.insert(self.bodies, body)
	return body
end

--a static box, the soft version of a wall
function SoftWorld:newwall(x1, y1, x2, y2, data, friction, category)
	local body = newbody(self)
	body.static, body.awake = true, false
	body.data, body.friction, body.category = data, friction or SOFTFRICTION, category or 1
	addelement(body, addparticle(body, x1, y1, x1, y1), addparticle(body, x2, y1, x2, y1),
		addparticle(body, x2, y2, x2, y2), addparticle(body, x1, y2, x1, y2))
	finalize(body)
	table.insert(self.bodies, body)
	return body
end

function SoftWorld:remove(body)
	for k, other in ipairs(self.bodies) do
		if other == body then
			table.remove(self.bodies, k)
			break
		end
	end
	if body.static then --whatever rested on a wall has to notice it's gone
		self:wakeall()
	end
end

function SoftWorld:wakeall()
	for _, body in ipairs(self.bodies) do
		if not body.static then
			body:wake()
		end
	end
end

---------------------------------------------------------------------------------------------------
--the body as a whole, Box2D style: its centre of mass, and the velocity of its centre and of its turning

function SoftBody:getWorldCenter()
	local x, y, m = self.x, self.y, self.m
	local cx, cy = 0, 0
	for i = 1, self.n do
		cx, cy = cx + m[i]*x[i], cy + m[i]*y[i]
	end
	return cx/self.mass, cy/self.mass
end

function SoftBody:getX()
	return (self:getWorldCenter())
end

function SoftBody:getY()
	return select(2, self:getWorldCenter())
end

function SoftBody:getLinearVelocity()
	local vx, vy, m = self.vx, self.vy, self.m
	local cvx, cvy = 0, 0
	for i = 1, self.n do
		cvx, cvy = cvx + m[i]*vx[i], cvy + m[i]*vy[i]
	end
	return cvx/self.mass, cvy/self.mass
end

function SoftBody:setLinearVelocity(vx, vy) --changes how fast the body moves as a whole, keeping its wobble
	local cvx, cvy = self:getLinearVelocity()
	local dvx, dvy = vx - cvx, vy - cvy
	for i = 1, self.n do
		self.vx[i], self.vy[i] = self.vx[i] + dvx, self.vy[i] + dvy
	end
	self:wake()
end

function SoftBody:getAngularVelocity()
	local x, y, vx, vy, m = self.x, self.y, self.vx, self.vy, self.m
	local cx, cy = self:getWorldCenter()
	local spin, inertia = 0, 0
	for i = 1, self.n do
		local rx, ry = x[i] - cx, y[i] - cy
		spin = spin + m[i]*(rx*vy[i] - ry*vx[i])
		inertia = inertia + m[i]*(rx*rx + ry*ry)
	end
	return inertia > 0 and spin/inertia or 0
end

function SoftBody:applyForce(fx, fy) --spread over the body by mass, so it accelerates as a whole
	self.fx, self.fy = self.fx + fx, self.fy + fy
	self:wake()
end

function SoftBody:applyTorque(torque) --turns the body as a whole
	self.torque = self.torque + torque
	self:wake()
end

function SoftBody:getUserData()
	return self.data
end

function SoftBody:setUserData(data)
	self.data = data
end

function SoftBody:wake()
	if not self.awake and not self.static then
		self.awake = true
		self.sleeptime = 0
		self.lineareas = nil
	end
end

function SoftBody:sleep()
	self.awake = false
	for i = 1, self.n do
		self.vx[i], self.vy[i] = 0, 0
		self.ox[i], self.oy[i] = self.x[i], self.y[i]
	end
end

function SoftBody:setMask(...) --categories this body doesn't collide with
	self.mask = {}
	for _, category in ipairs({...}) do
		self.mask[category] = true
	end
end

local function collides(a, b)
	return not a.mask[b.category] and not b.mask[a.category]
end

---------------------------------------------------------------------------------------------------
--stepping

--centre of mass, how the body moves as a whole and its fastest particle, for forces, damping, sleep and contact margins
function SoftBody:measure()
	local n, x, y, vx, vy, m = self.n, self.x, self.y, self.vx, self.vy, self.m
	local cx, cy, cvx, cvy = 0, 0, 0, 0
	for i = 1, n do
		local mi = m[i]
		cx, cy, cvx, cvy = cx + mi*x[i], cy + mi*y[i], cvx + mi*vx[i], cvy + mi*vy[i]
	end
	local mass = self.mass
	cx, cy, cvx, cvy = cx/mass, cy/mass, cvx/mass, cvy/mass
	local spin, inertia, fastest = 0, 0, 0
	for i = 1, n do
		local rx, ry = x[i] - cx, y[i] - cy
		spin = spin + m[i]*(rx*vy[i] - ry*vx[i])
		inertia = inertia + m[i]*(rx*rx + ry*ry)
		local speed = vx[i]*vx[i] + vy[i]*vy[i]
		if speed > fastest then fastest = speed end
	end
	self.cx, self.cy, self.cvx, self.cvy = cx, cy, cvx, cvy
	self.inertia = inertia
	self.spin = inertia > 0 and spin/inertia or 0
	self.fastest = sqrt(fastest)
end

function SoftBody:integrate(h, gravity) --moves the particles by their velocities after forces and gravity
	local n, x, y, vx, vy, ox, oy = self.n, self.x, self.y, self.vx, self.vy, self.ox, self.oy
	local ax, ay = self.fx/self.mass, gravity + self.fy/self.mass
	local turn = self.inertia > 0 and self.torque/self.inertia or 0
	local cx, cy = self.cx, self.cy
	for i = 1, n do
		local px, py = x[i], y[i]
		local nvx = vx[i] + h*(ax - turn*(py - cy))
		local nvy = vy[i] + h*(ay + turn*(px - cx))
		vx[i], vy[i] = nvx, nvy
		ox[i], oy[i] = px, py
		x[i], y[i] = px + h*nvx, py + h*nvy
	end
end

function SoftBody:solve(invh, invh2) --one XPBD pass over the shape constraints
	local x, y, ox, oy, w = self.x, self.y, self.ox, self.oy, self.w
	local da, db, dl = self.da, self.db, self.dl
	local scale, damping = self.dscale, self.ddamping
	if self.dscaleh ~= invh then --what each constraint's correction is scaled by, which only changes with the substep length
		scale, damping = {}, {}
		local compliance = self.alpha*invh2
		local viscosity = SOFTVISCOSITY*invh --XPBD damping proportional to stiffness: gamma = alpha*(SOFTVISCOSITY/alpha)/h
		for k = 1, self.nd do
			local wsum = w[da[k]] + w[db[k]]
			scale[k] = 1/(wsum + compliance)
			--XPBD also adds gamma*wsum to the divisor, which with one pass per substep makes the rubber softer
			--under a steady load too. leaving it out keeps the stiffness; capping gamma keeps it stable
			damping[k] = math.min(viscosity, 0.5*(wsum + compliance)/wsum)
		end
		self.dscale, self.ddamping, self.dscaleh = scale, damping, invh
	end
	for k = 1, self.nd do
		local a, b = da[k], db[k]
		local xa, ya, xb, yb = x[a], y[a], x[b], y[b]
		local dx, dy = xa - xb, ya - yb
		local len = sqrt(dx*dx + dy*dy)
		if len > 1e-9 then
			dx, dy = dx/len, dy/len
			local stretching = dx*((xa - ox[a]) - (xb - ox[b])) + dy*((ya - oy[a]) - (yb - oy[b])) --this substep
			local s = (dl[k] - len - damping[k]*stretching)*scale[k]
			local sa, sb = w[a]*s, w[b]*s
			x[a], y[a] = xa + sa*dx, ya + sa*dy
			x[b], y[b] = xb - sb*dx, yb - sb*dy
		end
	end

	--areas: dA/dp of each corner is half the perpendicular of the edge between its neighbours
	local e1, e2, e3, e4, earea, ealpha = self.e1, self.e2, self.e3, self.e4, self.earea, self.ealpha
	for k = 1, self.ne do
		local a, b, c, d = e1[k], e2[k], e3[k], e4[k]
		local xa, ya, xb, yb, xc, yc = x[a], y[a], x[b], y[b], x[c], y[c]
		if d > 0 then
			local xd, yd = x[d], y[d]
			local area = ((xa*yb - xb*ya) + (xb*yc - xc*yb) + (xc*yd - xd*yc) + (xd*ya - xa*yd))/2
			local gax, gay = (yb - yd)/2, (xd - xb)/2
			local gbx, gby = (yc - ya)/2, (xa - xc)/2
			local gcx, gcy = (yd - yb)/2, (xb - xd)/2
			local gdx, gdy = (ya - yc)/2, (xc - xa)/2
			local wa, wb, wc, wd = w[a], w[b], w[c], w[d]
			local sum = wa*(gax*gax + gay*gay) + wb*(gbx*gbx + gby*gby) + wc*(gcx*gcx + gcy*gcy) + wd*(gdx*gdx + gdy*gdy)
			local s = (earea[k] - area)/(sum + ealpha[k]*invh2)
			x[a], y[a] = xa + wa*s*gax, ya + wa*s*gay
			x[b], y[b] = xb + wb*s*gbx, yb + wb*s*gby
			x[c], y[c] = xc + wc*s*gcx, yc + wc*s*gcy
			x[d], y[d] = xd + wd*s*gdx, yd + wd*s*gdy
		else
			local area = ((xb - xa)*(yc - ya) - (xc - xa)*(yb - ya))/2
			local gax, gay = (yb - yc)/2, (xc - xb)/2
			local gbx, gby = (yc - ya)/2, (xa - xc)/2
			local gcx, gcy = (ya - yb)/2, (xb - xa)/2
			local wa, wb, wc = w[a], w[b], w[c]
			local sum = wa*(gax*gax + gay*gay) + wb*(gbx*gbx + gby*gby) + wc*(gcx*gcx + gcy*gcy)
			local s = (earea[k] - area)/(sum + ealpha[k]*invh2)
			x[a], y[a] = xa + wa*s*gax, ya + wa*s*gay
			x[b], y[b] = xb + wb*s*gbx, yb + wb*s*gby
			x[c], y[c] = xc + wc*s*gcx, yc + wc*s*gcy
		end
	end
end

function SoftBody:finishstep(dt) --velocities from the substeps' motion are damped, then the body may fall asleep
	self:measure()
	local n, x, y, vx, vy = self.n, self.x, self.y, self.vx, self.vy
	local cx, cy, cvx, cvy, spin = self.cx, self.cy, self.cvx, self.cvy, self.spin
	local wobble = SOFTWOBBLE
	local drag = 1/(1 + dt*0.5) --the rigid pieces' linear damping
	for i = 1, n do
		local rigidvx, rigidvy = cvx - spin*(y[i] - cy), cvy + spin*(x[i] - cx)
		vx[i] = (vx[i] + wobble*(rigidvx - vx[i]))*drag
		vy[i] = (vy[i] + wobble*(rigidvy - vy[i]))*drag
	end
	self.fx, self.fy, self.torque = 0, 0, 0
	self.lineareas = nil
	self:updatebounds()

	if self.fastest < SOFTSLEEPSPEED then
		self.sleeptime = self.sleeptime + dt
		if self.sleeptime >= SOFTSLEEPTIME then
			self:sleep()
		end
	else
		self.sleeptime = 0
	end
	if self.miny > SOFTFREEZEY then --fell out of the game
		self:sleep()
	end
end

--contact candidates for P's boundary particles against E's boundary edges: each particle near or inside E
--is paired with E's closest edge. returns whether P moves into sleeping E hard enough to wake it
function SoftWorld:findcontacts(P, E, margin, friction, key)
	local minx, miny, maxx, maxy = E.minx - margin, E.miny - margin, E.maxx + margin, E.maxy + margin
	local px, py, pvx, pvy, bp = P.x, P.y, P.vx, P.vy, P.bp
	local ex, ey, ba, bb, nbe = E.x, E.y, E.ba, E.bb, E.nbe
	local margin2 = margin*margin
	local wake = false
	local nc = self.nc
	local cp, ci, ce, ca, cb, cf, ck = self.cp, self.ci, self.ce, self.ca, self.cb, self.cf, self.ck
	for k = 1, P.nbp do
		local i = bp[k]
		local x, y = px[i], py[i]
		if x > minx and x < maxx and y > miny and y < maxy then
			local inside, best, bestd2 = false, 0, huge
			for e = 1, nbe do
				local a, b = ba[e], bb[e]
				local ax, ay, bx, by = ex[a], ey[a], ex[b], ey[b]
				if (ay > y) ~= (by > y) and x < ax + (y - ay)*(bx - ax)/(by - ay) then
					inside = not inside
				end
				local dx, dy = bx - ax, by - ay
				local t = ((x - ax)*dx + (y - ay)*dy)/(dx*dx + dy*dy)
				if t < 0 then t = 0 elseif t > 1 then t = 1 end
				local qx, qy = ax + t*dx - x, ay + t*dy - y
				local d2 = qx*qx + qy*qy
				if d2 < bestd2 then
					best, bestd2 = e, d2
				end
			end
			if inside or bestd2 < margin2 then
				nc = nc + 1
				cp[nc], ci[nc], ce[nc], ca[nc], cb[nc], cf[nc], ck[nc] = P, i, E, ba[best], bb[best], friction, key
				if P.awake and not E.awake and not E.static and not wake then
					local a, b = ba[best], bb[best]
					local dx, dy = ex[b] - ex[a], ey[b] - ey[a]
					local approach = (pvy[i]*dx - pvx[i]*dy)/sqrt(dx*dx + dy*dy) --speed into the edge
					wake = approach > SOFTWAKESPEED or (inside and bestd2 > SOFTWAKEDEPTH*SOFTWAKEDEPTH)
				end
			end
		end
	end
	self.nc = nc
	return wake
end

function SoftWorld:solvecontacts(touched, h)
	local cp, ci, ce, ca, cb, cf, ck = self.cp, self.ci, self.ce, self.ca, self.cb, self.cf, self.ck
	local separation = SOFTMAXSEPARATION*h
	for c = 1, self.nc do
		local P, E, i, a, b = cp[c], ce[c], ci[c], ca[c], cb[c]
		local Px, Py, Ex, Ey = P.x, P.y, E.x, E.y
		local px, py, ax, ay, bx, by = Px[i], Py[i], Ex[a], Ey[a], Ex[b], Ey[b]
		local ex, ey = bx - ax, by - ay
		local len = sqrt(ex*ex + ey*ey)
		if len > 1e-9 then
			local t = ((px - ax)*ex + (py - ay)*ey)/(len*len)
			local tolerance = SOFTEDGETOL/len
			if t > -tolerance and t < 1 + tolerance then
				if t < 0 then t = 0 elseif t > 1 then t = 1 end
				local nx, ny = ey/len, -ex/len --out of E
				local depth = -((px - ax)*nx + (py - ay)*ny)
				if depth > -SOFTTOUCH then
					touched[ck[c]] = true
				end
				if depth > 0 then
					local wp = P.awake and P.w[i] or 0
					local wa, wb = 0, 0
					if E.awake then
						wa, wb = E.w[a]*(1 - t), E.w[b]*t
					end
					local sum = wp + wa*(1 - t) + wb*t
					if sum > 0 then
						--what moved in during this substep is pushed straight back out, but overlap that was
						--already there (a piece created inside another) only comes out at SOFTMAXSEPARATION
						local Pox, Poy, Eox, Eoy = P.ox, P.oy, E.ox, E.oy
						local qox, qoy = (1 - t)*Eox[a] + t*Eox[b], (1 - t)*Eoy[a] + t*Eoy[b]
						local before = -((Pox[i] - qox)*nx + (Poy[i] - qoy)*ny)
						if before > 0 then
							depth = depth - before + math.min(before, separation)
						end
						local s = depth/sum
						px, py = px + wp*s*nx, py + wp*s*ny
						ax, ay = ax - wa*s*nx, ay - wa*s*ny
						bx, by = bx - wb*s*nx, by - wb*s*ny

						--friction: undo the sliding along the edge during this substep, up to friction times the push
						local rx = (px - Pox[i]) - ((1 - t)*(ax - Eox[a]) + t*(bx - Eox[b]))
						local ry = (py - Poy[i]) - ((1 - t)*(ay - Eoy[a]) + t*(by - Eoy[b]))
						local rn = rx*nx + ry*ny
						local tx, ty = rx - rn*nx, ry - rn*ny
						local slide = sqrt(tx*tx + ty*ty)
						if slide > 1e-9 then
							local limit = cf[c]*depth
							local f = (slide < limit and 1 or limit/slide)/sum
							px, py = px - wp*f*tx, py - wp*f*ty
							ax, ay = ax + wa*f*tx, ay + wa*f*ty
							bx, by = bx + wb*f*tx, by + wb*f*ty
						end
						Px[i], Py[i] = px, py
						Ex[a], Ey[a], Ex[b], Ey[b] = ax, ay, bx, by
					end
				end
			end
		end
	end
end

function SoftWorld:update(dt)
	local bodies = self.bodies

	--bodies to simulate this step
	local awake = {}
	for _, body in ipairs(bodies) do
		if body.awake then
			body:measure()
			awake[#awake + 1] = body
		end
	end

	--contact candidates between awake bodies and anything near them; a sleeping body that gets hit wakes and joins in
	self.nc = 0
	local found = {} --pair key -> {a, b}
	local pairlist = {} --the keys in the order found
	local k = 1
	while k <= #awake do
		local A = awake[k]
		for _, B in ipairs(bodies) do
			if B ~= A then
				local margin = (A.fastest + (B.awake and B.fastest or 0))*dt + 1
				if A.minx - margin < B.maxx and B.minx - margin < A.maxx and A.miny - margin < B.maxy and B.miny - margin < A.maxy and collides(A, B) then
					local key = pairkey(A, B)
					if not found[key] then
						found[key] = {A, B}
						pairlist[#pairlist + 1] = key
						local friction = sqrt(A.friction*B.friction)
						local woke = self:findcontacts(A, B, margin, friction, key)
						self:findcontacts(B, A, margin, friction, key)
						if woke then
							B:wake()
							B:measure()
							awake[#awake + 1] = B
						end
					end
				end
			end
		end
		k = k + 1
	end

	local h = dt/SOFTSUBSTEPS
	local invh, invh2 = 1/h, 1/(h*h)
	local touched = {}
	for substep = 1, SOFTSUBSTEPS do
		for _, body in ipairs(awake) do
			body:integrate(h, self.gravity)
		end
		for _, body in ipairs(awake) do
			body:solve(invh, invh2)
		end
		self:solvecontacts(touched, h)
		for _, body in ipairs(awake) do
			local x, y, vx, vy, ox, oy = body.x, body.y, body.vx, body.vy, body.ox, body.oy
			for i = 1, body.n do
				vx[i], vy[i] = (x[i] - ox[i])*invh, (y[i] - oy[i])*invh
			end
		end
	end
	for _, body in ipairs(awake) do
		body:finishstep(dt)
	end

	--contact callbacks for pairs that started touching
	local touching = {}
	for _, key in ipairs(pairlist) do
		if touched[key] then
			touching[key] = true
			if not self.touching[key] and self.callback then
				self.callback(found[key][1], found[key][2])
			end
		end
	end
	self.touching = touching
end

---------------------------------------------------------------------------------------------------
--lines

local clipx, clipy, clipx2, clipy2, clipx3, clipy3 = {}, {}, {}, {}, {}, {}

local function clipaty(xs, ys, cnt, line, below, outx, outy) --keeps the part of a polygon below (or above) a line. returns its corner count
	local out = 0
	local px, py = xs[cnt], ys[cnt]
	local pin = (py >= line) == below
	for j = 1, cnt do
		local cx, cy = xs[j], ys[j]
		local cin = (cy >= line) == below
		if cin ~= pin then
			out = out + 1
			outx[out], outy[out] = px + (line - py)/(cy - py)*(cx - px), line
		end
		if cin then
			out = out + 1
			outx[out], outy[out] = cx, cy
		end
		px, py, pin = cx, cy, cin
	end
	return out
end

local function polygonarea(xs, ys, cnt)
	local area = 0
	for j = 1, cnt do
		local k = j % cnt + 1
		area = area + xs[j]*ys[k] - xs[k]*ys[j]
	end
	return math.abs(area)/2
end

--adds the body's area in each line (rows of height pixels from y = 0) to areas. sleeping bodies keep their result
function SoftBody:addlineareas(areas, lines, height)
	if not self.lineareas then
		local result = {}
		local x, y = self.x, self.y
		local e1, e2, e3, e4 = self.e1, self.e2, self.e3, self.e4
		for k = 1, self.ne do
			local cnt = e4[k] > 0 and 4 or 3
			clipx[1], clipy[1], clipx[2], clipy[2], clipx[3], clipy[3] = x[e1[k]], y[e1[k]], x[e2[k]], y[e2[k]], x[e3[k]], y[e3[k]]
			if cnt == 4 then
				clipx[4], clipy[4] = x[e4[k]], y[e4[k]]
			end
			local top, bottom = huge, -huge
			for j = 1, cnt do
				top, bottom = math.min(top, clipy[j]), math.max(bottom, clipy[j])
			end
			local first, last = math.floor(top/height) + 1, math.floor(bottom/height) + 1
			if first == last then
				if first >= 1 and first <= lines then
					result[first] = (result[first] or 0) + polygonarea(clipx, clipy, cnt)
				end
			else
				for line = math.max(first, 1), math.min(last, lines) do
					local c = clipaty(clipx, clipy, cnt, (line - 1)*height, true, clipx2, clipy2)
					c = clipaty(clipx2, clipy2, c, line*height, false, clipx3, clipy3)
					if c >= 3 then
						result[line] = (result[line] or 0) + polygonarea(clipx3, clipy3, c)
					end
				end
			end
		end
		self.lineareas = result
	end
	for line, area in pairs(self.lineareas) do
		areas[line] = areas[line] + area
	end
end

--cuts away the part of a body between heights top and bottom: elements across the cut are clipped (into
--triangles), new particles go where the cut crosses edges, and every connected part left becomes a body.
--returns the bodies left, which is just the body if the cut missed it
function SoftWorld:cut(body, top, bottom)
	if body.maxy <= top or body.miny >= bottom then
		return {body}
	end
	local x, y, vx, vy, rx, ry = {}, {}, {}, {}, {}, {}
	for i = 1, body.n do
		x[i], y[i], vx[i], vy[i], rx[i], ry[i] = body.x[i], body.y[i], body.vx[i], body.vy[i], body.rx[i], body.ry[i]
	end
	local n = body.n

	local crossings = {}
	local function crossing(kept, gone, line) --the particle where the cut at line crosses the edge between two particles
		local key = (kept < gone and kept*65536 + gone or gone*65536 + kept)*2 + (line == top and 0 or 1)
		if not crossings[key] then
			local t = (line - y[kept])/(y[gone] - y[kept])
			if t < SOFTCUTSNAP then
				crossings[key] = kept
			else
				n = n + 1
				x[n], y[n] = x[kept] + t*(x[gone] - x[kept]), line
				vx[n], vy[n] = vx[kept] + t*(vx[gone] - vx[kept]), vy[kept] + t*(vy[gone] - vy[kept])
				rx[n], ry[n] = rx[kept] + t*(rx[gone] - rx[kept]), ry[kept] + t*(ry[gone] - ry[kept])
				crossings[key] = n
			end
		end
		return crossings[key]
	end
	local function clip(corners, keep, line) --the part of an element on the kept side of a line
		local out = {}
		local prev = corners[#corners]
		local prevkept = keep(y[prev])
		for _, cur in ipairs(corners) do
			local curkept = keep(y[cur])
			if curkept then
				if not prevkept then
					out[#out + 1] = crossing(cur, prev, line)
				end
				out[#out + 1] = cur
			elseif prevkept then
				out[#out + 1] = crossing(prev, cur, line)
			end
			prev, prevkept = cur, curkept
		end
		local unique = {}
		for j, p in ipairs(out) do
			if p ~= out[j % #out + 1] then
				unique[#unique + 1] = p
			end
		end
		return unique
	end
	local function above(py) return py <= top end
	local function below(py) return py >= bottom end

	local elements = {}
	for k = 1, body.ne do
		local corners = elementcorners(body, k)
		local isabove, isinside, isbelow = false, false, false
		for _, p in ipairs(corners) do
			if above(y[p]) then
				isabove = true
			elseif below(y[p]) then
				isbelow = true
			else
				isinside = true
			end
		end
		if not isinside and not (isabove and isbelow) then
			elements[#elements + 1] = corners
		else
			for _, side in ipairs({{isabove, above, top}, {isbelow, below, bottom}}) do
				if side[1] then
					local polygon = clip(corners, side[2], side[3])
					for j = 2, #polygon - 1 do --as triangles, which stay rigid with just their edges
						elements[#elements + 1] = {polygon[1], polygon[j], polygon[j + 1]}
					end
				end
			end
		end
	end

	--group the elements that share particles
	local parent = {}
	local function root(p)
		while parent[p] and parent[p] ~= p do
			p = parent[p]
		end
		return p
	end
	local kept = {}
	for _, corners in ipairs(elements) do
		local area = 0
		for j = 1, #corners do
			local a, b = corners[j], corners[j % #corners + 1]
			area = area + rx[a]*ry[b] - rx[b]*ry[a]
		end
		if area > 0.02 then --slivers left by the clipping go
			kept[#kept + 1] = corners
			local r = root(corners[1])
			parent[r] = r
			for j = 2, #corners do
				local other = root(corners[j])
				parent[other] = r
			end
		end
	end

	local parts, order = {}, {}
	for _, corners in ipairs(kept) do
		local r = root(corners[1])
		if not parts[r] then
			parts[r] = {}
			order[#order + 1] = r
		end
		table.insert(parts[r], corners)
	end

	self:remove(body)
	local result = {}
	for _, r in ipairs(order) do
		local part = newbody(self, body.kind, body.density)
		part.data, part.category, part.mask, part.friction, part.cut = body.data, body.category, body.mask, body.friction, true
		local index = {}
		for _, corners in ipairs(parts[r]) do
			local c = {}
			for j, p in ipairs(corners) do
				if not index[p] then
					index[p] = addparticle(part, x[p], y[p], rx[p], ry[p], vx[p], vy[p])
				end
				c[j] = index[p]
			end
			addelement(part, c[1], c[2], c[3], c[4] or 0)
		end
		finalize(part)
		if part.area >= SOFTMINAREA and part.n <= SOFTMAXPARTICLES then
			table.insert(self.bodies, part)
			result[#result + 1] = part
		end
	end
	for _, other in ipairs(self.bodies) do --what rested on the cut part may fall now
		if other.miny < bottom then
			other:wake()
		end
	end
	return result
end

--the shape of a body for drawing and tests: its elements as lists of particle indices
function SoftBody:elements()
	local list = {}
	for k = 1, self.ne do
		list[k] = elementcorners(self, k)
	end
	return list
end
