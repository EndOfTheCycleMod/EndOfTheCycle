class EC_StrategyCamera extends XComBaseCamera;

event PostBeginPlay()
{
	super.PostBeginPlay();

	// create the camera stack
	CameraStack = new class'EC_CameraStack';
}

simulated state BootstrappingStrategy
{
Begin:
	GotoState('');
}

function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	CameraStack.UpdateCameras(DeltaTime);
	OutVT.POV = CameraStack.GetCameraLocationAndOrientation();
	//ApplyCameraModifiers(DeltaTime, OutVT.POV);
}

// window edge scroll input
simulated function EdgeScrollCamera(float XOffset, float YOffset)
{
	local Vector2D Offset;

	Offset.X = XOffset;
	Offset.Y = YOffset;
	CameraStack.EdgeScrollCameras(Offset);
}
// key scroll input
simulated function ScrollCamera(float XOffset, float YOffset)
{
	local Vector2D Offset;

	Offset.X = XOffset;
	Offset.Y = YOffset;
	CameraStack.ScrollCameras(Offset);
}