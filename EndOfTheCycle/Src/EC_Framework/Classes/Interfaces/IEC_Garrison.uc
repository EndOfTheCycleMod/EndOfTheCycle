// Interface for everything that can hold units.
// GameState-Object
interface IEC_Garrison;

// capacity for units
function int Gar_GetCurrentlyFilledCapacity();
function int Gar_GetMaxCapacity();

function int Gar_GetUnitCount();
function array<IEC_Unit> Gar_GetUnits();
function IEC_Unit Gar_GetLeadingUnit();