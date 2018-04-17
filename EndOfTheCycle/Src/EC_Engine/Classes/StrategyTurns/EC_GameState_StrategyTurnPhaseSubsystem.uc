// Subsystems exist within complex turn phases. They are not added by default to any turn phases and need to be added explicitely to
// any turn phases that it wants to handle. They are not cleaned up by default.
class EC_GameState_StrategyTurnPhaseSubsystem extends XComGameState_BaseObject;

// Do things, fill out actions. Actions filled out need to be independent of Step, only game state code may depend on that.
// However, actions may depend on game state code
function PostProcessTurnPhase(StateObjectReference PhaseRef, out array<ECPotentialTurnPhaseAction> PotentialActions, ECTurnPhaseStep Step, XComGameState NewGameState)
{

}