// TODO: Optimize functions, cache results, ...
class EC_VisibilityManager extends Object implements(X2VisualizationMgrObserverInterface) dependson(EC_VisibilityDataStructures);



var IEC_StrategyMap Map;

function Init(IEC_StrategyMap _Map)
{
	self.Map = _Map;
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
}

//// Player-agnostic functions ////

function array<int> GetVisibleTiles(StateObjectReference Source, optional int HistoryIndex = -1)
{
	local XComGameState_BaseObject Obj;

	Obj = `XCOMHISTORY.GetGameStateForObjectID(Source.ObjectID, , HistoryIndex);
	return Map.GetVisibleTiles(IEC_StrategyWorldEntity(Obj).Ent_GetPosition(), IEC_VisibilityInterface(Obj).Vis_GetSightRange(), IEC_VisibilityInterface(Obj).Vis_GetSightHeight());
}

function array<StateObjectReference> GetVisibleEntities(StateObjectReference Source, optional int HistoryIndex = -1)
{
	return CollectEntities(GetVisibleTiles(Source, HistoryIndex), HistoryIndex);
}

function bool CanSee(StateObjectReference Source, StateObjectReference Target, optional int HistoryIndex = -1)
{
	local array<StateObjectReference> Refs;
	Refs = GetVisibleEntities(Source, HistoryIndex);
	return Refs.Find('ObjectID', Target.ObjectID) != INDEX_NONE;
}

function bool CanSeeTile(StateObjectReference Source, int Tile, optional int HistoryIndex = -1)
{
	local array<int> Tiles;
	Tiles = GetVisibleTiles(Source, HistoryIndex);
	return Tiles.Find(Tile) != INDEX_NONE;
}

function array<int> GetVisibleTilesForPlayer(StateObjectReference Player, optional int HistoryIndex = -1)
{
	local array<StateObjectReference> Viewers;
	local array<int> AllTiles, Tiles;
	local int i, j;

	Viewers = GetViewersForPlayer(Player, HistoryIndex);

	for (i = 0; i < Viewers.Length; i++)
	{
		Tiles = GetVisibleTiles(Viewers[i], HistoryIndex);
		for (j = 0; j < Tiles.Length; j++)
		{
			// Oof ouch owie my complexity
			if (AllTiles.Find(Tiles[j]) == INDEX_NONE)
			{
				AllTiles.AddItem(Tiles[j]);
			}
		}
	}

	return AllTiles;
}

function array<StateObjectReference> GetVisibleEntitiesForPlayer(StateObjectReference Player, optional int HistoryIndex = -1)
{
	return CollectEntities(GetVisibleTilesForPlayer(Player, HistoryIndex), HistoryIndex);
}

function bool PlayerCanSee(StateObjectReference Player, StateObjectReference Target, optional int HistoryIndex = -1)
{
	local array<StateObjectReference> Refs;
	Refs = GetVisibleEntitiesForPlayer(Player, HistoryIndex);
	return Refs.Find('ObjectID', Target.ObjectID) != INDEX_NONE;
}

function bool PlayerCanSeeTile(StateObjectReference Player, int Tile, optional int HistoryIndex = -1)
{
	local array<int> Tiles;
	Tiles = GetVisibleTilesForPlayer(Player, HistoryIndex);
	return Tiles.Find(Tile) != INDEX_NONE;
}

function array<StateObjectReference> GetViewersForPlayer(StateObjectReference Player, optional int HistoryIndex = -1)
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject Obj;
	local array<StateObjectReference> Ret, Refs;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_BaseObject', Obj, , , HistoryIndex)
	{
		if (IEC_VisibilityInterface(Obj) != none && IEC_StrategyWorldEntity(Obj).Ent_IsOnMap())
		{
			Refs = IEC_VisibilityInterface(Obj).Vis_GetPlayers();
			if (Refs.Find('ObjectID', Player.ObjectID) != INDEX_NONE)
			{
				Ret.AddItem(Obj.GetReference());
			}
		}
	}

	return Ret;
}

function array<StateObjectReference> CollectEntities(optional array<int> Tiles, optional int HistoryIndex = -1)
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject Obj;
	local array<StateObjectReference> Ret;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_BaseObject', Obj, , , HistoryIndex)
	{
		if (IEC_StrategyWorldEntity(Obj) != none && IEC_StrategyWorldEntity(Obj).Ent_IsOnMap() && (Tiles.Length == 0 || Tiles.Find(IEC_StrategyWorldEntity(Obj).Ent_GetPosition()) != INDEX_NONE))
		{
			Ret.AddItem(Obj.GetReference());
		}
	}

	return Ret;
}

//// Functions relevant for visualization, not player-agnostic ////


function string RetrieveFoggyState(StateObjectReference Ref)
{
	// TODO
	return "";
}

function EECVisState GetVisibilityState(StateObjectReference Ref)
{
	
}

// Super simple and wasteful function right here
// TODO: Optimize the shit out of this
function SyncFOW(int HistoryIndex = -1)
{
	local IEC_StratMapFOWVisualizer FowVis;
	local array<int> VisibleTiles;
	local array<StateObjectReference> Entities;
	local int i;
	local FOWUpdateParams P;
	local array<FOWUpdateParams> Params;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	FowVis = `ECMAP.GetFOWVisualizer();

	// First, hide all tiles
	FowVis.Clear(eECVS_Unexplored);

	// Then, show all visible tiles
	VisibleTiles = GetVisibleTilesForPlayer(`ECCTRL.ControllingPlayer, HistoryIndex);

	for (i = 0; i < VisibleTiles.Length; i++) {
		P.Tile = VisibleTiles[i];
		P.NewState = eECVS_Full;
		Params.AddItem(P);
	}
	FowVis.UpdateFOW(Params, false);

	// Hide all entities
	Entities = CollectEntities( , HistoryIndex);
	for (i = 0; i < Entities.Length; i++)
	{
		IEC_StrategyWorldEntityVisualizer(History.GetVisualizer(Entities[i].ObjectID)).EntVis_Hide();
	}

	// Show visible entities
	Entities = CollectEntities(VisibleTiles, HistoryIndex);
	for (i = 0; i < Entities.Length; i++)
	{
		IEC_StrategyWorldEntityVisualizer(History.GetVisualizer(Entities[i].ObjectID)).EntVis_Show();
	}
}



/// <summary>
/// Final validation catch-all that makes sure the visualizers' visibility is in accord
/// with the game state visibility.
/// </summary>
event OnVisualizationIdle()
{
	SyncFOW();
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	SyncFOW(AssociatedGameState.HistoryIndex);
}
