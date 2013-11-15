Team = { }

Team.Create = function(actors)
	local team = { }
	team.Actors = actors
	team.OnKilled = { }
	Team._AddActorEventHandlers(team)
	return team
end

Team._AddActorEventHandlers = function(team)
	for i, actor in ipairs(team.Actors) do
	
		Actor.AddKilledEventHandler(actor, function()
			if Team.IsDead(team) then
				for i, handler in ipairs(team.OnKilled) do
					handler()
				end
			end
		end)
		
	end
end

Team.IsDead = function(team)
	for i, actor in ipairs(team.Actors) do
		if not Actor.IsDead(actor) then
			return false
		end
	end
	return true
end

Team.AddKilledEventHandler = function(team, func)
	table.insert(team.OnKilled, func)
end

Team.Contains = function(team, actor)
	for i, a in ipairs(team.Actors) do
		if a == actor then
			return true
		end
	end
	return false
end

Team.Do = function(team, func)
	for i, actor in ipairs(team.Actors) do
		func(actor)
	end
end