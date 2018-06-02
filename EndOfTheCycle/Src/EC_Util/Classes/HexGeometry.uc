// Helper class containing simple geometry functions for Hexagonal Grids.
// Used so that both Hex Map Visualizer and Hex Map Game State can access this
class HexGeometry extends Object;

struct PointNeighbors
{
	var IntPoint p[6];
};

// A single border trace
struct BorderTrace
{
	// Vertices of the resulting trace. X = TileID, Y = VertexIndex where 0 = up, clockwise...
	var array<IntPoint> Vertices;
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

// Given a set of tiles, return all border traces
final function array<BorderTrace> TraceBorders(array<int> Tiles)
{
	local int i, j;
	local bool FoundEdge;
	local IntPoint CurrentVertex, StartVertex, TempVertex;
	local IntPoint P;
	// This is an int array because UnrealScript can't Find() structs
	local array<int> ConsideredVertices;
	local PointNeighbors points;
	local IntPoint TempPoint;
	local BorderTrace Trace, EmptyTrace;
	local array<BorderTrace> Traces;

	Traces.Length = 0;
	// Why bother with exit conditions when you can just return from the whole function
	while (true)
	{
		Trace = EmptyTrace;
		// First, we find an edge we haven't considered yet.
		FoundEdge = false;
		for (i = Tiles.Length - 1; i >= 0 && !FoundEdge; i--)
		{
			P = GetTile2DCoords(Tiles[i]);
			points = Directions[P.Y & 1];
			for (j = 0; j < ArrayCount(points.p) && !FoundEdge; j++)
			{
				TempPoint.X = P.X + points.p[j].X;
				TempPoint.Y = P.Y + points.p[j].Y;
				if (!(TempPoint.X > -1 && TempPoint.Y > -1 && TempPoint.X < Width && TempPoint.Y < Height && Tiles.Find(GetHandleFromPoint(TempPoint)) != INDEX_NONE))
				{
					CurrentVertex.X = Tiles[i];
					// The way we have Directions set up allows us to write it this way -- j is the edge
					CurrentVertex.Y = j;
					if (ConsideredVertices.Find(CurrentVertex.X * 6 + CurrentVertex.Y) == INDEX_NONE)
					{
						FoundEdge = true;
					}
				}
			}
		}
		if (!FoundEdge)
		{
			return Traces;
		}
		StartVertex = CurrentVertex;

		Trace.Vertices.AddItem(StartVertex);
		ConsideredVertices.AddItem(StartVertex.X * 6 + StartVertex.Y);
		do
		{
			TempVertex = CurrentVertex;
			// Now, we can just increase (wrapping) CurrentVertex.Y, which moves us one edge on the same tile further
			TempVertex.Y = (TempVertex.Y + 1) % 6;
			// Then, we check if there's a tile in the position we were pointing to, and if so, switch tiles
			TempPoint = GetTile2DCoords(CurrentVertex.X);
			// TempPoint provides info on whether we are on odd or even rows, and TempVertex yields the edge
			TempPoint.X = TempPoint.X + Directions[TempPoint.Y & 1].p[TempVertex.Y].X;
			TempPoint.Y = TempPoint.Y + Directions[TempPoint.Y & 1].p[TempVertex.Y].Y;
			// Is the Tile within our borders?
			if ((TempPoint.X > -1 && TempPoint.Y > -1 && TempPoint.X < Width && TempPoint.Y < Height && Tiles.Find(GetHandleFromPoint(TempPoint)) != INDEX_NONE))
			{
				// If so, switch edges
				TempVertex.X = GetHandleFromPoint(TempPoint);
				TempVertex.Y = (CurrentVertex.Y + 5) % 6;
			}
			CurrentVertex = TempVertex;
			Trace.Vertices.AddItem(CurrentVertex);
			ConsideredVertices.AddItem(CurrentVertex.X * 6 + CurrentVertex.Y);
		} until (CurrentVertex == StartVertex);

		Traces.AddItem(Trace);
	}

	return Traces;
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

final function string GetPositionDebugInfo(int Pos)
{
	local IntPoint P;
	P = GetTile2DCoords(Pos);
	return "(X:" @ P.X $ ", Y:" @ P.Y $ ")";
}

defaultproperties
{
	// The order of these is important -- it matches our internal edge representation for TraceBorders
	Directions(0)=(p[0]=(X=0, Y=-1), p[1]=(X=1, Y=0), p[2]=(X=0, Y=1), p[3]=(X=-1, Y=1), p[4]=(X=-1, Y=0), p[5]=(X=-1, Y=-1))
	Directions(1)=(p[0]=(X=1, Y=-1), p[1]=(X=1, Y=0), p[2]=(X=1, Y=1), p[3]=(X=0, Y=1), p[4]=(X=-1, Y=0), p[5]=(X=0, Y=-1))
}