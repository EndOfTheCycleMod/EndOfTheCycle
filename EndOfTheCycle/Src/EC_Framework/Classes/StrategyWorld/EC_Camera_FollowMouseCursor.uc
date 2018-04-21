class EC_Camera_FollowMouseCursor extends X2Camera implements(IEC_Camera);

var Box GameVolume;
var vector CurrentLookAt, TargetLookAt;

var float LocationInterpolationRampAlpha;

function SetGameVolume(Box B)
{
	self.GameVolume = B;
	CurrentLookAt = 0.5f * (B.Min + B.Max);
	TargetLookAt = CurrentLookAt;
}

// X2Camera Interface
function TPOV GetCameraLocationAndOrientation()
{
	local TPOV POV;

	POV.FOV = 60;
	POV.Rotation.Pitch = -38 * DegToUnrRot;
	POV.Rotation.Yaw = 270 * DegToUnrRot;
	POV.Rotation.Roll = 0 * DegToUnrRot;
	POV.Location = CurrentLookAt + (1200 * vect(0,0,1)) - (1200 * sin(38 * PI / 180) * vect(0,-1,0));

	return POV;
}


/// <summary>
/// Notifies the camera that the user is attempting to scroll with key input
/// </summary>
function ScrollCamera(Vector2D Offset)
{
	TargetLookAt.X += Offset.X;
	TargetLookAt.Y -= Offset.Y;
}

/// <summary>
/// Notifies the camera that the user is attempting to scroll with the window edges
/// </summary>
function EdgeScrollCamera(Vector2D Offset)
{
	ScrollCamera(Offset);
}

/// <summary>
/// Notifies the camera that the user is attempting to scroll without smoothing
/// </summary>
function RawScrollCamera(Vector2D Offset)
{
	ScrollCamera(Offset);
}

// Note: This should probably be moved to a strategy X2Camera_LookAt.
// It appears that X2Camera_LookAt cannot be subclassed for strategy
// because some native functions involve checking for the level floor etc.
function UpdateCamera(float DeltaTime)
{
	local Vector NewLookAt;
	local Vector LookAtDelta;
	local float InterpolateDistance;
	local float DeltaLength;

	super.UpdateCamera(DeltaTime);

	NewLookAt = TargetLookAt;
	LookAtDelta = NewLookAt - CurrentLookAt;
	DeltaLength = VSize(LookAtDelta);

	// only interpolate until we get "close enough". Prevents FP error from making us never arrive
	if(DeltaLength > 0.01)
	{

		// ramp alpha is a value from 0.0-1.0 that takes ease-in/out into account for smoother motion
		LocationInterpolationRampAlpha = fMin(1.0, LocationInterpolationRampAlpha + DeltaTime / 0.35f);
		LocationInterpolationRampAlpha = fMin(LocationInterpolationRampAlpha, ComputeLocationBrakeAlpha(DeltaLength));

		InterpolateDistance = 3000 * DeltaTime * LocationInterpolationRampAlpha;
		InterpolateDistance = fMin(DeltaLength, InterpolateDistance);
		
		LookAtDelta = Normal(LookAtDelta) * InterpolateDistance;

		if(VSizeSq(LookAtDelta) > 0)
		{
			CurrentLookAt = CurrentLookAt + LookAtDelta;
			return;
		}
	}

	CurrentLookAt = NewLookAt;
	LocationInterpolationRampAlpha = 0.0;
}

protected function float ComputeLocationBrakeAlpha(float DistanceFromDestination)
{
	local float BrakeStartDistance;
	local float BrakeAlpha;

	BrakeStartDistance = 0.35f * 3000 * 0.4;
	BrakeAlpha = DistanceFromDestination / BrakeStartDistance;

	// clamp. Never go all the way to 0, as then we will never arrive
	BrakeAlpha = FClamp(BrakeAlpha, 0.01f, 1.0f);
	
	return BrakeAlpha;
}