print("loading all parts")
--local path = love.filesystem.getWorkingDirectory() .. "/parts/"
--local parts = love.filesystem.getDirectoryItems(path)
-- TODO: load all parts dynamically
local parts = {"body", "speedyfin", "agilefin", "mouth", "eye"}
for i, v in ipairs(parts) do
	local part = require("parts."..v)
	registerPart(part)
end