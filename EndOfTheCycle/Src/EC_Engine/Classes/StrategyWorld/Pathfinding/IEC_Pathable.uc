interface IEC_Pathable;

// Ent_isMovable should return the general possibility of
// this unit moving. I.e. a landed avenger should probably return false.
function bool Path_IsMovable();
function MoverData Path_GetMoverData();
// Store a path to perform later
function QueuePath(array<int> Path);
// Perform the queued path
function PerformQueuedPath();