Part_Eye = Class{__includes=Part, name="Part_Eye"}

function Part_Eye:drawThis()
	local verts = genPoly(self.position, 4, 40*self.size, self.rotation)
	love.graphics.setColor( self:getCol(255, 255, 255) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(0, 0, 0) )
	love.graphics.polygon("line", verts)

	local diff = (vector(cam:mousepos()) - self.position);
	local diff2 = diff:clone()
	if diff:len() > 8.0*self.size then diff = diff:normalized() * 8.0*self.size end

	local verts = genPoly(self.position + diff, 4, 25*self.size, self.rotation)
	love.graphics.setColor( self:getCol(0, 0, 255) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(0, 0, 255) )
	love.graphics.polygon("line", verts)



	if diff2:len() > 12.0*self.size then diff2 = diff2:normalized() * 12.0*self.size end
	local verts = genPoly(self.position + diff2, 4, 15*self.size, self.rotation)
	love.graphics.setColor( self:getCol(0, 0, 0) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(0, 0, 0) )
	love.graphics.polygon("line", verts)
end

function Part_Eye:stats()
	return {partnum = 1, vision = 1}
end

return Part_Eye