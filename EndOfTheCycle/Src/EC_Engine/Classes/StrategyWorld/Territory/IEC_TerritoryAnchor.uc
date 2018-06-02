// Interface for geoscape entities granting control over territory (tiles)
interface IEC_TerritoryAnchor;

function array<int> Ter_GetTiles();
function StateObjectReference Ter_GetPlayer();
function int Ter_GetPriority();