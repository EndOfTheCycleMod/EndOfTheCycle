interface IEC_StrategyMap;

// Basic tile types for map queries
const TILE_GROUND       = 0x0001; // Open ground
const TILE_VEGETATION   = 0x0002; // Dense vegetation
const TILE_WATER        = 0x0004; // Water tiles
const TILE_MOUNTAIN     = 0x0008; // Mountain tiles

function LoadMap();
// Polling function for LoadMap
function bool IsLoaded();

// Create the default camera for this map. Corresponds to the standard X2Camera_FollowMouseCursor in tactical
function X2Camera CreateDefaultCamera();

// The map communicates to external systems via position *handles*. They need to be unique and 
// consistent over the course of a campaign, even handling potential map updates gracefully.
// A position is a non-negative integer. These integers need not be continuous,
// but are encouraged to be continuous since this improves performance for certain functions (see GetValidPositionRanges)
// It should be noted that these functions should only be used by Engine classes -- a class
// implementing this interface is not the authority about pathing queries. These functions simply
// return the base map's features to the Pathing system, which may apply additional rules (like teleporters or w/e)
function array<int> GetAdjacentMapPositions(int Pos);
function bool AreAdjacent(int A, int B);

function bool GetWorldPositionAndRotation(int PosHandle, out vector pos, out rotator rot);

// Return the handle of the currently highlighted tile, or a negative integer to indicate that no tile is highlighted
function int GetCursorHighlightedTile();

// Return one of the TILE_ consts above
function int GetTileInfo(int Pos);

// Return an array of inclusive ranges representing valid tile handles
// The Map interface doesn't require that this is a good representation,
// but it's rather likely that tile handles will be *somewhat* continuous
function array<IntPoint> GetValidPositionRanges();

// Debug functionality
static function CreateRandomMap(XComGameState NewGameState);
function string GetPositionDebugInfo(int Pos);