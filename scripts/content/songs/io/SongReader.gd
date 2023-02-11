extends Object
class_name SongReader

const SIGNATURE:PackedByteArray = [0x53,0x53,0x2b,0x6d]

func read_from_file(path:String) -> Song:
	var file = FileAccess.open(path,FileAccess.READ)
	assert(file != null) #,"Couldn't read file: %s" % err)
	assert(file.get_buffer(4) == SIGNATURE) #,"This isn't a map")
	var song = Song.new()
	var file_version = file.get_16()
	match file_version:
		1: _sspmv1(file,song)
		2: _sspmv2(file,song)
	return song

func get_audio_format(buffer:PackedByteArray):
	if buffer.slice(0,4) == PackedByteArray([0x4F,0x67,0x67,0x53]): return Globals.AudioFormat.OGG

	if (buffer.slice(0,4) == PackedByteArray([0x52,0x49,0x46,0x46])
	and buffer.slice(8,12) == PackedByteArray([0x57,0x41,0x56,0x45])): return Globals.AudioFormat.WAV
	
	if (buffer.slice(0,2) == PackedByteArray([0xFF,0xFB])
	or buffer.slice(0,2) == PackedByteArray([0xFF,0xF3])
	or buffer.slice(0,2) == PackedByteArray([0xFF,0xFA])
	or buffer.slice(0,2) == PackedByteArray([0xFF,0xF2])
	or buffer.slice(0,3) == PackedByteArray([0x49,0x44,0x33])): return Globals.AudioFormat.MP3
	
	return Globals.AudioFormat.UNKNOWN

func _cover(image:Image,song:Song):
	var texture = ImageTexture.create_from_image(image)
	song.cover = texture
func _audio(buffer:PackedByteArray,song:Song):
	var format = get_audio_format(buffer)
	match format:
		Globals.AudioFormat.WAV:
			var stream = AudioStreamWAV.new()
			stream.data = buffer
			song.audio = stream
		Globals.AudioFormat.OGG:
			var stream = AudioStreamOggVorbis.new()
			stream.data = buffer
			song.audio = stream
		Globals.AudioFormat.MP3:
			var stream = AudioStreamMP3.new()
			stream.data = buffer
			song.audio = stream
		_: 
			print("I don't recognise this format! %s" % buffer.slice(0,3))
			song.broken = true

func _sspmv1(file:FileAccess,song:Song):
	file.seek(file.get_position()+2) # Header reserved space or something
	song.id = file.get_line()
	song.name = file.get_line()
	song.song = song.name
	song.creator = file.get_line()
	file.seek(file.get_position()+4) # skip last_ms
	var note_count = file.get_32()
	song.difficulty = file.get_8()
	# Cover
	var cover_type = file.get_8()
	match cover_type:
		1:
			var height = file.get_16()
			var width = file.get_16()
			var mipmaps = bool(file.get_8())
			var format = file.get_8()
			var length = file.get_64()
			var image = Image.create_from_data(width,height,mipmaps,format,file.get_buffer(length))
			_cover(image,song)
		2:
			var image = Image.new()
			var length = file.get_64()
			image.load_png_from_buffer(file.get_buffer(length))
			_cover(image,song)
	if file.get_8() != 1: # No music
		song.broken = true
		return
	var music_length = file.get_64()
	var music_signature = file.get_buffer(12)
	var music_format = get_audio_format(music_signature)
	if music_format == Globals.AudioFormat.UNKNOWN:
		song.broken = true
		return
	file.seek(file.get_position()-12)
	_audio(file.get_buffer(music_length),song)
	file.seek(file.get_position()+1)
	song.notes = []
	for i in range(note_count):
		var note = Song.Note.new()
		note.index = i + 1
		note.time = float(file.get_32())/1000
		if file.get_8() == 1:
			note.x = file.get_float()
			note.y = file.get_float()
		else:
			note.x = float(file.get_8())
			note.y = float(file.get_8())
		song.notes.append(note)

func _read_data_type(file:FileAccess,skip_type:bool=false,skip_array_type:bool=false,type:int=0,array_type:int=0):
	if !skip_type:
		type = file.get_8()
	match type:
		1: return file.get_8()
		2: return file.get_16()
		3: return file.get_32()
		4: return file.get_64()
		5: return file.get_float()
		6: return file.get_real()
		7:
			var value:Vector2
			var t = file.get_8()
			if t == 0:
				value = Vector2(file.get_8(),file.get_8())
				return value
			value = Vector2(file.get_float(),file.get_float())
			return value
		8: return file.get_buffer(file.get_16())
		9: return file.get_buffer(file.get_16()).get_string_from_utf8()
		10: return file.get_buffer(file.get_32())
		11: return file.get_buffer(file.get_32()).get_string_from_utf8()
		12:
			if !skip_array_type:
				array_type = file.get_8()
			var array = []
			array.resize(file.get_16())
			for i in range(array.size()):
				array[i] = _read_data_type(file,true,false,array_type)
			return array
func _sspmv2(file:FileAccess,song:Song):
	file.seek(0x26)
	var marker_count = file.get_32()
	song.difficulty = file.get_8()
	file.get_16() # Why checked earth did he think star rating would be stored in the file thats actually so ridiculous
	if !bool(file.get_8()): # Does the map have music?
		song.broken = true
		return
	var cover_exists = bool(file.get_8())
	file.seek(0x40)
	var audio_offset = file.get_64()
	var audio_length = file.get_64()
	var cover_offset = file.get_64()
	var cover_length = file.get_64()
	var marker_def_offset = file.get_64()
	file.seek(0x70)
	var markers_offset = file.get_64()
	file.seek(0x80)
	song.id = file.get_buffer(file.get_16()).get_string_from_utf8()
	song.name = file.get_buffer(file.get_16()).get_string_from_utf8()
	song.song = file.get_buffer(file.get_16()).get_string_from_utf8()
	song.creator = ""
	for i in range(file.get_16()):
		var creator = file.get_buffer(file.get_16()).get_string_from_utf8()
		if i != 0:
			song.creator += " & "
		song.creator += creator
	# Cover
	if cover_exists:
		file.seek(cover_offset)
		var image = Image.new()
		image.load_png_from_buffer(file.get_buffer(cover_length))
		_cover(image,song)
	# Audio
	file.seek(audio_offset)
	_audio(file.get_buffer(audio_length),song)
	# Markers
	file.seek(marker_def_offset)
	var markers = {}
	var types = []
	for _i in range(file.get_8()):
		var type = []
		types.append(type)
		type.append(file.get_buffer(file.get_16()).get_string_from_utf8())
		markers[type[0]] = []
		var count = file.get_8()
		for _o in range(1,count+1):
			type.append(file.get_8())
		file.get_8()
	file.seek(markers_offset)
	for _i in range(marker_count):
		var marker = []
		var ms = file.get_32()
		marker.append(ms)
		var type_id = file.get_8()
		var type = types[type_id]
		for i in range(1,type.size()):
			var data_type = type[i]
			var v = _read_data_type(file,true,false,data_type)
			marker.append_array([data_type,v])
		markers[type[0]].append(marker)
	if !markers.has("ssp_note"):
		song.broken = true
		return
	song.notes = []
	var i = 1
	for note_data in markers.get("ssp_note"):
		if note_data[1] != 7: continue
		var note = Song.Note.new()
		note.index = i
		note.time = float(note_data[0])/1000
		note.x = note_data[2].x
		note.y = note_data[2].y
		song.notes.append(note)
		i += 1