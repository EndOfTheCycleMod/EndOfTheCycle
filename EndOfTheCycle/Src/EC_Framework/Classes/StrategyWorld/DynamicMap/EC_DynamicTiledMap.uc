// A Dynamic Tiled Map that can be used for simple prototyping and testing. Ugly, but functional.
class EC_DynamicTiledMap extends Actor implements(IEC_StrategyMap);


const HEX_SIZE = 144.0f;         // 96 * 1.5
const HEX_DST = 249.415316289f;  // 2 * HEX_SIZE * cos(30°)
const SQRT_3 = 1.73205080756f;

struct PointNeighbors
{
	var IntPoint p[6];
};

var const PointNeighbors Directions[2];

var StaticMesh HexMesh;

var MaterialInstanceConstant MIC_Flat;
var MaterialInstanceConstant MIC_Wilderness;
var MaterialInstanceConstant MIC_Water;
var MaterialInstanceConstant MIC_Mountain;

// The map has this layout (X,Y)
// 0,0   1,0   2,0   3,0   ... Width,0
//    0,1   1,1   2,1   3,1...    Width,1
// 0,2   1,2   2,2   3,2   ... Width,2
//    0,3   1,3   2,3   3,3...    Width,3
// ...

var int Width, Height;
var array<StaticMeshComponent> TileMeshes;

var transient int LastHoveredTile;

// EC_Hex.M_Hex / EC_Hex.SM_Hex

function LoadMap()
{
	local Material ParentMat;
	local EC_GameState_MapTileData MapData;
	local int x, y;
	local StaticMeshComponent SMC;
	local vector TileTrans;
	local LinearColor TempColor;

	`log("Loading map at position X: " $ Location.X $ ", Y: " $ Location.Y $ ", Z: " $ Location.Z);

	MapData = EC_GameState_MapTileData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'EC_GameState_MapTileData'));
	Width = MapData.Width;
	Height = MapData.Height;
	`log(Width $"x"$ Height);

	HexMesh = StaticMesh(`CONTENT.RequestGameArchetype("EC_Hex.SM_Hex"));
	ParentMat = Material(`CONTENT.RequestGameArchetype("EC_Hex.M_Hex"));
	
	TempColor = MakeLinearColor(0.8, 1.0, 0.0, 1.0);
	MIC_Flat = new class'MaterialInstanceConstant';
	MIC_Flat.SetParent(ParentMat);
	MIC_Flat.SetVectorParameterValue('Color', TempColor);

	TempColor = MakeLinearColor(0.0, 0.4, 0.0, 1.0);
	MIC_Wilderness = new class'MaterialInstanceConstant';
	MIC_Wilderness.SetParent(ParentMat);
	MIC_Wilderness.SetVectorParameterValue('Color', TempColor);

	TempColor = MakeLinearColor(0.4, 0.7, 1.0, 1.0);
	MIC_Water = new class'MaterialInstanceConstant';
	MIC_Water.SetParent(ParentMat);
	MIC_Water.SetVectorParameterValue('Color', TempColor);

	TempColor = MakeLinearColor(0.8, 0.8, 1.0, 1.0);
	MIC_Mountain = new class'MaterialInstanceConstant';
	MIC_Mountain.SetParent(ParentMat);
	MIC_Mountain.SetVectorParameterValue('Color', TempColor);

	for (y = 0; y < Height; y++)
	{
		for (x = 0; x < Width; x++)
		{
			SMC = new class'StaticMeshComponent';
			SMC.SetStaticMesh(HexMesh);
			switch (MapData.Tiles[y * Width + x])
			{
				case eECTT_Water:
					SMC.SetMaterial(0, MIC_Water);
					TileTrans.Z = 0.0f;
					break;
				case eECTT_Flat:
					SMC.SetMaterial(0, MIC_Flat);
					TileTrans.Z = 30.0f;
					break;
				case eECTT_Wilderness:
					SMC.SetMaterial(0, MIC_Wilderness);
					TileTrans.Z = 30.0f;
					break;
				case eECTT_Mountain:
					SMC.SetMaterial(0, MIC_Mountain);
					TileTrans.Z = 60.0f;
					break;
			}
			AttachComponent(SMC);
			TileTrans.X = HEX_SIZE * SQRT_3 * (x + 0.5f * (y & 1));
			TileTrans.Y = HEX_SIZE * 1.5f * y;
			SMC.SetTranslation(TileTrans);
			TileMeshes.AddItem(SMC);
		}
	}
	// Register for the PostRender function that lets us project the mouse cursor
	AddHUDOverlayActor();
}

