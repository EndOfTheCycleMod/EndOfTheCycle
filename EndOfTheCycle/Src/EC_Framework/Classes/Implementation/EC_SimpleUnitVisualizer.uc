class EC_SimpleUnitVisualizer extends Actor;

var protected int ObjectID;

function InitFromState(EC_GameState_SimpleUnit UnitState)
{
    self.ObjectID = UnitState.ObjectID;
}