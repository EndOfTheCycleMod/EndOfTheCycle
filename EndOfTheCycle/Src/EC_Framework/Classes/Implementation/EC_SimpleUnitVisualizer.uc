class EC_SimpleUnitVisualizer extends Actor implements(IEC_StrategyWorldEntityVisualizer);

var protected int ObjectID;

var StaticMeshComponent StaticMeshComponent;

function InitFromState(EC_GameState_SimpleUnit UnitState)
{
	self.ObjectID = UnitState.ObjectID;
}

function EntVis_SetLocation(vector NewLocation)
{
	SetLocation(NewLocation);
}

function EntVis_Hide()
{
	SetVisible(false);
}

function EntVis_Show()
{
	SetVisible(true);
}

function EntVis_SetFoggy(string FoggyState);


event PostBeginPlay()
{
	// Temp Mesh
	StaticMeshComponent.SetStaticMesh(StaticMesh(`CONTENT.RequestGameArchetype("Strat_Ship_Int_Room_RecoveryCenter.Meshes.AVG_SoldierPoseStand")));
}

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		BlockRigidBody=false
		bUsePrecomputedShadows=FALSE
	End Object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
}