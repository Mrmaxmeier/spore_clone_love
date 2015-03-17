cellStage = {}

require("player")

function cellStage:enter()
	-- body

	ownPlayer = OwnPlayer()
	players = {ownPlayer}
end

function cellStage:update(dt)
	-- body
	for i, v in ipairs(players) do
		v:update(dt)
	end
end