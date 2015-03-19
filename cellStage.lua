cellStage = {}

require("player")

function cellStage:enter()
	-- body

	ownPlayer = OwnPlayer()
	if creature then
		ownPlayer.creature = creature
	else
		ownPlayer.creature = generateCreature(1.0)
	end
	players = {ownPlayer}


	cam = Camera(0, 0)
	cam:zoomTo(2)
	cam:lookAt(ownPlayer.position:unpack())
end

function cellStage:update(dt)
	-- body
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
end