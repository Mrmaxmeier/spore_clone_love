Gamestate = require("hump.gamestate")
vector = require("hump.vector")
Camera = require("hump.camera")
Class = require("hump.class")
loveframes = require("loveframes")
lovebird = require("lovebird")
serpent = require("serpent")
require 'pl'

DEBUG_MODE = false

require("utils")
require("creature")
require("part")

require("creatureCreator")
require("cellStage")

ALL_PARTS = {}

function registerPart(part)
	table.insert(ALL_PARTS, part)
	print("registered", part.name)
end

require("parts.loadAll")

myJoystick = nil


function love.load()
	print("\aSWAG")

	Gamestate.registerEvents{'draw', 'update', 'quit', 'mousepressed',
							 'mousereleased', 'mousemoved', 'keypressed',
							 'textinput', 'joystickadded', 'joystickremoved'}
	Gamestate.switch(creatureCreator)

end

function love.update(dt)
	if DEBUG_MODE then
		lovebird.update() --horrible performance on windows?!
	end
end

function love.draw()
	love.window.setTitle("SporeClone (Kawaii-edition) "..love.timer.getFPS().. "FPS")
end


function love.keypressed( key, isrepeat )
	if key == "1" then
		Gamestate.switch(cellStage)
	end
	if key == "2" then
		Gamestate.switch(creatureCreator)
	end
end


function love.joystickadded(joystick)
	myJoystick = joystick
	print(joystick:getName().." added!")
end

function love.joystickremoved(joystick)
	print(joystick:getName().." removed!")
	if myJoystick ~= nil then
		if not myJoystick:isConnected() then
			myJoystick = nil
		end
	end
end