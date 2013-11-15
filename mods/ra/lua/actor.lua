HasTraitInfo = function(actorType, className) return _OpenRA.HasTraitInfo(actorType, className) end
TraitInfoOrDefault = function(actorType, className) return _OpenRA.TraitInfoOrDefault(actorType, className) end
TraitInfo = function(actorType, className) return _OpenRA.TraitInfo(actorType, className) end

HasTrait = function(actor, className) return _OpenRA.HasTrait(actor, className) end
TraitOrDefault = function(actor, className) return _OpenRA.TraitOrDefault(actor, className) end
Trait = function(actor, className) return _OpenRA.Trait(actor, className) end

Actor = { }

Actor.Create = function(name, init)
	local td = New("TypeDictionary")
	local addToWorld = true
	for key, value in pairs(init) do
		if key == "AddToWorld" then
			addToWorld = value
		else
			td:Add(New(key .. "Init", { value }))
		end
	end
	return World:CreateActor(addToWorld, name, td)
end

Actor.Turn = function(actor, facing)
	actor:QueueActivity(New("Turn", { { facing, "Int32" } }))
end

Actor.Move = function(actor, location)
	actor:QueueActivity(New("Move", { location, Map.GetWRangeFromCells(0) }))
end

Actor.MoveNear = function(actor, location, nearEnough)
	actor:QueueActivity(New("Move", { location, Map.GetWRangeFromCells(nearEnough) }))
end

Actor.HeliFly = function(actor, position)
	actor:QueueActivity(New("HeliFly", { position }))
end

Actor.HeliLand = function(actor, requireSpace)
	actor:QueueActivity(New("HeliLand", { requireSpace }))
end

Actor.Hunt = function(actor)
	actor:QueueActivity(New("Hunt", { actor, false }))
end

Actor.HuntBlind = function(actor)
	actor:QueueActivity(New("Hunt", { actor, true }))
end

Actor.UnloadCargo = function(actor, unloadAll)
	actor:QueueActivity(New("UnloadCargo", { unloadAll }))
end

Actor.Harvest = function(actor)
	actor:QueueActivity(New("FindResources"))
end

Actor.Scatter = function(actor)
	local mobile = Trait(actor, "Mobile")
	mobile:Nudge(actor, actor, true)
end

Actor.Wait = function(actor, period)
	actor:QueueActivity(New("Wait", { { period, "Int32" } }))
end

Actor.WaitFor = function(actor, func)
	_OpenRA.WaitFor(actor, func)
end

Actor.CallFunc = function(actor, func)
	_OpenRA.CallFunc(actor, func)
end

Actor.RemoveSelf = function(actor)
	actor:QueueActivity(New("RemoveSelf"))
end

Actor.Stop = function(actor)
	actor:CancelActivity()
end

Actor.IsDead = function(actor)
	return _OpenRA.IsDead(actor)
end

Actor.IsInWorld = function(actor)
	return actor.IsInWorld
end

Actor.Owner = function(actor)
	return actor.Owner
end

Actor.AddKilledEventHandler = function(actor, func)
	_OpenRA.AddKilledEventHandler(actor, func)
end

Actor.AddAddedEventHandler = function(actor, func)
	_OpenRA.AddAddedEventHandler(actor, func)
end

Actor.AddRemovedEventHandler = function(actor, func)
	_OpenRA.AddRemovedEventHandler(actor, func)
end