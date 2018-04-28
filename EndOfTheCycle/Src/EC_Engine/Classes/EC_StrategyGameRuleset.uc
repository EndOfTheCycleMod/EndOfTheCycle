// Game Ruleset class that provides the strategy turn logic. Is a state machine driven by the states provided as TurnPhase templates
class EC_StrategyGameRuleSet extends X2GameRuleset config(ECTurnLogic) dependson(EC_StrategyDataStructures);

// for each player, set up these turn phases
var config array<name> PlayerTurnOrder;
var config array<name> DefaultTurnPhases;


// cached result with pseudo-actions. reset when any game state is submitted
var transient ECTurnPhaseProcessResult CachedTurnPhaseResult;
// Kept in sync with EC_GameState_PersistentTurnData
var transient protectedwrite StateObjectReference CurrentPlayer;
var transient protectedwrite StateObjectReference CurrentTurnPhase;



var transient bool isReady;

/// <summary>
/// Called by the tactical game start up process when a new battle is starting
/// </summary>
simulated function StartNewGame()
{
	super.StartNewGame();

	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();
	`log("STARTING GAME");
	GotoState('StartStrategyGame');
}

/// <summary>
/// Entry point for the rules engine if the map URL indicates this IS a loaded save game
/// </summary>
simulated function LoadGame()
{
	super.LoadGame();

	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();
	`log("LOADING GAME");
	GotoState('LoadStrategyGame');
}

/// <summary>
/// This event is called after a system adds a gamestate to the history, perhaps circumventing the ruleset itself.
/// </summary>
simulated event OnSubmitGameState()
{
	bWaitingForNewStates = false;
	CachedTurnPhaseResult = default.CachedTurnPhaseResult;
}

/// <summary>
/// Reponsible for verifying that a set of newly incoming game states obey the rules.
/// </summary>
simulated function bool ValidateIncomingGameStates()
{
	// TODO: Why is this function so useless?
	return true;
}

/// <summary>
/// Returns true if the visualizer is currently in the process of showing the last game state change
/// </summary>
simulated function bool WaitingForVisualizer()
{
	// Also catches latent game state builds
	return class'XComGameStateVisualizationMgr'.static.VisualizerBusy() || `XCOMVISUALIZATIONMGR.VisualizationTree != none;
}

/// <summary>
/// Expanded version of WaitingForVisualizer designed for the end of a unit turn. WaitingForVisualizer and EndOfTurnWaitingForVisualizer would ideally be consolidated, but
/// the potential for knock-on would be high as WaitingForVisualizer is used in many places for many different purposes.
/// </summary>
simulated function bool EndOfTurnWaitingForVisualizer()
{
	return !class'XComGameStateVisualizationMgr'.static.VisualizerIdleAndUpToDateWithHistory() || (`XCOMVISUALIZATIONMGR.VisualizationTree != none);
}


simulated function bool IsSavingAllowed()
{
	if (IsDoingLatentSubmission())
	{
		return false;
	}

	if (!IsInState('ProcessingActiveTurnPhase'))
	{
		return false;
	}

	return true;
}

simulated function bool WaitingForUserContinue()
{
	return bWaitingForNewStates && !BuildingLatentGameState;
}

