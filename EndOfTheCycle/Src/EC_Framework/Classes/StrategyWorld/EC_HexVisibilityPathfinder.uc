// Custom pathfinder class for the visibility manager.
// Uses an algorithm adapted from http://catlikecoding.com/unity/tutorials/hex-map/part-22/
// The general idea is to find the shortest path to the target / each tile, avoiding obstacles, and discard
// tiles that aren't reached with the shortest path.
// This is a very simple algorithm that probably ends up being rather counter-intuitive
// A better, but much more complicated algorithm can be found at http://www-cs-students.stanford.edu/~amitp/Articles/HexLOS.html
class EC_HexVisibilityPathfinder extends EC_AbstractPathfinder within EC_AbstractHexMap;

// Only valid during Pathfinding
var transient int SourceHeightOffset, SightRange, SourceHeight, StartTile;

function SetParams(int _SourceHeightOffset, int _SightRange)
{
	self.SourceHeightOffset = _SourceHeightOffset;
	self.SightRange = _SightRange;
}

function PathfindingResult BuildPath(int Start, int End, MoverData MoveData)
{
	self.SourceHeight = Map.GetTileElevation(Start) + SourceHeightOffset;
	self.StartTile = Start;
	return super.BuildPath(Start, End, MoveData);
}
function bool CanEnter(int Tile, const out MoverData MoveData)
{
	return Map.GetTileDistance(StartTile, Tile) <= SightRange;
}
// We allow the sight range to enter tiles that are higher than the source height, but we don't allow
// the "path" to leave them -- obstacles "block" LOS, but you can still see the obstacles themselves
function bool CanCross(int FromTile, int ToTile, const out MoverData MoveData)
{
	return Map.GetTileElevation(FromTile) <= SourceHeight;
}

// Only from neighbor to neighbor!
function int GetCost(int FromTile, int ToTile, const out MoverData MoveData)
{
	// No move denominator
	return 1;
}

function int GetCostHeuristic(int FromTile, int ToTile, const out MoverData MoveData)
{
	if (ToTile >= 0)
	{
		return Map.GetTileDistance(FromTile, ToTile);
	}
	return 0;
}
