// A Dynamic Tiled Map that can be used for simple prototyping and testing. Ugly, but functional.
class EC_DynamicTiledMap extends EC_AbstractHexMap;

const SQRT_3 = 1.73205080756f;
var const vector VertexOffsets[6];

var StaticMesh HexMesh;

var MaterialInstanceConstant MIC_Flat;
var MaterialInstanceConstant MIC_Wilderness;
var MaterialInstanceConstant MIC_Water;
var MaterialInstanceConstant MIC_Mountain;

var array<StaticMeshComponent> TileMeshes;

var transient vector MouseWorldOrigin, MouseWorldDirection;

// EC_Hex.M_Hex / EC_Hex.SM_Hex

// IEC_StrategyMap interface

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

	Geom = new class'HexGeometry';
	Geom.SetDimensions(Width, Height);

	Vis = new (self) class'EC_HexVisibilityPathfinder';
	Vis.Init(self);

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
			SMC.SetTraceBlocking(true, true);
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

function bool GetWorldPositionAndRotation(int PosHandle, out vector pos, out rotator rot)
{
	pos = TileMeshes[PosHandle].Translation;
	rot = TileMeshes[PosHandle].Rotation;
	return true;
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

function int GetEdgeInfo(int Pos)
{
	return 0;
}

function int GetTileElevation(int Pos)
{
	local EC_GameState_MapTileData MapData;

	MapData = EC_GameState_MapTileData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'EC_GameState_MapTileData'));

	switch (MapData.Tiles[Pos])
	{
		case eECTT_Water:
			return 0;
		case eECTT_Flat:
		case eECTT_Wilderness:
			return 5;
		case eECTT_Mountain:
			return 9;
	}
}

function array<InterpCurveVector> TraceBorders(array<int> Tiles, float Alpha)
{
	local array<BorderTrace> Borders;
	local BorderTrace B;
	local int i, j;
	local array<InterpCurveVector> Ret;
	local InterpCurveVector Curve, EmptyCurve;
	local InterpCurvePointVector Point;

	Borders = Geom.TraceBorders(Tiles);

	EmptyCurve.InterpMethod = IMT_UseFixedTangentEvalAndNewAutoTangents;
	Point.InterpMode = CIM_Linear; // TEST

	for (i = 0; i < Borders.Length; i++)
	{
		Curve = EmptyCurve;
		B = Borders[i];
		for (j = 0; j < B.Vertices.Length; j++)
		{
			Point.InVal = j;
			Point.OutVal = TileMeshes[B.Vertices[j].X].Translation + VertexOffsets[B.Vertices[j].Y] * HEX_SIZE * -1 * Alpha + vect(0,0,10);
			Curve.Points.AddItem(Point);
		}
		Ret.AddItem(Curve);
	}

	return Ret;
}

static function CreateRandomMap(XComGameState NewGameState)
{
	local EC_GameState_MapTileData Data;

	Data = EC_GameState_MapTileData(NewGameState.CreateNewStateObject(class'EC_GameState_MapTileData'));
	Data.CreateRandomMap(60, 40);
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local vector2d MouseLocation;

	local Vector HitLocation, HitNormal;
	local TraceHitInfo TraceInfo;
	local EC_DynamicTiledMap HitActor;
	local int HitCompIndex;
	local vector TrEnd;

	MouseLocation = LocalPlayer(GetALocalPlayerController().Player).ViewportClient.GetMousePosition();
	kCanvas.DeProject(MouseLocation, MouseWorldOrigin, MouseWorldDirection);

	TrEnd = MouseWorldOrigin + (MouseWorldDirection * 16384);

//	`log("Trace from ("$MouseWorldOrigin.X$", "$MouseWorldOrigin.Y$", "$MouseWorldOrigin.Z$") to ("$TrEnd.X$", "$TrEnd.Y$", "$TrEnd.Z$")");
	// Do a simple bullet trace against the map itself
	foreach WorldInfo.TraceActors(class'EC_DynamicTiledMap',
								HitActor,
								HitLocation,
								HitNormal,
								TrEnd,
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

event Tick(float DeltaTime)
{
	//`ECSHAPES.DrawCylinder(MouseWorldOrigin, MouseWorldOrigin + (MouseWorldDirection * 16384), 30);
}

defaultproperties
{
	VertexOffsets(0)=(X=0,Y=1,Z=0)
	VertexOffsets(1)=(X=-0.866,Y=0.5,Z=0)
	VertexOffsets(2)=(X=-0.866,Y=-0.5,Z=0)
	VertexOffsets(3)=(X=0,Y=-1,Z=0)
	VertexOffsets(4)=(X=0.866,Y=-0.5,Z=0)
	VertexOffsets(5)=(X=0.866,Y=0.5,Z=0)
	// TODO: Evaluate
	bStatic=false
	bStaticCollision=true
	bWorldGeometry=true
	bCollideActors=true
	bBlockActors=true
	bMovable=false
	CollisionType=COLLIDE_BlockAll
}