class EC_GameState_UnitActionsSubsystem extends EC_GameState_StrategyTurnPhaseSubsystem;

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
				if (ActionO.Act_HasQueuedActions())
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
				// Continue with the loop -- we want to show the user all potential actions
			}
		}
	}
}