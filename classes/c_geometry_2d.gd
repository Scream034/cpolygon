extends Object
class_name CGeometry2D

## X = A - B
static func intersection(polygon_a: PackedVector2Array, polygon_b: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = Geometry2D.clip_polygons(polygon_a, polygon_b)
	if result.is_empty(): return []

	return result