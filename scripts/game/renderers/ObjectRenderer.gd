extends MultiMeshInstance3D
class_name ObjectRenderer

@onready var manager:ObjectManager = get_parent()

func _process(_delta):
	var objects = (get_parent() as ObjectManager).objects
	self.render_objects(objects)

func render_objects(objects:Array):
	pass