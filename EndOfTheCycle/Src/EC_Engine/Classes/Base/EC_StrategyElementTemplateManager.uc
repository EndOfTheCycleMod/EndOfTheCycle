// Use our own template manager so we don't get stuff mixed up
class EC_StrategyElementTemplateManager extends X2DataTemplateManager;

static function EC_StrategyElementTemplateManager GetStrategyElementTemplateManager()
{
	return EC_StrategyElementTemplateManager(class'Engine'.static.GetTemplateManager(class'EC_StrategyElementTemplateManager'));
}

function bool AddStrategyElementTemplate(EC_StrategyElementTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function EC_StrategyElementTemplate FindStrategyElementTemplate(name DataName)
{
	return EC_StrategyElementTemplate(FindDataTemplate(DataName));
}

function array<EC_StrategyElementTemplate> GetAllTemplatesOfClass(class<EC_StrategyElementTemplate> TemplateClass, optional int UseTemplateGameArea=-1)
{
	local array<EC_StrategyElementTemplate> arrTemplates;
	local X2DataTemplate Template;

	foreach IterateTemplates(Template, none)
	{
		if ((UseTemplateGameArea > -1) && !Template.IsTemplateAvailableToAllAreas(UseTemplateGameArea))
			continue;

		if (ClassIsChildOf(Template.Class, TemplateClass))
		{
			arrTemplates.AddItem(EC_StrategyElementTemplate(Template));
		}
	}

	return arrTemplates;
}

DefaultProperties
{
	TemplateDefinitionClass=class'EC_StrategyElement'
	ManagedTemplateClass=class'EC_StrategyElementTemplate'
}