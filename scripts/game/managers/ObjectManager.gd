extends BaseManager
class_name ObjectManager

@export_node_path("Node3D") var origin_path
@onready var origin = get_node(origin_path)

var objects = []
var objects_dict = {}

var player:PlayerObject

func _ready():
	append_object(origin.get_node("Player"),false)
	player = objects_dict.get("Player")
	origin.set_physics_process(player.local_player)
	append_object(origin.get_node("World"),false)
	append_object(origin.get_node("HUD"),false)

func append_object(object:GameObject,parent:bool=true):
	if objects_dict.has(object.id): return
	object.game = game
	object.manager = self
	if player != null: object.set_physics_process(player.local_player)
	objects.append(object)
	objects_dict[object.id] = object
	if object is HitObject:
		object.connect("on_hit_state_changed",Callable(player,"hit_object_state_changed").bind(object))
	var current_parent = object.get_parent()
	if parent and current_parent != origin:
		if current_parent != null:
			current_parent.remove_child(object)
		origin.add_child(object)
	for child in object.get_children():
		if child is GameObject:
			append_object(child,false)

func build_map(map:Map):
	map.notes.sort_custom(func(a,b): return a.time < b.time)
	var note_objects = []
	for note in map.notes:
		note = note as Map.Note
		var id = note.data.get("id","note-%s" % note.index)
		var object = NoteObject.new(id,note)
		object.process_mode = Node.PROCESS_MODE_DISABLED
		object.process_priority = 4
		object.hittable = true
		object.spawn_time = note.time - 1
		object.despawn_time = note.time + 1
		object.visible = false
		append_object(object)
	objects.sort_custom(func(a,b): return a.spawn_time < b.spawn_time)

func _process(_delta):
	for object in objects:
		if object.permanent:
			object.process_mode = Node.PROCESS_MODE_INHERIT
			continue
		if game.sync_manager.current_time >= object.spawn_time and game.sync_manager.current_time <= object.despawn_time:
			object.process_mode = Node.PROCESS_MODE_INHERIT
			continue
		object.process_mode = Node.PROCESS_MODE_DISABLED
		if game.sync_manager.current_time < object.spawn_time: break