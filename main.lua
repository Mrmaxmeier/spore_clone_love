Gamestate = require "hump.gamestate"
vector = require "hump.vector"
Camera = require "hump.camera"
Class = require "hump.class"

package.path = package.path .. ";penlight/lua/?.lua"
local pl = require('pl.import_into')()
local C= require 'pl.comprehension' . new()


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

function Creature:draw()
	if self.body then body:draw() end
end

function Creature:partsChanged()
	self:updateStats()
	local reversedParts = self.body:getAllParts()
	self.partList = {}
    local itemCount = #reversedParts
    for k, v in ipairs(reversedParts) do
        self.partList[itemCount + 1 - k] = v
    end
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
		connected:draw()
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
	self.handle = handle
end

function Part:detach() 
	self.parent.connected[self.handle] = nil
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
			self.connected[i]:updatePosition(handlePos)
		end
	end
end

function Part:stats()
	return {partnum = 1}
end

function Part:getAllStats()
	local stats = self:stats()
	for i, part in ipairs(self.connected) do
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
	local parts = {self}
	for i, part in ipairs(self.connected) do
		if part then
			parts[#parts+1] = part
		end
	end

	for i, part in ipairs(self.connected) do
		if part then
			for k, v in pairs(part:getAllParts()) do
				parts[#parts+1] = v
			end
		end
	end
	return parts
end


function Part:updateAll(dt)
	self:update(dt)
	for i, part in ipairs(self.connected) do
		if part then part:updateAll(dt) end
	end
end

function Part:insideHitbox(point)
	return point:dist(self.position) < self.size * 100
end


Part_Body = Class{__includes=Part, name="Part_Body"}

function Part_Body:getHandlePositions_Rel()
	local res = {}
	for i=0,2 do
		pos = vector(100 * self.size, 0):rotated(2.0 * math.pi / 3.0 * i + self.rotation)
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
	verts = genPoly(self.position, 4, 35*self.size, self.rotation)
	love.graphics.setColor( self:getCol(255, 255, 255) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(0, 0, 0) )
	love.graphics.polygon("line", verts)

	local diff = (vector(cam:mousepos()) - self.position);
	local diff2 = diff:clone()
	if diff:len() > 8.0*self.size then diff = diff:normalized() * 8.0*self.size end

	verts = genPoly(self.position + diff, 4, 20*self.size, self.rotation)
	love.graphics.setColor( self:getCol(0, 0, 255) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(0, 0, 255) )
	love.graphics.polygon("line", verts)



	if diff2:len() > 12.0*self.size then diff2 = diff2:normalized() * 12.0*self.size end
	verts = genPoly(self.position + diff2, 4, 10*self.size, self.rotation)
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

	local dir = vector(40, 0):rotated(self.rotation)

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

ALL_PARTS = {Part_Body, Part_Eye, Part_Fin}

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
	eye2 = Part_Eye()
	body:attach(fin, 1)
	body:attach(body2, 2)
	body2:attach(eye2, 2)
	body2:attach(body3, 1)


	creature:partsChanged()

	body:updatePosition(vector(0, 0))
	cam:lookAt(body.position:unpack())


	print("Parts")
	pl.pretty.dump(body:getAllParts())
	print("Stats:")
	pl.pretty.dump(body:getAllStats())

	love.graphics.setNewFont(30)

	iconImage = love.graphics.newImage( "icon.png" )
	print("SetIcon:", love.window.setIcon(iconImage:getData()))
	--print(image:getWidth())


	sidebar = {}
	for k, v in pairs(ALL_PARTS) do
		sidebar[k] = v()
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
	--love.graphics.print( pl.pretty.write(creature.stats), 0, 0)

	love.graphics.setColor(222, 255, 222, 127)
	love.graphics.rectangle("fill", 0, 0, sx/5, sy)
	for k,v in pairs(sidebar) do
		v.position = vector(sx/10, k*sy/(#sidebar+1))
		v.size = 0.1 + sx/800 * 0.5
		v:draw()
	end
end

function creatureCreator:update(dt)
	--cam:zoom(1 + dt*0.1)
	creature:update(dt)
	body:updatePosition(vector(0, 0))
	--body.rotation = love.timer.getTime()*0.1
	if love.keyboard.isDown("left")  then body.rotation = body.rotation - dt end
	if love.keyboard.isDown("right") then body.rotation = body.rotation + dt end

	for k,v in pairs(sidebar) do
		v:update(dt)
	end
end

function creatureCreator:mousepressed( x, y, mb )
	if mb == "wu" then cam:zoom(1.0 + 0.2) end
	if mb == "wd" then cam:zoom(1.0 - 0.2) end
end



function love.load()
	print("\aSWAG")

	-- only register draw, update and quit
	Gamestate.registerEvents{'draw', 'update', 'quit', 'mousepressed'}
	Gamestate.switch(creatureCreator)

end

function love.update(dt)
end

function love.draw()
	love.window.setTitle("SporeClone: "..love.timer.getFPS().." FPS")
end