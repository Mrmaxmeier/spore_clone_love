Gamestate = require "hump.gamestate"
vector = require "hump.vector"
Camera = require "hump.camera"
Class = require "hump.class"
loveframes = require("loveframes")
lovebird = require("lovebird")

local serpent = require "serpent"
require 'pl'
--local C= require 'pl.comprehension' . new()

DEBUG_MODE = false

function genPoly(posMod, corners, size, rotation)
	local verts = {}
	for i=0, corners-1 do
		local pos = vector(size, 0):rotated(2.0 * math.pi / corners * i + rotation) + posMod
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

	if not (editorSelected ~= nil and loveframes.util.GetCollisionCount() > 0) then
		local mPos = vector(cam:mousepos())
		for i, v in ipairs(self.partList) do
			if v:insideHitbox(mPos) then
				v.isHighlighted = true
				break
			end
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
	if self.body then self.body:draw() end
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
end


function generateCreature(complexity)
	local numParts = love.math.random(3, complexity*12)
	local creature = Creature()
	creature.body = Part_Body()
	creature:partsChanged()

	while #creature.partList < numParts do
		local allHinges = {}
		for partI, part in ipairs(creature.partList) do
			for handle, v in ipairs(part:getHandlePositions_Abs()) do
				if not part.connected[handle] then
					table.insert(allHinges, {part=part, handle=handle})
				end
			end
		end
		if #allHinges < 1 then break end

		local newPart = ALL_PARTS[math.random(1, #ALL_PARTS)]()
		local rnd = math.random(1, #allHinges)
		allHinges[rnd].part:attach(newPart, allHinges[rnd].handle)
		creature:partsChanged()
	end
	creature:partsChanged()
	return creature
end



Part = Class{
	init = function(self)
		self.data = {sizeMod=2/3, rotMod=0}
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
		local verts = genPoly(pos, 4, 35*self.size - i*self.size * 5.0, self.rotation + math.pi*0.25)
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
		local verts = genPoly(pos, 4, 35*self.size - i*self.size * 5.0, self.rotation + math.pi*0.25)
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
	creature = generateCreature(1.0)
	creature.body:updatePosition(vector(0, 0))
	cam:lookAt(creature.body.position:unpack())


	--print("Parts")
	--pretty.dump(body:getAllParts())
	print("Stats:")
	pretty.dump(creature.body:getAllStats())

	love.graphics.setNewFont(30)

	iconImage = love.graphics.newImage( "icon.png" )
	print("SetIcon:", love.window.setIcon(iconImage:getData()))

	sidebar = {}
	for i, v in ipairs(ALL_PARTS) do
		sidebar[i] = v()
	end

	editorSelected = nil
	partEditorFrame = loveframes.Create("frame")
	partEditorFrame:SetName("Part Editor")
	partEditorFrame:SetResizable(true)
	partEditorFrame:SetMinWidth(200):SetMinHeight(175):SetHeight(200)
	partEditorFrame:CenterWithinArea(love.graphics.getWidth() - 200, 0, 100, 200)
	partEditorFrame.OnClose = function (object)
		editorSelected = nil
		loveframes.SetState("none")
		return false
	end
	partEditorFrame:SetState("partEditor")
	mouseHandle = nil
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


	loveframes.draw()

	if DEBUG_MODE then
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("d", 0, 0)
	end
end

function creatureCreator:update(dt)
	loveframes.update(dt)
	--cam:zoom(1 + dt*0.1)
	creature:update(dt)
	creature.body:updatePosition(vector(0, 0))
	--body.rotation = love.timer.getTime()*0.1
	if love.keyboard.isDown("left")  then creature.body.rotation = creature.body.rotation - dt end
	if love.keyboard.isDown("right") then creature.body.rotation = creature.body.rotation + dt end

	for i, v in ipairs(sidebar) do
		v.isHighlighted = false
	end

	if not (editorSelected ~= nil and loveframes.util.GetCollisionCount() > 0) then
		res = self:sidebarSelected()
		if res then res.isHighlighted = true end
	end

	for i, v in ipairs(sidebar) do
		v:update(dt)
	end
end

function creatureCreator:mousepressed( x, y, mb )
	loveframes.mousepressed(x, y, mb)
	if mb == "wu" then cam:zoom(1.0 + 0.2) end
	if mb == "wd" then cam:zoom(1.0 - 0.2) end


	if mb == "l" then
		if mouseHandle == nil and not (editorSelected ~= nil and loveframes.util.GetCollisionCount() > 0) then
			-- search for parts
			res = creature:selectedPart()
			if res ~= nil then
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
		if mouseHandle == nil then
			editorSelected = creature:selectedPart()
			if editorSelected ~= nil then
				while #(partEditorFrame:GetChildren()) > 0 do
					--ente
					for i,v in ipairs(partEditorFrame:GetChildren()) do
						v:Remove()
					end
				end
				loveframes.SetState("partEditor")
				editorSelected:editorUI(partEditorFrame)
			else
				loveframes.SetState("none")
			end
		end
	end
end

function creatureCreator:mousemoved(x, y, dx, dy)
	if mouseHandle ~= nil then
		--dragging a part over handles
		local p = nil
		local hI = nil
		local hPos = nil
		p, hI, hPos = creature:selectedHinge()
		if p ~= nil then
			mouseHandle:updatePosition(hPos)
		else
			mouseHandle:updatePosition(vector(cam:mousepos()))
		end
	end
end

function creatureCreator:mousereleased(x, y, mb)
	loveframes.mousereleased(x, y, mb)
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
function creatureCreator:keypressed(key)
	loveframes.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end

	if key == "+" then
		creature.body:setData("corners", creature.body.data.corners + 1)
	end
	if key == "-" then
		creature.body:setData("corners", creature.body.data.corners - 1)
	end

	if key == "r" then
		creature = generateCreature(1.0)
	end

	if key == "d" then
		DEBUG_MODE = not DEBUG_MODE
	end
end

function creatureCreator:textinput(text)
	loveframes.textinput(text)
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
	Gamestate.registerEvents{'draw', 'update', 'quit', 'mousepressed',
							 'mousereleased', 'mousemoved', 'keypressed', 'textinput'}
	Gamestate.switch(creatureCreator)

end

function love.update(dt)
	if DEBUG_MODE then
		lovebird.update()
		--horrible performance on windows
	end
end

function love.draw()
	love.window.setTitle("SporeClone (Kawaii edition)"..love.timer.getFPS().. "FPS")
end
