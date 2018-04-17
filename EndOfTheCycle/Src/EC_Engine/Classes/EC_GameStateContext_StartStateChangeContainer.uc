// Simple helper hack to give us a simple start state.
// TODO: Merge with EC_GameStateContext_StrategyGameRule later
class EC_GameStateContext_StartStateChangeContainer extends XComGameStateContext_ChangeContainer;

event bool IsStartState()
{
	return true;
}