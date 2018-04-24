// Interface for everything that can be standalone on the strategy map
interface IEC_StrategyWorldEntity;

// is this entity on the map? certain entities may be stored somewhere in other entities, so they aren't on the map
function bool Ent_IsOnMap();
// get the owning entity of this. Should be something if Ent_IsOnMap() == false
function StateObjectReference Ent_GetOwningEntity();
// get the current position this entity is occupying. Should be not-none if Ent_IsOnMap() == true
function int Ent_GetPosition();
// Forces the position to the given tile. Should only ever be used for initialization
function Ent_ForceSetPosition(int Pos, XComGameState NewGameState);

// get the owning player of this entity. may be none
function StateObjectReference Ent_GetStrategyOwningPlayer();
// get the currently controlling player of this entity
function StateObjectReference Ent_GetStrategyControllingPlayer();

// find the visualizer
function Actor Ent_GetVisualizer();
function Actor Ent_FindOrCreateVisualizer();