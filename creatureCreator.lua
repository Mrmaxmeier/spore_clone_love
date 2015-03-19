
creatureCreator = {}

function creatureCreator:enter()
	cam = Camera(0, 0)
	cam:zoomTo(2)
	if not creature then
		creature = generateCreature(1.0)
	end
	creature.body:updatePosition(vector(0, 0))
	cam:lookAt(creature.body.position:unpack())

	--print("Stats:")
	--pretty.dump(creature.body:getAllStats())

	love.graphics.setNewFont(30)


	sidebar = {}
	for i, v in ipairs(ALL_PARTS) do
		sidebar[i] = v()
	end

	editorSelected = nil
	partEditorFrame = loveframes.Create("frame")
	partEditorFrame:SetName("Part Editor")
	partEditorFrame:SetResizable(true)
	partEditorFrame:SetMinWidth(200):SetMinHeight(175):SetHeight(200)
	partEditorFrame:CenterWithinArea(love.graphics.getWidth() - 200, 35, 135, 200)
	partEditorFrame.OnClose = function (object)
		editorSelected = nil
		partEditorFrame:SetVisible(false)
		return false
	end
	partEditorFrame:SetVisible(false)
	mouseHandle = nil
	toolbar = self:createToolbar()
end

function creatureCreator:draw()
	sx = love.graphics.getWidth()
	sy = love.graphics.getHeight()

	--body:updatePosition(vector(sx*0.05, 0))

	--Swag
	--love.graphics.setColor(255, 255, 255)
	--love.graphics.draw(image, 0, 0, 0, 0.3, 0.3)
	love.graphics.setBackgroundColor( 0, 0, 205 )

	cam:attach()
	creature:draw()
	cam:detach()

	--HUD
	love.graphics.setColor(255, 255, 255)
	--love.graphics.print( "Editing: "..creature.name, 0, 0)
	--love.graphics.print( pretty.write(creature.stats), 0, 0)

	love.graphics.setColor(222, 255, 222, 127)
	love.graphics.rectangle("fill", 0, 0, sx/5, sy)
	for i, v in ipairs(sidebar) do
		v.position = vector(sx/10, i*sy/(#sidebar+1))
		v.size = 0.1 + sx/800 * 0.5
		v:draw()
	end

	if mouseHandle ~= nil then
		cam:attach()
		mouseHandle:draw()
		cam:detach()
	end


	loveframes.draw()

	if DEBUG_MODE then
		love.graphics.setColor(255, 255, 255)
		love.graphics.print("d", 0, 0)
	end
end

function creatureCreator:update(dt)
	loveframes.update(dt)
	--cam:zoom(1 + dt*0.1)
	creature:update(dt)
	creature.body:updatePosition(vector(0, 0))
	--body.rotation = love.timer.getTime()*0.1
	if love.keyboard.isDown("left")  then creature.body.rotation = creature.body.rotation - dt end
	if love.keyboard.isDown("right") then creature.body.rotation = creature.body.rotation + dt end

	for i, v in ipairs(sidebar) do
		v.isHighlighted = false
	end

	if not (editorSelected ~= nil and loveframes.util.GetCollisionCount() > 0) then
		res = self:sidebarSelected()
		if res then res.isHighlighted = true end
	end

	for i, v in ipairs(sidebar) do
		v:update(dt)
	end
end

function creatureCreator:mousepressed( x, y, mb )
	loveframes.mousepressed(x, y, mb)
	if mb == "wu" then cam:zoom(1.0 + 0.2) end
	if mb == "wd" then cam:zoom(1.0 - 0.2) end


	if mb == "l" then
		if mouseHandle == nil and not (editorSelected ~= nil and loveframes.util.GetCollisionCount() > 0) then
			-- search for parts
			res = creature:selectedPart()
			if res ~= nil then
				if res.parent ~= nil then
					mouseHandle = res:clone()
					if love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt") then
						--swag
					else
						res:detach()
						creature:partsChanged()
					end

					mouseHandle:updatePosition(vector(cam:mousepos()))
				end
			else
				res = creatureCreator:sidebarSelected()
				if res ~= nil then
					mouseHandle = res:clone()
					mouseHandle:updatePosition(vector(cam:mousepos()))
				end
			end
		end
	end

	if mb == "r" then
		if mouseHandle == nil then
			editorSelected = creature:selectedPart()
			if editorSelected ~= nil then
				while #(partEditorFrame:GetChildren()) > 0 do
					--ente
					for i,v in ipairs(partEditorFrame:GetChildren()) do
						v:Remove()
					end
				end
				if not partEditorFrame:GetVisible() then
					partEditorFrame:CenterWithinArea(love.graphics.getWidth() - 210, 35, 135, 200)
				end
				partEditorFrame:SetVisible(true)

				editorSelected:editorUI(partEditorFrame)
			else
				partEditorFrame:SetVisible(false)
			end
		end
	end
end

function creatureCreator:mousemoved(x, y, dx, dy)
	if mouseHandle ~= nil then
		--dragging a part over handles
		local p = nil
		local hI = nil
		local hPos = nil
		p, hI, hPos = creature:selectedHinge()
		if p ~= nil then
			mouseHandle:updatePosition(hPos)
		else
			mouseHandle:updatePosition(vector(cam:mousepos()))
		end
	end
end

function creatureCreator:mousereleased(x, y, mb)
	loveframes.mousereleased(x, y, mb)
	if mb == "l" then
		if mouseHandle ~= nil then
			p, hI, hPos = creature:selectedHinge()
			if p ~= nil then
				p:attach(mouseHandle, hI)
				creature:partsChanged()
			end
		end
		mouseHandle = nil
	end
end
function creatureCreator:keypressed(key)
	loveframes.keypressed(key)
	if key == "escape" then
		love.event.quit()
	end

	if key == "r" then
		creature = generateCreature(1.0)
	end

	if key == "d" then
		DEBUG_MODE = not DEBUG_MODE
	end
end

function creatureCreator:textinput(text)
	loveframes.textinput(text)
end

function creatureCreator:sidebarSelected()
	local absMPos = vector(love.mouse.getPosition())
	for i, v in ipairs(sidebar) do
		if absMPos.x < love.graphics.getWidth()/5 then
			if absMPos.y < (i) * love.graphics.getHeight()/(#sidebar) then
				if absMPos.y > (i-1) * love.graphics.getHeight()/(#sidebar) then
					return v
				end
			end
		end
	end
end


function creatureCreator:createToolbar()

	local width = love.graphics.getWidth()

	local toolbar = loveframes.Create("panel")
	toolbar:SetSize(width, 35)
	toolbar:SetPos(0, 0)

	toolbar.Update = function (obj)
		obj:SetSize(love.graphics.getWidth(), 35)
	end

	local info = loveframes.Create("text", toolbar)
	info:SetPos(5, 3)
	info:SetText("ESC to quit, r to generate random creature\nrightclick for part options")

	saveButton = loveframes.Create("button", toolbar)
	saveButton:SetPos(toolbar:GetWidth() - 105, 5)
	saveButton:SetSize(100, 25)
	saveButton:SetText("Save")
	saveButton.OnClick = function()
		local frame = loveframes.Create("frame")
		frame:SetName("Save / Cancel?")
		frame:SetSize(210, 130):Center():SetModal(true)
		local text = loveframes.Create("text", frame)
		text:SetText("Name: ")
		text:SetX(5):SetY(45)


		local doSave = function()
			creature:saveToDisk()
			frame:Remove()
		end

		local textinput = loveframes.Create("textinput", frame)
		textinput:SetPos(5 + 50, 40)
		textinput:SetWidth(210-60)
		textinput.OnEnter = function(object)
			doSave()
		end
		textinput.OnTextChanged = function(object, text)
			creature.name = object:GetText()
		end
		textinput:SetFocus(true)
		textinput:SetText(creature.name)

		local form = loveframes.Create("form", frame)
		form:SetPos(5, 75)
		form:SetSize(200, 130-(75+15))
		form:SetLayoutType("horizontal")
		local saveButt = loveframes.Create("button")
		saveButt:SetText("Save")
		saveButt:SetWidth((200/2) - 7)
		form:AddItem(saveButt)
		saveButt.OnClick = function(object)
			doSave()
		end
		local cancelButt = loveframes.Create("button")
		cancelButt:SetText("Cancel")
		cancelButt:SetWidth((200/2) - 7)
		cancelButt.OnClick = function(object)
			frame:Remove()
		end
		form:AddItem(cancelButt)
	end
	saveButton.Update = function (obj)
		obj:SetPos(love.graphics.getWidth() - 105, 5):SetSize(100, 25)
	end

	local creatureLoadList = loveframes.Create("multichoice", toolbar)
	creatureLoadList:SetPos(toolbar:GetWidth() - 250, 5)
	creatureLoadList:SetWidth(140)
	creatureLoadList:SetChoice("Load")
	creatureLoadList.OnChoiceSelected = function(object, choice)
		print("load", choice)
		if love.filesystem.exists("creatures/"..choice) then
			local file = love.filesystem.newFile("creatures/"..choice)
			file:open("r")
			local str = file:read()
			ok, copy = serpent.load(str)
			file:close()
			creature = loadCreature(copy)
			creature:partsChanged()
		end
	end
	creatureLoadList.Update = function (obj)
		obj:SetPos(love.graphics.getWidth() - 250, 5)
	end

	local oldmousePressed = creatureLoadList.mousepressed
	creatureLoadList.mousepressed = function (self, x, y, button)
		self:Clear()
		self:SetChoice("Load")

		if not love.filesystem.exists("creatures") then
			love.filesystem.createDirectory("creatures")
		end

		--insert all loadable creatures
		local files = love.filesystem.getDirectoryItems("creatures")
		for k, file in ipairs(files) do
			self:AddChoice(file)
		end

		--
		self:Sort()
		oldmousePressed(self, x, y, button)
	end
	return toolbar
end
