// A simple turn phase that is run exactly once and serves a specific purpose, does not have any actions.
class EC_GameState_StrategyTurnPhase extends XComGameState_BaseObject dependson(EC_StrategyDataStructures);

// Linked list of Turn Phases
var StateObjectReference NextTurnPhase;

var protected name m_TemplateName;

// Generic Data object
var StateObjectReference Data;
var bool DoneOneTimeProcessing; // See ProcessTurnPhase


function OnCreation(optional X2DataTemplate Template)
{
	`assert(EC_StrategyTurnPhaseTemplate(Template) != none);
	m_TemplateName = Template.DataName;
}

function name GetMyTemplateName()
{
	return m_TemplateName;
}

function EC_StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'EC_StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

function EC_StrategyTurnPhaseTemplate GetMyTemplate()
{
	return EC_StrategyTurnPhaseTemplate(GetMyTemplateManager().FindStrategyElementTemplate(GetMyTemplateName()));
}

function BeginTurnPhase(XComGameState NewGameState)
{
	`XEVENTMGR.TriggerEvent('StrategyTurnPhaseBegun', self, self, NewGameState);
}


function EndTurnPhase(XComGameState NewGameState)
{
	`XEVENTMGR.TriggerEvent('StrategyTurnPhaseEnded', self, self, NewGameState);
}

// This simple Turn Phase does not process actions and ends immediately
// In general, it's a good practice to not do any duplicate processing if the function is called twice
// you may use the DoneOneTimeProcessing boolean for that
function ECTurnPhaseProcessResult ProcessTurnPhase()
{
	local ECTurnPhaseProcessResult Result, EmptyResult;
	
	GetMyTemplate().ProcessTurnPhase(self.GetReference(), Result.PotentialActions, eECTPS_None);

	Result = EmptyResult;
	Result.Type = eECTPPRT_End;

	return Result;
}

function Cleanup(XComGameState NewGameState)
{

}