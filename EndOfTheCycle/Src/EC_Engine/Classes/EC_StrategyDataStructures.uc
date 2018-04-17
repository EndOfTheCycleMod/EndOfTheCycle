class EC_StrategyDataStructures extends Object;

// A turn phase needs to begin, then have any number of steps (the turn phase is in "step" while actions are available)
// After the turn phase returns _End, the finalize step is done, which may return _AA or _End. If _AA is returned, the turn phase is pushed back into
// "Step". An example of this is units with a queued path. We want the player to still be able to change the command in Step, so we run the pending
// path in Finalize and then evaluate if we still have actions left. If so, we move back to step until the player has moved all their units
enum ECTurnPhaseStep
{
	eECTPS_None,
	eECTPS_Step,
	eECTPS_Finalize,
};

enum ECTurnPhaseProcessResultType
{
	eECTPPRT_None,				// sentinel empty value
	eECTPPRT_ActionsAvailable,	// wait for user / game input. a list of available pseudo-actions is provided, with reasons and references to the things requiring user input
	eECTPPRT_End				// end this turn phase.
};

// A potential action is one of these -- if it's truly optional, we don't really want to show it at all
enum ECPotentialTurnPhaseActionType
{
	eECPTPAT_Optional, 	// This action *can* but really shouldn't be skipped (choosing new research, moving units: can be skipped (timeout?), but we want the player to always have do it)
	eECPTPAT_Required 	// This action cannnot be skipped and must be resolved before continuing the turn (ex: pending battle)
};

struct ECPotentialTurnPhaseAction
{
	var ECPotentialTurnPhaseActionType Type;
	var StateObjectReference Source;
	var StateObjectReference Player;

	// Appearance
	var string DisplayName;
	var bool bExtended;
	var LinearColor Color; // if bExtended
	var string ImagePath;  // if bExtended

	// when UI decides to show the user where the "thing" needs to be done, trigger this event
	// with Source as Data and Source
	var name EventName;

	var string DebugString;
};

struct ECTurnPhaseProcessResult
{
	var ECTurnPhaseProcessResultType Type;
	// for eECTPPRT_ActionsAvailable
	var array<ECPotentialTurnPhaseAction> PotentialActions;
};