class EC_StrategyPlayerTemplate extends EC_StrategyElementTemplate;

function EC_GameState_StrategyPlayer CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local EC_GameState_StrategyPlayer Player;

	Player = EC_GameState_StrategyPlayer(NewGameState.CreateNewStateObject(class'EC_GameState_StrategyPlayer', self));

	return Player;
}