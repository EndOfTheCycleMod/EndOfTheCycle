class EC_GameState_MapTileData extends XComGameState_BaseObject;

enum EECTileType
{
	eECTT_Water,
	eECTT_Flat,
	eECTT_Wilderness,
	eECTT_Mountain,
};

var int Width, Height;

var array<EECTileType> Tiles;


function CreateRandomMap(int w, int h)
{
	local int i, j;
	Width = w;
	Height = h;
	Tiles.Length = w * h;
	for (i = 0; i < h; i++)
	{
		for (j = 0; j < w; j++)
		{
			Tiles[i * w + j] = EECTileType(`SYNC_RAND(eECTT_Max));
		}
	}
}