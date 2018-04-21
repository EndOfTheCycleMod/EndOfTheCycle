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