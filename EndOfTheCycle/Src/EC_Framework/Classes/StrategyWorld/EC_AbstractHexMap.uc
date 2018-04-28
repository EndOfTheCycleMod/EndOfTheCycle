class EC_AbstractHexMap extends Actor abstract implements(IEC_StrategyMap, IEC_StratMapFOWVisualizer);

const HEX_SIZE = 144.0f;         // 96 * 1.5
const HEX_DST = 249.415316289f;  // 2 * HEX_SIZE * cos(30°)

struct PointNeighbors
{
	var IntPoint p[6];
};

var const PointNeighbors Directions[2];

// The map has this layout (X,Y)
// 0,0   1,0   2,0   3,0   ... Width,0
//    0,1   1,1   2,1   3,1...    Width,1
// 0,2   1,2   2,2   3,2   ... Width,2
//    0,3   1,3   2,3   3,3...    Width,3
// ...

var int Width, Height;

var EC_HexVisibilityPathfinder Vis;

var transient int LastHoveredTile;

var transient ScriptedTexture FOWTexture;
var transient array<FOWUpdateParams> ImmediateQueue;

// These functions must be overridden by subclasses.
// UnrealScript requires even abstract classes to implement the
// full interface, which makes this a bit awkward.
function LoadMap()
{
	`REDSCREEN("Error:" @ default.Class @ "needs to override" @ GetFuncName());
}

function bool IsLoaded()
{
	`REDSCREEN("Error:" @ default.Class @ "needs to override" @ GetFuncName());
	return false;
}

function X2Camera CreateDefaultCamera()
{
	`REDSCREEN("Error:" @ default.Class @ "needs to override" @ GetFuncName());
	return none;
}

function bool GetWorldPositionAndRotation(int PosHandle, out vector pos, out rotator rot)
{
	`REDSCREEN("Error:" @ default.Class @ "needs to override" @ GetFuncName());
	return false;
}

function int GetTileInfo(int Pos)
{
	`REDSCREEN("Error:" @ default.Class @ "needs to override" @ GetFuncName());
	return 0;
}

function int GetEdgeInfo(int Pos)
{
	`REDSCREEN("Error:" @ default.Class @ "needs to override" @ GetFuncName());
	return 0;
}

function int GetTileElevation(int Pos)
{
	`REDSCREEN("Error:" @ default.Class @ "needs to override" @ GetFuncName());
	return 0;
}

static function CreateRandomMap(XComGameState NewGameState)
{
	`REDSCREEN("Error:" @ default.Class @ "needs to override" @ GetFuncName());
}

function array<int> GetAdjacentMapPositions(int Pos)
{
	local IntPoint P;
	local array<int> arr;
	local PointNeighbors points;
	local IntPoint TempPoint;
	local int i;
	
	P = GetTile2DCoords(Pos);
	points = Directions[P.Y & 1];
	for (i = 0; i < ArrayCount(points.p); i++)
	{
		TempPoint.X = P.X + points.p[i].X;
		TempPoint.Y = P.Y + points.p[i].Y;
		if (TempPoint.X > -1 && TempPoint.Y > -1 && TempPoint.X < Width && TempPoint.Y < Height)
		{
			arr.AddItem(GetHandleFromPoint(TempPoint));
		}
	}
	return arr;
}

function bool AreAdjacent(int A, int B)
{
	local IntPoint PA, PB;

	if (A == B) return false;
	
	PA = GetTile2DCoords(A);
	PB = GetTile2DCoords(B);

	return PA.Y == PB.Y && Abs(PA.X - PB.X) < 2
	    || PA.X == PB.X && Abs(PA.Y - PB.Y) < 2
		|| (((PA.Y & 1) == 0) ? (PA.X - PB.X) == 1 && Abs(PA.Y - PB.Y) < 2 : (PA.X - PB.X) == -1 && Abs(PA.Y - PB.Y) < 2);

}

function int GetCursorHighlightedTile()
{
	return LastHoveredTile;
}

function int GetTileDistance(int A, int B)
{
	local IntPoint PA, PB;

	PA = GetTile2DCoords(A);
	PB = GetTile2DCoords(B);

	return Max(Max(
		Abs(PB.Y - PA.Y),     
		Abs(FCeil(PB.Y / -2.0f) + PB.X - FCeil(PA.Y / -2.0f) - PA.X)),
		Abs(-PB.Y - FCeil(PB.Y / -2.0f) - PB.X + PA.Y  + FCeil(PA.Y / -2.0f) + PA.X));
}

