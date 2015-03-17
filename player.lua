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
end

function Player:spawn()
	self:onSpawn()
end

function Player:move(x, y)

end