// An enhanced turn phase with subsystems, capabilities to wait for user confirms, as well as subsystems
class EC_GameState_StrategyTurnPhaseEnhanced extends EC_GameState_StrategyTurnPhase;

var ECTurnPhaseStep Step;

// Subsystems are a way to make turn phases modular. For example, the "main" turn phase has a UnitActions subsystem that
// gives the player's units action points and prevents ending the turn until all units have received their instructions
// there might also be a Battle subsystem that blocks certain operations while a battle is pending -- it's far more restrictive
// EC_GameState_TurnPhaseSubsystem
var array<StateObjectReference> TurnPhaseSubsystems;

const UserRequestContinueEventName = 'EC_ConfirmContinue';

function OnCreation(optional X2DataTemplate Template)
{
	local Object ThisObj;

	super.OnCreation(Template);
	
	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, UserRequestContinueEventName, OnUserConfirmContinue, ELD_Immediate, , self, true);
}

function BeginTurnPhase(XComGameState NewGameState)
{
	super.BeginTurnPhase(NewGameState);
	Step = eECTPS_Step;
}


// if this function returns true, this phase cannot be ended automatically but NEEDS a user input
// (click on the continue button) after ProcessTurnPhase has returned eECTPPRT_End and the visualizer has ended
function bool RequiresPlayerInputToEnd()
{
	return GetMyTemplate().NeedsPlayerEndPhase;
}


// The main "update loop" of any turn phase. The Strategy game rule set will call this function until it returns eECTPPRT_End
// This function is called an unspecified amount of times
function ECTurnPhaseProcessResult ProcessTurnPhase()
{
	local ECTurnPhaseProcessResult Result;
	local ECPotentialTurnPhaseAction Action, EmptyAction;
	local int i;
	local XComGameStateHistory History;
	local EC_GameState_StrategyTurnPhaseEnhanced LocalPhase;
	local EC_GameState_StrategyTurnPhaseSubsystem Subsystem;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	`log("Processing turn phase");

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Process Turn Phase" @ m_TemplateName @ "@ step" @ GetEnum(Enum'ECTurnPhaseStep', Step));
	
	GetMyTemplate().ProcessTurnPhase(self.GetReference(), Result.PotentialActions, Step, NewGameState);

	for (i = 0; i < TurnPhaseSubsystems.Length; i++)
	{
		Subsystem = EC_GameState_StrategyTurnPhaseSubsystem(History.GetGameStateForObjectID(TurnPhaseSubsystems[i].ObjectID));
		Subsystem.PostProcessTurnPhase(self.GetReference(), Result.PotentialActions, Step, NewGameState);
	}

	if (Step == eECTPS_Finalize && Result.PotentialActions.Length > 0)
	{
		// move back to step if we still have actions
		// actions should be independent of step
		`log("Move to step from Finalize");
		LocalPhase = EC_GameState_StrategyTurnPhaseEnhanced(NewGameState.ModifyStateObject(self.Class, self.ObjectID));
		LocalPhase.Step = eECTPS_Step;
	}
	else if (Step == eECTPS_Step && Result.PotentialActions.Length == 0)
	{
		`log("Steppin'");
		if (RequiresPlayerInputToEnd())
		{
			// add an action that moves us to finalize when the player presses a button
			Action = EmptyAction;
			Action.Type = eECPTPAT_Optional;
			Action.Source = self.GetReference();
			Action.Player = `ECRULES.CurrentPlayer;
			Action.DisplayName = "Continue";
			Action.bExtended = false;
			Action.EventName = UserRequestContinueEventName;
			Action.DebugString = "Filler action for turn ending";
			Result.PotentialActions.AddItem(Action);
		}
		else
		{
			// move to finalize immediately
			LocalPhase = EC_GameState_StrategyTurnPhaseEnhanced(NewGameState.ModifyStateObject(self.Class, self.ObjectID));
			LocalPhase.Step = eECTPS_Finalize;
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	Result.Type = (Step == eECTPS_Finalize && Result.PotentialActions.Length == 0) ? eECTPPRT_End : eECTPPRT_ActionsAvailable;

	return Result;
}

function EventListenerReturn OnUserConfirmContinue(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local EC_GameState_StrategyTurnPhaseEnhanced LocalPhase;
	
	`log("Received finalize event");

	if (Step == eECTPS_Step && `ECRULES.WaitingForUserContinue())
	{	
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("User Request Continue");
		LocalPhase = EC_GameState_StrategyTurnPhaseEnhanced(NewGameState.ModifyStateObject(self.Class, self.ObjectID));
		LocalPhase.Step = eECTPS_Finalize;
		`GAMERULES.SubmitGameState(NewGameState);
		`log("Finalized");
	}

	return ELR_NoInterrupt;
}

function Cleanup(XComGameState NewGameState)
{
	local StateObjectReference Ref;
	
	foreach TurnPhaseSubsystems(Ref)
	{
		NewGameState.RemoveStateObject(Ref.ObjectID);
	}
}
