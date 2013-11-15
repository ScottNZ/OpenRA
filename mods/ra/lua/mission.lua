Mission = { }

Mission.PerformHelicopterInsertion = function(owner, helicopterName, passengerNames, enterPosition, unloadPosition, exitPosition)
	local facing = { Map.GetFacing(WPos.op_Subtraction(unloadPosition, enterPosition), 0), "Int32" }
	local altitude = { TraitInfo(helicopterName, "AircraftInfo").CruiseAltitude, "Int32" }
	local heli = Actor.Create(helicopterName, { Owner = owner, CenterPosition = enterPosition, Facing = facing, Altitude = altitude })
	local cargo = Trait(heli, "Cargo")
	local passengers = { }
	for i, passengerName in ipairs(passengerNames) do
		local passenger = Actor.Create(passengerName, { AddToWorld = false, Owner = owner })
		cargo:Load(heli, passenger)
		passengers[i] = passenger
	end
	Actor.HeliFly(heli, unloadPosition)
	Actor.Turn(heli, 0)
	Actor.HeliLand(heli, true)
	Actor.UnloadCargo(heli, true)
	Actor.Wait(heli, 125)
	Actor.HeliFly(heli, exitPosition)
	Actor.RemoveSelf(heli)
	return heli, passengers
end

Mission.PerformHelicopterExtraction = function(owner, helicopterName, passengers, enterPosition, loadPosition, exitPosition)
	local facing = { Map.GetFacing(WPos.op_Subtraction(loadPosition, enterPosition), 0), "Int32" }
	local altitude = { TraitInfo(helicopterName, "AircraftInfo").CruiseAltitude, "Int32" }
	local heli = Actor.Create(helicopterName, { Owner = owner, CenterPosition = enterPosition, Facing = facing, Altitude = altitude })
	local cargo = Trait(heli, "Cargo")
	Actor.HeliFly(heli, loadPosition)
	Actor.Turn(heli, 0)
	Actor.HeliLand(heli, true)
	Actor.WaitFor(heli, function()
		for i, passenger in ipairs(passengers) do
			if not cargo.Passengers:Contains(passenger) then
				return false
			end
		end
		return true
	end)
	Actor.Wait(heli, 125)
	Actor.HeliFly(heli, exitPosition)
	Actor.RemoveSelf(heli)
	return heli
end

Mission.Reinforce = function(owner, reinforcementNames, enterLocation, rallyPointLocation, interval)
	local facing = { Map.GetFacing(CPos.op_Subtraction(rallyPointLocation, enterLocation), 0), "Int32" }
	for i = 1, #reinforcementNames do
		RunAfterDelay((i - 1) * interval, function()
			local reinforcement = Actor.Create(reinforcementNames[i], { Owner = owner, Location = enterLocation, Facing = facing })
			Actor.MoveNear(reinforcement, rallyPointLocation, 2)
		end)
	end
end

Mission.MissionOver = function(winners, losers, setWinStates)
	World:SetLocalPauseState(true)
	World:SetPauseLocked(true)
	if winners then
		for i, player in ipairs(winners) do
			Media.PlaySpeechNotification(player, "Win")
			if setWinStates then
				OpenRA.SetWinState(player, "Won")
			end
		end
	end
	if losers then
		for i, player in ipairs(losers) do
			Media.PlaySpeechNotification(player, "Lose")
			if setWinStates then
				OpenRA.SetWinState(player, "Lost")
			end
		end
	end
end

Mission.GetGroundAttackersOf = function(player)
	return Utils.Where(World.Actors, function(actor)
		return not Actor.IsDead(actor) and Actor.IsInWorld(actor) and Actor.Owner(actor) == player and HasTrait(actor, "AttackBase") and HasTrait(actor, "Mobile")
	end)
end
