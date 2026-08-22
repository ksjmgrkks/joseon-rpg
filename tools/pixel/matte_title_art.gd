extends SceneTree
##
## 시작 화면 아트 후처리 — PixelLab 이 `no_background=true` 를 무시하고 불투명 배경으로
## 내주는 경우가 있어(현판·안개에서 실제로 그랬다) 여기서 알파를 만들어 준다.
##
## 실행: godot --headless --path . --script res://tools/pixel/matte_title_art.gd
##
## ① 현판(title_plaque) — 배경이 균일한 회색 한 덩어리라 **테두리 플러드필**로 지운다.
##    (안쪽 나뭇결이 배경색과 비슷해도, 테두리에서 연결되지 않으면 안 지워진다.)
## ② 안개(title_mist) — 검은 배경 위 흰 연기라, 지우는 게 아니라 **밝기를 그대로 알파로**
##    바꾼다. 연기 가장자리가 부드럽게 빠져서 플러드필보다 훨씬 자연스럽다.
##

const PLAQUE := "res://assets/ui/title_plaque.png"
const MIST := "res://assets/ui/title_mist.png"
const BG_TOL := 0.10        # 배경으로 볼 색 거리(0~1)


func _init() -> void:
	_matte_plaque()
	_mist_to_alpha()
	quit(0)


func _matte_plaque() -> void:
	var img := Image.load_from_file(PLAQUE)
	if img == null:
		push_error("없음: " + PLAQUE)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var bg := img.get_pixel(0, 0)
	var visited := PackedByteArray()
	visited.resize(w * h)
	var stack: Array[Vector2i] = []
	for x in range(w):
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in range(h):
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	var cleared := 0
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var i := p.y * w + p.x
		if visited[i] == 1:
			continue
		visited[i] = 1
		var c := img.get_pixel(p.x, p.y)
		if c.a <= 0.01 or _dist(c, bg) > BG_TOL:
			continue
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		cleared += 1
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))
	img.save_png(ProjectSettings.globalize_path(PLAQUE))
	print("현판: 배경 %d px 투명화 (배경색 %s)" % [cleared, bg])


func _mist_to_alpha() -> void:
	var img := Image.load_from_file(MIST)
	if img == null:
		push_error("없음: " + MIST)
		return
	img.convert(Image.FORMAT_RGBA8)
	# 이미 변환된 파일에 또 돌리면 알파가 전부 1 이 되어 흰 판이 된다(실제로 겪음) — 막는다.
	# 원본은 배경까지 완전히 불투명하므로, 알파가 조금이라도 있으면 이미 처리된 것이다.
	if img.detect_alpha() != Image.ALPHA_NONE:
		print("안개: 이미 알파가 있음 — 건너뜀")
		return
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			var lum := 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			# 연기는 흰색으로 통일하고, 밝기를 알파로 옮긴다.
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(lum * 1.15, 0.0, 1.0)))
	img.save_png(ProjectSettings.globalize_path(MIST))
	print("안개: 밝기 → 알파 변환 완료")


## 두 색의 RGB 거리(0~1). 알파는 보지 않는다.
func _dist(a: Color, b: Color) -> float:
	return (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0
