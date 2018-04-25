class EC_StrategyTurnPhaseTemplate extends EC_StrategyElementTemplate;

var class<EC_GameState_StrategyTurnPhase> TurnPhaseClass;

var bool NeedsPlayerEndPhase;

delegate ProcessTurnPhaseDelegate(StateObjectReference PhaseRef, out array<ECPotentialTurnPhaseAction> PotentialActions, ECTurnPhaseStep Step);
delegate PostCreateInstanceFromTemplateDelegate(EC_GameState_StrategyTurnPhase Phase, XComGameState NewGameState);

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
	if (PostCreateInstanceFromTemplateDelegate != none)
	{
		PostCreateInstanceFromTemplateDelegate(Phase, NewGameState);
	}

	return Phase;
}

defaultproperties
{
	TurnPhaseClass=class'EC_Engine.EC_GameState_StrategyTurnPhase'
}