class EC_GameState_SimpleUnit extends XComGameState_BaseObject implements(IEC_Unit, IEC_StrategyWorldEntity, IEC_Pathable);

var int CurrentPosition;
var int Mobility;

// IEC_Unit Interface

function name Un_GetUnitTemplateName()
{
	return 'SimpleUnit';
}


function string Un_GetName(optional ENameType NameType = eNameType_Full)
{
	return "Sample Unit Implementation";
}
function string Un_GetIcon()
{

}
function string Un_GetPortrait()
{
	return "UILibrary_Common.Head_Ramirez";
}

function bool Un_HasAssociatedUnitState();
function StateObjectReference Un_GetUnitRef();
function XComGameState_Unit Un_CreateUnitState(XComGameState NewGameState);

function int Un_GetUnitSize()
{
	return 1;
}
function array<name> Un_GetUnitTags()
{
	local array<name> arr;
	arr.Length = 0;
	return arr;
}
function bool Un_Equals(IEC_Unit Other)
{
	return XComGameState_BaseObject(Other) != none && XComGameState_BaseObject(Other).ObjectID == self.ObjectID;
}

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

}

function StateObjectReference Ent_GetStrategyControllingPlayer()
{

}

function Actor Ent_GetVisualizer()
{
	return `XCOMHISTORY.GetVisualizer(self.ObjectID);
}

function Actor Ent_FindOrCreateVisualizer()
{
	local EC_SimpleUnitVisualizer Vis;

	Vis = EC_SimpleUnitVisualizer(`XCOMHISTORY.GetVisualizer(self.ObjectID));
	if (Vis != none)
	{
		return Vis;
	}

	Vis = class'WorldInfo'.static.GetWorldInfo().Spawn(class'EC_SimpleUnitVisualizer');
	Vis.InitFromState(self);
	`XCOMHISTORY.SetVisualizer(self.ObjectID, Vis);
	return Vis;
}

function Ent_SyncVisualizer(optional XComGameState FromGameState = none)
{
	local EC_GameState_SimpleUnit TargetUnitState;
	local int HistIdx;
	local int TileLocation;
	local vector Pos;
	local rotator Rot;
	local EC_SimpleUnitVisualizer Vis;

	Vis = EC_SimpleUnitVisualizer(Ent_GetVisualizer());
	`assert(Vis != none);
	HistIdx = -1;
	if (FromGameState != none)
	{
		TargetUnitState = EC_GameState_SimpleUnit(FromGameState.GetGameStateForObjectID(self.ObjectID));
		if (TargetUnitState == none)
		{
			HistIdx = FromGameState.HistoryIndex;
		}
	}
	TargetUnitState = EC_GameState_SimpleUnit(`XCOMHISTORY.GetGameStateForObjectID(self.ObjectID, , HistIdx));
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

// IEC_Pathable Interface
function bool Path_IsMovable()
{
	return true;
}

function MoverData Path_GetMoverData()
{
	local MoverData Data;

	Data.Mobility = 3 * `MOVE_DENOMINATOR;
	Data.CurrentMobility = Data.Mobility;
	Data.Domain = eUD_Land;
	Data.PathfinderClass = class'EC_DefaultUnitPathfinder';

	return Data;
}

function Path_QueuePath(array<int> Path);
function Path_PerformQueuedPath();

function IEC_StrategyWorldEntity Path_GetStrategyWorldEntity()
{
	return self;
}

defaultproperties
{
	CurrentPosition=-1
}