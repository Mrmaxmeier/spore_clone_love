Part_Fin = Class{__includes=Part, name="Part_Fin"}

function Part_Fin:setUp()
	self.data.phase = 0
	self.data.speed = 0.3
	self.data.agility = 0.3
end

function Part_Fin:update(dt)
	self.data.phase = self.data.phase + dt * self.data.speed*2
	self.data.phase = self.data.phase + dt * self.data.agility*5
end

function Part_Fin:drawThis()
	local length = (self.data.speed + self.data.agility/2) * 100
	local dir = vector(length*self.size, 0):rotated(self.rotation)

	for i=0, 4 do
		local speed = 1.0 * 2.0
		local size = (self.data.speed + self.data.agility/2) * (35* self.size - i*self.size * 5.0)
		local pos = self.position + dir * i/4.0
		pos = pos + vector(0, math.sin(self.data.phase * speed + i) * i):rotated(self.rotation)
		local verts = genPoly(pos, 4, size, self.rotation + math.pi*0.25)
		local cMod = (255/2)/4*i
		love.graphics.setColor( self:getCol(255-cMod, 255-cMod, 255-cMod) )
		love.graphics.polygon("fill", verts)
		love.graphics.setColor( self:getCol(0, 0, 0) )
		love.graphics.polygon("line", verts)
	end

end


function Part_Fin:stats()
	return {partnum = 1, speed = self.data.speed,
			agility = self.data.agility}
end

return Part_Fin