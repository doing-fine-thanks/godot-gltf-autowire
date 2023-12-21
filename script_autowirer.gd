@tool
extends EditorScenePostImportPlugin

# from https://github.com/godotengine/godot-proposals/issues/8271#issuecomment-1783984295

var verbose := true

const SCRIPT_SEARCH_ROOT: String = "res://"
const SCRIPT_EXT_FILTER: Array[String] = [".gd", ".cs"]
const SCRIPT_PROP_NAME: String = "wirescript"

class ScriptFileData:
	var script_basename: String
	var script_resource_path: String

func _post_process(scene: Node) -> void:
	_merge_extras_and_wire_scripts(scene, _get_all_scripts(SCRIPT_SEARCH_ROOT, SCRIPT_EXT_FILTER))

func _get_all_scripts(path: String, file_ext := [], files := []) -> Array:
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var file_path: String = dir.get_current_dir() + "/"  + file_name
			if dir.current_is_dir():
				files = _get_all_scripts(file_path, file_ext, files)
			else:
				if not file_ext.is_empty() and ("." + file_name.get_extension()) not in file_ext:
					file_name = dir.get_next()
					continue
				
				var script_file_data := ScriptFileData.new()
				script_file_data.script_basename = get_pathless_file_basename(file_path)
				script_file_data.script_resource_path = file_path
				files.append(script_file_data)
			
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)

	return files

func get_pathless_file_basename(file_path: String) -> String:
	return file_path.get_basename().split("/")[-1]

func apply_script(node: Node, scripts: Array, extras: Dictionary) -> Node:
	for key in extras:
		if key == SCRIPT_PROP_NAME:
			for script in scripts:
				if script.script_basename == extras[key]:
					print("applying script " + script.script_resource_path + " to " + str(node))
					node.set_script(load(script.script_resource_path))
	return node

func _merge_extras_and_wire_scripts(scene : Node, scripts: Array) -> void:
	var verbose_output = []

	## wire scene root
	#var scene_extras = scene.get_meta("extras")
	#apply_script(scene, scripts, scene_extras)

	# remerge meta nodes for meshImporter structures
	var nodes : Array[Node] = scene.find_children("*" + "_meta", "Node")
	verbose_output.append_array(["Metadata nodes:",  nodes])
	for node in nodes:
		var extras = node.get_meta("extras")
		if !extras:
			verbose_output.append("Node %s contains no 'extras' metadata" % node)
			continue
		var parent = node.get_parent()
		if !parent:
			verbose_output.append("Node %s has no parent" % node)
			continue
		var idx_original = node.get_index() - 1
		if idx_original < 0 or parent.get_child_count() <= idx_original:
			verbose_output.append("Original node index %s is out of bounds. Parent child count: %s" % [idx_original, parent.get_child_count()])
			continue
		var original = node.get_parent().get_child(idx_original)
		if original:
			verbose_output.append("Setting extras metadata for %s" % original)
			original.set_meta("extras", extras)
			if node.has_meta("mesh_extras"):
				if original is MeshInstance3D and original.mesh:
					verbose_output.append("Setting extras metadata for mesh %s" % original.mesh)
					original.mesh.set_meta("extras", node.get_meta("mesh_extras"))
				else:
					verbose_output.append("Metadata node %s has 'mesh_extras' but original %s has no mesh, preserving as 'mesh_extras'" % [node, original])
					original.set_meta("mesh_extras", node.get_meta("mesh_extras"))
		else:
			verbose_output.append("Original node not found for %s" % node)
		node.queue_free()

	var all_nodes = scene.find_children("*")
	all_nodes.append(scene)
	for node in all_nodes:
		var extras = node.get_meta("extras")
		if extras:
			apply_script(node, scripts, extras)
	
	
	if verbose:
		for item in verbose_output:
			print_debug(item)


	