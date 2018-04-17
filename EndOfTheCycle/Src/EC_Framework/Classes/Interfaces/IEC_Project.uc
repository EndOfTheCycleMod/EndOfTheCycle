// generic interface for any project that may need to be completed
// projects generally may require work, resources and items
// GameState-Object
interface IEC_Project;

// The costs required for this project to complete
function ECStrategyCost Proj_GetAllCosts();
// The costs that are *still* required
function ECStrategyCost Proj_GetRemainingCosts();
// The costs that this project has converted into progress
function ECStrategyCost Proj_GetInvestedCosts();
// The costs that this project has reserved, but not yet converted into progress
// When a project is cancelled, all allocated costs need to be freed without modification
function ECStrategyCost Proj_GetAllocatedCosts();

// progress of this project
function float Proj_GetProgress();
// priority of this project. defines order in which work is done
function int Proj_GetPriority();
// whether this project can be paused and unpaused
function bool Proj_AllowStartPause();
// whether this project can receive work
function bool Proj_CanReceiveWork();
// whether this project can ever be completed at all
function bool Proj_CanEverBeCompleted();
// can the project be repeated upon completion?
function bool Proj_CanBeRepeated();

// Free all invested and allocated resources and resets progress
function bool Proj_CanCancel(optional XComGameState NewGameState, optional out string FailReason);
function bool Proj_Cancel(optional XComGameState NewGameState);

// The initiating thing of this project, and the target of the project
// Both may not exist
function StateObjectReference Proj_GetProjectSource();
function StateObjectReference Proj_GetProjectFocus();