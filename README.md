# Godot glTF Autowire 

This plugin auto-assigns scripts to any imported glTF by using `glTF "extras".` Any supported glTF element will search for a `gdscript` file in your Godot 
project that matches a value specified in the extras section and assign it to the root element generated by the import. 

This workflow allows you to edit `glTF` or `.blender` files and automatically add scripts to individual elements in 
them [without having the create an inherited scene](https://www.reddit.com/r/godot/comments/129sgc8/what_is_the_intended_workflow_for_inheriting/).

Currently supported elements are:
 - Root scenes (such as the hierarchy root in a blender file).
 - Meshes (see mesh notes). 
 - Empties

### Mesh notes:
`godot-gltf-autowire` will do it's best to assign the script to the _root of a meshes generated nodes_. This means that if you leverage blender workflow 
shortcuts for importing meshes as Rigidbodies and Colliders, the script will be assigned to the root-most element that results from the import (IE: the 
`Rigidbodie` node, not the `MeshInstance` node childed under it). 

## How To Use:
For this example, we will just use Blender, given that the circumstance you'd be editing raw `glTF` .json values is pretty slim (though please correct me if I am 
wrong).

https://www.youtube.com/watch?v=-3YDapynmbk

Note that the keyword and searchpath for the plugin can be set in `addons/godot-gltf-autowire/script_autowirer.gd`. At some point this will be moved into project settings. 

## How to keep the autowiring from happening:
This autowiring is `opt-in`, which is to say if you don't add the autowire tag to the glTF import, this plugin won't try to wire scripts to the file. 

## Credits:
This plugin is heavily based off the work from @noidexe: https://github.com/godotengine/godot-proposals/issues/8271#issuecomment-1783984295








