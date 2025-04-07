extends Object
class_name EditorWaitPolygon2D

const NODE_NAME = "EditorWaitPolygon2D"

signal final(sucess: bool)

var parent_path: NodePath
var node: Polygon2D

func _init(p_parent_path: NodePath) -> void:
	parent_path = p_parent_path

## Creates a new Polygon2D node and adds it to the parent node
func create() -> bool:
	var parent = get_parent()
	if !is_instance_valid(parent):
		push_error("Parent is not valid for: ", parent_path)
		return false
	elif is_instance_valid(node):
		push_error(node.name + " already exists")
		return false

	node = Polygon2D.new()

	# Parse name
	var index = 0
	while parent.has_node(NODE_NAME + "_" + str(index)):
		index += 1
	node.name = NODE_NAME + "_" + str(index)

	# Add to scene tree
	parent.add_child(node)
	node.set_owner(parent.owner)
	return true

## Returns the parent node of the node
func get_parent() -> Node:
	if parent_path == null:
		push_error("Parent path is null")
		return
	
	var parent = EditorPluginCPolygon.root.get_node(parent_path)
	if parent == null:
		push_error("Parent is null")
		return
	
	return parent

## Selects the node and waits for the selection to be changed
func select_async() -> void:
	if node == null:
		return
	
	EditorPluginCPolygon.editor_selection.clear()
	EditorPluginCPolygon.editor_selection.add_node(node)
	await EditorPluginCPolygon.editor_selection.selection_changed

## Waits for the node to be created and then selects it
func wait_create_async() -> bool:
	if !create():
		return false
	
	await select_async()
	var result = await _wait_for_create_async()
	return result

func _wait_for_create_async() -> bool:
	EditorPluginCPolygon.editor_undo_redo.history_changed.connect(_on_history_changed_for_create, CONNECT_REFERENCE_COUNTED)
	var success = await final
	EditorPluginCPolygon.editor_undo_redo.history_changed.disconnect(_on_history_changed_for_create)
	return success

func _on_history_changed_for_create() -> void:
	var id = EditorPluginCPolygon.editor_undo_redo.get_object_history_id(node)
	if id == 0:
		push_warning(NODE_NAME + " not found in history")
		emit_signal("final", false)
		return

	var history = EditorPluginCPolygon.editor_undo_redo.get_history_undo_redo(id)
	if history == null:
		push_error("History not found")
		emit_signal("final", false)
		return
	
	var current_action_name = history.get_current_action_name()

	if current_action_name == "Create Polygon":
		emit_signal("final", true)
	else:
		push_warning("You're not creating a polygon (select %s): %s" % [node.name, current_action_name])