class EC_CameraStack extends X2CameraStack;


/// <summary>
/// Adds the specified X2Camera to the camera stack. Must implement IEC_Camera
/// </summary>
function AddCamera(X2Camera Camera)
{
	if (IEC_Camera(Camera) == none)
	{
		`REDSCREEN("Cannot push" @ Camera.Class.Name @ "onto camera stack. Are you attempting to use a tactical camera?");
	}
	else
	{
		super.AddCamera(Camera);
	}
}









// Functions that aren't used in strategy

function bool ShouldUnitUseScanline(XGUnitNativeBase Unit)
{
	`REDSCREEN(GetFuncName() @ "not supported by strategy camera stack.");
	return false;
}

function bool ShowTargetingOutlines()
{
	`REDSCREEN(GetFuncName() @ "not supported by strategy camera stack.");
	return false;
}

function bool ShouldUnitUse3rdPersonStyleOutline(XGUnitNativeBase Unit)
{
	`REDSCREEN(GetFuncName() @ "not supported by strategy camera stack.");
	return false;
}

function bool AllowBuildingCutdown()
{
	`REDSCREEN(GetFuncName() @ "not supported by strategy camera stack.");
	return false;
}

function bool AllowProximityDither(out DitherParameters outDitherParameters)
{
	`REDSCREEN(GetFuncName() @ "not supported by strategy camera stack.");
	return false;
}
