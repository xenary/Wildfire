require "/scripts/wildfire.lua"

function init()
	script.setUpdateDelta(6)
	rng = sb.makeRandomSource()
	timer = 0.25
end

function update(dt)
	pos = entity.position()
	timer = math.max(0, timer - dt)
	if timer == 0 then
		if projectile.getParameter("projectileName") == "flamethrower" then
			local _ = rng:randInt(1, 20)
			if _ == 20 then
				spreadFire(1.5)
			end
		else
			spreadFire(1.5)
		end
	end
end