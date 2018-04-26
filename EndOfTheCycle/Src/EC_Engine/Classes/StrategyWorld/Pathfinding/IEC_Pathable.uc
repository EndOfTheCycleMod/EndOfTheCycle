// Interface for all IEC_StrategyWorldEntities that want to use pathing.
// Player units will receive a pathing pawn, while the AI will consider
// these units pathable
interface IEC_Pathable;

// Ent_isMovable should return the general possibility of
// this unit moving. I.e. a landed avenger should probably return false.
function bool Path_IsMovable();
// Return information to the pathing system
function MoverData Path_GetMoverData();
// Called when the input system / pathfinding system confirms a path
// This path may not be valid! You may not have enough action points,
// or the path may lead through mountains that were in Fog of War
function Path_QueuePath(array<PathfindingNode> PathNodes);