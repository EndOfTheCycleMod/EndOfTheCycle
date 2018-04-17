class EC_StrategyElement_DefaultPlayers extends EC_StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(StandardPlayer('XComPlayer'));
	Templates.AddItem(StandardPlayer('AdventPlayer'));

	Templates.AddItem(FactionPlayer('ReaperPlayer'));
	Templates.AddItem(FactionPlayer('SkirmisherPlayer'));
	Templates.AddItem(FactionPlayer('TemplarPlayer'));

	return Templates;
}

static function EC_StrategyPlayerTemplate StandardPlayer(name TemplateName)
{
	local EC_StrategyPlayerTemplate Template;

	`CREATE_X2TEMPLATE(class'EC_StrategyPlayerTemplate', Template, TemplateName);

	return Template;
}

static function EC_StrategyPlayerTemplate FactionPlayer(name TemplateName)
{
	local EC_StrategyPlayerTemplate Template;

	`CREATE_X2TEMPLATE(class'EC_StrategyPlayerTemplate', Template, TemplateName);

	return Template;
}
