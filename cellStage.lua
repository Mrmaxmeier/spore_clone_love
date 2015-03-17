cellStage = {}

require("player")

function cellStage:enter()
	-- body

	ownPlayer = OwnPlayer()
	ownPlayer.creature = generateCreature(1.0)
	players = {ownPlayer}


	cam = Camera(0, 0)
	cam:zoomTo(2)
	cam:lookAt(ownPlayer.position:unpack())
end

function cellStage:update(dt)
	-- body
	for i, v in ipairs(players) do
		v:update(dt)
	end
end

function cellStage:draw()
	cam:attach()
	for i, v in ipairs(players) do
		v:draw()
	end
	cam:detach()
end