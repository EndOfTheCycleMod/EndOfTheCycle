class EC_StrategyInput extends XComInputBase within EC_StrategyController;

function DrawHUD( HUD HUD )
{
	Outer.DrawDebugData(HUD);
}

// Return false if the input is consumed in preprocessing; else return true and input continues down the waterfall. 
// TODO
simulated function bool PreProcessCheckGameLogic( int cmd, int ActionMask ) 
{
	if( GetScreenStack() != none && Get2DMovie() != none && Get2DMovie().bIsInited )
	{
		return true;
	}
	return false;
}

simulated function bool PostProcessCheckGameLogic( float DeltaTime )
{

//	Controller_CheckForWindowScroll();
	Mouse_CheckForWindowScroll(DeltaTime);
//	Mouse_FreeLook();
//	Mouse_CheckForFreeAim();

	EC_StrategyCamera(PlayerCamera).PostProcessInput();

	return true;
}



simulated function Mouse_CheckForWindowScroll(float fDeltaTime)
{
	local EC_StrategyController kController;
	local XComHUD kHud;
	local EC_StrategyCamera Cam;
	local Vector2D v2Tmp, v2Mouse, v2ScreenSize; 
	local float fScrollAmount;
	local bool bInScrollArea;

	kController = Outer;
	kHud = XComHud(kController.myHUD);
	Cam = EC_StrategyCamera(Outer.PlayerCamera);

	// If mouse isn't yet fully initialized bail out - sbatista 6/17/2013
	if (!pres.GetMouseCoords(v2Tmp)) return;

	//Don't use the UI reporting mouse loc, because you'll end up with fun rounding errors and sadness. 
	//Use the player controller's info on teh hardware mouse. -bsteiner 
	v2Mouse = XComLocalPlayer(kController.Player).ViewportClient.GetMousePosition();

	if (v2Mouse.Y <= 1 || //Up
		v2Mouse.Y >= (v2ScreenSize.y - 1) || //Down
		v2Mouse.X <= 1 ||  //Left
		v2Mouse.X >= (v2ScreenSize.x - 1)) //Right
	{
		bInScrollArea = true;
	}
	//Checking edges of the screen for mouse-push camera scrolling.
	if( pres != none && pres.Get2DMovie().IsMouseActive() && bInScrollArea
		&& kHud.bGameWindowHasFocus
		&& pres.m_kUIMouseCursor != none
		&& !pres.m_kUIMouseCursor.bIsInDefaultLocation  
		&& !pres.IsPauseMenuRaised()
		&& !TestMouseConsumedByFlash() )
	{
		v2ScreenSize = XComLocalPlayer(kController.Player).SceneView.GetSceneResolution();
		fScrollAmount = GetScrollSpeedInUnitsPerSecond() * fDeltaTime;

		if( v2Mouse.Y <= 1 )        //Up
			Cam.EdgeScrollCamera( 0, fScrollAmount );
		else if( v2Mouse.Y >= (v2ScreenSize.y - 1) )   //Down
			Cam.EdgeScrollCamera( 0, -fScrollAmount );

		if( v2Mouse.X <= 1 )        //Left
			Cam.EdgeScrollCamera( -fScrollAmount, 0 );
		else if( v2Mouse.X >= (v2ScreenSize.x - 1) )   //Right
			Cam.EdgeScrollCamera( fScrollAmount, 0 );
	}
}

function float GetScrollSpeedInUnitsPerSecond()
{
	return 2000;
}

function bool Key_W( int ActionMask ){ return ArrowUp( ActionMask );}
function bool Key_A( int ActionMask ){ return ArrowLeft( ActionMask );}
function bool Key_S( int ActionMask ){ return ArrowDown( ActionMask );}
function bool Key_D( int ActionMask ){ return ArrowRight( ActionMask );}

simulated function bool ArrowUp( int ActionMask )
{
	return AttemptScrollCamera(ActionMask, 0, GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY);
}
simulated function bool ArrowDown( int ActionMask )
{
	return AttemptScrollCamera(ActionMask, 0, -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY);
}

simulated function bool ArrowLeft( int ActionMask )
{
	return AttemptScrollCamera(ActionMask, -GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0);
}

simulated function bool ArrowRight( int ActionMask )
{
	return AttemptScrollCamera(ActionMask, GetScrollSpeedInUnitsPerSecond() * SIGNAL_REPEAT_FREQUENCY, 0);
}

simulated function bool AttemptScrollCamera(int ActionMask, float X, float Y)
{
	// Only pay attention to presses or repeats
	if ( (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 
		|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT) != 0
		|| ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0)
	{
		EC_StrategyCamera(PlayerCamera).ScrollCamera(X, Y);
		return true;
	}
	return false;
}


simulated function bool EscapeKey( int ActionMask )
{
	return Start_Button(ActionMask);
}

function bool Start_Button( int ActionMask )
{
	if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		ScriptTrace();
		`ECPRES.UIPauseMenu(, !`ECRULES.IsSavingAllowed());
		return true;
	}
	return false;
}

function bool LMouse(int ActionMask)
{
	local bool bHandled;
	local int Tile;

	bHandled = false; 

	if(TestMouseConsumedByFlash())
		return false;

	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		Tile = `ECMAP.GetCursorHighlightedTile();
		Outer.SelectTile(Tile);
		bHandled = true;
	}

	return bHandled;
}

function bool RMouse(int ActionMask)
{
	local bool bHandled;

	bHandled = false; 

	if(TestMouseConsumedByFlash())
		return false;

	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		bHandled = Outer.ConfirmPath();
	}

	return bHandled;
}

