InsertionHelicopterType = "tran.insertion"
ExtractionHelicopterType = "tran.extraction"
JeepReinforcements = { "jeep", "jeep" }
JeepInterval = 50
JeepDelay = 125
TanyaType = "e7"
EinsteinType = "einstein"
FlareType = "flare"
Cruisers = { "ca", "ca", "ca", "ca" }
CruiserDelay = 250
CameraDelay = 125
CivilianWait = 150
BaseAlertDelay = 300

SendInsertionHelicopter = function()
	local heli, passengers = Mission.PerformHelicopterInsertion(player, InsertionHelicopterType, { TanyaType },
		InsertionEntry.CenterPosition, InsertionLZ.CenterPosition, InsertionEntry.CenterPosition)
	tanya = passengers[1]
	Actor.AddKilledEventHandler(tanya, TanyaKilled)
end

SendJeeps = function()
	Media.PlaySpeechNotification(nil, "ReinforcementsArrived")
	Mission.Reinforce(player, JeepReinforcements, InsertionEntry.Location, InsertionLZ.Location, JeepInterval)
end

RunInitialActivities = function()
	SendInsertionHelicopter()
	Actor.HuntBlind(Patrol1)
	Actor.HuntBlind(Patrol2)
	Actor.HuntBlind(Patrol3)
	Actor.HuntBlind(Patrol4)
	Actor.Harvest(Harvester)
	Team.Do(civiliansTeam, function(c)
		Actor.Wait(c, CivilianWait)
		Actor.Hunt(c)
	end)
end

LabGuardsKilled = function()
	CreateEinstein()
	
	Actor.Create(FlareType, { Owner = england, Location = ExtractionFlarePoint.Location })
	Media.PlaySpeechNotification(nil, "SignalFlareNorth")
	SendExtractionHelicopter()
	
	RunAfterDelay(BaseAlertDelay, function()
		local ussrUnits = Mission.GetGroundAttackersOf(ussr)
		for i, unit in ipairs(ussrUnits) do
			Actor.Hunt(unit)
		end
	end)
	
	RunAfterDelay(CruiserDelay, function()
		Media.PlaySpeechNotification(nil, "AlliedReinforcementsArrived")
		Actor.Create("camera", { Owner = player, Location = CruiserCameraPoint.Location })
		SendCruisers()
	end)
end

SendExtractionHelicopter = function()
	local heli = Mission.PerformHelicopterExtraction(player, ExtractionHelicopterType, { einstein },
		SouthReinforcementsPoint.CenterPosition, ExtractionLZ.CenterPosition, ExtractionExitPoint.CenterPosition)
	Actor.AddKilledEventHandler(heli, HelicopterDestroyed)
	Actor.AddRemovedEventHandler(heli, HelicopterExtractionCompleted)
end

HelicopterExtractionCompleted = function()
	MissionAccomplished()
end

SendCruisers = function()
	for i, cruiser in ipairs(Cruisers) do
		local ca = Actor.Create(cruiser, { Owner = england, Location = SouthReinforcementsPoint.Location })
		Actor.Move(ca, _G["CruiserPoint" .. i].Location)
	end
end

LabDestroyed = function(self, e)
	if not einstein then
		MissionFailed()
	end
end

EinsteinKilled = function(self, e)
	MissionFailed()
end

HelicopterDestroyed = function(self, e)
	MissionFailed()
end

TanyaKilled = function(self, e)
	MissionFailed()
end

OilPumpDestroyed = function(self, e)
	RunAfterDelay(JeepDelay, SendJeeps)
end

CreateEinstein = function()
	einstein = Actor.Create(EinsteinType, { Location = EinsteinSpawnPoint.Location, Owner = player })
	Actor.Scatter(einstein)
	Actor.AddKilledEventHandler(einstein, EinsteinKilled)
end

MissionAccomplished = function()
	Mission.MissionOver({ player }, nil, false)
	--Media.PlayMovieFullscreen("snowbomb.vqa", nil)
end

MissionFailed = function()
	Mission.MissionOver(nil, { player }, false)
	Media.PlayMovieFullscreen("bmap.vqa", nil)
end

WorldLoaded = function()
	OpenRA.CenterViewport(InsertionLZ.CenterPosition)
	
	player = OpenRA.GetPlayer("Greece")
	england = OpenRA.GetPlayer("England")
	ussr = OpenRA.GetPlayer("USSR")

	Actor.AddKilledEventHandler(Lab, LabDestroyed)
	Actor.AddKilledEventHandler(OilPump, OilPumpDestroyed)
	
	labGuardsTeam = Team.Create({ LabGuard1, LabGuard2, LabGuard3 })
	Team.AddKilledEventHandler(labGuardsTeam, LabGuardsKilled)
	
	civiliansTeam = Team.Create({ Civilian1, Civilian2 })
	
	RunInitialActivities()
	
	RunAfterDelay(CameraDelay, function() Actor.Create("camera", { Owner = player, Location = BaseCameraPoint.Location }) end)
	
	Media.PlayMovieFullscreen("ally1.vqa", function() Media.PlayMovieFullscreen("landing.vqa", Media.PlayRandomMusic) end)
end