/// <summary>
/// This method builds a local list of state object references for objects that are relatively static, and that we 
/// may need to access frequently. Using the cached ObjectID from a game state object reference is much faster than
/// searching for it each time we need to use it.
/// </summary>
simulated function BuildLocalStateObjectCache()
{
	local EC_GameState_PersistentTurnData Data;
	local Object ThisObj;
	super.BuildLocalStateObjectCache();
	
	CachedHistory = `XCOMHISTORY;
	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'EC_OnTurnDataUpdate', OnTurnDataChanged, ELD_OnStateSubmitted);

	Data = EC_GameState_PersistentTurnData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'EC_GameState_PersistentTurnData', false));
	CurrentPlayer = Data.CurrentPlayer;
	CurrentTurnPhase = Data.TurnPhase;

}

function EventListenerReturn OnTurnDataChanged(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local EC_GameState_PersistentTurnData Data;
	Data = EC_GameState_PersistentTurnData(EventData);
	CurrentPlayer = Data.CurrentPlayer;
	CurrentTurnPhase = Data.TurnPhase;
	return ELR_NoInterrupt;
}

// TODO: The map has important information that we may need to set up a proper start state
// Can we communicate this with InitGame, or do we better split that state?
state StartStrategyGame
{
Begin:
	PushState('InitGame');
	GotoState(GetNextState(GetStateName()));
}

state LoadStrategyGame
{
Begin:
	PushState('InitGame');
	GotoState(GetNextState(GetStateName()));
}

state InitGame
{

	function LoadMap()
	{
		local EC_GameState_CampaignSetupData SetupData;
		local class MapClass;
		SetupData = EC_GameState_CampaignSetupData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'EC_GameState_CampaignSetupData'));
		MapClass = class'Engine'.static.FindClassType(SetupData.StrategyMapActorClassPath);
		`ECGAME.Map = IEC_StrategyMap(Spawn(class<Actor>(MapClass)));
		`ECMAP.LoadMap();
	}
	
	function CreateDefaultPathfinder()
	{
		`ECGAME.DefaultPathfinder = new class'EC_DefaultUnitPathfinder';
		`ECGAME.DefaultPathfinder.Init(`ECMAP);
	}

	function bool MapLoading()
	{
		return !`ECMAP.IsLoaded();
	}

Begin:
	LoadMap();
	Sleep(1.0f);
	while (MapLoading())
	{
		Sleep(0.0f);
	}
	`XCOMVISUALIZATIONMGR.EnableBuildVisualization();
	`XCOMVISUALIZATIONMGR.OnJumpForwardInHistory();
	`XCOMVISUALIZATIONMGR.CheckStartBuildTree();

	CreateDefaultPathfinder();
	SyncVisualizers();
	Sleep(1.0f);

	`PRESBASE.UIStopMovie();
	`PRESBASE.HideLoadingScreen();
	class'WorldInfo'.static.GetWorldInfo().MyLocalEnvMapManager.SetEnableCaptures(true);
	XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).bProcessedTravelDestinationLoaded = true;
	class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(false);
	`ECCAMSTACK.AddCamera(`ECMAP.CreateDefaultCamera());
	`ECMAP.GetFOWVisualizer().InitResources();

	isReady = true;
	PopState();

}

static function SyncVisualizers()
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject Entity;

	History = `XCOMHISTORY;
	
	foreach History.IterateByClassType(class'XComGameState_BaseObject', Entity)
	{
		if (IEC_StrategyWorldEntity(Entity) != none)
		{
			IEC_StrategyWorldEntity(Entity).Ent_FindOrCreateVisualizer();
		}
	}

	foreach History.IterateByClassType(class'XComGameState_BaseObject', Entity)
	{
		if (IEC_StrategyWorldEntity(Entity) != none)
		{
			IEC_StrategyWorldEntity(Entity).Ent_SyncVisualizer();
		}
	}
}


// Whenever we end up waiting for new states, the current turn phase has a list of pseudo-actions that still need to be done
// We notify the player visualizer about this, and generally, it stores them and then tells the player what still needs to be done
// whenever they run an action (submit a game state), we try to process the turn again, which in turn may return potential actions
// This is a bit similar to how ActionsAvailable() works in the tactical logic, but it's more integrated into the strategy rules here

