@tool
extends EditorPlugin

# from https://github.com/godotengine/godot-proposals/issues/8271#issuecomment-1783984295

var importer

var autowirer = load("res://addons/godot-gltf-autowire/script_autowirer.gd").new()


func _enter_tree() -> void:
	importer = ExtrasImporter.new()
	GLTFDocument.register_gltf_document_extension(importer)
	add_scene_post_import_plugin(autowirer)


func _exit_tree() -> void:
	GLTFDocument.unregister_gltf_document_extension(importer)

class ExtrasImporter extends GLTFDocumentExtension:
	func _import_post(state: GLTFState, root: Node) -> Error:

		# Add metadata to scene root
		var root_scene_json = state.json.get("scenes", null)[0]
		var root_scene = root
		if root_scene and root_scene_json.has("extras"):
			root_scene.set_meta("extras", root_scene_json["extras"])
		
		# Add metadata to materials
		var materials_json : Array = state.json.get("materials", [])
		var materials : Array[Material] = state.get_materials()
		for i in materials_json.size():
			if materials_json[i].has("extras"):
				materials[i].set_meta("extras", materials_json[i]["extras"])
		
		# Add metadata to ImporterMeshes
		var meshes_json : Array = state.json.get("meshes", [])
		var meshes : Array[GLTFMesh] = state.get_meshes()
		for i in meshes_json.size():
			if meshes_json[i].has("extras"):
				meshes[i].mesh.set_meta("extras", meshes_json[i]["extras"])
		
		# Add metadata to nodes
		var nodes_json : Array = state.json.get("nodes", [])
		for i in nodes_json.size():
			var node = state.get_scene_node(i)
			if !node:
				continue
			if nodes_json[i].has("extras"):
				# Handle special case
				if node is ImporterMeshInstance3D:
					# ImporterMeshInstance3D nodes will be converted later to either
					# MeshInstance3D or StaticBody3D and metadata will be lost
					# A sibling is created preserving the metadata. It can be later 
					# merged back in using a EditorScenePostImport script
					var metadata_node = Node.new()
					metadata_node.set_meta("extras", nodes_json[i]["extras"])
					
					# Meshes are also ImporterMeshes that will be later converted either
					# to ArrayMesh or some form of collision shape. 
					# We'll save it as another metadata item. If the mesh is reused we'll 
					# have duplicated info but at least it will always be accurate
					if node.mesh and node.mesh.has_meta("extras"):
						metadata_node.set_meta("mesh_extras", node.mesh.get_meta("extras"))
					
					# Well add it as sibling so metadata node always follows the actual metadata owner
					node.add_sibling(metadata_node)
					# Make sure owner is set otherwise it won't get serialized to disk
					metadata_node.owner = node.owner
					# Add a suffix to the generated name so it's easy to find
					metadata_node.name += "_meta"
				# In all other cases just set_meta
				else:
					node.set_meta("extras", nodes_json[i]["extras"])
		return OK
