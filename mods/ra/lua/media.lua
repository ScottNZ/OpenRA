Media = { }

Media.PlaySpeechNotification = function(player, notification)
	_OpenRA.PlaySpeechNotification(player, notification)
end

Media.PlaySoundNotification = function(player, notification)
	_OpenRA.PlaySoundNotification(player, notification)
end

Media.PlayRandomMusic = function()
	_OpenRA.PlayRandomMusic()
end

Media.PlayMovieFullscreen = function(movie, onComplete)
	if onComplete == nil then
		onComplete = function() end
	end
	_OpenRA.PlayMovieFullscreen(movie, onComplete)
end