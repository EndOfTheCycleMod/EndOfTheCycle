class EC_GameState_SimpleHeadquarters extends XComGameState_BaseObject implements(IEC_VisibilityInterface, IEC_TerritoryAnchor, IEC_StrategyWorldEntity);

var protected int CurrentPosition;

var StateObjectReference ControllingPlayer;

// IEC_StrategyWorldEntity Interface

function bool Ent_IsOnMap()
{
	return CurrentPosition >= 0;
}

function StateObjectReference Ent_GetOwningEntity()
{
	local StateObjectReference NullRef;
	NullRef.ObjectID = 0;
	return NullRef;
}

function int Ent_GetPosition()
{
	return CurrentPosition;
}

function Ent_ForceSetPosition(int Pos, XComGameState NewGameState)
{
	CurrentPosition = Pos;
}

function StateObjectReference Ent_GetStrategyOwningPlayer()
{
	return ControllingPlayer;
}

function StateObjectReference Ent_GetStrategyControllingPlayer()
{
	return ControllingPlayer;
}

function Actor Ent_GetVisualizer()
{
	return `XCOMHISTORY.GetVisualizer(self.ObjectID);
}

function Actor Ent_FindOrCreateVisualizer()
{
	local EC_SimpleHeadquartersVisualizer Vis;

	Vis = EC_SimpleHeadquartersVisualizer(`XCOMHISTORY.GetVisualizer(self.ObjectID));
	if (Vis != none)
	{
		return Vis;
	}

	Vis = class'WorldInfo'.static.GetWorldInfo().Spawn(class'EC_SimpleHeadquartersVisualizer');
	Vis.InitFromState(self);
	`XCOMHISTORY.SetVisualizer(self.ObjectID, Vis);
	return Vis;
}

function Ent_SyncVisualizer(optional XComGameState FromGameState = none)
{
	local EC_GameState_SimpleHeadquarters TargetUnitState;
	local int HistIdx;
	local int TileLocation;
	local vector Pos;
	local rotator Rot;
	local EC_SimpleHeadquartersVisualizer Vis;

	Vis = EC_SimpleHeadquartersVisualizer(Ent_GetVisualizer());
	`assert(Vis != none);
	HistIdx = -1;
	if (FromGameState != none)
	{
		TargetUnitState = EC_GameState_SimpleHeadquarters(FromGameState.GetGameStateForObjectID(self.ObjectID));
		if (TargetUnitState == none)
		{
			HistIdx = FromGameState.HistoryIndex;
		}
	}
	TargetUnitState = EC_GameState_SimpleHeadquarters(`XCOMHISTORY.GetGameStateForObjectID(self.ObjectID, , HistIdx));
	`assert(TargetUnitState != none);
	TileLocation = TargetUnitState.Ent_GetPosition();
	if (TileLocation > INDEX_NONE)
	{
		Vis.SetVisible(true);
		`ECMAP.GetWorldPositionAndRotation(TileLocation, Pos, Rot);
		Vis.SetLocation(Pos);
		Vis.SetRotation(Rot);
	}
	else
	{
		Vis.SetVisible(false);
	}
}

function bool Ent_SupportsFoggyState()
{
	return false;
}

function string Ent_ToFoggyState();

function int Vis_GetSightRange()
{
	return 2;
}
function int Vis_GetSightHeight()
{
	return 2;
}

function array<StateObjectReference> Vis_GetPlayers()
{
	local array<StateObjectReference> Refs;
	Refs.AddItem(ControllingPlayer);
	return Refs;
}

function array<int> Ter_GetTiles()
{
	local array<int> Tiles;

	Tiles = `ECMAP.GetAdjacentMapPositions(CurrentPosition);
	Tiles.AddItem(CurrentPosition);

	return Tiles;
}

function StateObjectReference Ter_GetPlayer()
{
	return ControllingPlayer;
}

function int Ter_GetPriority()
{
	return 50;
}

