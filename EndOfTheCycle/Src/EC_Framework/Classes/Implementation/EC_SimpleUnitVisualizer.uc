class EC_SimpleUnitVisualizer extends Actor implements(IEC_StrategyWorldEntityVisualizer);

var protected int ObjectID;

function InitFromState(EC_GameState_SimpleUnit UnitState)
{
	self.ObjectID = UnitState.ObjectID;
}

function EntVis_SetLocation(vector NewLocation)
{

}