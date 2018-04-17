// Generic Unit interface.
// May not always have a backing game state object! some units may be stored much more efficiently
interface IEC_Unit;

function name Un_GetUnitTemplateName();

function string Un_GetName(optional ENameType NameType = eNameType_Full);
function string Un_GetIcon();
function string Un_GetPortrait();

// Does this unit have a UnitState?
function bool Un_HasAssociatedUnitState();
// If so, return here a reference to it
function StateObjectReference Un_GetUnitRef();
// If not, create it in this game state.
function XComGameState_Unit Un_CreateUnitState(XComGameState NewGameState);

function int Un_GetUnitSize();
// support for arbitrary tags
function array<name> Un_GetUnitTags();
// Can't compare references
function bool Un_Equals(IEC_Unit Other);