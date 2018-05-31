// Helper class containing simple geometry functions for Hexagonal Grids.
// Used so that both Hex Map Visualizer and Hex Map Game State can access this
class HexGeometry extends Object;

struct PointNeighbors
{
	var IntPoint p[6];
};

var const PointNeighbors Directions[2];

// The map has this layout (X,Y)
// 0,0   1,0   2,0   3,0   ... Width,0
//    0,1   1,1   2,1   3,1...    Width,1
// 0,2   1,2   2,2   3,2   ... Width,2
//    0,3   1,3   2,3   3,3...    Width,3
// ...

var int Width, Height;

final function HexGeometry SetDimensions(int _Width, int _Height)
{
	Width = _Width;
	Height = _Height;
	return self;
}

final function array<int> GetAdjacentMapPositions(int Pos)
{
	local IntPoint P;
	local array<int> arr;
	local PointNeighbors points;
	local IntPoint TempPoint;
	local int i;
	
	P = GetTile2DCoords(Pos);
	points = Directions[P.Y & 1];
	for (i = 0; i < ArrayCount(points.p); i++)
	{
		TempPoint.X = P.X + points.p[i].X;
		TempPoint.Y = P.Y + points.p[i].Y;
		if (TempPoint.X > -1 && TempPoint.Y > -1 && TempPoint.X < Width && TempPoint.Y < Height)
		{
			arr.AddItem(GetHandleFromPoint(TempPoint));
		}
	}
	return arr;
}

final function bool AreAdjacent(int A, int B)
{
	local IntPoint PA, PB;

	if (A == B) return false;
	
	PA = GetTile2DCoords(A);
	PB = GetTile2DCoords(B);

	return PA.Y == PB.Y && Abs(PA.X - PB.X) < 2
	    || PA.X == PB.X && Abs(PA.Y - PB.Y) < 2
		|| (((PA.Y & 1) == 0) ? (PA.X - PB.X) == 1 && Abs(PA.Y - PB.Y) < 2 : (PA.X - PB.X) == -1 && Abs(PA.Y - PB.Y) < 2);

}

final function int GetTileDistance(int A, int B)
{
	local IntPoint PA, PB;

	PA = GetTile2DCoords(A);
	PB = GetTile2DCoords(B);

	return Max(Max(
		Abs(PB.Y - PA.Y),     
		Abs(FCeil(PB.Y / -2.0f) + PB.X - FCeil(PA.Y / -2.0f) - PA.X)),
		Abs(-PB.Y - FCeil(PB.Y / -2.0f) - PB.X + PA.Y  + FCeil(PA.Y / -2.0f) + PA.X));
}

final function array<int> GetTilesInRange(int Pos, int Range)
{
	local array<int> Tiles;
	// TODO
	`REDSCREEN("Not implemented");
	Tiles.Length = 0;
	return Tiles;
}

final function IntPoint GetTile2DCoords(int TileHandle)
{
	local IntPoint P;
	P.X = TileHandle % Width;
	P.Y = TileHandle / Width;
	return P;
}

final function int GetHandleFromCoords(int x, int y)
{
	return y * Width + x;
}

final function int GetHandleFromPoint(IntPoint p)
{
	return p.y * Width + p.x;
}

defaultproperties
{
	Directions(0)=(p[0]=(X=1, Y=0), p[1]=(X=0, Y=-1), p[2]=(X=-1, Y=-1), p[3]=(X=-1, Y=0), p[4]=(X=-1, Y=1), p[5]=(X=0, Y=1))
	Directions(1)=(p[0]=(X=1, Y=0), p[1]=(X=1, Y=-1), p[2]=(X=0, Y=-1), p[3]=(X=-1, Y=0), p[4]=(X=0, Y=1), p[5]=(X=1, Y=1))
}