// This state object is internally used by the Strategy Game Rule set and should not be used from any other systems
class EC_GameState_PersistentTurnData extends XComGameState_BaseObject;

var StateObjectReference CurrentPlayer;

// the currently active turn phase. Since turn phases are a linked list, storing the active one here
var StateObjectReference TurnPhase;

// List of players + current index into the list
var array<StateObjectReference> Players;
var int PlayerIndex;



// Trigger an event whenever we are changed -- allows systems like the Game Rules to re-cache the information
simulated event OnStateSubmitted()
{
	// Super important check: Since the EC_StrategyGameRuleset actor does things in response to any turn phase updates, 
	// we can't let this event trigger from another thread. Otherwise, we'll end up in multithreading hell
	if (`GAMERULES.BuildingLatentGameState)
	{
		`REDSCREEN(default.Class.Name @ "can't be modified from latent game states, its state is shared with the game rules!\n" @ GetScriptTrace());
	}
	`XEVENTMGR.TriggerEvent('EC_OnTurnDataUpdate', self, self, XComGameState(Outer));
}