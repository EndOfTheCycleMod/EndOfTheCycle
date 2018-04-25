class EC_StrategyTurnPhaseTemplate extends EC_StrategyElementTemplate;

var class<EC_GameState_StrategyTurnPhase> TurnPhaseClass;

var bool NeedsPlayerEndPhase;

delegate ProcessTurnPhaseDelegate(StateObjectReference PhaseRef, out array<ECPotentialTurnPhaseAction> PotentialActions, ECTurnPhaseStep Step);

function ProcessTurnPhase(StateObjectReference PhaseRef, out array<ECPotentialTurnPhaseAction> PotentialActions, ECTurnPhaseStep Step)
{
	if (ProcessTurnPhaseDelegate != none)
	{
		ProcessTurnPhaseDelegate(PhaseRef, PotentialActions, Step);
	}
}

function EC_GameState_StrategyTurnPhase CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local EC_GameState_StrategyTurnPhase Phase;

	Phase = EC_GameState_StrategyTurnPhase(NewGameState.CreateNewStateObject(TurnPhaseClass, self));

	return Phase;
}

defaultproperties
{
	TurnPhaseClass=class'EC_Engine.EC_GameState_StrategyTurnPhase'
}