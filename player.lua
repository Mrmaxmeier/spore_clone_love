Player = Class{
	init = function(self)
		self.creature = nil
		self.position = vector(0, 0)
		self.velocity = vector(0, 0)
		self.type = "BaseClass"
		self.stats = {}
		self.name = "Player"
		self.hp = 0
		self.mVec = vector(0, 0)
		self.mVecNew = vector(0, 0)
		self.powerlevel = 0
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

	self:updateMovement(dt)
	self.velocity = self.velocity + self.mVec:normalized() * self.powerlevel
	self.velocity = self.velocity - 0.0001*self.velocity*self.velocity:len()
	self.position = self.position + self.velocity * dt

	if self.creature then
		self.creature.body.rotation = self.mVec:angleTo()
		self.creature.body:updatePosition(self.position)
		self.creature:update(dt)
	end
end

function Player:spawn()
	self:onSpawn()
end

function Player:move(vec)
	--self.newSpeed = vec:len() * self.stats.speed * 100
	--self.newDirection = vec:angleTo()
	self.mVecNew = vec * self.stats.agility
end

function Player:updateMovement(dt)
	if self.mVec:len() == 0 then
		self.mVec.x = math.random()
		self.mVec.y = math.random()
	end
	dirVec = self.mVec:normalized() + self.mVecNew*dt
	self.mVec = self.mVec:len() * dirVec:normalized()
	self.powerlevel = math.max(0, dirVec * self.mVecNew) * self.stats.speed
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
		if not self.stats.speed or self.stats.speed < 0 then
			self.stats.speed = 0
		end
		if not self.stats.agility or self.stats.agility < 0 then
			self.stats.agility = 0
		end
	end
end


OwnPlayer = Class{__includes=Player}