require("parts.fin")

Part_SpeedyFin = Class{__includes=Part_Fin, name="Part_SpeedyFin"}

function Part_SpeedyFin:setUp()
	self.data.phase = 0
	self.data.speed = 1
	self.data.agility = 0.2
end

return Part_SpeedyFin