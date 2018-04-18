// Player class object for strategy
class EC_GameState_StrategyPlayer extends XComGameState_BaseObject;

struct PlayerRelation
{
	var name TeamName;
	var int PlayerRelationFlags;
};

const PLR_RELATION_WAR				= 0x0000001;
const PLR_RELATION_COLD				= 0x0000002;
const PLR_RELATION_TRUCE			= 0x0000004;
const PLR_RELATION_PEACE			= 0x0000008;
const PLR_RELATION_ALLY				= 0x0000010;

// combined flags
// this player knows about the other
const PLR_RELATION_KNOWN					= 0x000001F;
// this player may traverse other player territory
const PLR_RELATION_MAY_TRAVERSE_TERRITORY	= 0x0000011; // (PLR_RELATION_WAR | PLR_RELATION_ALLY)
// this player may traverse other player units
const PLR_RELATION_MAY_TRAVERSE_UNITS		= 0x0000018; // (PLR_RELATION_PEACE | PLR_RELATION_ALLY)
// this player may attack other player's things
// you can only attack things you can actually enter, so this applies in neutral territory.
// in other player's territory, MAY_TRAVERSE_TERRITORY applies in addition, so you need to be at war for that
const PLR_RELATION_MAY_ATTACK				= 0x0000003; // (PLR_RELATION_WAR | PLR_RELATION_COLD)



var private name m_TemplateName;
var protectedwrite array<PlayerRelation> m_PlayerRelations;

static function EC_StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'EC_StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

simulated function name GetMyTemplateName()
{
	return self.m_TemplateName;
}

simulated function EC_StrategyPlayerTemplate GetMyTemplate()
{
	return EC_StrategyPlayerTemplate(GetMyTemplateManager().FindStrategyElementTemplate(self.m_TemplateName));
}

function OnCreation(optional X2DataTemplate Template)
{
	`assert(EC_StrategyPlayerTemplate(Template) != none);
	m_TemplateName = Template.DataName;
}


function SetRelationTowardsPlayer(name PlayerName, int Relation)
{
	local int i, rel;
	i = m_PlayerRelations.Find('TeamName', PlayerName);
	// remove other status
	rel = m_PlayerRelations[i].PlayerRelationFlags;
	rel = rel & (~PLR_RELATION_KNOWN);
	rel = rel | Relation;
	`assert((rel & PLR_RELATION_KNOWN) != 0);
	m_PlayerRelations[i].PlayerRelationFlags = rel;
}