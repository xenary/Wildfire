-- Wildfire by Xenary
-- https://github.com/xenary

require "/scripts/vec2.lua"

function init()
	rng = sb.makeRandomSource()
	timer = rng:randf(0.5, 1.5)
	originalTimer = timer
	pos = entity.position()
	mcontroller.setRotation(-math.pi / 2)
end

function spreadFire(radius)
	local tileList = {}
	local tQ = world.radialTileQuery(pos, radius, "background")
	local _ = 1
	if #tQ ~= 0 then
		for k, v in pairs(tQ) do
			local tilePos = vec2.add(v, { 0.5, 0.5 } )
			if isFlammableTile(tilePos, "background", false) and isValidSpawnPos(tilePos) then
				tileList[_] = tilePos
				_ = _ + 1
			elseif isFlammableMod(tilePos, "background") and isValidSpawnPos(vec2.add(tilePos, { 0, 1 } )) then
				tileList[_] = vec2.add(tilePos, { 0, 1 } )
				_ = _ + 1
			end
		end
	end
	tQ = world.radialTileQuery(pos, radius, "foreground")
	if #tQ ~= 0 then
		for k, v in pairs(tQ) do
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
	if #tileList > 0 then
		local _ = rng:randInt(1, #tileList)
		world.spawnProjectile("wfflame", tileList[_])
		if projectile.getParameter("projectileName") == "flamethrower" or projectile.getParameter("projectileName") == "molotovflame" then
			projectile.die()
		end
	end
end

function isValidSpawnPos(tilePos)
	local eQ = world.entityQuery(tilePos, 2, { includedTypes = { "projectile" }, boundMode = "position" } )
	if #eQ > 0 then
		for k, v in pairs(eQ) do
			if (world.entityName(v) == "wfflame" and world.magnitude(world.entityPosition(v), tilePos) < 0.5) or (world.entityName(v) == "wfflame2" and world.magnitude(world.entityPosition(v), tilePos) < 1.5) then
				return false
			end
		end
	end
	return true
end

function isFlammableTile(tilePos, layer, returnMatConfig)
	if world.material(tilePos, layer) ~= nil and world.material(tilePos, layer) ~= false then
		local matConfig = root.materialConfig(world.material(tilePos, layer))
		if not world.isTileProtected(tilePos) and matConfig ~= nil then
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
		return true
	else
		return false
	end
end

function createBurnList(occupiedPosList, layer, withMatName)
	local burnList = {}
	local _ = 1
	if withMatName then
		for k, v in pairs(occupiedPosList) do
			local vMatConfig = isFlammableTile(v, layer, true)
			if vMatConfig ~= false then
				burnList[_] = v
				burnList[_ + 1] = vMatConfig.config.materialName
				_ = _ + 2
			end
			if isFlammableMod(vec2.add(v, { 0, -1 } ), layer) then
				world.placeMod(vec2.add(v, { 0, -1 } ), layer, "charredgrass", nil, true)
			end
		end
	else
		for k, v in pairs(occupiedPosList) do
			if isFlammableTile(v, layer, false) then
				burnList[_] = v
				_ = _ + 1
			end
			if isFlammableMod(vec2.add(v, { 0, -1 } ), layer) then
				world.placeMod(vec2.add(v, { 0, -1 } ), layer, "charredgrass", nil, true)
			end
		end
	end
	return burnList
end

function replaceBurnedBlocks(burnList, layer)
	if #burnList ~= 0 then
		for k = 1, #burnList, 2 do
			local kMatConfig = root.materialConfig(burnList[k + 1])
			if ((kMatConfig.config.footstepSound == "/sfx/blocks/footstep_lightwood.ogg" or kMatConfig.config.footstepSound == "/sfx/blocks/footstep_wood.ogg")
			and not (kMatConfig.config.materialName == "shojiscreenpanel"
			or kMatConfig.config.materialName == "bookpiles"
			or kMatConfig.config.materialName == "coconutblock"
			or kMatConfig.config.materialName == "bamboo"
			or kMatConfig.config.materialName == "neonblock")
			and (not kMatConfig.config.renderParameters.lightTransparent or kMatConfig.config.collisionKind == "platform"))
			then
				local _ = rng:randInt(1, 5)
				if _ <= 4 then
					if kMatConfig.config.collisionKind == "platform" then
						world.placeMaterial(burnList[k], layer, "burnedplatform", nil, true)
					else
						world.placeMaterial(burnList[k], layer, "burnedwood", nil, true)
					end
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
	local eQ = world.entityQuery(queryPos, 0.5, { includedTypes = { "projectile" }, withoutEntityId = entity.id(), boundMode = "position" } )
	if #eQ ~= 0 then
		for k, v in pairs(eQ) do
			if world.entityName(v) == "wfflame" then
				local eQ = world.entityQuery(spawnPos, 1.5, { includedTypes = { "projectile" }, withoutEntityId = entity.id(), boundMode = "position" } )
				if #eQ ~= 0 then
					for k, v in pairs(eQ) do
						if v ~= nil and world.entityName(v) == "wfflame2" then
							return false
						end
					end
					for k, v in pairs(eQ) do
						if v ~= nil and world.entityName(v) == "wfflame" and world.callScriptedEntity(v, "projectile.timeToLive") > 0 then
							world.callScriptedEntity(v, "projectile.die")
						end
					end
				end
				world.callScriptedEntity(v, "projectile.die")
				world.spawnProjectile("wfflame2", spawnPos, nil, nil, nil, { timeToLive = projectile.timeToLive() } )
				projectile.die()
				return true
			end
		end
	elseif direction == nil then
		checkMergeCandidate("left")
	end
end

function update(dt)
	if projectile.timeToLive() == 0 then
		return
	end
	if placeBgBlocks then
		replaceBurnedBlocks(burnListBgWithNames, "background")
		projectile.die()
		script.setUpdateDelta(30)
		return
	end
	if placeFgBlocks then
		replaceBurnedBlocks(burnListFgWithNames, "foreground")
		placeBgBlocks = true
		return
	end
	local occupiedPosList = {}
	if world.entityName(entity.id()) == "wfflame" then
		occupiedPosList[1] = vec2.add(pos, { -0.5, -0.5 } )
	elseif world.entityName(entity.id()) == "wfflame2" then
		occupiedPosList[1] = pos
		occupiedPosList[2] = vec2.add(pos, { -1, 0 } )
		occupiedPosList[3] = vec2.add(pos, { -1, -1 } )
		occupiedPosList[4] = vec2.add(pos, { 0, -1 } )
	end
	local isFloating = true
	for k, v in pairs(occupiedPosList) do
		if isFlammableTile(v, "foreground", false) or isFlammableTile(v, "background", false)
		then
			isFloating = false
		end
	end
	if isFloating and (projectile.getParameter("projectileName") == "wfflame" and (isFlammableMod(vec2.add(pos, { 0, -1 } ), "foreground") or isFlammableMod(vec2.add(pos, { 0, -1 } ), "background")))
	or (projectile.getParameter("projectileName") == "wfflame2" and (isFlammableMod(vec2.add(occupiedPosList[3], { 0, -1 } ), "foreground") or isFlammableMod(vec2.add(occupiedPosList[3], { 0, -1 } ), "background")
	or isFlammableMod(vec2.add(occupiedPosList[4], { 0, -1 } ), "foreground") or isFlammableMod(vec2.add(occupiedPosList[4], { 0, -1 } ), "background"))) then
		isFloating = false
	end
	if isFloating then
		projectile.die()
		return
	end
	if projectile.timeToLive() <= 0.5 then
		local burnListFg = createBurnList(occupiedPosList, "foreground", false)
		local burnListBg = createBurnList(occupiedPosList, "background", false)
		burnListFgWithNames = createBurnList(occupiedPosList, "foreground", true)
		burnListBgWithNames = createBurnList(occupiedPosList, "background", true)
		world.damageTiles(burnListFg, "foreground", pos, "explosive", 999.0, 0)
		world.damageTiles(burnListBg, "background", pos, "explosive", 999.0, 0)
		placeFgBlocks = true
		script.setUpdateDelta(6)
		return
	end
	if world.entityName(entity.id()) == "wfflame" and checkMergeCandidate() then
		return
	end
	timer = math.max(0, timer - dt)
	if timer <= 0 then
		local _ = rng:randInt(1, 2)
		if _ == 2 then
			if world.entityName(entity.id()) == "wfflame" then
				spreadFire(2)
			elseif world.entityName(entity.id()) == "wfflame2" then
				spreadFire(2.5)
			end
		end
		timer = originalTimer
	end
end