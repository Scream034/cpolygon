extends Object
class_name EditorPolygon2DUndoRedoData

var path: NodePath
var original_polygon: PackedVector2Array
var result: Array[PackedVector2Array]
var _result_nodes: Array[Node]

func _init(node: Polygon2D) -> void:
	path = node.get_path()
	original_polygon = node.polygon.duplicate()

func _to_string() -> String:
	return "EditorPolygon2DUndoRedoData:\n\tpath: %s\n\toriginal_polygon: %s\n\tresult: %s" % [path, original_polygon, result]