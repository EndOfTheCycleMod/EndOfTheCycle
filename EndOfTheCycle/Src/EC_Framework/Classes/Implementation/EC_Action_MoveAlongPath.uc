class EC_Action_MoveAlongPath extends X2Action;

var EC_SimpleUnitVisualizer Vis;
var array<int> Path;
var float EndWorldTime;

const MOVETIME = 0.3f;

var vector SourceMoveLoc, TargetMoveLoc;

var Rotator DumbRot;

function Init()
{
	super.Init();
	Vis = EC_SimpleUnitVisualizer(Metadata.VisualizeActor);
}

simulated state Executing
{
Begin:
	TargetMoveLoc = Vis.Location;
	while (Path.Length > 0)
	{
		SourceMoveLoc = TargetMoveLoc;
		`ECMAP.GetWorldPositionAndRotation(Path[0], TargetMoveLoc, DumbRot);
		Path.Remove(0, 1);
		EndWorldTime = WorldInfo.TimeSeconds + MOVETIME;
		while (WorldInfo.TimeSeconds < EndWorldTime)
		{
			Vis.SetLocation(VLerp(SourceMoveLoc, TargetMoveLoc, 1 - ((EndWorldTime - WorldInfo.TimeSeconds) / MOVETIME)));
			Sleep(0.0f);
		}
	} 
	CompleteAction();
}