// State that advances the turn phases, or, if needed, cycles through players, sets up new turn phases, ...
state Rollover
{
	function DoRollover()
	{
		local EC_GameState_PersistentTurnData Data;
		local EC_GameStateContext_StrategyGameRule Context;

		Data = EC_GameState_PersistentTurnData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'EC_GameState_PersistentTurnData', false));
		if (NeedsPlayerRollover(Data))
		{
			Context = EC_GameStateContext_StrategyGameRule(class'EC_GameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
			Context.GameRuleType = eECStrategyGameRule_RolloverPlayers;
			SubmitGameStateContext(Context);

			Context = EC_GameStateContext_StrategyGameRule(class'EC_GameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
			Context.GameRuleType = eECStrategyGameRule_SetupPlayerPhases;
			SubmitGameStateContext(Context);
		}
		else
		{
			Context = EC_GameStateContext_StrategyGameRule(class'EC_GameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
			Context.GameRuleType = eECStrategyGameRule_RolloverPhases;
			SubmitGameStateContext(Context);
		}
	}

	// Returns true if we need to advance the player index and set up a new turn
	function bool NeedsPlayerRollover(EC_GameState_PersistentTurnData Data)
	{
		local EC_GameState_StrategyTurnPhase TurnPhase;
		if (Data.TurnPhase.ObjectID <= 0)
		{
			return true;
		}
		else
		{
			TurnPhase = EC_GameState_StrategyTurnPhase(`XCOMHISTORY.GetGameStateForObjectID(Data.TurnPhase.ObjectID));
			return TurnPhase.NextTurnPhase.ObjectID <= 0;
		}
	}

Begin:
	DoRollover();
	`log("Rollover");
	while(EndOfTurnWaitingForVisualizer())
	{
		Sleep(0.0f);
	}
	GotoState(GetNextState(GetStateName()));
}

state BeginTurnPhase
{
	function BeginTurnPhase()
	{
		local EC_GameStateContext_StrategyGameRule Context;
		
		Context = EC_GameStateContext_StrategyGameRule(class'EC_GameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
		Context.GameRuleType = eECStrategyGameRule_TurnPhaseBegin;

		SubmitGameStateContext(Context);
	}
Begin:
	BeginTurnPhase();
	`log("BeginTurnPhase");
	while(EndOfTurnWaitingForVisualizer())
	{
		Sleep(0.0f);
	}
	GotoState(GetNextState(GetStateName()));
}


state ProcessingActiveTurnPhase
{
	// essentially X2TacticalGameRuleSet.state'TurnPhase_UnitActions'.ActionsAvailable except it does not only observe, but may make game state submissions
	function ECTurnPhaseProcessResult StepTurnPhase()
	{
		local ECTurnPhaseProcessResult LocalResult;
		
		bWaitingForNewStates = true;

		LocalResult = EC_GameState_StrategyTurnPhase(CachedHistory.GetGameStateForObjectID(CurrentTurnPhase.ObjectID)).ProcessTurnPhase();

		// We only wait for new states if we have available actions and the turn phase did not do any processing on its own
		// Any game state submission resets bWaitingForNewStates to false
		bWaitingForNewStates = bWaitingForNewStates && LocalResult.Type == eECTPPRT_ActionsAvailable;
		return LocalResult;
	}

Begin:
	do
	{
		// Wait for the visualizer before waiting for new states
		while(EndOfTurnWaitingForVisualizer())
		{
			Sleep(0.0f);
		}
		// if actions are available, wait
		while (WaitingForUserContinue())
		{
			Sleep(0.0f);
		}
		// Process turn phase
		CachedTurnPhaseResult = StepTurnPhase();
	} until(CachedTurnPhaseResult.Type == eECTPPRT_End);
	while(EndOfTurnWaitingForVisualizer())
	{
		Sleep(0.0f);
	}
	GotoState(GetNextState(GetStateName()));
}

state EndTurnPhase
{
	function EndTurnPhase()
	{
		local EC_GameStateContext_StrategyGameRule Context;
		
		Context = EC_GameStateContext_StrategyGameRule(class'EC_GameStateContext_StrategyGameRule'.static.CreateXComGameStateContext());
		Context.GameRuleType = eECStrategyGameRule_TurnPhaseEnd;

		SubmitGameStateContext(Context);
	}

Begin:
	EndTurnPhase();
	while(EndOfTurnWaitingForVisualizer())
	{
		Sleep(0.0f);
	}
	GotoState(GetNextState(GetStateName()));
}


simulated function name GetNextState(name CurrentState, optional name DefaultPhaseName='ProcessingActiveTurnPhase')
{
	switch (CurrentState)
	{
		// It is important that saved games always are made when this actor is in the 'ProcessingActiveTurnPhase' state
		// As entering or leaving Begin- / EndTurnPhase states may have side effects
		case 'LoadStrategyGame':
			return 'ProcessingActiveTurnPhase';
		case 'StartStrategyGame':
			return 'Rollover';
		case 'Rollover':
			return 'BeginTurnPhase';
		case 'BeginTurnPhase':		
			return 'ProcessingActiveTurnPhase';
		case 'ProcessingActiveTurnPhase':
			return 'EndTurnPhase';
		case 'EndTurnPhase':
			return 'Rollover';
	}
	`assert(false);
	return DefaultPhaseName;
}


simulated function array<ECPotentialTurnPhaseAction> GetActionsForPlayer(StateObjectReference Player)
{
	local array<ECPotentialTurnPhaseAction> Actions;
	local int i;

	for (i = 0; i < CachedTurnPhaseResult.PotentialActions.Length; i++)
	{
		if (CachedTurnPhaseResult.PotentialActions[i].Player.ObjectID == Player.ObjectID)
		{
			Actions.AddItem(CachedTurnPhaseResult.PotentialActions[i]);
		}
	}
	return Actions;
}


// Make modifications to the strategy start state to get a campaign rolling
static function SetupGameStartState(XComGameState StartState)
{
	local EC_GameState_PersistentTurnData TurnData;
	local array<EC_StrategyElementTemplate> Templates;
	local EC_StrategyElementTemplate Template;
	local EC_GameState_StrategyPlayer PlayerState;

	TurnData = EC_GameState_PersistentTurnData(StartState.CreateNewStateObject(class'EC_GameState_PersistentTurnData'));
	
	Templates = class'EC_StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager()
	                .GetAllTemplatesOfClass(class'EC_StrategyPlayerTemplate');

	foreach Templates(Template)
	{
		PlayerState = EC_StrategyPlayerTemplate(Template).CreateInstanceFromTemplate(StartState);
		TurnData.Players.AddItem(PlayerState.GetReference());
	}
	TurnData.PlayerIndex = -1;
}





simulated function DrawDebugLabel(Canvas kCanvas)
{
	local string kStr;
	local int iX, iY;
	local ECPotentialTurnPhaseAction Action;
	local EC_GameState_StrategyPlayer Player;
	local int Tile;
	local IEC_StrategyMap Map;
	
	iX=250;
	iY=50;
	Player = EC_GameState_StrategyPlayer(`XCOMHISTORY.GetGameStateForObjectID(CurrentPlayer.ObjectID));

	kStr =      "=========================================================================================\n";
	kStr = kStr$"Rules Engine (State"@GetStateName()@")\n";
	kStr = kStr$"=========================================================================================\n";	
	kStr = kStr$"\n";
	kStr = kStr$"Current Player:" @ Player.GetMyTemplateName() $"\n";
	kStr = kStr$"\n";
	kStr = kStr$"Cached Result:\n";
	foreach CachedTurnPhaseResult.PotentialActions(Action)
	{
		kStr = kStr$"    "$Action.DebugString$"\n";
	}

	Map = `ECMAP;
	if (Map != none)
	{
		Tile = Map.GetCursorHighlightedTile();
		if (Tile >= 0)
		{
			kStr = kStr $ Map.GetPositionDebugInfo(Tile) $ "\n";
		}
		else
		{
			kStr = kStr$"No tile highlighted\n";
		}
	}

	kCanvas.SetPos(iX, iY);
	kCanvas.SetDrawColor(0,255,0);
	kCanvas.DrawText(kStr);


}

simulated event Tick(float DeltaTime)
{
	local vector Pos;
	local rotator Rot;
	local int Tile;

	Tile = `ECMAP.GetCursorHighlightedTile();
	if (Tile >= 0)
	{
		`ECMAP.GetWorldPositionAndRotation(Tile, Pos, Rot);
		`ECSHAPES.DrawSphere(Pos, vect(15,15,15), MakeLinearColor(0,0,1,1), false);
	}
	`ECSHAPES.DrawSphere(vect(0,0,10), vect(45,45,45), MakeLinearColor(0,0,1,1), false);
}