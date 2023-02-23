extends ObjectRenderer
class_name NoteRenderer

func _ready():
	multimesh.instance_count = 0
	multimesh.use_colors = true
	var mesh = SoundSpacePlus.blocks.get_by_id("cube")
	multimesh.mesh = mesh.mesh

func render_objects(objects:Array):
	var notes = []
	for object in objects:
		if manager.game.sync_manager.current_time < object.spawn_time:
			break
		if not (object is NoteObject and object.visible):
			continue
		notes.append(object)
	var count = notes.size()
	if count > multimesh.instance_count: multimesh.instance_count = count
	multimesh.visible_instance_count = count
	var i = 0
	for note in notes:
		multimesh.set_instance_color(i,note.colour)
		multimesh.set_instance_transform(i,note.global_transform)
		i += 1