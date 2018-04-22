class EC_StrategyCheatManager extends XComCheatManager within EC_StrategyController;

var int PathingSourceTile;
var int LastGoal;
var PathfindingResult Result;

// Override, `PRES -> `PRESBASE
exec function EnablePostProcessEffect(name EffectName, bool bEnable)
{
	`PRESBASE.EnablePostProcessEffect(EffectName, bEnable);
}

exec function StartPathing()
{
	PathingSourceTile = `ECMAP.GetCursorHighlightedTile();
}

exec function EndPathing()
{
	PathingSourceTile = -1;
}

function DrawDebugLabel(Canvas kCanvas)
{
	local vector Pos, pos2D;
	local rotator Rot;
	local int End;
	local MoverData Data;
	local int i;

	End = `ECMAP.GetCursorHighlightedTile();
	if (PathingSourceTile > -1 && End > -1)
	{
		`ECMAP.GetWorldPositionAndRotation(PathingSourceTile, Pos, Rot);
		`ECSHAPES.DrawSphere(Pos, vect(30,30,30), MakeLinearColor(1,0,0,1), false);
		if (LastGoal != End)
		{
			Data.Domain = eUD_Land;
			Result = `ECGAME.DefaultPathfinder.BuildPath(PathingSourceTile, End, Data);
			LastGoal = End;
		}
		if (Result.PathFound)
		{
			for (i = 0; i < Result.Nodes.Length - 1; i++)
			{
				`ECMAP.GetWorldPositionAndRotation(Result.Nodes[i].Tile, Pos, Rot);
				`ECSHAPES.DrawSphere(Pos, vect(30,30,30), MakeLinearColor(0,1,0,1), false);
				pos2D = kCanvas.Project(Pos);
				kCanvas.SetPos(pos2D.X, pos2D.Y);
				kCanvas.SetDrawColor(255,0,0);
				kCanvas.DrawText(Result.Nodes[i].Distance);
			}
		}
		else
		{

		}
	}
}

defaultproperties
{
	PathingSourceTile=-1
	LastGoal=-1
}