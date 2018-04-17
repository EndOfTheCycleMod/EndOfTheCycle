// Interface for everything that could be shown in UI Screens / panels
// Needs to be separate because interface inheritance is extremely dangerous
interface IEC_UIDisplayInfo;

function string UIGetName();
function string UIGetDescription();
function string UIGetStatus();

function string UIGetColor();