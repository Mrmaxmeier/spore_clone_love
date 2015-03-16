function genPoly(posMod, corners, size, rotation)
	local verts = {}
	for i=0, corners-1 do
		local pos = vector(size, 0):rotated(2.0 * math.pi / corners * i + rotation) + posMod
		table.insert(verts, pos.x)
		table.insert(verts, pos.y)
	end
	return verts
end