function array<int> GetTilesInRange(int Pos, int Range)
{

}

function bool TraceTiles(int Start, int End, optional int HeightOffset = 0, optional int SightRange = -1)
{

}

function array<int> GetVisibleTiles(int Start, int SightRange, optional int HeightOffset = 0)
{
	local PathfindingResult Result;
	local MoverData M;
	local array<int> VisibleTiles;
	local int i;
	
	Vis.Init(self);
	Vis.SetParams(HeightOffset, SightRange);

	// MoverData can stay empty -- it's not relevant for the HexVisibilityPathfinder
	Result = Vis.BuildPath(Start, -1, M);
	// Now we know the shortest obstacle-avoiding path to each tile -- discard tiles that need to
	// go around obstacles
	for (i = 0; i < Result.Nodes.Length; i++)
	{
		`assert(Result.Nodes[i].Distance >= GetTileDistance(Start, Result.Nodes[i].Tile));
		if (Result.Nodes[i].Distance == GetTileDistance(Start, Result.Nodes[i].Tile))
		{
			// The path we found was the shortest possible -- add it to the result
			VisibleTiles.AddItem(Result.Nodes[i].Tile);
		}
	}
	return VisibleTiles;
}

function array<IntPoint> GetValidPositionRanges()
{
	local IntPoint P;
	local array<IntPoint> ret;

	// Most simple of maps
	P.X = 0;
	P.Y = (Width * Height) - 1;
	ret.AddItem(P);

	return ret;
}

function string GetPositionDebugInfo(int Pos)
{
	local IntPoint P;
	P = GetTile2DCoords(Pos);
	return "(X:" @ P.X $ ", Y:" @ P.Y $ ")";
}


final function IntPoint GetTile2DCoords(int TileHandle)
{
	local IntPoint P;
	P.X = TileHandle % Width;
	P.Y = TileHandle / Width;
	return P;
}

final function int GetHandleFromCoords(int x, int y)
{
	return y * Width + x;
}

final function int GetHandleFromPoint(IntPoint p)
{
	return p.y * Width + p.x;
}


function IEC_StratMapFOWVisualizer GetFOWVisualizer()
{
	return self;
}

function InitResources()
{
	local LocalPlayer LP;
	local PostProcessChain PPChain;
	local int ChainIdx, I, MaxDim;
	local PostProcessEffect Effect, FoundEffect;
	local MaterialInstanceConstant MIC;
	local LinearColor C;

	MaxDim = Max(Width, Height);

	LP = LocalPlayer(GetALocalPlayerController().Player);
	if (LP != none)
	{
		for(ChainIdx = 0; ChainIdx < LP.PlayerPostProcessChains.Length; ++ChainIdx)
		{
			PPChain = LP.PlayerPostProcessChains[ChainIdx];
			Effect = PPChain.FindPostProcessEffect('M_PP_HexFOW');
			if (Effect != none)
			{
				FoundEffect = Effect;
				break;
			}
		}
	}
	`assert(FoundEffect != none);
	MIC = MaterialInstanceConstant(MaterialEffect(FoundEffect).Material);

	/* For some reason, doing is this way results in a `Failed to find function None in ScriptedTexture` (WUT?)
	 * Hence, we just let it get garbage collected
	I = MIC.TextureParameterValues.Find('ParameterName', 'FOWTex');
	if (I != INDEX_NONE)
	{
		FOWTexture = ScriptedTexture(MIC.TextureParameterValues[i].ParameterValue);
		if (FOWTexture != none)
		{
			`log("Calling Resize");
			class'ScriptedTexture'.static.Resize(FOWTexture, Max(Width, Height), Max(Width, Height));
			`log("Called Resize");
		}
	}*/


	if (FOWTexture == none)
	{
		FOWTexture = ScriptedTexture(class'ScriptedTexture'.static.Create(Max(Width, Height), Max(Width, Height), PF_A8R8G8B8, MakeLinearColor(1, 1, 1, 1), false, true, false, /*MIC -- see comment above*/none));
		FOWTexture.Filter = TF_Nearest;
		FOWTexture.Render = RenderFOW;
		MIC.SetTextureParameterValue('FOWTex', FOWTexture);
	}

	C.R = MaxDim;
	C.G = MaxDim;
	MIC.SetVectorParameterValue('MapDimensions', C);
	C.R = MaxDim;
	C.G = MaxDim;
	MIC.SetVectorParameterValue('TexSize', C);
	C.R = 0;
	C.G = 0;
	MIC.SetVectorParameterValue('Origin', C);
	MIC.SetScalarParameterValue('HexSize', HEX_SIZE);

	SubscribeToOnCleanupWorld();
}

function bool FOWInited()
{
	return FOWTexture != none;
}

simulated function RenderFOW(Canvas C)
{
	local int i;
	local IntPoint P;
	`log("Render!!");
	// TODO
	//FOWTexture.PreOptimizeDrawTiles(...);
	FOWTexture.bSkipNextClear = true;
	for (i = 0; i < ImmediateQueue.Length; i++)
	{
		// SetDrawColor
		P = GetTile2DCoords(ImmediateQueue[i].Tile);
		C.SetPos(P.X, P.Y);
		switch (ImmediateQueue[i].NewState)
		{
			case eECVS_Unexplored:
			case eECVS_Explored:
				C.SetDrawColor(0,0,0,255);
				break;
			case eECVS_Vision:
			case eECVS_Full:
				C.SetDrawColor(255,255,255,255);
				break;
		}
		C.DrawRect(1, 1);
	}
	ImmediateQueue.Length = 0;
}

function UpdateFOW(array<FOWUpdateParams> Params, bool Immediate)
{
	local int i;
	FOWTexture.bNeedsUpdate = true;

	for (i = 0; i < Params.Length; i++)
	{
		ImmediateQueue.AddItem(Params[i]);
	}
}

simulated event OnCleanupWorld()
{
	ReleaseResources();
}

function ReleaseResources()
{
	`log("Cleaning up resources");
	FOWTexture.Render = none;
	FOWTexture = none;
}

function DrawDebugLabel(Canvas kCanvas)
{
	kCanvas.SetPos(10, 10);
	kCanvas.DrawTile(FOWTexture, Max(Width, Height) * 3, Max(Width, Height) * 3, 0, 0, Max(Width, Height), Max(Width, Height));
}

`define assrt(a,b) InAssertEquals(`{a}, `{b}, "`{a}", string(`{b}));

simulated function RunTests()
{
	`assrt(GetTileDistance(4,4), 0);
	`assrt(GetTileDistance(GetHandleFromCoords(4,5),GetHandleFromCoords(4,4)), 1);
	`assrt(GetTileDistance(GetHandleFromCoords(5,4),GetHandleFromCoords(4,4)), 1);
	`assrt(GetTileDistance(GetHandleFromCoords(2,2),GetHandleFromCoords(1,3)), 1);
	`assrt(GetTileDistance(GetHandleFromCoords(2,2),GetHandleFromCoords(3,3)), 2);
	`assrt(GetTileDistance(GetHandleFromCoords(0,0),GetHandleFromCoords(3,3)), 5);
	`assrt(GetTileDistance(GetHandleFromCoords(0,39),GetHandleFromCoords(59,0)), 39+39);
	`assrt(GetTileDistance(GetHandleFromCoords(0,39),GetHandleFromCoords(58,0)), 39+38);
	`assrt(GetTileDistance(GetHandleFromCoords(0,0),GetHandleFromCoords(59,39)), 39+40);
}

final function InAssertEquals(int A, int B, string S, string T)
{
	if (A == B)
	{
		`log("OK:" @ S @ "==" @ T);
	}
	else
	{
		`log("FAIL:" @ S @ "is" @ A $ ", expected" @ T);
	}
}


defaultproperties
{
	Directions(0)=(p[0]=(X=1, Y=0), p[1]=(X=0, Y=-1), p[2]=(X=-1, Y=-1), p[3]=(X=-1, Y=0), p[4]=(X=-1, Y=1), p[5]=(X=0, Y=1))
	Directions(1)=(p[0]=(X=1, Y=0), p[1]=(X=1, Y=-1), p[2]=(X=0, Y=-1), p[3]=(X=-1, Y=0), p[4]=(X=0, Y=1), p[5]=(X=1, Y=1))

	Begin Object Class=EC_HexVisibilityPathfinder Name=HexVis
	End Object
	Vis=HexVis
}