Gamestate = require "hump.gamestate"
vector = require "hump.vector"
Camera = require "hump.camera"
Class = require "hump.class"


Part = Class{
	init = function(self)
		self.data = "lel"
		self.position = vector(0, 0)
		self.connected = {}
		self.parent = nil
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
	res = {}
	for i, pos in pairs(self:getHandlePositions_Rel()) do
		table.insert(res, pos + self.position)
	end
	return res
end

function Part:drawHandles()
	for i, handle in pairs(self:getHandlePositions_Abs()) do
		love.graphics.circle("line", handle.x, handle.y, 50, 5)
	end
end

function Part:connect(other, handle)
	self.connected[handle] = other
end

function Part:updatePosition(newPosition)
	--print("updating pos of "..self.name)
	self.position = newPosition
	for i, handlePos in pairs(self:getHandlePositions_Abs()) do
		if self.connected[i] then
			self.connected[i]:updatePosition(handlePos)
		end
	end
end



Part_Body = Class{__includes=Part, name="Part_Body"}

function Part_Body:getHandlePositions_Rel()
	res = {}
	for i=1,3 do
		pos = vector(100, 0):rotated(2.0 * math.pi / 3.0 * i + love.timer.getTime()*0.1)
		table.insert(res, pos)
	end
	return {}
end

function Part_Body:drawThis()
	love.graphics.setColor( 255, 255, 255, 255 )
	love.graphics.circle("line", self.position.x, self.position.y, 100, 5)
end

Part_Eye = Class{__includes=Part, name="Part_Eye"}

function Part_Eye:drawThis()
	love.graphics.setColor( 0, 255, 0, 255 )
	love.graphics.circle("fill", self.position.x, self.position.y, 50, 5)
end


creatureCreator = {}

function creatureCreator:enter()
	cam = Camera(0, 0)
	cam:zoomTo(2)
	body = Part_Body()
	eye = Part_Eye()
	body:connect(eye, 2)
	body:updatePosition(vector(0, 0))
	cam:lookAt(body.position:unpack())
end

function creatureCreator:draw()
	--love.graphics.rectangle("fill",10,10,500,500)
	cam:attach()
	body:draw()
	cam:detach()
end

function creatureCreator:update(dt)
	--cam:zoom(1 + dt*0.1)
	body:updatePosition(vector(0, 0))
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