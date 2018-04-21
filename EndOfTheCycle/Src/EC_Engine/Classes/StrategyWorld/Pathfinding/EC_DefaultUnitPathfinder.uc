class EC_DefaultUnitPathfinder extends EC_Pathfinder;


const MOVE_IGNORERIVERPENALTIES        = 0x0001;
const MOVE_IGNOREROUGHTERRAINPENALTIES = 0x0002;
const MOVE_TRAVERSEMOUNTAINS           = 0x0004;
const MOVE_ENDONMOUNTAINS              = 0x0008;
const MOVE_CLIMBCLIFFS                 = 0x0010;
const MOVE_IGNORECLIFFPENALTIES        = 0x0020;
const MOVE_THROUGHFOW                  = 0x0040;
const MOVE_BYPASSZOC                   = 0x0080;