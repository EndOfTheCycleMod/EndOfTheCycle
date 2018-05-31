// Interface for class managing the FOW
interface IEC_StratMapFOWVisualizer;

// Create and initialize whatever resources are needed
function InitResources();

function bool FOWInited();

// Update the current FOW state. If Immediate is passed, no fany animations should be done
function UpdateFOW(array<FOWUpdateParams> Params, bool Immediate);
// Draw the Entire FOW state to the NewState. Much more performant
function Clear(EECVisState NewState);

// Do we need this? Can the Map just subscribe to world cleanup
function ReleaseResources();