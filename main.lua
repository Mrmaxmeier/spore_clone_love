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



Part = Class{
	init = function(self)
		self.data = "lel"
		self.position = vector(0, 0)
		self.connected = {}
		self.parent = nil
		self.size = 1
		self.rotation = 0
	end,
	name="Part"
}


function Part:draw()
	self:drawThis()
	if true then self:drawHandles() end

	for i, connected in pairs(self.connected) do
		connected:draw()
	end
	
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
			verts = genPoly(handle + self.position, 5, 10, love.timer.getTime()*0.1 + self.rotation)
			love.graphics.setColor( 0, 0, 0 )
			love.graphics.polygon("fill", verts)
			love.graphics.setColor( 0, 255, 255)
			love.graphics.polygon("line", verts)
		end
	end
end

function Part:connect(other, handle)
	self.connected[handle] = other
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



Part_Body = Class{__includes=Part, name="Part_Body"}

function Part_Body:getHandlePositions_Rel()
	local res = {}
	for i=0,2 do
		pos = vector(100, 0):rotated(2.0 * math.pi / 3.0 * i + love.timer.getTime()*0.1)
		--pos = vector(100, 0):rotated(2.0 * math.pi / 3.0 * i)
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
	verts  = genPoly(self.position, 3, 100, self.rotation)
	love.graphics.setColor( 0, 0, 0 )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( 255, 255, 255)
	love.graphics.polygon("line", verts)
end

Part_Eye = Class{__includes=Part, name="Part_Eye"}

function Part_Eye:drawThis()
	verts = genPoly(self.position, 4, 30, self.rotation)
	love.graphics.setColor( 0, 0, 0 )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( 255, 255, 255)
	love.graphics.polygon("line", verts)
end


creatureCreator = {}

function creatureCreator:enter()
	cam = Camera(0, 0)
	cam:zoomTo(2)
	body = Part_Body()
	body2 = Part_Body()
	eye = Part_Eye()
	eye2 = Part_Eye()
	body:connect(eye, 1)
	body:connect(eye2, 2)
	body:connect(body2, 3)
	body:updatePosition(vector(0, 0))
	cam:lookAt(body.position:unpack())
end

function creatureCreator:draw()
	cam:attach()
	body:draw()
	cam:detach()
end

function creatureCreator:update(dt)
	--cam:zoom(1 + dt*0.1)
	body:updatePosition(vector(0, 0))
	body.rotation = love.timer.getTime()*0.1
end




function love.load()
	print("\aSWAG")

	-- only register draw, update and quit
	Gamestate.registerEvents{'draw', 'update', 'quit'}
	Gamestate.switch(creatureCreator)

end

function love.update(dt)
end

function love.draw()
	love.window.setTitle("SporeClone: "..love.timer.getFPS().." FPS")
end