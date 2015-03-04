Gamestate = require "hump.gamestate"
vector = require "hump.vector"
Camera = require "hump.camera"
Class = require "hump.class"


local serpent = require "serpent"
require 'pl'
--local C= require 'pl.comprehension' . new()



function genPoly(posMod, corners, size, rotation)
	local verts = {}
	for i=0, corners-1 do
		pos = vector(size, 0):rotated(2.0 * math.pi / corners * i + rotation) + posMod
		table.insert(verts, pos.x)
		table.insert(verts, pos.y)
	end
	return verts
end


Creature = Class{
	init = function(self)
		self.body = nil
		self.stats = {}
		self.name = "Unnamed Creature"
		self.position = vector(0, 0)
		self.velocity = vector(0, 0)
		self.partList = {}
	end
}

function Creature:updateStats()
	if self.body then
		self.stats = self.body:getAllStats()
	end
end

function Creature:update(dt)
	if self.body then
		self.body:updateAll(dt)
	end


	for i, v in ipairs(self.partList) do
		v.isHighlighted = false
	end

	local mPos = vector(cam:mousepos())
	for i, v in ipairs(self.partList) do
		if v:insideHitbox(mPos) then
			v.isHighlighted = true
			break
		end
	end
end

function Creature:selectedPart()
	local mPos = vector(cam:mousepos())
	for i, v in ipairs(self.partList) do
		if v:insideHitbox(mPos) then
			return v
		end
	end
	return nil;
end


function Creature:selectedHinge()
	local mPos = vector(cam:mousepos())
	for i, part in ipairs(self.partList) do
		for hI, hPos in ipairs(part:getHandlePositions_Abs()) do
			if mPos:dist(hPos) < 30*part.size then
				return part, hI, hPos --part, hingeIndex
			end
		end
	end
	return nil, nil, nil
end


function Creature:draw()
	if self.body then body:draw() end
end

