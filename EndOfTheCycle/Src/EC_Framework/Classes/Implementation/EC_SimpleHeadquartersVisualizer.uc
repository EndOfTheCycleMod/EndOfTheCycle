class EC_SimpleHeadquartersVisualizer extends Actor implements(IEC_StrategyWorldEntityVisualizer);

var protected int ObjectID;

var StaticMeshComponent StaticMeshComponent;

function InitFromState(EC_GameState_SimpleHeadquarters HQState)
{
	self.ObjectID = HQState.ObjectID;
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
	StaticMeshComponent.SetStaticMesh(StaticMesh(`CONTENT.RequestGameArchetype("Strat_Ship_Int_Room_Ring.Meshes.3DIcons_City")));
	StaticMeshComponent.SetScale(8);
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