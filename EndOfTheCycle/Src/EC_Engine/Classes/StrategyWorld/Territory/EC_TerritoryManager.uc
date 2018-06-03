class EC_TerritoryManager extends Object implements(X2VisualizationMgrObserverInterface);

struct PlayerTerritoryListItem
{
	var int PlayerID;
	var array<int> Tiles;
};

var IEC_StrategyMap Map;
var Actor MapActor;

var Material MasterMaterial;
var MaterialInstanceConstant WhiteMIC;

function Init(IEC_StrategyMap _Map)
{
	local LinearColor C;
	self.Map = _Map;
	self.MapActor = Actor(Map);
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
	MasterMaterial = Material(`CONTENT.RequestGameArchetype("EC_Border.M_Border"));
	WhiteMIC = new (MasterMaterial) class'MaterialInstanceConstant';
	WhiteMIC.SetParent(MasterMaterial);
	C = MakeLinearColor(1.0f, 1.0f, 1.0f, 1.0f);
	WhiteMIC.SetVectorParameterValue('OuterColor', C);
}


function array<PlayerTerritoryListItem> BuildTerritoryLists(optional int HistoryIndex = -1)
{
	local array<PlayerTerritoryListItem> Players;
	local array<int> Tiles, AllTiles;
	local array<IEC_TerritoryAnchor> Anchors;
	local int i, j, k, Tile;

	Anchors = GetSortedAnchors(HistoryIndex);
	AllTiles.Length = 0;
	for (i = 0; i < Anchors.Length; i++)
	{
		j = Players.Find('PlayerID', Anchors[i].Ter_GetPlayer().ObjectID);
		if (j == INDEX_NONE)
		{
			Players.Add(1);
			j = Players.Length - 1;
			Players[j].PlayerID = Anchors[i].Ter_GetPlayer().ObjectID;
		}
		Tiles = Anchors[i].Ter_GetTiles();
		for (k = 0; k < Tiles.Length; k++)
		{
			Tile = Tiles[k];
			if (AllTiles.Find(Tile) == INDEX_NONE)
			{
				Players[j].Tiles.AddItem(Tile);
				// Mark tile as used, as it has a higher priority
				AllTiles.AddItem(Tile);
			}
		}
	}
	return Players;
}


function array<IEC_TerritoryAnchor> GetSortedAnchors(optional int HistoryIndex = -1)
{
	local XComGameStateHistory History;
	local XComGameState_BaseObject Obj;
	local array<IEC_TerritoryAnchor> Anchors;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_BaseObject', Obj, , , HistoryIndex)
	{
		if (IEC_TerritoryAnchor(Obj) != none/* && IEC_StrategyWorldEntity(Obj).Ent_IsOnMap()*/)
		{
			Anchors.AddItem(IEC_TerritoryAnchor(Obj));
		}
	}
	// TODO: Doesn't work for large arrays
	if (Anchors.Length > 90)
	{
		`REDSCREENONCE("Warning, number of Territory Anchors exceeded 90. Please update" @ Class.Name $ ":" $ GetFuncName());
	}
	Anchors.Sort(ByPriority);
	return Anchors;
}

function int ByPriority(IEC_TerritoryAnchor A, IEC_TerritoryAnchor B)
{
	return A.Ter_GetPriority() - B.Ter_GetPriority();
}

// TODO: Improve so that we don't recalculate it every single time
function SyncTerritory(optional int HistoryIndex = -1)
{
	local array<PlayerTerritoryListItem> Lists;
	local int i, j, CompIndex;
	local EC_TerritoryBorderComponent Comp;
	local array<EC_TerritoryBorderComponent> Comps;
	local array<InterpCurveVector> Curves;
	local MaterialInstanceConstant MIC;
	local LinearColor Clr;

	Lists = BuildTerritoryLists();

	// I want an index-based access
	foreach MapActor.ComponentList(class'EC_TerritoryBorderComponent', Comp)
	{
		Comps.AddItem(Comp);
	}

	CompIndex = 0;

	for (i = 0; i < Lists.Length; i++)
	{
		Clr = EC_GameState_StrategyPlayer(`XCOMHISTORY.GetGameStateForObjectID(Lists[i].PlayerID)).GetMyTemplate().PlayerColor;
		MIC = new (MasterMaterial) class'MaterialInstanceConstant';
		MIC.SetParent(MasterMaterial);
		MIC.SetVectorParameterValue('OuterColor', Clr);

		Curves = Map.TraceBorders(Lists[i].Tiles, 0.95f);

		for (j = 0; j < Curves.Length; j++)
		{
			if (CompIndex < Comps.Length)
			{
				Comp = Comps[CompIndex];
				Comp.SetHidden(false);
				CompIndex++;
			}
			else
			{
				Comp = new (MapActor) class'EC_TerritoryBorderComponent';
				Comp.SetMaterial(MIC);
				MapActor.AttachComponent(Comp);
			}

			// Use a Z offset of 10000 to convince the ribbon to point up
			Comp.UpdatePathRenderData(Curves[j], Curves[j].Points[Curves[j].Points.Length - 1].InVal, none, `ECCAMSTACK.GetCameraLocationAndOrientation().Location +  vect(0,0,10000));
		}
	}

	// Hide all leftover components
	for (CompIndex = CompIndex; CompIndex < Comps.Length; CompIndex++)
	{
		Comps[i].SetHidden(true);
	}

}

event OnVisualizationIdle()
{
	SyncTerritory();
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	SyncTerritory(AssociatedGameState.HistoryIndex);
}
