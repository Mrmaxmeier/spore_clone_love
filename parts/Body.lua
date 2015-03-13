Part_Body = Class{__includes=Part, name="Part_Body"}

function Part_Body:getHandlePositions_Rel()
	if not self.data.corners then self.data.corners = 3 end
	local res = {}
	for i=0, self.data.corners-1 do
		local pos = vector(100 * self.size, 0):rotated(2.0 * math.pi / self.data.corners * (self.data.corners-i) + self.rotation)
		table.insert(res, pos)
	end
	return res
end

function Part_Body:getHandleRotation()
	if not self.data.corners then self.data.corners = 3 end
	local res = {}
	for i=0, self.data.corners-1 do
		table.insert(res, (2.0 * math.pi / self.data.corners) * (self.data.corners-i) + self.rotation)
	end
	return res
end

function Part_Body:drawThis()
	if not self.data.corners then self.data.corners = 3 end
	local verts = genPoly(self.position, self.data.corners, 100*self.size, self.rotation)
	love.graphics.setColor( self:getCol(0, 0, 0) )
	love.graphics.polygon("fill", verts)
	love.graphics.setColor( self:getCol(255, 255, 255) )
	love.graphics.polygon("line", verts)
end


function Part_Body:setData(key, val)
	if key == "corners" then
		if val < 3 then val = 3 end
		if val < self.data.corners then
			for i, v in ipairs(self.connected) do
				if i > val then v:detach() end
			end
		end
		self.data[key] = val
	else self.data[key] = val end
end


function Part_Body:editorUI(frame)
	local rows = 7
	self:stdEditorUI(frame, rows)

	local text = loveframes.Create("text", frame)
	text.Update = function(object, dt)
		object:CenterX()
		object:SetY(frame:GetHeight()/rows*5)
	end
	local cornersSlider = loveframes.Create("slider", frame)
	cornersSlider:SetPos(5, 30)
	cornersSlider:SetWidth(290)
	cornersSlider:SetMinMax(3, 8.5)
	cornersSlider.Update = function(object, dt)
		object:CenterX()
		object:SetY(frame:GetHeight()/rows*6)
		object:SetWidth(frame:GetWidth()-20)
	end
	cornersSlider.OnValueChanged = function(object)
		local corners = math.floor(object:GetValue())
		text:SetText("#corners: "..corners)
		self:setData("corners", corners)
	end

	cornersSlider:SetValue(self.data.corners)
end

return Part_Body