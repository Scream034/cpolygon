extends EditorCBaseButton
class_name EditorCCutButton

var clipped_node: Polygon2D

func _init() -> void:
	scene_path = "scenes/cut_button.tscn"

func _enter_tree() -> void:
	super._enter_tree()
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	EditorPluginCPolygon.l("Cut button: ", EditorPluginCPolygon.selections)

	if len(EditorPluginCPolygon.selections) == 0: return
	elif is_instance_valid(clipped_node) && is_instance_valid(clipped_node.owner):
		OS.alert("Wait for previous cut to finish", "Error!")
		EditorPluginCPolygon.editor_selection.add_node(clipped_node)
		return

	var target = EditorPluginCPolygon.selections[0] as Polygon2D
	var x_clipped_node = EditorPluginCPolygon.selections.get(1) as Polygon2D if len(EditorPluginCPolygon.selections) > 1 else null
	if !is_instance_valid(target): return

	# if we have clipped node then we don't need to wait create new clipped node
	if is_instance_valid(x_clipped_node):
		clipped_node = x_clipped_node
		cut(target)
		return
	# else we need to wait for create new clipped node

	var wait_polygon = EditorWaitPolygon2D.new(target.get_path())
	var success = await wait_polygon.wait_create_async()

	if success:
		clipped_node = wait_polygon.node
		cut(target)
	else:
		EditorPluginCPolygon.l("Failed cut")

func cut(target: Polygon2D) -> void:
	EditorPluginCPolygon.l("Cutting polygon")

	# for true intersection we need to have same position
	if clipped_node.global_position != target.global_position:
		clipped_node.global_position = target.global_position

	var target_path = target.get_path()
	var clipped_data = EditorPolygon2DUndoRedoData.new(clipped_node)

	EditorPluginCPolygon.editor_undo_redo.create_action("Cut polygon")
	EditorPluginCPolygon.editor_undo_redo.add_do_method(self, "_apply_cut", target_path, clipped_data)
	EditorPluginCPolygon.editor_undo_redo.add_undo_method(self, "_undo_cut", target_path, target.polygon, clipped_data)
	EditorPluginCPolygon.editor_undo_redo.commit_action()

	clipped_node = null

func _apply_cut(path: String, clipped_data: EditorPolygon2DUndoRedoData) -> void:
	var target = EditorPluginCPolygon.root.get_node_or_null(path) as Polygon2D
	if !is_instance_valid(target):
		push_warning("Cut button: Failed to apply cut")
		return

	# just apply intersection
	clipped_data.result = CGeometry2D.intersection(target.polygon, clipped_data.original_polygon)
	target.polygon = clipped_data.result.pop_front()

	EditorPluginCPolygon.editor_selection.clear()

	# try to create clipped nodes (when multiple intersection)
	var clipped_data_size = clipped_data.result.size()
	EditorPluginCPolygon.l("Clipped data size: ", clipped_data_size, " ", len(clipped_data.result))
	if (clipped_data_size > 0):
		clipped_data._result_nodes = []

		var p_parent = target.get_parent().get_parent() # for add clipped nodes to parent
		var instance = target.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as Polygon2D # for create clipped nodes

		# Remove clipped node from target
		print(clipped_data.path.get_name(clipped_data.path.get_name_count() - 2), target.name)
		if clipped_data.path.get_name(clipped_data.path.get_name_count() - 2) == target.name:
			var clipped = EditorPluginCPolygon.root.get_node(clipped_data.path) as Polygon2D
			var child = instance.get_node(target.get_path_to(clipped))
			instance.remove_child(child)
			child.queue_free()

			# free
			child = null
			clipped = null

		for index in clipped_data_size:
			var polygon = clipped_data.result.get(index)
			var node = instance.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as Polygon2D
			node.polygon = polygon
			node.global_position = target.global_position
			node.name = target.name + "_" + str(index)

			target.add_child(node)
			node.owner = p_parent
			clipped_data._result_nodes.push_back(node)

			EditorPluginCPolygon.editor_selection.add_node(node)
			EditorPluginCPolygon.l("Created clipped node: ", node.name, " [", polygon, "]")

	EditorPluginCPolygon.editor_selection.add_node(target)


func _undo_cut(path: String, target_polygon: PackedVector2Array, clipped_data: EditorPolygon2DUndoRedoData) -> void:
	var target = EditorPluginCPolygon.root.get_node_or_null(path) as Polygon2D
	if !is_instance_valid(target):
		push_warning("Cut button: Failed to undo cut")
		return
	
	target.polygon = target_polygon
	
	if clipped_data._result_nodes != null:
		for node in clipped_data._result_nodes:
			EditorPluginCPolygon.l("Remove clipped node: ", node.name)
			node.get_parent().remove_child(node)
			node.owner = null
			node.queue_free()