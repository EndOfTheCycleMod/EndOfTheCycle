class EC_GameState_UnitActionsSubsystem extends EC_GameState_StrategyTurnPhaseSubsystem;

function OnBeginTurnPhase(StateObjectReference TurnPhase, XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject O;
	local IEC_ActionInterface ActionO;
	
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_BaseObject', O)
	{
		ActionO = IEC_ActionInterface(O);
		if (ActionO != none)
		{
			ActionO = IEC_ActionInterface(NewGameState.ModifyStateObject(O.Class, O.ObjectID));
			ActionO.Act_SetupActionsForBeginTurn(NewGameState, `ECRULES.CurrentPlayer);
			`log("Set up begin turn actions");
		}
	}
}

function OnEndTurnPhase(StateObjectReference TurnPhase, XComGameState NewGameState)
{

}

function PostProcessTurnPhase(StateObjectReference PhaseRef, out array<ECPotentialTurnPhaseAction> PotentialActions, ECTurnPhaseStep Step)
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject O;
	local IEC_ActionInterface ActionO;
	local array<ECPotentialTurnPhaseAction> LocalActions;
	local int i;
	local bool PerformActions;
	History = `XCOMHISTORY;

	// If we want to finalize, ask all entities to perform
	// their queued actions
	// Warning: If we don't catch some actions here, it's possible that the actions
	// leak over to the next player! TODO: Maybe we need to rewrite EC_GameState_StrategyTurnPhaseEnhanced
	// to actively notify it of any queued actions
	if (Step == eECTPS_Finalize)
	{
		PerformActions = true;
		while (PerformActions)
		{
			PerformActions = false;
			foreach History.IterateByClassType(class'XComGameState_BaseObject', O)
			{
				ActionO = IEC_ActionInterface(O);
				if (ActionO != none)
				{
					if (ActionO.Act_CanPerformQueuedActions(`ECRULES.CurrentPlayer))
					{
						PerformActions = true;
						ActionO.Act_PerformQueuedActions();
					}
				}
			}
		}
	}

	foreach History.IterateByClassType(class'XComGameState_BaseObject', O)
	{
		ActionO = IEC_ActionInterface(O);
		if (ActionO != none)
		{
			LocalActions.Length = 0;
			if (!ActionO.Act_CanPerformQueuedActions(`ECRULES.CurrentPlayer) && ActionO.Act_HasAvailableActions(LocalActions))
			{
				// We have actions available for a thing that doesn't have any queued actions
				for (i = 0; i < LocalActions.Length; i++)
				{
					PotentialActions.AddItem(LocalActions[i]);
				}
			}
		}
	}
}