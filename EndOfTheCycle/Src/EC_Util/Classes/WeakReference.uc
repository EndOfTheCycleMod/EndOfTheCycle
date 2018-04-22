class WeakReference extends Object;

var string Path;
var class ObjectClass;

function Set(Object o)
{
	Path = PathName(o);
	ObjectClass = o.Class;
}

function Object Get()
{
	return FindObject(Path, ObjectClass);
}