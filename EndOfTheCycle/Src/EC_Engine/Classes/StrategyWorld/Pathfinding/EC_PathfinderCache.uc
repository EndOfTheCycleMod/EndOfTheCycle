// Object that can optionally be used for pathing queries to make them faster.
// Since the EC_Pathfinder can (but doesn't need to) be shared between users,
// making it cache the results itself would lead to frequent congestion.
// Making users store a cache instead makes the system more scalable.
class EC_PathfinderCache extends Object within EC_Pathfinder;