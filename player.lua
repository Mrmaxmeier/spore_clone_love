Player = Class{
	init = function(self)
		self.creature = nil
		self.position = vector(0, 0)
		self.velocity = vector(0, 0)
		self.rotation = 0
		self.type = "BaseClass"
		self.stats = {}
		self.name = "Player"
		self.hp = 0
		self.speed = 0
		self.direction = 0
		self.dead = false
	end,
}

--Callbacks

function Player:onSpawn() end
function Player:onDeath() end


function Player:update(dt)
	if self.hp <= 0 and not self.dead then
		self.dead = true
		self:onDeath()
	end

	self.velocity = vector(self.speed, 0):rotated(self.direction)
	self.position = self.position + self.velocity * dt

	if self.creature then
		self.creature.body:updatePosition(self.position)
		self.creature:update(dt)
	end
end

function Player:spawn()
	self:onSpawn()
end

function Player:move(vec)
	self.speed = vec:len() * self.stats.speed * 100
	self.direction = vec:angleTo()
end

function Player:draw()
	if self.creature then
		self.creature:draw()
	end
end

function Player:updateStats()
	if self.creature then
		self.creature:updateStats()
		self.stats = self.creature.stats
		if not self.stats.speed then self.stats.speed = 0 end
	end
end


OwnPlayer = Class{__includes=Player}