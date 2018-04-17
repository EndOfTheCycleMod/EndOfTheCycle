// Common interface for everything that can have a normal not-slot-based inventory to store XComGameState_Items
// GameState-Object
interface IEC_Inventory;

// Those functions are separate because UI may want to check (and get a reason). It is perfectly valid for an operation to fail silently if the user
// doesn't need to know about it

// return true if the item can be added to inventory. if false is returned, a fail reason is expected
function bool Inv_CanAddItemToInventory(XComGameState_Item ItemState, optional XComGameState NewGameState, optional out string FailReason);
// Try to add the item to inventory. return true if successful, false otherwise
function bool Inv_AddItemToInventory(XComGameState_Item ItemState, optional XComGameState NewGameState);

// return true if the item can be removed from inventory. if false is returned, a fail reason is expected
function bool Inv_CanRemoveItemToInventory(XComGameState_Item ItemState, optional XComGameState NewGameState, optional out string FailReason);
// Try to remove the item from inventory. return true if successful, false otherwise
function bool Inv_RemoveItemToInventory(XComGameState_Item ItemState, optional XComGameState NewGameState);

// get all items contained in this inventory. use PendingGameState to check for update states of sub-inventories
function array<XComGameState_Item> Inv_GetAllInventoryItems(optional XComGameState PendingGameState);

// return the "capacity" of this inventory. it generally is an upper bound on the total size of items in this inventory, multiplied by their templated size
function int Inv_GetInventoryCapacity();
// return ItemCats / WeaponCats that can be stored in this inventory. If ItemCat matches, it can be stored, if not and the ItemCat is 'weapon', WeaponCat is checked
function array<name> Inv_GetValidItemTypes();