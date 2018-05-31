class EC_AbstractHexMap extends Actor abstract implements(IEC_StrategyMap, IEC_StratMapFOWVisualizer);

const HEX_SIZE = 144.0f;         // 96 * 1.5
const HEX_DST = 249.415316289f;  // 2 * HEX_SIZE * cos(30°)

var int Width, Height;

// Assign both of these from whatever function in your subclass you get your Dimensions from.
var HexGeometry Geom;
var EC_HexVisibilityPathfinder Vis;

var transient int LastHoveredTile;

var transient ScriptedTexture FOWTexture;

struct RenderInstruction
{
	var vector2d Source;
	var vector2d Dim;
	var Color Color;
};

var transient array<RenderInstruction> RenderQueue;

var const Color WHITE, BLACK;

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
	return Geom.GetAdjacentMapPositions(Pos);
}

function bool AreAdjacent(int A, int B)
{
	return Geom.AreAdjacent(A, B);
}

function int GetCursorHighlightedTile()
{
	return LastHoveredTile;
}

function int GetTileDistance(int A, int B)
{
	return Geom.GetTileDistance(A, B);
}

function array<int> GetTilesInRange(int Pos, int Range)
{
	return Geom.GetTilesInRange(Pos, Range);
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
	P = Geom.GetTile2DCoords(Pos);
	return "(X:" @ P.X $ ", Y:" @ P.Y $ ")";
}


function IEC_StratMapFOWVisualizer GetFOWVisualizer()
{
	return self;
}

function InitResources()
{
	local LocalPlayer LP;
	local PostProcessChain PPChain;
	local int ChainIdx, MaxDim;
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
	local RenderInstruction Inst;
	`log("Render!!");
	// TODO
	//FOWTexture.PreOptimizeDrawTiles(...);
	FOWTexture.bSkipNextClear = true;
	for (i = 0; i < RenderQueue.Length; i++)
	{
		// SetDrawColor
		Inst = RenderQueue[i];
		C.SetPos(Inst.Source.X, Inst.Source.Y);
		C.SetDrawColorStruct(Inst.Color);
		C.DrawRect(Inst.Dim.X, Inst.Dim.Y);
	}
	RenderQueue.Length = 0;
}

function UpdateFOW(array<FOWUpdateParams> Params, bool Immediate)
{
	local int i;
	local IntPoint P;
	local RenderInstruction Inst;

	FOWTexture.bNeedsUpdate = true;

	Inst.Dim.X = 1;
	Inst.Dim.Y = 1;
	for (i = 0; i < Params.Length; i++)
	{
		P = Geom.GetTile2DCoords(Params[i].Tile);
		Inst.Source.X = P.X;
		Inst.Source.Y = P.Y;
		Inst.Color = ColorForState(Params[i].NewState);

		RenderQueue.AddItem(Inst);
	}
}

function Clear(EECVisState NewState)
{
	local RenderInstruction Inst;

	FOWTexture.bNeedsUpdate = true;

	Inst.Source.X = 0;
	Inst.Source.Y = 0;
	Inst.Dim.X = Width;
	Inst.Dim.Y = Height;
	Inst.Color = ColorForState(NewState);

	RenderQueue.AddItem(Inst);
}

function Color ColorForState(EECVisState VisState)
{
	switch (VisState)
	{
		case eECVS_Unexplored:
		case eECVS_Explored:
			return BLACK;
		case eECVS_Vision:
		case eECVS_Full:
			return WHITE;
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
	`assrt(GetTileDistance(Geom.GetHandleFromCoords(4,5),Geom.GetHandleFromCoords(4,4)), 1);
	`assrt(GetTileDistance(Geom.GetHandleFromCoords(5,4),Geom.GetHandleFromCoords(4,4)), 1);
	`assrt(GetTileDistance(Geom.GetHandleFromCoords(2,2),Geom.GetHandleFromCoords(1,3)), 1);
	`assrt(GetTileDistance(Geom.GetHandleFromCoords(2,2),Geom.GetHandleFromCoords(3,3)), 2);
	`assrt(GetTileDistance(Geom.GetHandleFromCoords(0,0),Geom.GetHandleFromCoords(3,3)), 5);
	`assrt(GetTileDistance(Geom.GetHandleFromCoords(0,39),Geom.GetHandleFromCoords(59,0)), 39+39);
	`assrt(GetTileDistance(Geom.GetHandleFromCoords(0,39),Geom.GetHandleFromCoords(58,0)), 39+38);
	`assrt(GetTileDistance(Geom.GetHandleFromCoords(0,0),Geom.GetHandleFromCoords(59,39)), 39+40);
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
	WHITE=(R=255,G=255,B=255,A=255)
	BLACK=(R=0,G=0,B=0,A=255)
}