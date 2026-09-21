@tool
extends Node


func classdb_query(params: Dictionary) -> Variant:
	var requested_class: String = params.get("class_name", "")
	if requested_class.is_empty():
		return {"error": {"code": -32602, "message": "Class name is required"}}

	if not ClassDB.class_exists(requested_class):
		return {"error": {"code": -32602, "message": "Class not found: " + requested_class}}

	var info: Dictionary = {
		"name": requested_class,
		"parent": ClassDB.get_parent_class(requested_class),
		"inheritance": _get_inheritance(requested_class),
		"constants": ClassDB.class_get_integer_constant_list(requested_class),
		"signals": ClassDB.class_get_signal_list(requested_class),
		"methods_count": ClassDB.class_get_method_list(requested_class).size(),
	}
	return info


func classdb_list_methods(params: Dictionary) -> Variant:
	var requested_class: String = params.get("class_name", "")
	var include_inherited: bool = params.get("include_inherited", false)
	if requested_class.is_empty():
		return {"error": {"code": -32602, "message": "Class name is required"}}

	if not ClassDB.class_exists(requested_class):
		return {"error": {"code": -32602, "message": "Class not found: " + requested_class}}

	var methods: Array = []
	var method_list: Array = ClassDB.class_get_method_list(requested_class, include_inherited)
	for method in method_list:
		methods.append({
			"name": method["name"],
			"args": method.get("args", []),
			"return": method.get("return", {}),
			"flags": method.get("flags", 0),
		})
	return {"class": requested_class, "methods": methods, "count": methods.size()}


func classdb_list_classes(params: Dictionary) -> Variant:
	var filter: String = params.get("filter", "")
	var all_classes: Array = ClassDB.get_class_list()

	if not filter.is_empty():
		var filtered: Array = []
		for cls in all_classes:
			if filter.to_lower() in cls.to_lower():
				filtered.append(cls)
		return {"classes": filtered, "count": filtered.size()}

	return {"classes": all_classes, "count": all_classes.size()}


func _get_inheritance(requested_class: String) -> Array:
	var chain: Array = []
	var current: String = requested_class
	while not current.is_empty():
		chain.append(current)
		current = ClassDB.get_parent_class(current)
	return chain
