class EC_StrategyGame extends XComGameInfo;

var IEC_StrategyMap Map;


// GameInfo Interface
function StartMatch()
{
	local bool bStandardLoad;
	local XComOnlineEventMgr OnlineEventMgr;

	super.StartMatch();
	`log("######## StartMatch ########");

	// Ensure that the player has the correct rich presence
	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetOnlineStatus();

	OnlineEventMgr = `ONLINEEVENTMGR;
	bStandardLoad = OnlineEventMgr.bPerformingStandardLoad;

	if (bStandardLoad) 
	{

		//We came from a load menu
		OnlineEventMgr.FinishLoadGame();			
		`GAMERULES.LoadGame();
	}	
	else 
	{
		if( `XCOMHISTORY.GetNumGameStates() < 1 )
		{
			// Create Start State
			class'EC_StrategyGame'.static.CreateStrategyStartState();
		}

		//We came from starting a new game
		`GAMERULES.StartNewGame();
	}
}

auto State PendingMatch
{
Begin:
	while (`PRESBASE.Get2DMovie().bIsInited)
	{
		Sleep(0.1f);
	}

	StartMatch();
End:
}

// TODO: Move
static function CreateStrategyStartState()
{
	local XComGameState NewGameState;
	local IEC_StrategyMap Map;

	NewGameState = class'EC_GameStateContext_StartStateChangeContainer'.static.CreateChangeState("Create New Strategy Start");

	// TODO:
	Map = IEC_StrategyMap(`CONTENT.RequestGameArchetype("EC_Framework.Default__EC_DynamicTiledMap"));
	Map.CreateRandomMap(NewGameState);

	class'EC_StrategyGameRuleset'.static.SetupGameStartState(NewGameState);

	`XCOMHISTORY.AddGameStateToHistory(NewGameState);
}

// XComGameInfo interface

simulated function class<X2GameRuleset> GetGameRulesetClass()
{
	return class'EC_StrategyGameRuleset';
}

function string GetSavedGameDescription()
{
	return "END OF THE CYCLE STRATEGY SAVE";
}
function string GetSavedGameCommand()
{
	return "open Strategy_Root?game=EC_Engine.EC_StrategyGame";
}
// Returns the map name used to resolve the image for the save game preview.
// Needn't be a valid map name
function string GetSavedGameMapName()
{
	return "StrategyMap";
}




// EC_StrategyGame interface

simulated function IEC_StrategyMap GetOrCreateStrategyMap();



defaultproperties
{
	PlayerControllerClass=class'EC_StrategyController'
	DefaultPawnClass=class'XComGame.XComHeadquartersPawn'
}