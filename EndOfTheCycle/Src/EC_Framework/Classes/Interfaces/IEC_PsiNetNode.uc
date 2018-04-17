// Nodes in the Advent Psionic Network
// GameState-Object
interface IEC_PsiNetNode;

function array<StateObjectReference> GetConnectedNodes();

// Nodes usually exist on the strategy layer, but may have tactical instances (i.e. a workstation to hack)
function bool IsTacticalNode();
function StateObjectReference GetMyStrategyNode();

