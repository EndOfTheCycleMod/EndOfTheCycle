// Base class for a path solver. Provides a default implementation of A*, though
// subclasses are free to use whatever they want to.
class EC_Pathfinder extends Actor dependson(EC_VisibilityManager);

enum EECUnitDomain
{
	eUD_None,  // effectively immobile
	eUD_Land,  // moves on land
	eUD_Water, // moves on water
	eUD_Hover, // can move on land and water
};


// Pathfinding structs

struct PathfindingNode
{
	var int Tile;
	var int Distance;
	var int TentativeDistance;
	var int VisitedViaIndex; // Index into the ClosedSet
};

// Stores properties of a given movable object about its mobility
struct MoverData
{
	var int ObjectID; // Do we need this or do we introduce unneccessary dependencies? Keeping for comparison now
	var int PlayerObjectID; // 
	var int Mobility; // Mobility per turn
	var int CurrentMobility; // Leftover mobility for this turn
	var int MoverFlags;
	var EECUnitDomain Domain;
	var class<EC_Pathfinder> PathfinderClass;
};

// Stores an exploration from a path to a given goal
struct PathfindingResult
{
	// The tile position we started on
	var int StartPosition;
	// Goal tile
	var int GoalPosition;
	// Copy of the mover data used
	var MoverData Data;
	// Was the path a success?
	var bool PathFound;
	// Array containing the path
	var array<PathfindingNode> Nodes;

	structdefaultproperties
	{
		StartPosition=-2
		GoalPosition=-2
	}
};


var IEC_StrategyMap Map;

// Explicit map initialization
function Init(IEC_StrategyMap _Map)
{
	Map = _Map;
}

// Pass a negative value to End to indicate that instead a Dijkstra exploration should be done
function PathfindingResult BuildPath(int Start, int End, MoverData MoveData)
{
	local PathfindingNode EmptyNode, Node, Neighbor;
	local array<PathfindingNode> OpenSet, ClosedSet;
	local array<int> Neighbors;
	local int N, OpenSetIdx, NewDist, Next;
	local PathfindingResult Result;

	Result.StartPosition = Start;
	Result.GoalPosition = End;
	Result.Data = MoveData;
	Result.PathFound = false;

	if (End < 0 || CanEnter(End, MoveData))
	{
		/*if (End < 0)
		{
			`log("Dijkstra from" @ Map.GetPositionDebugInfo(Start));
		}
		else
		{
			`log("Path from" @ Map.GetPositionDebugInfo(Start) @ "to" @ Map.GetPositionDebugInfo(End));
		}*/
		Node = EmptyNode;
		Node.Tile = Start;
		Node.Distance = 0;
		Node.TentativeDistance = GetCostHeuristic(Start, End, MoveData);
		Node.VisitedViaIndex = -1;
		Enqueue(Node, OpenSet);
		while (OpenSet.Length > 0)
		{
			Node = Dequeue(OpenSet);
			ClosedSet.AddItem(Node);

			if (Node.Tile == End)
			{
				Result.PathFound = true;
				break;
			}

			Neighbors = GetNeighbors(Node.Tile);
			foreach Neighbors(N)
			{
				if (!CanEnter(N, MoveData))
					continue;
				if (ClosedSet.Find('Tile', N) != INDEX_NONE)
					continue;

				OpenSetIdx = OpenSet.Find('Tile', N);
				if (OpenSetIdx != INDEX_NONE)
				{
					// Extract the node, as we may update its score. Sounds complicated, but is more straightforward
					Neighbor = Extract(OpenSetIdx, OpenSet);
				}
				else
				{
					Neighbor.Tile = N;
					Neighbor.Distance = MaxInt;
					Neighbor.TentativeDistance = MaxInt;
				}
				NewDist = Node.Distance + GetCost(Node.Tile, Neighbor.Tile, MoveData);
				if (NewDist < Neighbor.Distance)
				{
					Neighbor.VisitedViaIndex = ClosedSet.Length - 1;
					Neighbor.Distance = NewDist;
					Neighbor.TentativeDistance = Neighbor.Distance + GetCostHeuristic(Neighbor.Tile, End, MoveData);
				}
				Enqueue(Neighbor, OpenSet);
			}
		}
	}
	if (!Result.PathFound)
	{
		if (End < 0)
		{
			Result.Nodes = ClosedSet;
		}
		else
		{
			Result.Nodes.Length = 0;
		}
	}
	else
	{
		// The last ClosedSet entry contains the goal
		`assert(ClosedSet[ClosedSet.Length - 1].Tile == End);
		Next = ClosedSet.Length - 1;
		while (Next >= 0)
		{
			Node = ClosedSet[Next];
			Next = Node.VisitedViaIndex;
			Result.Nodes.InsertItem(0, Node);
		}
	}
	return Result;
}

static final function int Enqueue(PathfindingNode Node, out array<PathfindingNode> Queue)
{
	local int i;
	for (i = 0; i < Queue.Length; i++)
	{
		if (Node.TentativeDistance > Queue[i].TentativeDistance)
		{
			break;
		}
	}
	Queue.InsertItem(i, Node);
	return i;
}

static final function PathfindingNode Extract(int Index, out array<PathfindingNode> Queue)
{
	local PathfindingNode N;
	N = Queue[Index];
	Queue.Remove(Index, 1);
	return N;
}

static final function PathfindingNode Dequeue(out array<PathfindingNode> Queue)
{
	return Extract(Queue.Length - 1, Queue);
}

// Overrideable functions
function array<int> GetNeighbors(int Tile)
{
	return Map.GetAdjacentMapPositions(Tile);
}
function bool CanEnter(int Tile, const out MoverData MoveData)
{
	switch (MoveData.Domain)
	{
		case eUD_Land:
			return (Map.GetTileInfo(Tile) & (class'IEC_StrategyMap'.const.TILE_GROUND | class'IEC_StrategyMap'.const.TILE_VEGETATION)) != 0;
		case eUD_Water:
			return (Map.GetTileInfo(Tile) & class'IEC_StrategyMap'.const.TILE_WATER) != 0;
		case eUD_Hover:
			return true;
		case eUD_None:
			return true;
	}
}
function bool CanCross(int FromTile, int ToTile, const out MoverData MoveData)
{
	return true;
}
// Only from neighbor to neighbor!
function int GetCost(int FromTile, int ToTile, const out MoverData MoveData)
{
	return 1 * `MOVE_DENOMINATOR;
}

function int GetCostHeuristic(int FromTile, int ToTile, const out MoverData MoveData)
{
	if (ToTile >= 0)
	{
		return Map.GetTileDistance(FromTile, ToTile) * `MOVE_DENOMINATOR;
	}
	return 0;
}
