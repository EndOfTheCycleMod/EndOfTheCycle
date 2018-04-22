// Interface for class managing the FOW
interface IEC_StratMapFOWVisualizer;

struct FOWUpdateParams
{
	var int Tile;
	var EECVisState NewState;
};

// Create and initialize whatever resources are needed
function InitResources();

function bool FOWInited();

// Update the current FOW state. If Immediate is passed, no fany animations should be done
function UpdateFOW(array<FOWUpdateParams> Params, bool Immediate);

// As if we're ever going to call this
function ReleaseResources();