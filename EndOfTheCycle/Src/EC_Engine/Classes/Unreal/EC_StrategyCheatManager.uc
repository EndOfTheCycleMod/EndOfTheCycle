class EC_StrategyCheatManager extends XComCheatManager within EC_StrategyController dependson(IEC_StratMapFOWVisualizer);

// Pathing
var int PathingSourceTile;
var int LastGoal;
var PathfindingResult Result;

// Visibility/FOW
var int VisHeight, VisRange;
var int LastTile;
var array<FOWUpdateParams> UndoParams;


enum EDebugState
{
	eDS_None,
	eDS_Pathing,
	eDS_Vision,
};

var EDebugState DebugState;

// Override, `PRES -> `PRESBASE
exec function EnablePostProcessEffect(name EffectName, bool bEnable)
{
	`PRESBASE.EnablePostProcessEffect(EffectName, bEnable);
}

exec function StartPathing()
{
	PathingSourceTile = `ECMAP.GetCursorHighlightedTile();
	GotoDebugState(eDS_Pathing);
}

exec function EndDebugMode()
{
	GotoDebugState(eDS_None);
}

exec function StartVisibility(int Height, int Range)
{
	VisHeight = Height;
	VisRange = Range;
	GotoDebugState(eDS_Vision);
}

// CheatManager extends Object which is not Actor, so states aren't supported
function GotoDebugState(EDebugState NewState)
{
	switch (DebugState)
	{
		case eDS_Pathing:
			Pathing_EndState();
			break;
		case eDS_Vision:
			Vision_EndState();
			break;
		default:
	}

	DebugState = NewState;
	
	switch (DebugState)
	{
		case eDS_Vision:
			Vision_BeginState();
			break;
		default:
	}
}

function DrawDebugLabel(Canvas kCanvas)
{
	switch (DebugState)
	{
		case eDS_Pathing:
			Pathing_DrawDebugLabel(kCanvas);
			break;
		case eDS_Vision:
			Vision_DrawDebugLabel(kCanvas);
			break;
		default:
	}
}

function Pathing_DrawDebugLabel(Canvas kCanvas)
{
	local vector Pos, pos2D;
	local rotator Rot;
	local int End;
	local MoverData Data;
	local int i;

	End = `ECMAP.GetCursorHighlightedTile();
	if (PathingSourceTile > -1 && End > -1)
	{
		`ECMAP.GetWorldPositionAndRotation(PathingSourceTile, Pos, Rot);
		`ECSHAPES.DrawSphere(Pos, vect(30,30,30), MakeLinearColor(1,0,0,1), false);
		if (LastGoal != End)
		{
			Data.Domain = eUD_Land;
			Result = `ECGAME.DefaultPathfinder.BuildPath(PathingSourceTile, End, Data);
			LastGoal = End;
		}
		if (Result.PathFound)
		{
			for (i = 0; i < Result.Nodes.Length - 1; i++)
			{
				`ECMAP.GetWorldPositionAndRotation(Result.Nodes[i].Tile, Pos, Rot);
				`ECSHAPES.DrawSphere(Pos, vect(30,30,30), MakeLinearColor(0,1,0,1), false);
				pos2D = kCanvas.Project(Pos);
				kCanvas.SetPos(pos2D.X, pos2D.Y);
				kCanvas.SetDrawColor(255,0,0);
				kCanvas.DrawText(Result.Nodes[i].Distance);
			}
		}
	}
}

function Pathing_EndState()
{
	PathingSourceTile = -1;
	LastGoal = -1;
}

function Vision_BeginState()
{
	TheWorldIsDark();
}

function Vision_DrawDebugLabel(Canvas kCanvas)
{
	local int Tile, i;
	local array<int> VisibleTiles;
	local array<FOWUpdateParams> Params;
	local FOWUpdateParams P;
	local IEC_StratMapFOWVisualizer FOWVis;

	Tile = `ECMAP.GetCursorHighlightedTile();
	FOWVis = `ECMAP.GetFOWVisualizer();

	if (Tile != LastTile && Tile > -1 && FOWVis.FOWInited())
	{
		LastTile = Tile;
		VisibleTiles = `ECMAP.GetVisibleTiles(Tile, VisRange, VisHeight);
		FOWVis.UpdateFOW(UndoParams, true);
		UndoParams.Length = 0;
		Params.Length = 0;
		for (i = 0; i < VisibleTiles.Length; i++)
		{
			P.Tile = VisibleTiles[i];
			P.NewState = eECVS_Full;
			Params.AddItem(P);
			// Maintain the params to undo this FOW tick for the next time. A bit wasteful, but cheats and testing
			P.NewState = eECVS_Unexplored;
			UndoParams.AddItem(P);
		}
		FOWVis.UpdateFOW(Params, true);
	}
}

function Vision_EndState()
{
	local IEC_StratMapFOWVisualizer FOWVis;

	LastTile = -1;
	FOWVis = `ECMAP.GetFOWVisualizer();
	if (FOWVis.FOWInited())
	{
		FOWVis.UpdateFOW(UndoParams, true);
		UndoParams.Length = 0;
	}
}

exec function SetFOWState(bool st)
{
	local IEC_StratMapFOWVisualizer FOWVis;
	local array<FOWUpdateParams> Params;
	local FOWUpdateParams P;
	FOWVis = `ECMAP.GetFOWVisualizer();
	if (FOWVis.FOWInited())
	{
		P.Tile = `ECMAP.GetCursorHighlightedTile();
		if (P.Tile >= 0)
		{
			P.NewState = st ? eECVS_Full : eECVS_Unexplored;
			Params.AddItem(P);
			FOWVis.UpdateFOW(Params, true);
		}
	}
}

exec function TheWorldIsDark()
{
	local IEC_StratMapFOWVisualizer FOWVis;

	FOWVis = `ECMAP.GetFOWVisualizer();
	
	if (FOWVis.FOWInited())
	{
		FOWVis.Clear(eECVS_Unexplored);
	}
}

exec function SyncFOW()
{
	`ECGAME.VisibilityManager.SyncFOW();
}

exec function SyncTerritory()
{
	`ECGAME.TerritoryManager.SyncTerritory();
}

defaultproperties
{
	PathingSourceTile=-1
	LastGoal=-1
	LastTile=-1
}