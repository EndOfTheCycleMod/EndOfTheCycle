// Actor that allows external systems to respond to pathing queries without
// having to poll the map. This class maintains an efficient (both space and time) representation
// of the strategy map graph.
// Internally this class uses Dijkstra's Algorithm to find paths. A* was considered, but deemed unrealiable
// as game mechanics may complicate the distance heuristic to the point where we hit dimishing returns.
class EC_Pathfinder extends Actor;

// Traversal rules
const TRAV_GROUND       = 0x0001;
const TRAV_MOUNTAIN     = 0x0002;
const TRAV_AIR          = 0x0004;
const TRAV_RAIL         = 0x0008;
const TRAV_ROAD         = 0x0010;
const TRAV_SPECIAL      = 0x0020;

struct PathfindingNode
{
	var int Tile;
	var int Distance;
	var int VisitedViaIndex; // Index into the PathfindingResult's array of Nodes
	var int TraversalType;
};

// Stores properties of a given movable object about its mobility
struct MoverData
{
	//var int ObjectID; // Do we need this or do we introduce unnecessary dependencies this way?
	var int Mobility; // Mobility
	var int AllowedPositionTileTypes; // Bitfield of tile types that can be entered (see IEC_StrategyMap)
	var int AllowedTraversalTypes; // Bitfield of traversal types that can be used (see consts above)
};


// Stores an exploration of the reachable tiles from a given source tile with a given mobility, or a path to a given goal
struct PathfindingResult
{
	// The tile position we started on
	var int StartPosition;
	// If >= 0, goal position. Otherwise this is a Dijkstra exploration
	var int GoalTile;
	// Copy of the mover data used
	var MoverData Data;
	// Array containing the node exploration. If GoalTile >= 0, the last
	// entry is the goal.
	var array<PathfindingNode> Nodes;
};

var IEC_StrategyMap Map;

// Explicit map initialization
function Init(IEC_StrategyMap _Map)
{
	Map = _Map;
}