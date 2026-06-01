@tool
extends Node


func classdb_query(params: Dictionary) -> Variant:
	var class_name: String = params.get("class_name", "")
	if class_name.is_empty():
		return {"error": {"code": -32602, "message": "Class name is required"}}

	if not ClassDB.class_exists(class_name):
		return {"error": {"code": -32602, "message": "Class not found: " + class_name}}

	var info: Dictionary = {
		"name": class_name,
		"parent": ClassDB.get_parent_class(class_name),
		"inheritance": _get_inheritance(class_name),
		"constants": ClassDB.class_get_integer_constant_list(class_name),
		"signals": ClassDB.class_get_signal_list(class_name),
		"methods_count": ClassDB.class_get_method_count(class_name),
	}
	return info


func classdb_list_methods(params: Dictionary) -> Variant:
	var class_name: String = params.get("class_name", "")
	var include_inherited: bool = params.get("include_inherited", false)
	if class_name.is_empty():
		return {"error": {"code": -32602, "message": "Class name is required"}}

	if not ClassDB.class_exists(class_name):
		return {"error": {"code": -32602, "message": "Class not found: " + class_name}}

	var methods: Array = []
	var method_list: Array = ClassDB.class_get_method_list(class_name, include_inherited)
	for method in method_list:
		methods.append({
			"name": method["name"],
			"args": method.get("args", []),
			"return": method.get("return", {}),
			"flags": method.get("flags", 0),
		})
	return {"class": class_name, "methods": methods, "count": methods.size()}


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


func _get_inheritance(class_name: String) -> Array:
	var chain: Array = []
	var current: String = class_name
	while not current.is_empty():
		chain.append(current)
		current = ClassDB.get_parent_class(current)
	return chain
