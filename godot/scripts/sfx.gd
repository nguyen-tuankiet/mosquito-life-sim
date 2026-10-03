extends Node
## Autoload "Sfx": âm thanh tạo bằng code (bíp + tiếng vỗ cánh có âm thanh nổi theo hướng).

const RATE := 22050.0
var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var beeps: Array = []
var muted := false
var hum_vol := 0.0
var hum_pan := 0.0
var hum_freq := 430.0
var _hph := 0.0
var _tph := 0.0

func _ready() -> void:
	player = AudioStreamPlayer.new()
	var s := AudioStreamGenerator.new()
	s.mix_rate = RATE
	s.buffer_length = 0.12
	player.stream = s
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback

func beep(f: float, d: float = 0.1, type: String = "sine", vol: float = 0.06, slide: float = 0.0) -> void:
	if muted:
		return
	beeps.append({"f": f, "d": d, "t": 0.0, "type": type, "vol": vol, "slide": slide, "ph": 0.0})

func hum(vol: float, pan: float, freq: float = 430.0) -> void:
	hum_vol = vol
	hum_pan = pan
	hum_freq = freq

func _wave(type: String, ph: float) -> float:
	var x := fposmod(ph, 1.0)
	match type:
		"square": return 1.0 if x < .5 else -1.0
		"saw": return x * 2.0 - 1.0
		"triangle": return abs(x * 4.0 - 2.0) - 1.0
		_: return sin(x * TAU)

func _process(_dt: float) -> void:
	if playback == null:
		return
	var n := playback.get_frames_available()
	for i in n:
		var l := 0.0
		var r := 0.0
		for b in beeps:
			if b["t"] < b["d"]:
				var k: float = b["t"] / b["d"]
				var f: float = b["f"] + b["slide"] * k
				b["ph"] += f / RATE
				var v: float = _wave(b["type"], b["ph"]) * b["vol"] * (1.0 - k)
				l += v
				r += v
				b["t"] += 1.0 / RATE
		if hum_vol > 0.001 and not muted:
			_hph += hum_freq / RATE
			_tph += 24.0 / RATE
			var tr: float = 0.5 + 0.5 * sin(_tph * TAU)
			var v: float = _wave("saw", _hph) * hum_vol * tr * 0.5
			l += v * clamp(1.0 - hum_pan, 0.0, 1.0) * 1.2
			r += v * clamp(1.0 + hum_pan, 0.0, 1.0) * 1.2
		playback.push_frame(Vector2(l, r))
	if beeps.size() > 0 and beeps[0]["t"] >= beeps[0]["d"]:
		beeps = beeps.filter(func(b): return b["t"] < b["d"])
