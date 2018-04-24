class EC_StrategyController extends XComPlayerController;

var StateObjectReference SelectedEntity;

// TODO: Evaluate Start

var bool                                m_bAffectsHUD;
var bool                                m_bInCinematicMode;

/* SetPause()
 Try to pause game; returns success indicator.
 Replicated to server in network games.
 */
function bool SetPause( bool bPause, optional delegate<CanUnpause> CanUnpauseDelegate=CanUnpause, optional bool bFromLossOfFocus)
{
	local bool bResult;
	
	bResult = super.SetPause(bPause, CanUnpauseDelegate, bFromLossOfFocus);

	if( EC_StrategyPresentationLayer(Pres).Get3DMovie() != none )
	{
		EC_StrategyPresentationLayer(Pres).Get3DMovie().SetPause(bPause);
	}

	return bResult;
}

function SetCinematicMode( bool bInCinematicMode, bool bHidePlayer, bool bAffectsHUD, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsButtons, optional bool bDoClientRPC = true, optional bool bOverrideUserMusic = false )
{
	super.SetCinematicMode( bInCinematicMode, bHidePlayer, bAffectsHUD, bAffectsMovement, bAffectsTurning, bAffectsButtons, bDoClientRPC, bOverrideUserMusic );

	CinematicModeToggled(bInCinematicMode, bAffectsMovement, bAffectsTurning, bAffectsHUD);
}

simulated function CinematicModeToggled(bool bInCinematicMode, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsHUD)
{
	m_bInCinematicMode = bInCinematicMode;
	m_bAffectsHUD = bAffectsHUD;

	if (bInCinematicMode)
	{
		if( PlayerCamera != none )
			PlayerCamera.ClearAllCameraShakes();

		if (bAffectsHUD)
		{
			Pres.HideUIForCinematics();
			
			//ConsoleCommand( "SetPPVignette "@string(!bInCinematicMode));
		}
		if( PlayerCamera != none )
			PlayerCamera.PushState('CinematicView');

		PushState( 'CinematicMode' );
	}
	else
	{
		if (bAffectsHUD)
		{
			Pres.ShowUIForCinematics();
			//ConsoleCommand( "SetPPVignette "@string(!bInCinematicMode));
		}

		if( PlayerCamera != none && PlayerCamera.IsInState('CinematicView',true) )
		{
			while( PlayerCamera.IsInState('CinematicView', true) )
				PlayerCamera.PopState();

			XComBaseCamera(PlayerCamera).bHasOldCameraState = false; //Force an instant transition
			PlayerCamera.ResetConstrainAspectRatio();
		}

		PopState();
	}
}

simulated function SetInputState( name nStateName, optional bool bForce )
{
	XComHeadquartersInput( PlayerInput ).GotoState( nStateName );
}

state CinematicMode
{
	event BeginState(Name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
	}

	event EndState(Name NextStateName)
	{
		super.EndState(NextStateName);
	}
/*
	// don't show menu in cenematic mode - the button skips the cinematic
	exec function ShowMenu();

	// dont playe selection sound
	exec function PlayUnitSelectSound();*/
}

/** Start as PhysicsSpectator by default */
auto state PlayerWaiting
{

Begin:
	PlayerReplicationInfo.bOnlySpectator = false;
	WorldInfo.Game.bRestartLevel = false;
	WorldInfo.Game.RestartPlayer( Self );
	WorldInfo.Game.bRestartLevel = true;
	SetCameraMode('ThirdPerson');
}

/**
 * Looks at the current game state and uses that to set the
 * rich presence strings
 *
 * Licensees (that's us!) should override this in their player controller derived class
 */
reliable client function ClientSetOnlineStatus()
{
	`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_InGameSP);
}

// TODO: Evaluate End

function SelectTile(int Tile)
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject StateObject;
	local array<StateObjectReference> EntitiesOnTile;
	local int idx;

	History = `XCOMHISTORY;

	// TODO: There's no way we can leave this code here. Move to a common manager class that provides faster access.
	// We will need all these functions for Pathfinding and Visibility too!
	foreach History.IterateByClassType(class'XComGameState_BaseObject', StateObject)
	{
		if (IEC_StrategyWorldEntity(StateObject) != none && IEC_StrategyWorldEntity(StateObject).Ent_GetPosition() == Tile)
		{
			EntitiesOnTile.AddItem(StateObject.GetReference());
		}
	}
	if (EntitiesOnTile.Length > 0)
	{
		idx = EntitiesOnTile.Find('ObjectID', SelectedEntity.ObjectID);
		if (idx != INDEX_NONE)
		{
			idx = WrapIndex(idx + 1, 0, EntitiesOnTile.Length);
		}
		else
		{
			idx = 0;
		}
		SelectEntity(EntitiesOnTile[idx]);
	}
}

protected function SelectEntity(StateObjectReference NewEntity)
{
	if (SelectedEntity.ObjectID > 0)
	{
		Deselect();
	}
}

function Deselect()
{

}

function DrawDebugData(HUD H)
{
	DrawDebugLabels(H.Canvas);
}

function DrawDebugLabels(Canvas kCanvas)
{
	`ECRULES.DrawDebugLabel(kCanvas);
	`ECCHEAT.DrawDebugLabel(kCanvas);
	DrawDebugLabel(kCanvas);
}

function DrawDebugLabel(Canvas kCanvas)
{
	local int iX, iY;
	iX=250;
	iY=50;
}

defaultproperties
{
	CameraClass=class'EC_StrategyCamera'
	InputClass=class'EC_StrategyInput'
	CheatClass=class'EC_StrategyCheatManager'
	PresentationLayerClass=class'EC_StrategyPresentationLayer'
}
