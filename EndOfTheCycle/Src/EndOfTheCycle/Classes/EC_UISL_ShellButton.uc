class EC_UISL_ShellButton extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIButton TheButton;
	if (UIShell(Screen) != none)
	{
		TheButton = Screen.Spawn(class'UIButton', Screen).InitButton('', "End of the Cycle", OnButtonClicked);
		TheButton.SetPosition(100, 100);
		TheButton.SetSize(1720, 880);
		TheButton.SetFontSize(100);
	}
}

function OnButtonClicked(UIButton Button)
{
	Button.ConsoleCommand("open Strategy_Root");
}