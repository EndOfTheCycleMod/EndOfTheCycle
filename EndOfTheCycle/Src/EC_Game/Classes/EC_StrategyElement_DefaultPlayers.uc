class EC_StrategyElement_DefaultPlayers extends EC_StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(StandardPlayer('XComPlayer', MakeLinearColor(0.604f, 0.796f, 0.796f, 1.0f)));
	Templates.AddItem(StandardPlayer('AdventPlayer', MakeLinearColor(0.749f, 0.118f, 0.18f, 1.0f)));

	Templates.AddItem(FactionPlayer('ReaperPlayer', MakeLinearColor(0.635f, 0.529f, 0.322f, 1.0f)));
	Templates.AddItem(FactionPlayer('SkirmisherPlayer', MakeLinearColor(0.749f, 0.118f, 0.18f, 1.0f)));
	Templates.AddItem(FactionPlayer('TemplarPlayer', MakeLinearColor(0.714, 0.702, 0.89, 1.0f)));

	return Templates;
}

static function EC_StrategyPlayerTemplate StandardPlayer(name TemplateName, LinearColor C)
{
	local EC_StrategyPlayerTemplate Template;

	`CREATE_X2TEMPLATE(class'EC_StrategyPlayerTemplate', Template, TemplateName);
	Template.PlayerColor = C;
	return Template;
}

static function EC_StrategyPlayerTemplate FactionPlayer(name TemplateName, LinearColor C)
{
	local EC_StrategyPlayerTemplate Template;

	`CREATE_X2TEMPLATE(class'EC_StrategyPlayerTemplate', Template, TemplateName);
	Template.PlayerColor = C;
	return Template;
}
