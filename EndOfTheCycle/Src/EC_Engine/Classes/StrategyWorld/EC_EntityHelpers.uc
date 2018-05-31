class EC_EntityHelpers extends Object;

function StateObjectReference GetRootEntity(StateObjectReference Entity, optional int HistoryIndex = -1)
{
	local int id;
	local XComGameState_BaseObject Obj;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	id = Entity.ObjectID;
	do
	{
		Obj = History.GetGameStateForObjectID(id, , HistoryIndex);
		id = IEC_StrategyWorldEntity(Obj).Ent_GetOwningEntity().ObjectID;
	} until (id <= 0);

	return Obj.GetReference();
}