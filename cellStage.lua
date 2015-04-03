cellStage = {}

require("player")

function cellStage:enter()
	ownPlayer = OwnPlayer()
	if creature then
		ownPlayer.creature = creature
	else
		ownPlayer.creature = generateCreature(1.0)
	end
	ownPlayer:updateStats()
	players = {ownPlayer}


	cam = Camera(0, 0)
	cam:zoomTo(1)
	cam:lookAt(ownPlayer.position:unpack())
	love.graphics.setBackgroundColor( 0, 0, 205 )
end

function cellStage:update(dt)
	mv = vector(0, 0)
	if love.keyboard.isDown("w") then mv.y = mv.y - 1 end
	if love.keyboard.isDown("a") then mv.x = mv.x - 1 end
	if love.keyboard.isDown("s") then mv.y = mv.y + 1 end
	if love.keyboard.isDown("d") then mv.x = mv.x + 1 end
	if myJoystick then
		mv.x = mv.x + myJoystick:getAxis(1)
		mv.y = mv.y + myJoystick:getAxis(2)
	end
	ownPlayer:move(mv)

	for i, player in ipairs(players) do
		player:update(dt, false)
	end
end

function cellStage:draw()
	cam:attach()
	for i, player in ipairs(players) do
		player:draw()
	end
	cam:detach()

	love.graphics.setColor(255, 255, 255)
	love.graphics.print("Speed: "..ownPlayer.stats.speed, 0, 0)
	love.graphics.print("Agility: "..ownPlayer.stats.agility, 0, 25)
end