Part = Class{
	init = function(self)
		self.data = {sizeMod=2/3, rotMod=0}
		self.position = vector(0, 0)
		self.connected = {}
		self.parent = nil
		self.size = 1
		self.rotation = 0
		self.isHighlighted = false
		self:setUp()
	end,
	name="Part"
}

function Part:setUp()
end


function Part:getCol(r, g, b)
	if self.isHighlighted then
		return 255 - r, 255 - g, 255 - b
	end
	return r, g, b
end


function Part:draw()
	self:drawThis()
	if mouseHandle ~= nil then self:drawHandles() end

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
	other.size = self.size * other.data.sizeMod
	other.parent = self
	other.handle = handle
end

function Part:detach()
	if self.parent ~= nil then
		if self.handle ~= nil then
			self.parent.connected[self.handle] = nil
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
				self.connected[i].rotation = handleRot[i] + self.connected[i].data.rotMod
			end
			self.connected[i].size = self.size * self.connected[i].data.sizeMod
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
	local serTable = {connected = {}, data = self.data, partType=self.name}
	for k, v in pairs(self.connected) do
		serTable.connected[k] = v:ser()
	end
	return serTable
end

function Part:loadData( t )
	self.data = tablex.deepcopy(t)
end

function Part:setData(key, data)
	self.data[key] = data
end

function Part:stdEditorUI(frame, rows)
	local sizeModText = loveframes.Create("text", frame)
	sizeModText.Update = function(object, dt)
		object:CenterX()
		object:SetY(frame:GetHeight()/rows*1)
	end
	local sizeModSlider = loveframes.Create("slider", frame)
	sizeModSlider:SetWidth(290)
	sizeModSlider:SetMinMax(1, 4)
	sizeModSlider.Update = function(object, dt)
		object:CenterX()
		object:SetY(frame:GetHeight()/rows*2)
		object:SetWidth(frame:GetWidth()-20)
	end
	sizeModSlider.OnValueChanged = function(object)
		local sizeMod = math.floor(object:GetValue())
		sizeModText:SetText("SizeMod: "..sizeMod.."/3")
		self:setData("sizeMod", sizeMod/3)
	end
	sizeModSlider:SetValue(math.floor(self.data.sizeMod*3))



	local rotModText = loveframes.Create("text", frame)
	rotModText.Update = function(object, dt)
		object:CenterX()
		object:SetY(frame:GetHeight()/rows*3)
	end
	local rotModSlider = loveframes.Create("slider", frame)
	rotModSlider:SetWidth(290)
	rotModSlider:SetMinMax(0, 360)
	rotModSlider.Update = function(object, dt)
		object:CenterX()
		object:SetY(frame:GetHeight()/rows*4)
		object:SetWidth(frame:GetWidth()-20)
	end
	rotModSlider.OnValueChanged = function(object)
		local rotMod = math.floor(object:GetValue()/5)*5
		rotModText:SetText("rotMod: "..rotMod)
		self:setData("rotMod", rotMod*(math.pi/180))
	end
	rotModSlider:SetValue(self.data.rotMod/(math.pi/180))
end

function Part:editorUI(frame)
	self:stdEditorUI(frame, 5)
end

function loadPart(t)
	local partTable = {}
	for i,v in ipairs(ALL_PARTS) do
		partTable[v.name] = v
	end
	local part = partTable[t.partType]()
	part:loadData(t.data)
	for k, v in pairs(t.connected) do
		if v ~= nil then
			part:attach(loadPart(v), k)
		end
	end
	return part
end

function Part:clone()
	--local ok, t = serpent.load(self:ser())
	return loadPart(self:ser())
end
