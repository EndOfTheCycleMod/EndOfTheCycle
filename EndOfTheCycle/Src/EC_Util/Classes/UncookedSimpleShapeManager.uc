// Custom shape manager class that references our uncooked assets. The builtin one just doesn't work without debugging.
class UncookedSimpleShapeManager extends SimpleShapeManager;

var StaticMesh Sphere, Cube, Cyl, Cone;

event PostBeginPlay()
{
	Sphere = StaticMesh(`CONTENT.RequestGameArchetype("SimpleShapes_Debug.ASE_UnitSphere"));
	Cube = StaticMesh(`CONTENT.RequestGameArchetype("SimpleShapes_Debug.ASE_UnitCube"));
	Cyl = StaticMesh(`CONTENT.RequestGameArchetype("SimpleShapes_Debug.ASE_UnitCylinder"));
	Cone = StaticMesh(`CONTENT.RequestGameArchetype("SimpleShapes_Debug.ASE_UnitCone"));
}

function ShapePair AddShape(StaticMesh StaticMesh, bool bPersistent)
{
	local string Trace;
	Trace = GetScriptTrace();
	if (InStr(Trace, "Sphere") != INDEX_NONE)
		StaticMesh = Sphere;
	else if (InStr(Trace, "Box") != INDEX_NONE)
		StaticMesh = Cube;
	else if (InStr(Trace, "Cylinder") != INDEX_NONE)
		StaticMesh = Cyl;
	else if (InStr(Trace, "Cone") != INDEX_NONE)
		StaticMesh = Cone;
	
	return super.AddShape(StaticMesh, bPersistent);
}
