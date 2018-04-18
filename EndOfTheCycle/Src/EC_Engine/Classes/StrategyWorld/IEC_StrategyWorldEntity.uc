// Interface for everything that can be standalone on the strategy map
interface IEC_StrategyWorldEntity;

// is this entity on the map? certain entities may be stored somewhere in other entities, so they aren't on the map
function bool Ent_IsOnMap();
// get the owning entity of this. Should be something if Ent_IsOnMap() == false
function StateObjectReference Ent_GetOwningEntity();
// get the current position this entity is occupying. Should be not-none if Ent_IsOnMap() == true
function int Ent_GetPosition();

// get the owning player of this entity. may be none
function StateObjectReference Ent_GetStrategyOwningPlayer();
// get the currently controlling player of this entity
function StateObjectReference Ent_GetStrategyControllingPlayer();

// Ent_isMovable should return the general possibility of
// this unit moving. Even units that are temporarily not able to move
// (mobility 0) can return true
function bool Ent_IsMovable();
function MoverData Ent_GetMoverData();


// find the visualizer
function Actor Ent_GetVisualizer();
function Actor Ent_FindOrCreateVisualizer();