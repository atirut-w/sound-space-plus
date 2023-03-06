extends BaseManager
class_name SyncManager

signal finished

var playing:bool = false
var playback_speed:float = 1

var last_time:int = 0
var real_time:float = 0
var current_time:float = 0
var length:float = 0

func start(from:float=0):
	last_time = Time.get_ticks_usec()
	real_time = from
	playing = true
func seek(from:float=0):
	last_time = Time.get_ticks_usec()
	real_time += from - current_time
func finish():
	playing = false
	finished.emit()

var paused:bool = false
func _notification(what):
	if what == Node.NOTIFICATION_PAUSED:
		paused = true
		just_paused()
	elif what == Node.NOTIFICATION_UNPAUSED:
		paused = false
		just_unpaused()
func just_paused():
	pass
func just_unpaused():
	pass

func _process(delta):
	if !playing: return
	var now = Time.get_ticks_usec()
	var time = playback_speed * (now - last_time) / 1000000.0
	last_time = now
	real_time += time
	current_time = real_time
	try_finish()

func try_finish():
	if current_time > length:
		finish()
