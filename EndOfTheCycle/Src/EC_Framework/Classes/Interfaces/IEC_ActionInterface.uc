// Interface for all Entities that want to perform actions
// per turn, such as pathing, fortifying, ...
// Used by the Actions Subsystem
interface IEC_ActionInterface;

// Whether this entity must still perform some actions before
// the turn can end (i.e. if Actions.Length > 0), Actions sorted by priority
// The Actions subsystem may transform those, for example only using the first one
function bool Act_HasAvailableActions(out array<ECPotentialTurnPhaseAction> Actions);
// Whether this entity has queued actions (whether PerformQueuedActions changes the game state)
function bool Act_CanPerformQueuedActions(StateObjectReference Player);
// If there's a queued path / healing / ... action, perform it
// May make game state submissions
function Act_PerformQueuedActions();

// Gain action points for beginning the current turn
function Act_SetupActionsForBeginTurn(XComGameState NewGameState, StateObjectReference Player);