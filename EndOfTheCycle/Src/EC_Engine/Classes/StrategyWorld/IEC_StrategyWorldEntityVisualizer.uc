// Interface that visualizers of StrategyWorldEntities should implement
interface IEC_StrategyWorldEntityVisualizer;

// Custom function so that Visualizers may adjust dependent values
// I.e. if a visualizer stores its location to look at, it may want to move that one too
function EntVis_SetLocation(vector NewLocation);

function EntVis_Hide();
function EntVis_Show();
function EntVis_SetFoggy(string FoggyState);
