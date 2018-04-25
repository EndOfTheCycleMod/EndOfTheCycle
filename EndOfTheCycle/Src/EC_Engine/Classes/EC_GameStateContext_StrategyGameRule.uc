class EC_GameStateContext_StrategyGameRule extends XComGameStateContext;

enum ECStrategyGameRuleStateChange
{
	eECStrategyGameRule_StrategyGameStart,
	eECStrategyGameRule_ReplaySync,
	eECStrategyGameRule_TurnPhaseBegin,
	eECStrategyGameRule_TurnPhaseEnd,
	eECStrategyGameRule_SetupPlayerPhases,
	eECStrategyGameRule_RolloverPlayers,
	eECStrategyGameRule_RolloverPhases,
};

// Input Context Start
var ECStrategyGameRuleStateChange GameRuleType;


// Result Context Start

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}


function XComGameState ContextBuildGameState()
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local EC_GameState_PersistentTurnData TurnData;
	local EC_GameState_StrategyTurnPhase Phase, PhaseIterator, UpdatedPhase;
	local EC_GameStateContext_StrategyGameRule NewContext;
	local EC_StrategyTurnPhaseTemplate TurnPhaseTemplate;
	local EC_StrategyElementTemplateManager StrategyElementTemplateManager;
	local name TurnPhaseTemplateName;

	History = `XCOMHISTORY;
	NewGameState = none;

	`log("ContextBuildGameState:" @ GetEnum(Enum'ECStrategyGameRuleStateChange', GameRuleType));

	switch(GameRuleType)
	{
		case eECStrategyGameRule_TurnPhaseEnd: 
			// Take the current turn phase and end it properly
			NewGameState = History.CreateNewGameState(true, self);
			TurnData = GetAndAddTurnData(NewGameState);
			Phase = EC_GameState_StrategyTurnPhase(NewGameState.ModifyStateObject(class'EC_GameState_StrategyTurnPhase', TurnData.TurnPhase.ObjectID));
			Phase.EndTurnPhase(NewGameState);
			break;
		case eECStrategyGameRule_TurnPhaseBegin: 
			// Take the current turn phase and begin it properly
			NewGameState = History.CreateNewGameState(true, self);
			NewContext = EC_GameStateContext_StrategyGameRule(NewGameState.GetContext());
			TurnData = GetAndAddTurnData(NewGameState);
			Phase = EC_GameState_StrategyTurnPhase(History.GetGameStateForObjectID(TurnData.TurnPhase.ObjectID));
			Phase = EC_GameState_StrategyTurnPhase(NewGameState.ModifyStateObject(class'EC_GameState_StrategyTurnPhase', TurnData.TurnPhase.ObjectID));
			Phase.BeginTurnPhase(NewGameState);
			break;
		case eECStrategyGameRule_SetupPlayerPhases:
			NewGameState = History.CreateNewGameState(true, self);
			NewContext = EC_GameStateContext_StrategyGameRule(NewGameState.GetContext());
			TurnData = GetAndAddTurnData(NewGameState);
			
			StrategyElementTemplateManager = class'EC_StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

			foreach class'EC_StrategyGameRuleset'.default.DefaultTurnPhases(TurnPhaseTemplateName)
			{
				TurnPhaseTemplate = EC_StrategyTurnPhaseTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate(TurnPhaseTemplateName));
				UpdatedPhase = TurnPhaseTemplate.CreateInstanceFromTemplate(NewGameState);
				if (Phase == none)
				{
					TurnData.TurnPhase = UpdatedPhase.GetReference();
				}
				else
				{
					Phase.NextTurnPhase = UpdatedPhase.GetReference();
				}
				Phase = UpdatedPhase;
			}
			break;
		case eECStrategyGameRule_RolloverPlayers:
			// Advance the player index and remove all old turn data
			NewGameState = History.CreateNewGameState(true, self);
			NewContext = EC_GameStateContext_StrategyGameRule(NewGameState.GetContext());
			TurnData = GetAndAddTurnData(NewGameState);
			foreach History.IterateByClassType(class'EC_GameState_StrategyTurnPhase', PhaseIterator)
			{
				UpdatedPhase = EC_GameState_StrategyTurnPhase(NewGameState.ModifyStateObject(class'EC_GameState_StrategyTurnPhase', PhaseIterator.ObjectID));
				UpdatedPhase.Cleanup(NewGameState);
				NewGameState.RemoveStateObject(UpdatedPhase.ObjectID);
			}
			TurnData.PlayerIndex = TurnData.PlayerIndex + 1;
			if (TurnData.PlayerIndex >= TurnData.Players.Length)
			{
				TurnData.PlayerIndex = 0;
			}
			TurnData.CurrentPlayer = TurnData.Players[TurnData.PlayerIndex];
			break;
		case eECStrategyGameRule_RolloverPhases:
			// Advance the turn phase
			NewGameState = History.CreateNewGameState(true, self);
			NewContext = EC_GameStateContext_StrategyGameRule(NewGameState.GetContext());
			TurnData = GetAndAddTurnData(NewGameState);
			Phase = EC_GameState_StrategyTurnPhase(History.GetGameStateForObjectID(TurnData.TurnPhase.ObjectID));
			TurnData.TurnPhase = Phase.NextTurnPhase;
			break;
		default:
			`assert(false);
	}

	return NewGameState;
}

static function EC_GameState_PersistentTurnData GetAndAddTurnData(XComGameState NewGameState)
{
	local EC_GameState_PersistentTurnData TurnData;

	TurnData = EC_GameState_PersistentTurnData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'EC_GameState_PersistentTurnData', false));
	TurnData = EC_GameState_PersistentTurnData(NewGameState.ModifyStateObject(class'EC_GameState_PersistentTurnData', TurnData.ObjectID));

	return TurnData;
}

function string VerboseDebugString()
{
	return "EC_GameStateContext_StrategyGameRule"$"::"$ GetEnum(Enum'ECStrategyGameRuleStateChange', self.GameRuleType);
}