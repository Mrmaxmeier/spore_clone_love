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

function Creature:update(dt, isEditor)
	isEditor = isEditor or true

	if self.body then
		self.body:updateAll(dt)
	end

	if not isEditor then
		return
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

function Creature:saveToDisk()
	--TODO: save creature to disk w/ self.name
	if not love.filesystem.exists("creatures") then
		love.filesystem.createDirectory("creatures")
	end

	local file = love.filesystem.newFile("creatures/"..self.name)
	file:open("w")
	local t = {name = self.name, body = self.body:ser()}
	file:write(serpent.dump(t))
	file:close()
end


function generateCreature(complexity)
	local numParts = love.math.random(3, complexity*12)
	local creature = Creature()
	for i,v in ipairs(ALL_PARTS) do
		if v.name == "Part_Body" then
			creature.body = v()
		end
	end
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

function loadCreature(t)
	local creature = Creature()
	creature.name = t.name
	creature.body = loadPart(t.body)
	return creature
end