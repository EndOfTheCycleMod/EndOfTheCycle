class EC_UIStrategyHUD extends UIScreen;

var UILargeButton ContinueButton;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	
	ContinueButton = Spawn(class'UILargeButton', self);
	ContinueButton.bAnimateOnInit = false;
	ContinueButton.InitLargeButton(,"Continue",, OnContinue);
	ContinueButton.AnchorBottomRight();
	ContinueButton.DisableNavigation();
	ContinueButton.ShowBG(true);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	return false;
}

simulated function OnContinue(UIButton Button)
{
	local array<ECPotentialTurnPhaseAction> PotentialActions;
	local ECPotentialTurnPhaseAction A;
	local XComGameState_BaseObject Source;

	PotentialActions = `ECRULES.CachedTurnPhaseResult.PotentialActions;
	if (PotentialActions.Length > 0)
	{
		A = PotentialActions[0];
		PotentialActions.Remove(0, 1);
		PotentialActions.AddItem(A);
		`ECRULES.CachedTurnPhaseResult.PotentialActions = PotentialActions;
		Source = `XCOMHISTORY.GetGameStateForObjectID(A.Source.ObjectID);
		`log("Triggering" @ A.EventName @ "with source" @ Source.Class.Name);
		`XEVENTMGR.TriggerEvent(A.EventName, Source, Source);
	}
	
}


defaultproperties
{
	bHideOnLoseFocus = false;
	bAnimateOnInit = false;
}