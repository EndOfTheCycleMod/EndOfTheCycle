// Interface for everything that wants to see other entities on the strategy world
// Things that only get seen may not implement this class -- all Game State Objects
// implementing IEC_StrategyWorldEntity can be seen!
// Must also implement IEC_StrategyWorldEntity
interface IEC_VisibilityInterface;

function int Vis_GetSightRange();
function int Vis_GetSightHeight();
// Get players this entity provides visibility for
function array<StateObjectReference> Vis_GetPlayers();