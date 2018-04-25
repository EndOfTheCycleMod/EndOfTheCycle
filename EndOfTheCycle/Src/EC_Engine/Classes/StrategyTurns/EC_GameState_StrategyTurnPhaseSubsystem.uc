// Subsystems exist within complex turn phases.
class EC_GameState_StrategyTurnPhaseSubsystem extends XComGameState_BaseObject abstract;

var StateObjectReference OwnerPhase;

function OnBeginTurnPhase(StateObjectReference TurnPhase, XComGameState NewGameState)
{

}

function OnEndTurnPhase(StateObjectReference TurnPhase, XComGameState NewGameState)
{

}

// Do things, fill out actions. Actions filled out need to be independent of Step, only game state code may depend on that.
// However, actions may depend on game state code
function PostProcessTurnPhase(StateObjectReference PhaseRef, out array<ECPotentialTurnPhaseAction> PotentialActions, ECTurnPhaseStep Step)
{

}