class EC_DefaultTurnPhases extends EC_StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateMainTurnPhaseTemplate());

	return Templates;
}

static function EC_StrategyTurnPhaseTemplate CreateMainTurnPhaseTemplate()
{
	local EC_StrategyTurnPhaseTemplate Template;

	`CREATE_X2TEMPLATE(class'EC_StrategyTurnPhaseTemplate', Template, 'MainTurnPhase');
	Template.TurnPhaseClass = class'EC_GameState_StrategyTurnPhaseEnhanced';
	Template.NeedsPlayerEndPhase = true;

	return Template;
}