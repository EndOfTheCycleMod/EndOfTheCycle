class EC_GameState_MapTileData extends XComGameState_BaseObject;

enum EECTileType
{
	eECTT_Water,
	eECTT_Flat,
	eECTT_Wilderness,
	eECTT_Mountain,
};

var int Width, Height;

var array<EECTileType> Tiles;

struct MapGenTile
{
	var int TileIndex;
	var int Height;
	var float Priority;
	var int MarkStep;
};

var transient array<MapGenTile> TempTiles;

var transient int GlobalStep;

// Adapted from http://catlikecoding.com/unity/tutorials/hex-map/part-23/
function CreateRandomMap(int w, int h)
{
	local int i, j;
	local int LandBudget, ChunkSizeMin, ChunkSizeMax, ChunkSize;
	local float TargetLandRatio;
	local EC_DynamicTiledMap TempMap;

	Width = w;
	Height = h;

	// TODO: Unfizzle this
	TempMap = class'WorldInfo'.static.GetWorldInfo().Spawn(class'EC_DynamicTiledMap');
	TempMap.Height = Height;
	TempMap.Width = Width;
	TempMap.TileMeshes.Length = Height * Width;

	TargetLandRatio = 0.5;
	
	Tiles.Length = w * h;
	TempTiles.Length = w * h;

	LandBudget = Tiles.Length * TargetLandRatio;
	
	for (i = 0; i < h; i++)
	{
		for (j = 0; j < w; j++)
		{
			Tiles[i * w + j] = eECTT_Water;
			TempTiles[i * w + j].TileIndex = i * w + j;
			TempTiles[i * w + j].Height = 0;
			TempTiles[i * w + j].MarkStep = 0;
			TempTiles[i * w + j].Priority = 0;
		}
	}
	GlobalStep = 0;
	ChunkSizeMin = 30;
	ChunkSizeMax = 100;
	while (LandBudget > 0)
	{
		ChunkSize = Rand(ChunkSizeMax - ChunkSizeMin) + ChunkSizeMin;
		LandBudget = RaiseTerrain(ChunkSize, LandBudget, TempMap);
	}
	for (i = 0; i < h; i++)
	{
		for (j = 0; j < w; j++)
		{
			Tiles[i * w + j] = EECTileType(Clamp(TempTiles[i * w + j].Height, 0, 3));
		}
	}
	TempMap.Destroy();
}

function int RaiseTerrain(int ChunkSize, int LandBudget, EC_DynamicTiledMap Map)
{
	local int size, rise;
	local array<int> TileQueue;
	local array<int> Neighbors;
	local int i;
	local int NewTile, Tile;
	local int Ctr;
	local int Enqueued, Dequeued;

	Enqueued = 0;
	Dequeued = 0;
	GlobalStep++;

	NewTile = Rand(Map.TileMeshes.Length);

	TempTiles[NewTile].Priority = 0;
	TempTiles[NewTile].MarkStep = GlobalStep;
	Enqueue(NewTile, TileQueue);
	Enqueued++;
	Ctr = NewTile;

	size = 0;
	rise = (Rand(100) < 20) ? 2 : 1;
	while (size < ChunkSize && TileQueue.Length > 0)
	{
		Tile = Dequeue(TileQueue);
		Dequeued++;
		if (TempTiles[Tile].Height == 0)
		{
			LandBudget--;
			if (LandBudget == 0)
			{
				return LandBudget;
			}
		}
		TempTiles[Tile].Height = Min(3, TempTiles[Tile].Height + rise);
		size++;
		Neighbors = Map.GetAdjacentMapPositions(Tile);
		for (i = 0; i < Neighbors.Length; i++)
		{
			if (TempTiles[Neighbors[i]].MarkStep < GlobalStep)
			{
				NewTile = Neighbors[i];
				TempTiles[NewTile].MarkStep = GlobalStep;
				TempTiles[NewTile].Priority = Map.GetTileDistance(Ctr, NewTile);
//				if (Rand(100) < 25)
//				{
					TempTiles[NewTile].Priority *= (1 + FRand());
//				}
				Enqueue(NewTile, TileQueue);
				Enqueued++;
			}
		}
	}
	return LandBudget;
}

final function Enqueue(int Tile, out array<int> Queue)
{
	local int i;
	for (i = 0; i < Queue.Length; i++)
	{
		if (TempTiles[Tile].Priority > TempTiles[Queue[i]].Priority)
		{
			break;
		}
	}
	Queue.InsertItem(i, Tile);
}

final function int Dequeue(out array<int> Queue)
{
	local int T;
	T = Queue[Queue.Length - 1];
	Queue.Remove(Queue.Length - 1, 1);
	return T;
}