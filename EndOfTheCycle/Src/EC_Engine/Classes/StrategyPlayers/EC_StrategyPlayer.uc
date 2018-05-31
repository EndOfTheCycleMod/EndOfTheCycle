// Visualizer of EC_GameState_StrategyPlayer. This is essentially the "input" system of any given player,
// be it an AI or a human player. This is essentially the XCOM-2 extension of what would normally be the
// UE3 PlayerController. This class should not store any state, because it may be destroyed and replaced
// at any time, for example when the user switches players for debug purposes
class EC_StrategyPlayer extends Actor;

var int ObjectID;

function InitFromState(EC_GameState_StrategyPlayer P)
{
	ObjectID = P.ObjectID;
	// TODO
	if (P.GetMyTemplateName() == 'XComPlayer')
	{
		`ECCTRL.SetControllingPlayer(P);
	}
}

function OnActionsAvailable()
{

}