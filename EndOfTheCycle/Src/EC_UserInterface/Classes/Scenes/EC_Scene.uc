// Base class for all Scenes. Scenes are a collection of level actors (+components, Kismet) with an interface to UI code that allows
// User Interface to easily place pawns for purposes of Loadout, Customization, Squad Select and similar
// This allows us to keep the UI classes relatively boilerplate-free, while scenes are easily exchangeable and customizable
class EC_Scene extends Actor abstract;