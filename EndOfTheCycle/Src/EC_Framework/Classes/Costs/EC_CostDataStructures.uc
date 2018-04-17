class EC_CostDataStructures extends Object;

enum EECItemType
{
	eECIT_Work,        // Costs work
	eECIT_Resource,    // Costs resources (resources are items that can be shared, such as supplies, ...)
	eECIT_Item,        // Costs items
};

struct ECItemCost
{
	var EECItemType Type;
	var name TemplateName;
	var int Quantity;
	var int IsPerTurnCost;
};


struct ECStrategyCost
{
	var array<ECItemCost> Costs;
	var int Duration;
};