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
		local verts = genPoly(pos, 4, 35*self.size - i*self.size * 5.0, self.rotation + math.pi*0.25)
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

return Part_Fin