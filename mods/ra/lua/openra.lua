New = function(className, args)
	return _OpenRA.New(className, args)
end

RunAfterDelay = function(delay, func)
	_OpenRA.RunAfterDelay(delay, func)
end

OpenRA = { }

OpenRA.Debug = function(obj)
	_OpenRA.Debug(obj)
end

OpenRA.CenterViewport = function(position)
	WorldRenderer.Viewport:Center(position)
end

OpenRA.ViewportCenterLocation = function(position)
	return WorldRenderer.Viewport.CenterLocation
end

OpenRA.Difficulty = function()
	return World.LobbyInfo.GlobalSettings.Difficulty
end

OpenRA.IsSinglePlayer = function()
	return World.LobbyInfo:get_IsSinglePlayer()
end

OpenRA.GetPlayer = function(internalName)
	return Utils.FirstOrNil(World.Players, function(p) return p.InternalName == internalName end)
end

OpenRA.SetWinState = function(player, winState)
	_OpenRA.SetWinState(player, winState)
end