function Creature:partsChanged()
	self:updateStats()
	local reversedParts = self.body:getAllParts()
	table.insert(reversedParts, 1, self.body)
	self.partList = {}
    local itemCount = #reversedParts
    for k, v in ipairs(reversedParts) do
        self.partList[itemCount + 1 - k] = v
    end
    print("PartList:")
    print(#self.partList)
end



Part = Class{
	init = function(self)
		self.data = {myData="lel"}
		self.position = vector(0, 0)
		self.connected = {}
		self.parent = nil
		self.size = 1
		self.rotation = 0
		self.isHighlighted = false
	end,
	name="Part"
}

function Part:getCol(r, g, b)
	if self.isHighlighted then
		return 255 - r, 255 - g, 255 - b
	end
	return r, g, b
end


function Part:draw()
	self:drawThis()
	if true then self:drawHandles() end

	for i, connected in pairs(self.connected) do
		if connected ~= nil then
			connected:draw()
		end
	end
	
end

function Part:update(dt)
	-- to be overwritten
end

function Part:drawThis()
	--to be overwritten
	love.graphics.circle("fill", self.position.x, self.position.y, 100, 5)
end

function Part:getHandlePositions_Rel()
	-- to be overwritten
	return {}
end

function Part:getHandlePositions_Abs()
	local res = {}
	for i, pos in pairs(self:getHandlePositions_Rel()) do
		table.insert(res, pos + self.position)
	end
	return res
end

function Part:getHandleRotation()
	--to be overwritten
	return {}
end

function Part:drawHandles()
	for i, handle in pairs(self:getHandlePositions_Abs()) do
		if not self.connected[i] then
			local modStrength = 1.5;
			local sMod = math.sin(love.timer.getTime()*modStrength*2.0)*0.1
			local rMod = love.timer.getTime()*modStrength
			local verts = genPoly(handle, 5, 10 * (self.size + sMod) , self.rotation + rMod)
			love.graphics.setColor( 0, 0, 0 )
			love.graphics.polygon("fill", verts)
			love.graphics.setColor( 0, 255, 255)
			love.graphics.polygon("line", verts)
		end
	end
end

function Part:attach(other, handle)
	self.connected[handle] = other
	other.size = self.size * 0.6
	other.parent = self
	other.handle = handle
end

function Part:detach()
	if self.parent ~= nil then
		if self.handle ~= nil then
			self.parent.connected[self.handle] = nil
			print("detached")
		else
			print("detach no handle")
		end
	else
		print("detach no parent")
	end
end


function Part:updatePosition(newPosition)
	--print("updating pos of "..self.name)
	self.position = newPosition
	local handleRot = self:getHandleRotation()
	for i, handlePos in pairs(self:getHandlePositions_Abs()) do
		if self.connected[i] then
			if handleRot[i] then
				self.connected[i].rotation = handleRot[i]
			end
			self.connected[i].size = self.size * 0.6
			self.connected[i]:updatePosition(handlePos)
		end
	end
end

function Part:stats()
	return {partnum = 1}
end

function Part:getAllStats()
	local stats = self:stats()
	for partHandle, part in pairs(self.connected) do
		if part then
			for k, v in pairs(part:getAllStats()) do
				if stats[k] ~= nil then
					stats[k] = stats[k] + v
				else
					stats[k] = v
				end
			end
		end
	end
	return stats
end


function Part:getAllParts()
	local parts = {}
	for k, part in pairs(self.connected) do
		if part then
			table.insert(parts, part)
		end
	end

	for k1, part in pairs(self.connected) do
		if part then
			for k, v in pairs(part:getAllParts()) do
				table.insert(parts, v)
			end
		end
	end
	return parts
end


function Part:updateAll(dt)
	self:update(dt)
	for k, part in pairs(self.connected) do
		if part then part:updateAll(dt) end
	end
end

function Part:insideHitbox(point)
	return point:dist(self.position) < self.size * 100
end

function Part:ser()
	local serTable = {connected = {}, data = {}, partType=self.name}
	for k, v in pairs(self.connected) do
		serTable.connected[k] = v:ser()
	end
	return serTable--serpent.dump(serTable)
end

function Part:loadData( t )
	-- body
end

function loadPart(t)
	print("loading part")
	print(t)
	local partTable = {Part_Eye=Part_Eye, Part_Body=Part_Body, Part_Fin=Part_Fin, Part_Mouth=Part_Mouth}
	local part = partTable[t.partType]()
	part:loadData(t.data)
	for k, v in pairs(t.connected) do
		if v ~= nil then
			part:attach(loadPart(v), k)
			print("attaching", k)
		end
	end
	return part
end

function Part:clone()
	--local ok, t = serpent.load(self:ser())
	return loadPart(self:ser())
end



Part_Body = Class{__includes=Part, name="Part_Body"}

function Part_Body:getHandlePositions_Rel()
	local res = {}
	for i=0, 2 do
		pos = vector(100 * self.size, 0):rotated(2.0 * math.pi / 3.0 * (3-i) + self.rotation)
		table.insert(res, pos)
	end
	return res
end

function Part_Body:getHandleRotation()
	local res = {}
	for i=0,2 do
		table.insert(res, 4.0 * math.pi / 3.0 * i + self.rotation)
	end
	return res
end

function Part_Body:drawThis()
	verts  = genPoly(self.position, 3, 100*self.size, self.rotation)
	love.graphics.setColor( self:getCol(0, 0, 0) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(255, 255, 255) )
	love.graphics.polygon("line", verts)
end

Part_Eye = Class{__includes=Part, name="Part_Eye"}

function Part_Eye:drawThis()
	verts = genPoly(self.position, 4, 40*self.size, self.rotation)
	love.graphics.setColor( self:getCol(255, 255, 255) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(0, 0, 0) )
	love.graphics.polygon("line", verts)

	local diff = (vector(cam:mousepos()) - self.position);
	local diff2 = diff:clone()
	if diff:len() > 8.0*self.size then diff = diff:normalized() * 8.0*self.size end

	verts = genPoly(self.position + diff, 4, 25*self.size, self.rotation)
	love.graphics.setColor( self:getCol(0, 0, 255) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(0, 0, 255) )
	love.graphics.polygon("line", verts)



	if diff2:len() > 12.0*self.size then diff2 = diff2:normalized() * 12.0*self.size end
	verts = genPoly(self.position + diff2, 4, 15*self.size, self.rotation)
	love.graphics.setColor( self:getCol(0, 0, 0) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(0, 0, 0) )
	love.graphics.polygon("line", verts)
end

function Part_Eye:stats()
	return {partnum = 1, vision = 1}
end

Part_Fin = Class{__includes=Part, name="Part_Fin", data={phase=0}}

function Part_Fin:update(dt)
	if not self.data.phase then self.data.phase = 0 end
	self.data.phase = self.data.phase + dt * 5.0
end

function Part_Fin:drawThis()
	if not self.data.phase then self.data.phase = 0 end

	local dir = vector(100*self.size, 0):rotated(self.rotation)

	for i=0, 4 do
		local speed = 1.0 * 2.0
		local pos = self.position + dir * i/4.0
		pos = pos + vector(0, math.sin(self.data.phase * speed + i) * i):rotated(self.rotation)
		verts = genPoly(pos, 4, 35*self.size - i*self.size * 5.0, self.rotation + math.pi*0.25)
		local cMod = (255/2)/4*i
		love.graphics.setColor( self:getCol(255-cMod, 255-cMod, 255-cMod) )
		love.graphics.polygon("fill", verts)
		love.graphics.setColor( self:getCol(0, 0, 0) )
		love.graphics.polygon("line", verts)
	end

end


function Part_Fin:stats()
	return {partnum = 1, speed = 1}
end




Part_Mouth = Class{__includes=Part, name="Part_Mouth", data={phase=0}}

function Part_Mouth:update(dt)
	if not self.data.phase then self.data.phase = 0 end
	self.data.phase = self.data.phase + dt * 5.0
end

function Part_Mouth:drawThis()
	if not self.data.phase then self.data.phase = 0 end

	local dir = vector(100*self.size, 0):rotated(self.rotation)
	for i=0, 4 do
		local speed = 1.0 * 2.0
		local pos = self.position + dir * i/4.0
		pos = pos + vector(0, 5*math.abs(math.sin(self.data.phase))*i*self.size):rotated(self.rotation)
		verts = genPoly(pos, 4, 35*self.size - i*self.size * 5.0, self.rotation + math.pi*0.25)
		local cMod = (255/2)/4*i
		love.graphics.setColor( self:getCol(255-cMod, 255-cMod, 255-cMod) )
		love.graphics.polygon("fill", verts)
		love.graphics.setColor( self:getCol(0, 0, 0) )
		love.graphics.polygon("line", verts)
	end
	local dir = vector(100*self.size, 0):rotated(self.rotation)
	for i=0, 4 do
		local speed = 1.0 * 2.0
		local pos = self.position + dir * i/4.0
		pos = pos + vector(0, -5*math.abs(math.sin(self.data.phase))*i*self.size):rotated(self.rotation)
		verts = genPoly(pos, 4, 35*self.size - i*self.size * 5.0, self.rotation + math.pi*0.25)
		local cMod = (255/2)/4*i
		love.graphics.setColor( self:getCol(255-cMod, 255-cMod, 255-cMod) )
		love.graphics.polygon("fill", verts)
		love.graphics.setColor( self:getCol(0, 0, 0) )
		love.graphics.polygon("line", verts)
	end

end


function Part_Mouth:stats()
	return {partnum = 1, mouth = 1}
end

ALL_PARTS = {Part_Body, Part_Eye, Part_Fin, Part_Mouth}

creatureCreator = {}

function creatureCreator:enter()
	cam = Camera(0, 0)
	cam:zoomTo(2)
	creature = Creature()
	body = Part_Body()
	creature.body = body
	body2 = Part_Body()
	body3 = Part_Body()
	fin = Part_Fin()
	fin2 = Part_Fin()
	fin3 = Part_Fin()
	eye2 = Part_Eye()
	body:attach(fin, 1)
	body:attach(fin3, 3)
	body:attach(body2, 2)
	body2:attach(body3, 1)
	body3:attach(eye2, 1)
	

	--eye2:detach()


	creature:partsChanged()

	body:updatePosition(vector(0, 0))
	cam:lookAt(body.position:unpack())


	--print("Parts")
	--pretty.dump(body:getAllParts())
	print("Stats:")
	pretty.dump(body:getAllStats())

	love.graphics.setNewFont(30)

	iconImage = love.graphics.newImage( "icon.png" )
	print("SetIcon:", love.window.setIcon(iconImage:getData()))

	sidebar = {}
	for i, v in ipairs(ALL_PARTS) do
		sidebar[i] = v()
	end
end

function creatureCreator:draw()
	sx = love.graphics.getWidth()
	sy = love.graphics.getHeight()

	--body:updatePosition(vector(sx*0.05, 0))
	
	--Swag
	--love.graphics.setColor(255, 255, 255)
	--love.graphics.draw(image, 0, 0, 0, 0.3, 0.3)
	love.graphics.setBackgroundColor( 0, 0, 205 )

	cam:attach()
	creature:draw()
	cam:detach()

	--HUD
	love.graphics.setColor(255, 255, 255)
	--love.graphics.print( "Editing: "..creature.name, 0, 0)
	--love.graphics.print( pretty.write(creature.stats), 0, 0)

	love.graphics.setColor(222, 255, 222, 127)
	love.graphics.rectangle("fill", 0, 0, sx/5, sy)
	for i, v in ipairs(sidebar) do
		v.position = vector(sx/10, i*sy/(#sidebar+1))
		v.size = 0.1 + sx/800 * 0.5
		v:draw()
	end

	if mouseHandle ~= nil then
		cam:attach()
		mouseHandle:draw()
		cam:detach()
	end
end

function creatureCreator:update(dt)
	--cam:zoom(1 + dt*0.1)
	creature:update(dt)
	body:updatePosition(vector(0, 0))
	--body.rotation = love.timer.getTime()*0.1
	if love.keyboard.isDown("left")  then body.rotation = body.rotation - dt end
	if love.keyboard.isDown("right") then body.rotation = body.rotation + dt end

	for i, v in ipairs(sidebar) do
		v.isHighlighted = false
	end

	res = self:sidebarSelected()
	if res then res.isHighlighted = true end

	for i, v in ipairs(sidebar) do
		v:update(dt)
	end
end

function creatureCreator:mousepressed( x, y, mb )
	if mb == "wu" then cam:zoom(1.0 + 0.2) end
	if mb == "wd" then cam:zoom(1.0 - 0.2) end


	if mb == "l" then
		if mouseHandle ~= nil then
			-- search for handles
		else
			-- search for parts
			res = creature:selectedPart()
			if res ~= nil then
				print("selectedPart")
				if res.parent ~= nil then
					mouseHandle = res:clone()
					if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
						--swag
					else
						res:detach()
						creature:partsChanged()
					end

					mouseHandle:updatePosition(vector(cam:mousepos()))
				end
			else
				res = creatureCreator:sidebarSelected()
				if res ~= nil then
					mouseHandle = res:clone()
					mouseHandle:updatePosition(vector(cam:mousepos()))
				end
			end
		end
	end

	if mb == "r" then
		print("\n\n\nSwag:")
		creature:partsChanged()
		pretty.dump(creature.body:ser())
	end
end

function creatureCreator:mousemoved(x, y, dx, dy)
	if mouseHandle ~= nil then
		--dragging a part over handles
		p, hI, hPos = creature:selectedHinge()
		if p ~= nil then
			mouseHandle:updatePosition(hPos)
		else
			mouseHandle:updatePosition(vector(cam:mousepos()))
		end
	end
end

function creatureCreator:mousereleased(x, y, mb)
	if mb == "l" then
		if mouseHandle ~= nil then
			p, hI, hPos = creature:selectedHinge()
			if p ~= nil then
				p:attach(mouseHandle, hI)
				creature:partsChanged()
			end
		end
		mouseHandle = nil
	end
end


function creatureCreator:sidebarSelected()
	local absMPos = vector(love.mouse.getPosition())
	for i, v in ipairs(sidebar) do
		if absMPos.x < love.graphics.getWidth()/5 then
			if absMPos.y < (i) * love.graphics.getHeight()/(#sidebar) then
				if absMPos.y > (i-1) * love.graphics.getHeight()/(#sidebar) then
					return v
				end
			end
		end
	end
end





function love.load()
	print("\aSWAG")

	-- only register draw, update and quit
	Gamestate.registerEvents{'draw', 'update', 'quit', 'mousepressed', 'mousereleased', 'mousemoved'}
	Gamestate.switch(creatureCreator)

end

function love.update(dt)
end

function love.draw()
	love.window.setTitle("SporeClone: "..love.timer.getFPS().." FPS")
end