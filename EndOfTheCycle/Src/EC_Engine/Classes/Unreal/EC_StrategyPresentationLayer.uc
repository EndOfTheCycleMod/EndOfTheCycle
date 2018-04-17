class EC_StrategyPresentationLayer extends XComPresentationLayerBase config(UI);

var config string StrategyHUDClassPath;

var UIScreen StrategyHUD;

simulated function Init()
{
	super.Init();

	Init3DDisplay();
	ScreenStack.Show();
}

// Called from InterfaceMgr when it's ready to rock..
simulated function InitUIScreens()
{
	`log("EC_StrategyPresentationLayer.InitUIScreens()");

	// Poll until game data is ready.
	SetTimer( 0.2, true, 'PollForUIScreensComplete');
}

simulated function PollForUIScreensComplete()
{
	`log("tick");
	if (`ECRULES.isReady)
	{
		`log("tock");
		ClearTimer( 'PollForUIScreensComplete' );
		InitUIScreensComplete();
	}
}

simulated function InitUIScreensComplete()
{
	super.InitUIScreens();
	
	`log("EC_StrategyPresentationLayer.InitUIScreensComplete()");
	UIWorldMessages();
	UIStrategyHUD();
	m_bPresLayerReady = true;
}

simulated function UIStrategyHUD()
{
	local class<UIScreen> StrategyHUDClass;

	StrategyHUDClass = class<UIScreen>(DynamicLoadObject(default.StrategyHUDClassPath, class'Class'));
	ScreenStack.Push(Spawn(StrategyHUDClass, self));
}