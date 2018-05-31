class EC_StrategyController extends XComPlayerController;

var StateObjectReference ControllingPlayer;
var EC_StrategyPlayer ControllingPlayerVisualizer;

var StateObjectReference SelectedEntity;

// TODO: Move
var bool ShowSelectionRing;
var vector SelectionRingLocation;

// TODO: Create a Pathing Pawn
var PathfindingResult PathResult;

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


function SetControllingPlayer(EC_GameState_StrategyPlayer PlayerState)
{
	ControllingPlayer = PlayerState.GetReference();
	ControllingPlayerVisualizer = EC_StrategyPlayer(PlayerState.GetVisualizer());
}

function SelectTile(int Tile)
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject StateObject;
	local array<StateObjectReference> EntitiesOnTile;
	local int idx;

	History = `XCOMHISTORY;
	`log("Select" @ Tile);

	// TODO: There's no way we can leave this code here. Move to a common manager class that provides faster access.
	// We will need all these functions for Pathfinding and Visibility too!
	foreach History.IterateByClassType(class'XComGameState_BaseObject', StateObject)
	{
		if (IEC_StrategyWorldEntity(StateObject) != none)
		{
			if (IEC_StrategyWorldEntity(StateObject).Ent_IsOnMap() && IEC_StrategyWorldEntity(StateObject).Ent_GetPosition() == Tile)
			{
				EntitiesOnTile.AddItem(StateObject.GetReference());
			}
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
	else
	{
		Deselect();
	}
}

simulated event PostBeginPlay()
{
	local Object ThisObj;
	super.PostBeginPlay();

	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'SelectAndLookAt', OnSelectAndLookAt);
}

simulated event Cleanup()
{
	local Object ThisObj;
	super.Cleanup();

	ThisObj = self;
	`XEVENTMGR.UnRegisterFromAllEvents(ThisObj);
}

function EventListenerReturn OnSelectAndLookAt(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	if (IEC_StrategyWorldEntity(EventSource) != none)
	{
		SelectEntity(XComGameState_BaseObject(EventSource).GetReference(), true);
	}
	else
	{
		`REDSCREEN(GetFuncName() $ "::" @ EventSource.Class @ "cannot be selected");
	}
	return ELR_NoInterrupt;
}


// General-purpose function to select a given entity. Compare to XComTacticalController::Visualizer_SelectUnit
function SelectEntity(StateObjectReference NewEntity, optional bool LookAt = false)
{
	local Actor Vis;
	local XComGameState_BaseObject O;
	if (SelectedEntity.ObjectID > 0)
	{
		Deselect();
	}
	SelectedEntity = NewEntity;
	O = `XCOMHISTORY.GetGameStateForObjectID(SelectedEntity.ObjectID);
	if (LookAt)
	{
		`XEVENTMGR.TriggerEvent('BaseCamLookAt', O, O);
	}
	ShowSelectionRing = true;
	Vis = `XCOMHISTORY.GetVisualizer(NewEntity.ObjectID);
	SelectionRingLocation = Vis.Location;
}

function Deselect()
{
	ShowSelectionRing = false;
	SelectedEntity = default.SelectedEntity;
	PathResult = default.PathResult;
}

function bool ConfirmPath()
{
	if (PathResult.PathFound)
	{
		GetCurrentPathable().Path_QueuePath(PathResult.Nodes);
		return true;
	}
	return false;
}

event PlayerTick( float DeltaTime )
{
	local int End;
	local MoverData Data;
	local IEC_Pathable Pathable;

	super.PlayerTick(DeltaTime);
	
	Pathable = GetCurrentPathable();
	if (Pathable != none)
	{
		End = `ECMAP.GetCursorHighlightedTile();
		Data = Pathable.Path_GetMoverData();
		if (PathResult.Data != Data
		|| PathResult.GoalPosition != End 
		|| PathResult.StartPosition != IEC_StrategyWorldEntity(Pathable).Ent_GetPosition())
		{
			PathResult = `ECGAME.DefaultPathfinder.BuildPath(IEC_StrategyWorldEntity(Pathable).Ent_GetPosition(), End, Data);
		}
	}
	else
	{
		PathResult = default.PathResult;
	}
}

protected function IEC_Pathable GetCurrentPathable()
{
	local IEC_Pathable Pathable;
	local XComGameState_BaseObject Obj;

	if (SelectedEntity.ObjectID > 0)
	{
		Obj = `XCOMHISTORY.GetGameStateForObjectID(SelectedEntity.ObjectID);
		if (IEC_Pathable(Obj) != none && IEC_Pathable(Obj).Path_IsMovable())
		{
			Pathable = IEC_Pathable(Obj);
		}
	}
	return Pathable;
}

function DrawDebugData(HUD H)
{
	DrawDebugLabels(H.Canvas);
}

function DrawDebugLabels(Canvas kCanvas)
{
	`ECRULES.DrawDebugLabel(kCanvas);
	`ECCHEAT.DrawDebugLabel(kCanvas);
	`ECMAP.DrawDebugLabel(kCanvas);
	DrawDebugLabel(kCanvas);
}

function DrawDebugLabel(Canvas kCanvas)
{
	local vector loc, Pos, pos2D;
	local rotator Rot;
	local int i;

	if (ShowSelectionRing)
	{
		loc = SelectionRingLocation;
		loc.X += cos(WorldInfo.TimeSeconds * 4) * 60;
		loc.Y += sin(WorldInfo.TimeSeconds * 4) * 60;
		`ECSHAPES.DrawSphere(loc, vect(20,20,20), MakeLinearColor(1,0.7,0.2,1), false);
	}

	if (SelectedEntity.ObjectID > 0)
	{
		if (PathResult.PathFound)
		{
			for (i = 0; i < PathResult.Nodes.Length - 1; i++)
			{
				`ECMAP.GetWorldPositionAndRotation(PathResult.Nodes[i].Tile, Pos, Rot);
				`ECSHAPES.DrawSphere(Pos, vect(30,30,30), MakeLinearColor(0,1,0,1), false);
				pos2D = kCanvas.Project(Pos);
				kCanvas.SetPos(pos2D.X, pos2D.Y);
				kCanvas.SetDrawColor(255,0,0);
				kCanvas.DrawText(PathResult.Nodes[i].Distance);
			}
		}
	}
}

defaultproperties
{
	CameraClass=class'EC_StrategyCamera'
	InputClass=class'EC_StrategyInput'
	CheatClass=class'EC_StrategyCheatManager'
	PresentationLayerClass=class'EC_StrategyPresentationLayer'
}
