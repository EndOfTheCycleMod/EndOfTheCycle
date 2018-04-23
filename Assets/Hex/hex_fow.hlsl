// This is a mirror of the source of the "Custom" node in Content/HexFOW.upk
// This is not valid HLSL, it's only valid in the context of the Unreal Material Compiler
// This mirror is there to make discussing the code easier.
// Everything below this line goes into the "Custom" node.

// This node tranforms world space coordinates into UV coords for the FOW texture

// Inputs:
// float2 MapDimensions -- the width and height of the Hex map in Hex Coords
// float2 Origin -- position of the center of the upmost left tile
// float HexSize -- size of a hex
// float2 WorldPosition -- world space position
// float2 TexSize       -- pixel size of the texture

// Outputs:
// float3 UVCoords -- r, g coordinates into the FOW texture to read the FOW from.
//                    b scalar whether we should use FOW at all

// Main
float2x2 invMatrix = {
	0.5773502691896258f, -0.3333333333f,
	0.0f,                0.6666666666f
};

float2 unroundHex = mul(invMatrix, WorldPosition - float3(Origin.r, Origin.g, 0.0f)) / HexSize;

float3 unroundCube = float3(unroundHex.x, -unroundHex.x - unroundHex.y ,unroundHex.y);
// Now round:
float3 tempRoundCube = round(unroundCube);
float3 diffs = abs(unroundCube - tempRoundCube);

if (diffs.x > diffs.y && diffs.x > diffs.z) {
	tempRoundCube.x = -tempRoundCube.y - tempRoundCube.z;
} else if (diffs.y > diffs.z) {
	tempRoundCube.y = -tempRoundCube.x - tempRoundCube.z;
} else {
	tempRoundCube.z = -tempRoundCube.x - tempRoundCube.y;
}
int3 intCube = tempRoundCube;

int col = intCube.x + (intCube.z - (intCube.z&1)) / 2;
int row = intCube.z;
float sclr = 1.0f;
if (col < 0 || col >= MapDimensions.r || row < 0 || row >= MapDimensions.g)
{
	sclr = 0.0f;
}
// +0.5f so we actually hit the pixel "center", whatever a pixel center is
return float3((float(col) + 0.5f) / TexSize.r, (float(row) + 0.5f) / TexSize.g, sclr);