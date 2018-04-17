interface IEC_StrategyMap;


function LoadMap();
// Polling function for LoadMap
function bool IsLoaded();

// Create the default camera for this map. Corresponds to the standard X2Camera_FollowMouseCursor in tactical
function X2Camera CreateDefaultCamera();

// The map communicates to external systems via position *handles*. They need to be unique and 
// consistent over the course of a campaign, even handling potential map updates gracefully
// A position is a non-negative integer.
function array<int> GetAdjacentMapPositions(int Pos);
function bool AreAdjacent(int A, int B);

function bool GetWorldPositionAndRotation(int PosHandle, out vector pos, out rotator rot);

// Return the handle of the currently highlighted tile, or a negative integer to indicate that no tile is highlighted
function int GetCursorHighlightedTile();

// Debug functionality
static function CreateRandomMap(XComGameState NewGameState);
function string GetPositionDebugInfo(int Pos);