function bool IsLoaded()
{
	return true;
}

function X2Camera CreateDefaultCamera()
{
	local EC_Camera_FollowMouseCursor Cam;
	local Box Dimensions;
	
	Cam = new class'EC_Camera_FollowMouseCursor';
	Dimensions.Min = Location;
	Dimensions.Max.X = Location.X + HEX_SIZE * (width + 1) * SQRT_3;
	Dimensions.Max.Y = Location.Y + HEX_SIZE * (height) * 1.5;
	Dimensions.Max.Z = Location.Z;
	Cam.SetGameVolume(Dimensions);

	return Cam;

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
		if (IsPointOnBoard(TempPoint.X, TempPoint.Y))
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

function bool GetWorldPositionAndRotation(int PosHandle, out vector pos, out rotator rot)
{
	pos = TileMeshes[PosHandle].Translation;
	rot = TileMeshes[PosHandle].Rotation;
	return true;
}

function int GetCursorHighlightedTile()
{
	return LastHoveredTile;
}

function int GetTileInfo(int Pos)
{
	local EC_GameState_MapTileData MapData;

	MapData = EC_GameState_MapTileData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'EC_GameState_MapTileData'));

	switch (MapData.Tiles[Pos])
	{
		case eECTT_Water:
			return class'IEC_StrategyMap'.const.TILE_WATER;
		case eECTT_Flat:
			return class'IEC_StrategyMap'.const.TILE_GROUND;
		case eECTT_Wilderness:
			return class'IEC_StrategyMap'.const.TILE_VEGETATION;
		case eECTT_Mountain:
			return class'IEC_StrategyMap'.const.TILE_MOUNTAIN;
	}
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

static function CreateRandomMap(XComGameState NewGameState)
{
	local EC_GameState_MapTileData Data;

	Data = EC_GameState_MapTileData(NewGameState.CreateNewStateObject(class'EC_GameState_MapTileData'));
	Data.CreateRandomMap(60, 40);
}


function string GetPositionDebugInfo(int Pos)
{
	local IntPoint P;
	P = GetTile2DCoords(Pos);
	return "Position at X:" @ P.X $ ", Y:" @ P.Y;
}




private function IntPoint GetTile2DCoords(int TileHandle)
{
	local IntPoint P;
	P.X = TileHandle % Width;
	P.Y = TileHandle / Width;
	return P;
}

private function int GetHandleFromCoords(int x, int y)
{
	return y * Width + x;
}

private function int GetHandleFromPoint(IntPoint p)
{
	return p.y * Width + p.x;
}

private function bool IsPointOnBoard(int x, int y)
{
	return x > -1 && y > -1 && x < Width && y < Height;
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local vector MouseWorldOrigin, MouseWorldDirection;
	local vector2d MouseLocation;

	local Vector HitLocation, HitNormal;
	local TraceHitInfo TraceInfo;
	local EC_DynamicTiledMap HitActor;
	local int HitCompIndex;

	local UIMouseCursor Cursor;

	Cursor = `PRESBASE.m_kUIMouseCursor;

	Cursor.UpdateMouseLocation();
	MouseLocation = Cursor.m_v2MouseLoc;
	kCanvas.DeProject(MouseLocation, MouseWorldOrigin, MouseWorldDirection);

	// Do a simple bullet trace against the map itself
	foreach TraceActors(class'EC_DynamicTiledMap',
								HitActor,
								HitLocation,
								HitNormal,
								MouseWorldOrigin + (MouseWorldDirection * 16384),
								MouseWorldOrigin,
								vect(0,0,0),
								TraceInfo,
								TRACEFLAG_Bullet)
	{
		// If we hit a strategy map, it better be us
		`assert(HitActor == self);
		HitCompIndex = TileMeshes.Find(TraceInfo.HitComponent);
		// We better don't have any components we don't know about
		`assert(HitCompIndex > INDEX_NONE);
		LastHoveredTile = HitCompIndex;
		return;
	}
	LastHoveredTile = INDEX_NONE;
}

defaultproperties
{
	Directions(0)=(p[0]=(X=1, Y=0), p[1]=(X=0, Y=-1), p[2]=(X=-1, Y=-1), p[3]=(X=-1, Y=0), p[4]=(X=-1, Y=1), p[5]=(X=0, Y=1))
	Directions(1)=(p[0]=(X=1, Y=0), p[1]=(X=1, Y=-1), p[2]=(X=0, Y=-1), p[3]=(X=-1, Y=0), p[4]=(X=0, Y=1), p[5]=(X=1, Y=1))
}