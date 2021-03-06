//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_EndOfTheCycle.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_EndOfTheCycle extends X2DownloadableContentInfo;

static event OnPostTemplatesCreated()
{
	`log("X2DownloadableContentInfo_EndOfTheCycle::OnPostTemplatesCreated");
	PatchPPChain();
}

static event PatchPPChain()
{
	local MaterialInterface TempMat;
	local MaterialEffect TempEffect;
	local MaterialInstanceConstant MIC;
	// Lets hope this stays cached in Engine...
	local PostProcessChain DefaultPP;

	DefaultPP = `XENGINE.GetDefaultPostProcessChain();
	`assert(DefaultPP != none);

	TempMat = MaterialInterface(`CONTENT.RequestGameArchetype("HexFOW.M_PP_HexFOW"));
	MIC = new (TempMat) class'MaterialInstanceConstant';
	MIC.SetParent(TempMat);
	TempEffect = new(DefaultPP) class'MaterialEffect';
	TempEffect.Material = MIC;
	TempEffect.SceneDPG = SDPG_PostProcess;
	TempEffect.EffectName = TempMat.Name;
	TempEffect.bShowInGame = true;

	DefaultPP.Effects.InsertItem(DefaultPP.Effects.Find(DefaultPP.FindPostProcessEffect('ShadowModeOn')), TempEffect);	
}

/// <summary>
/// Called from XComGameInfo::SetGameType
/// lets mods override the game info class for a given map
/// </summary>
static function OverrideGameInfoClass(string MapName, string Options, string Portal, out class<GameInfo> GameInfoClass)
{
	`log("OverrideGameInfoClass called. Map:" @ MapName);
	if (InStr(MapName, "Strategy_Root", , true) != INDEX_NONE)
	{
		`log("Override class to EC_StrategyGame");
		GameInfoClass = class'EC_Engine.EC_StrategyGame';
	}
}

exec function LogCameraTPOV()
{
	local TPOV CamTPOV;
	CamTPOV = class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().PlayerCamera.CameraCache.POV;
	`log("Camera State:" @ (class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().PlayerCamera.GetStateName()));
	`log(`showvar(CamTPOV.Location.X));
	`log(`showvar(CamTPOV.Location.Y));
	`log(`showvar(CamTPOV.Location.Z));
	`log(`showvar(CamTPOV.Rotation.Pitch));
	`log(`showvar(CamTPOV.Rotation.Roll));
	`log(`showvar(CamTPOV.Rotation.Yaw));
	`log(`showvar(CamTPOV.FOV));
}

// Test function
exec function TestHexMapDistances()
{
	local EC_DynamicTiledMap Map;

	Map = EC_DynamicTiledMap(`ECMAP);
	if (Map != none)
	{
		Map.RunTests();
	}
}

exec function DropTestSoldier()
{
	local XComGameState NewGameState;
	local EC_GameState_SimpleUnit NewUnit;
	local int Tile;

	Tile = `ECMAP.GetCursorHighlightedTile();

	if (Tile > INDEX_NONE)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Dropping test \"soldier\"");
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = VisualizeTestEntity;

		NewUnit = EC_GameState_SimpleUnit(NewGameState.CreateNewStateObject(class'EC_GameState_SimpleUnit'));
		NewUnit.ControllingPlayer = `ECRULES.CurrentPlayer;
		NewUnit.Ent_ForceSetPosition(Tile, NewGameState);
		NewUnit.Act_SetupActionsForBeginTurn(NewGameState, `ECRULES.CurrentPlayer);
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

exec function DropTestHQ()
{
	local XComGameState NewGameState;
	local EC_GameState_SimpleHeadquarters NewHQ;
	local int Tile;

	Tile = `ECMAP.GetCursorHighlightedTile();

	if (Tile > INDEX_NONE)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Dropping test \"HQ\"");
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = VisualizeTestEntity;

		NewHQ = EC_GameState_SimpleHeadquarters(NewGameState.CreateNewStateObject(class'EC_GameState_SimpleHeadquarters'));
		NewHQ.ControllingPlayer = `ECRULES.CurrentPlayer;
		NewHQ.Ent_ForceSetPosition(Tile, NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

static function VisualizeTestEntity(XComGameState VisualizeGameState)
{
	// TODO: ACTIONS!! For now we just sync directly because cheats and tests
	local XComGameState_BaseObject Entity;
	`log("Visualization is working!");
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_BaseObject', Entity)
	{
		if (IEC_StrategyWorldEntity(Entity) != none)
		{
			break;
		}
	}
	`assert(Entity != none);
	IEC_StrategyWorldEntity(Entity).Ent_FindOrCreateVisualizer();
	IEC_StrategyWorldEntity(Entity).Ent_SyncVisualizer(VisualizeGameState);
}

static function VisualizeTestSoldier(XComGameState VisualizeGameState)
{
	VisualizeTestEntity(VisualizeGameState);
}

exec function ShowVisibilityAsBorder()
{
	local XComRenderablePathComponent Comp;
	local Actor Map;
	local array<int> Tiles;
	local int i;
	local array<InterpCurveVector> Curves;

	Map = Actor(`ECMAP);

	Tiles = `ECGAME.VisibilityManager.GetVisibleTilesForPlayer(`ECCTRL.ControllingPlayer);

	Curves = `ECMAP.TraceBorders(Tiles, 0.95f);

	for (i = 0; i < Curves.Length; i++)
	{
		Comp = new class'XComRenderablePathComponent';	
		Comp.iPathLengthOffset = 0;
		Comp.fEmitterTimeStep = 1;
		Comp.fRibbonWidth = 10.0f;
		Comp.bTranslucentIgnoreFOW = false;
		Comp.PathType = eCU_NoConcealment;

		Map.AttachComponent(Comp);

		Comp.SetMaterial(MaterialInterface(`CONTENT.RequestGameArchetype("EC_Border.M_Border")));
		Comp.UpdatePathRenderData(Curves[i], Curves[i].Points[Curves[i].Points.Length - 1].InVal, none, `ECCAMSTACK.GetCameraLocationAndOrientation().Location);
	}
}