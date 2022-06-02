-- Wildfire by Xenary
-- https://github.com/xenary

require "/scripts/vec2.lua"

function init()
	rng = sb.makeRandomSource()
	name = projectile.getParameter("projectileName")
	if name == "wildfire_flame" or name == "wildfire_flame2" then
		timer = rng:randf(0.5, 1.5)
		pos = entity.position()
		relatedPlantId = projectile.getParameter("relatedPlantId")
		fireStarterBonus = projectile.getParameter("fireStarterBonus")
	else
		timer = 0.25
	end
	originalTimer = timer
end

function spreadFire(radius)
	local tileList = {}
	local tileQuery = world.radialTileQuery(pos, radius, "background")
	local _ = 1
	if #tileQuery > 0 then
		for k, v in pairs(tileQuery) do
			local tilePos = vec2.add(v, { 0.5, 0.5 } )
			if (isFlammableTile(tilePos, "background", false) or (world.liquidAt(tilePos) and world.liquidAt(tilePos)[1] == 5)) and isValidSpawnPos(tilePos) then
				tileList[_] = tilePos
				_ = _ + 1
			elseif isFlammableMod(tilePos, "background") and isValidSpawnPos(vec2.add(tilePos, { 0, 1 } )) then
				tileList[_] = vec2.add(tilePos, { 0, 1 } )
				_ = _ + 1
			end
		end
	end
	tileQuery = world.radialTileQuery(pos, radius, "foreground")
	if #tileQuery > 0 then
		for k, v in pairs(tileQuery) do
			local tilePos = vec2.add(v, { 0.5, 0.5 } )
			if isFlammableTile(tilePos, "foreground", false) and isValidSpawnPos(tilePos) then
				tileList[_] = tilePos
				_ = _ + 1
			elseif isFlammableMod(tilePos, "foreground") and isValidSpawnPos(vec2.add(tilePos, { 0, 1 } )) then
				tileList[_] = vec2.add(tilePos, { 0, 1 } )
				_ = _ + 1
			end
		end
	end
	local plantQuery = world.entityQuery(pos, 40.0, { withoutEntityId = entity.id(), boundMode = "position", includedTypes = { "plant" } } )
	if #plantQuery > 0 then
		for k, v in pairs(plantQuery) do
			for k2, v2 in pairs(world.objectSpaces(v)) do
				local plantWorldSpace = vec2.add(world.entityPosition(v), v2)
				if world.magnitude(plantWorldSpace, pos) < 1.0 then
					local tilePos = vec2.add(plantWorldSpace, { 0.5, 0.5 } )
					if isValidSpawnPos(tilePos) then
						tileList[_] = { tilePos, v }
						_ = _ + 1
					end
				end
			end
		end
	end
	if #tileList > 0 then
		local _ = rng:randInt(1, #tileList)
		if projectile.getParameter("projectileName") == "molotovflame" then
			if type(tileList[_][1]) == "table" then
				world.spawnProjectile("wildfire_flame", tileList[_][1], nil, nil, nil, { relatedPlantId = tileList[_][2], fireStarterBonus = true } )
			else
				world.spawnProjectile("wildfire_flame", tileList[_], nil, nil, nil, { fireStarterBonus = true } )
			end
			projectile.die()
		else
			if type(tileList[_][1]) == "table" then
				world.spawnProjectile("wildfire_flame", tileList[_][1], nil, nil, nil, { relatedPlantId = tileList[_][2] } )
			else
				world.spawnProjectile("wildfire_flame", tileList[_])
			end
		end
	end
end

function isValidSpawnPos(tilePos)
	local entQuery = world.entityQuery(tilePos, 2, { includedTypes = { "projectile" }, boundMode = "position" } )
	if #entQuery > 0 then
		for k, v in pairs(entQuery) do
			if (world.entityName(v) == "wildfire_flame" and world.magnitude(world.entityPosition(v), tilePos) < 0.5) or (world.entityName(v) == "wildfire_flame2" and world.magnitude(world.entityPosition(v), tilePos) < 1.5) then
				return false
			end
		end
	end
	return true
end

function isFlammableTile(tilePos, layer, returnMatConfig)
	if world.material(tilePos, layer) then
		local matConfig = root.materialConfig(world.material(tilePos, layer))
		if not world.isTileProtected(tilePos) and matConfig then
			if string.find(matConfig.config.materialName, "snow") or string.find(matConfig.config.materialName, "ice") or string.find(matConfig.config.materialName, "frozen") or string.find(matConfig.config.materialName, "slush")
			or matConfig.config.materialName == "burnedwood"
			or matConfig.config.materialName == "burnedplatform"
			then
				return false
			elseif matConfig.config.damageTable == "/tiles/flammableDamage.config" or matConfig.config.footstepSound == "/sfx/blocks/footstep_wood.ogg" or matConfig.config.footstepSound == "/sfx/blocks/footstep_lightwood.ogg" then
				if returnMatConfig then
					return matConfig
				else
					return true
				end
			end
		end
	end
	return false
end

function isValidPos(tilePos, layer)
	if world.material(tilePos, layer) then
		local matConfig = root.materialConfig(world.material(tilePos, layer))
		if not world.isTileProtected(tilePos) and matConfig then
			if string.find(matConfig.config.materialName, "snow") or string.find(matConfig.config.materialName, "ice") or string.find(matConfig.config.materialName, "frozen") or string.find(matConfig.config.materialName, "slush")
			or matConfig.config.materialName == "burnedwood"
			or matConfig.config.materialName == "burnedplatform"
			then
				return false
			elseif matConfig.config.damageTable == "/tiles/flammableDamage.config" or matConfig.config.footstepSound == "/sfx/blocks/footstep_wood.ogg" or matConfig.config.footstepSound == "/sfx/blocks/footstep_lightwood.ogg" then
				if returnMatConfig then
					return matConfig
				else
					return true
				end
			end
		end
	end
	return false
end

function isFlammableMod(tilePos, layer)
	if string.find((world.mod(tilePos, layer) or ""), "grass") and world.mod(tilePos, layer) ~= "charredgrass" then
		return "grass"
	elseif string.find((world.mod(tilePos, layer) or ""), "tilled") then
		return "tilled"
	else
		return false
	end
end

function createBurnList(posList, layer)
	local burnList = {}
	local matConfigList = {}
	local _ = 1
	for k, v in pairs(posList) do
		local matConfig = isFlammableTile(v, layer, true)
		if matConfig then
			burnList[_] = v
			matConfigList[_] = matConfig
			_ = _ + 1
		end
		local nearbyMod = isFlammableMod(vec2.add(v, { 0, -1 } ), layer)
		if nearbyMod then
			if nearbyMod == "grass" then
				world.placeMod(vec2.add(v, { 0, -1 } ), layer, "charredgrass", nil, true)
			else
				local damageList = { vec2.add(v, { 0, -1 } ) }
				world.damageTiles(damageList, layer, pos, "tilling", 0.01, 0)
			end
		end
		if world.liquidAt(v) and world.liquidAt(v)[1] == 5 then
			world.destroyLiquid(v)
		end
	end
	return burnList, matConfigList
end

function replaceBurnedBlocks(burnList, matConfigList, layer)
	for k, v in pairs(matConfigList) do
		if ((v.config.footstepSound == "/sfx/blocks/footstep_lightwood.ogg" or v.config.footstepSound == "/sfx/blocks/footstep_wood.ogg")
		and not (v.config.materialName == "shojiscreenpanel"
		or v.config.materialName == "bookpiles"
		or v.config.materialName == "coconutblock"
		or v.config.materialName == "bamboo"
		or v.config.materialName == "neonblock")
		and (not v.config.renderParameters.lightTransparent or v.config.collisionKind == "platform"))
		then
			local _ = rng:randInt(1, 5)
			if _ <= 4 then
				if v.config.collisionKind == "platform" then
					world.placeMaterial(burnList[k], layer, "burnedplatform", nil, true)
				else
					world.placeMaterial(burnList[k], layer, "burnedwood", nil, true)
				end
			end
		end
	end
end

function checkMergeCandidate(direction)
	local spawnPos = {}
	local queryPos = {}
	if direction == "right" or direction == nil then
		queryPos = vec2.add(pos, { 1, 0 } )
		spawnPos = vec2.add(pos, { 0.5, 0.5 } )
	elseif direction == "left" then
		queryPos = vec2.add(pos, { -1, 0 } )
		spawnPos = vec2.add(pos, { -0.5, 0.5 } )
	end
	local entQuery = world.entityQuery(queryPos, 0.5, { includedTypes = { "projectile" }, withoutEntityId = entity.id(), boundMode = "position" } )
	if #entQuery > 0 then
		for k, v in pairs(entQuery) do
			if world.entityName(v) == "wildfire_flame" then
				local entQuery = world.entityQuery(spawnPos, 1.5, { includedTypes = { "projectile" }, withoutEntityId = entity.id(), boundMode = "position" } )
				if #entQuery > 0 then
					for k, v in pairs(entQuery) do
						if v ~= nil and world.entityName(v) == "wildfire_flame2" then
							return false
						end
					end
					for k, v in pairs(entQuery) do
						if v ~= nil and world.entityName(v) == "wildfire_flame" and world.callScriptedEntity(v, "projectile.timeToLive") > 0 then
							world.callScriptedEntity(v, "projectile.die")
						end
					end
				end
				world.spawnProjectile("wildfire_flame2", spawnPos, nil, nil, nil, { relatedPlantId = relatedPlantId, fireStarterBonus = fireStarterBonus } )
				world.callScriptedEntity(v, "projectile.die")
				projectile.die()
				return true
			end
		end
	elseif direction == nil then
		checkMergeCandidate("left")
	end
end

function update(dt)
	if name == "wildfire_flame" or name == "wildfire_flame2" then
		if projectile.timeToLive() == 0 then
			return
		end
		if placeFgBlocks then
			replaceBurnedBlocks(burnListFg, matConfigListFg, "foreground")
			placeFgBlocks = false
			if not placeBgBlocks then
				projectile.die()
			end
			return
		end
		if placeBgBlocks then
			replaceBurnedBlocks(burnListBg, matConfigListBg, "background")
			projectile.die()
			return
		end
		local posList = {}
		if name == "wildfire_flame" then
			posList[1] = vec2.add(pos, { -0.5, -0.5 } )
		else
			posList[1] = pos
			posList[2] = vec2.add(pos, { -1, 0 } )
			posList[3] = vec2.add(pos, { -1, -1 } )
			posList[4] = vec2.add(pos, { 0, -1 } )
		end
		local isFloating = true
		if relatedPlantId then
			local plantSpaces = world.objectSpaces(relatedPlantId)
			if plantSpaces then
				for k, v in pairs(plantSpaces) do
					plantSpaces[k] = vec2.add(v, world.entityPosition(relatedPlantId))
				end
				for k, v in pairs(posList) do
					for k2, v2 in pairs(plantSpaces) do
						if world.magnitude(v, v2) < 1.0 then
							isFloating = false
							break
						end
					end
					if not isFloating then
						break
					end
				end
			end
		end
		if isFloating then	
			for k, v in pairs(posList) do
				local liquidInfo = world.liquidAt(v)
				if liquidInfo and liquidInfo[1] ~= 2 and liquidInfo[1] ~= 5 then
					projectile.die()
					return
				elseif isFlammableTile(v, "foreground", false) or isFlammableTile(v, "background", false) or (liquidInfo and liquidInfo[1] == 5) then
					isFloating = false
					break
				end
			end
		end
		if isFloating and (name == "wildfire_flame" and (isFlammableMod(vec2.add(pos, { 0, -1 } ), "foreground") or isFlammableMod(vec2.add(pos, { 0, -1 } ), "background")))
		or (name == "wildfire_flame2" and (isFlammableMod(vec2.add(posList[3], { 0, -1 } ), "foreground") or isFlammableMod(vec2.add(posList[3], { 0, -1 } ), "background")
		or isFlammableMod(vec2.add(posList[4], { 0, -1 } ), "foreground") or isFlammableMod(vec2.add(posList[4], { 0, -1 } ), "background"))) then
			isFloating = false
		end
		if isFloating then
			projectile.die()
			return
		end
		if projectile.timeToLive() <= 0.5 then
			burnListFg, matConfigListFg = createBurnList(posList, "foreground")
			burnListBg, matConfigListBg = createBurnList(posList, "background")
			if #burnListFg > 0 then
				world.damageTiles(burnListFg, "foreground", pos, "explosive", 999.0, 0)
			end
			if #burnListBg > 0 then
				world.damageTiles(burnListBg, "background", pos, "explosive", 999.0, 0)
			end
			if relatedPlantId then
				local plantBurnList = {}
				local _ = 1
				for k, v in pairs(posList) do
					if not world.material(v, "foreground") then
						plantBurnList[_] = v
						_ = _ + 1
					end
				end
				world.damageTiles(plantBurnList, "foreground", pos, "explosive", 999.0, 0)
			end
			if #burnListFg > 0 then
				placeFgBlocks = true
			end
			if #burnListBg > 0 then
				placeBgBlocks = true
			end
			if placeFgBlocks or placeBgBlocks then
				script.setUpdateDelta(6)
			end
			return
		end
		if name == "wildfire_flame" and checkMergeCandidate() then
			return
		end
	else
		pos = entity.position()
		local liquidInfo = world.liquidAt(pos)
		if liquidInfo and liquidInfo[1] ~= 2 and liquidInfo[1] ~= 5 then
			projectile.die()
			return
		end
	end
	timer = math.max(0, timer - dt)
	if timer <= 0 then
		if name == "wildfire_flame" or name == "wildfire_flame2" then
			local _ = rng:randInt(1, 2)
			if _ == 2 or fireStarterBonus then
				if name == "wildfire_flame" then
					spreadFire(2)
				else
					spreadFire(2.5)
				end
			end
		else
			if name == "flamethrower" then
				local _ = rng:randInt(1, 40)
				if _ < 40 then
					return
				end
			end
			spreadFire(1.5)
		end
		timer = originalTimer
	end
end