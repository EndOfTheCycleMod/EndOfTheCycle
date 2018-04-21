class EC_VisibilityManager extends Object;

enum EECVisState
{
	eECVS_Unexplored, // No info on what the tile is
	eECVS_Explored,   // Terrain explored, but info not up-to-date
	eECVS_Vision,     // Structures can be seen, but some details are hidden
	eECVS_Full,       // Full info on everything
};