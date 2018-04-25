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
	History = `XCOMHISTORY;

	// If we want to finalize, ask all entities to perform
	// their queued actions
	if (Step == eECTPS_Finalize)
	{
		foreach History.IterateByClassType(class'XComGameState_BaseObject', O)
		{
			ActionO = IEC_ActionInterface(O);
			if (ActionO != none)
			{
				if (ActionO.Act_HasQueuedActions() && ActionO.Act_HasAvailableActions(LocalActions))
				{
					ActionO.Act_PerformQueuedActions();
					// We (should have) made a game state submission. We must stop this loop
					// and show the user the update state
					break;
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
			if (!ActionO.Act_HasQueuedActions() && ActionO.Act_HasAvailableActions(LocalActions))
			{
				// We have actions available for a thing that doesn't have any queued actions
				// Copy over the first one
				PotentialActions.AddItem(LocalActions[0]);
				`log("Has Queued Path!!");
				// Continue with the loop -- we want to show the user all potential actions
			}
		}
	}
}