// Simple prototype move context. No interrupts and fairly specific implementation
class EC_GameStateContext_SimplePath extends XComGameStateContext;

var StateObjectReference Unit;
var array<int> MoveTiles;

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	local XComGameState NewGameState;
	local EC_GameState_SimpleUnit UnitState;

	NewGameState = `XCOMHISTORY.CreateNewGameState(true, self);

	UnitState = EC_GameState_SimpleUnit(NewGameState.ModifyStateObject(class'EC_GameState_SimpleUnit', Unit.ObjectID));
	UnitState.Ent_ForceSetPosition(MoveTiles[MoveTiles.Length - 1], NewGameState);
	UnitState.Mobility -= MoveTiles.Length;

	return NewGameState;
}

protected event ContextBuildVisualization()
{
	local VisualizationActionMetadata ActionMetadata;
	local EC_Action_MoveAlongPath Action;
	local EC_GameState_SimpleUnit UnitState;
	local XComGameStateHistory History;


	History = `XCOMHISTORY;

	foreach AssociatedState.IterateByClassType(class'EC_GameState_SimpleUnit', UnitState)
	{
		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , AssociatedState.HistoryIndex);
		ActionMetadata.VisualizeActor = History.GetVisualizer(UnitState.ObjectID);

		Action = EC_Action_MoveAlongPath(class'EC_Action_MoveAlongPath'.static.AddToVisualizationTree(ActionMetadata, self));
		Action.Path = MoveTiles;
	}
}
