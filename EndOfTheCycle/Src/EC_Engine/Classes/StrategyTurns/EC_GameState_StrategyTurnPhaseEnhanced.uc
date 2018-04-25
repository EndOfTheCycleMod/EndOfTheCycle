// An enhanced turn phase with subsystems, capabilities to wait for user confirms, as well as subsystems
// TODO: Can we move this to EC_Framework?
class EC_GameState_StrategyTurnPhaseEnhanced extends EC_GameState_StrategyTurnPhase;

var ECTurnPhaseStep Step;

// Subsystems are a way to make turn phases modular. For example, the "main" turn phase has a UnitActions subsystem that
// gives the player's units action points and prevents ending the turn until all units have received their instructions
// there might also be a Battle subsystem that blocks certain operations while a battle is pending -- it's far more restrictive
// EC_GameState_TurnPhaseSubsystem
var protected array<StateObjectReference> TurnPhaseSubsystems;

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
	local int i;
	local XComGameStateHistory History;
	local EC_GameState_StrategyTurnPhaseEnhanced LocalPhase;
	local EC_GameState_StrategyTurnPhaseSubsystem Subsystem;

	super.BeginTurnPhase(NewGameState);
	Step = eECTPS_Step;

	History = `XCOMHISTORY;

	for (i = 0; i < TurnPhaseSubsystems.Length; i++)
	{
		Subsystem = EC_GameState_StrategyTurnPhaseSubsystem(History.GetGameStateForObjectID(TurnPhaseSubsystems[i].ObjectID));
		// TODO: Subsystem member function, passing a NewGameState, but no ModifyStateObject before??
		Subsystem.OnBeginTurnPhase(self.GetReference(), NewGameState);
	}
}

function EndTurnPhase(XComGameState NewGameState)
{
	local int i;
	local XComGameStateHistory History;
	local EC_GameState_StrategyTurnPhaseEnhanced LocalPhase;
	local EC_GameState_StrategyTurnPhaseSubsystem Subsystem;

	super.EndTurnPhase(NewGameState);

	History = `XCOMHISTORY;

	for (i = 0; i < TurnPhaseSubsystems.Length; i++)
	{
		Subsystem = EC_GameState_StrategyTurnPhaseSubsystem(History.GetGameStateForObjectID(TurnPhaseSubsystems[i].ObjectID));
		// TODO: Subsystem member function, passing a NewGameState, but no ModifyStateObject before??
		Subsystem.OnEndTurnPhase(self.GetReference(), NewGameState);
	}
}

function AddSubsystem(XComGameState NewGameState, EC_GameState_StrategyTurnPhaseSubsystem Subsystem)
{
	if (TurnPhaseSubsystems.Find('ObjectID', Subsystem.ObjectID) == INDEX_NONE && Subsystem.OwnerPhase.ObjectID <= 0)
	{
		Subsystem.OwnerPhase = self.GetReference();
		TurnPhaseSubsystems.AddItem(Subsystem.GetReference());
	}
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
	
	// TODO: Split game state code and action code.
	GetMyTemplate().ProcessTurnPhase(self.GetReference(), Result.PotentialActions, Step);
	for (i = 0; i < TurnPhaseSubsystems.Length; i++)
	{
		Subsystem = EC_GameState_StrategyTurnPhaseSubsystem(History.GetGameStateForObjectID(TurnPhaseSubsystems[i].ObjectID));
		Subsystem.PostProcessTurnPhase(self.GetReference(), Result.PotentialActions, Step);
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Process Turn Phase" @ m_TemplateName @ "@ step" @ GetEnum(Enum'ECTurnPhaseStep', Step));
	if (Step == eECTPS_Finalize && Result.PotentialActions.Length > 0)
	{
		// move back to step if we still have actions
		// actions should be independent of step
		LocalPhase = EC_GameState_StrategyTurnPhaseEnhanced(NewGameState.ModifyStateObject(self.Class, self.ObjectID));
		LocalPhase.Step = eECTPS_Step;
	}
	else if (Step == eECTPS_Step && Result.PotentialActions.Length == 0)
	{
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

	if (Step == eECTPS_Step && `ECRULES.WaitingForUserContinue())
	{	
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("User Request Continue");
		LocalPhase = EC_GameState_StrategyTurnPhaseEnhanced(NewGameState.ModifyStateObject(self.Class, self.ObjectID));
		LocalPhase.Step = eECTPS_Finalize;
		`GAMERULES.SubmitGameState(NewGameState);
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
