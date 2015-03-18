function love.conf(t)
	print("conf")
	t.window.resizable = true
	t.identity = "SporeClone"
	t.version = "0.9.2"
	t.window.minwidth = 800
	t.window.minheight = 600
	t.window.icon = "icon.png"


	t.modules.audio         = false
	t.modules.event         = true
	t.modules.graphics      = true
	t.modules.image         = true
	t.modules.joystick      = true
	t.modules.keyboard      = true
	t.modules.math          = true
	t.modules.mouse         = true
	t.modules.physics       = false
	t.modules.sound         = true
	t.modules.system        = true
	t.modules.timer         = true
	t.modules.window        = true

	io.stdout:setvbuf("no")
end