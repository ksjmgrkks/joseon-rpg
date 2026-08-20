extends SceneTree
##
## 유저가 외부(비-PixelLab)에서 만들어 온 주인공 초상화 시트에서 표정 9종을 잘라
## assets/ui/portraits/protagonist/*.png 로 저장한다.
##
## 실행: godot --headless --path . --script res://tools/pixel/extract_protagonist_portraits.gd
## 입력: .art_ref_incoming/protagonist_portrait_sheet.png (커밋 안 함 — .gitignore)
##
## 2026-08-21 전면 재작성. 이전 판은 **검은 배경 JPEG** 전제라 테두리 플러드필 매팅 +
## 경계 침식 + 연결요소 청소까지 했고, 그래도 JPEG 링잉 탓에 초록 프린지가 남았다.
## 새 원본은 **배경이 이미 알파 0(투명)** 이라 매팅 자체가 필요 없다 — 잘라내기만 하면
## 프린지 문제가 원천적으로 사라진다. 하드코딩 그리드 좌표도 버리고 자동 검출로 바꿨다:
##   ① 오른쪽만 봤을 때 행 밴드가 정확히 3개가 되는 x 를 찾아 좌우를 가른다
##   ② 그리드 영역 안에서 완전히 투명한 행 구간 → 3개 행 밴드
##   ③ 각 행 밴드 안에서 완전히 투명한 열 구간 → 3개 칸
## 원본 해상도가 바뀌어도 좌표를 다시 재지 않아도 된다.
##

const SRC := "res://.art_ref_incoming/protagonist_portrait_sheet.png"
const OUT_DIR := "res://assets/ui/portraits/protagonist"
const ALPHA_MIN := 0.5      # 이 이상이면 '내용 있음'
const MIN_BAND := 40        # 밴드로 인정할 최소 두께(px) — 잡티 한 줄을 칸으로 오인하지 않게
const PAD := 2              # 칸을 잘라낸 뒤 사방으로 남길 여백(px)
## 이 칸들은 보랏빛 이펙트가 '자기 것'이라 연결요소 청소를 건너뛴다(청소하면 이펙트가 날아감).
const SKIP_COMPONENT_CLEAN := ["casting"]

# (row, col) -> 파일명. 이름은 이전 판과 동일 — 대화 시스템(dialogue_balloon.gd)이
# 이 파일명을 그대로 참조하므로 바꾸지 말 것.
const CELL_NAMES := {
	"0_0": "neutral",
	"0_1": "glance",
	"0_2": "downcast",
	"1_0": "smirk",
	"1_1": "thinking",
	"1_2": "shocked",
	"2_0": "back",
	"2_1": "casting",
	"2_2": "profile_staff",
}


func _init() -> void:
	var img := Image.load_from_file(SRC)
	if img == null:
		push_error("원본 없음: %s" % SRC)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	print("원본 %dx%d" % [w, h])

	# ① 왼쪽 대형 일러스트 / 오른쪽 9칸 그리드를 가르는 x
	var split := _find_split(img)
	if split < 0:
		push_error("좌우 분리 실패 — 오른쪽만 봤을 때 행이 3개가 되는 x 를 못 찾았다")
		quit(1)
		return

	# ② 그리드 영역의 행 밴드 3개
	var rows := _bands(_empty_rows(img, split, w), h)
	if rows.size() != 3:
		push_error("행 밴드가 3개가 아니다: %d" % rows.size())
		quit(1)
		return

	# ③ 열 경계는 '행마다' 구하지 않는다 — 3행(주문 시전)은 보랏빛 이펙트가 칸 경계를
	#    넘어 번져서 빈 열이 아예 없다(실측). 그리드는 규칙적이므로, 빈 열이 깨끗하게
	#    나오는 행에서 구한 열 경계를 세 행에 공통으로 적용한다.
	var cols: Array = []
	for band in rows:
		var c := _bands(_empty_columns(img, band.x, band.y + 1), w, split)
		if c.size() == 3:
			cols = c
			break
	if cols.is_empty():
		push_error("열 경계를 구할 수 있는 행이 하나도 없다")
		quit(1)
		return
	print("그리드 시작 x=%d / 행 %s / 열 %s" % [split, rows, cols])

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var saved := 0
	for r in range(3):
		var band: Vector2i = rows[r]
		for c in range(3):
			var cb: Vector2i = cols[c]
			var rect := Rect2i(cb.x, band.x, cb.y - cb.x + 1, band.y - band.x + 1)
			var cell := img.get_region(rect)
			var nm0: String = CELL_NAMES["%d_%d" % [r, c]]
			if not (nm0 in SKIP_COMPONENT_CLEAN):
				_keep_largest_component(cell)
			# 칸 안에서 실제 내용 bbox 로 한 번 더 조인다(칸마다 여백이 제각각이라).
			var used := cell.get_used_rect()
			used = used.grow(PAD).intersection(Rect2i(0, 0, cell.get_width(), cell.get_height()))
			cell = cell.get_region(used)
			var nm: String = CELL_NAMES["%d_%d" % [r, c]]
			cell.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT_DIR, nm]))
			print("  %-14s %dx%d" % [nm, cell.get_width(), cell.get_height()])
			saved += 1
	print("저장 %d칸" % saved)
	quit(0)
## y0..y1 구간에서 '내용이 하나도 없는' 열이면 true
func _empty_columns(img: Image, y0: int, y1: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(img.get_width())
	for x in range(img.get_width()):
		var empty := 1
		for y in range(y0, mini(y1, img.get_height())):
			if img.get_pixel(x, y).a > ALPHA_MIN:
				empty = 0
				break
		out[x] = empty
	return out


## x0..x1 구간에서 '내용이 하나도 없는' 행이면 true
func _empty_rows(img: Image, x0: int, x1: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(img.get_height())
	for y in range(img.get_height()):
		var empty := 1
		for x in range(x0, mini(x1, img.get_width())):
			if img.get_pixel(x, y).a > ALPHA_MIN:
				empty = 0
				break
		out[y] = empty
	return out


## 빈칸 플래그 배열 → 내용이 있는 구간(밴드) 목록. from 이후만 본다.
func _bands(empty: PackedByteArray, n: int, from: int = 0) -> Array:
	var out: Array = []
	var start := -1
	for i in range(from, n):
		if empty[i] == 0:
			if start < 0:
				start = i
		elif start >= 0:
			if i - start >= MIN_BAND:
				out.append(Vector2i(start, i - 1))
			start = -1
	if start >= 0 and n - start >= MIN_BAND:
		out.append(Vector2i(start, n - 1))
	return out


## 좌우 분리 지점 자동 탐색.
## 이 시트는 칸끼리 딱 붙어 있고 인물이 칸 경계까지 차 있어, '완전히 빈 열'은 없다 —
## 대신 **그리드 영역으로 범위를 좁히면 행 사이에는 진짜 빈 줄이 생긴다**(실측 확인).
## 그래서 후보 x 를 왼쪽부터 훑으며 "이 x 오른쪽만 봤을 때 행 밴드가 정확히 3개"인
## 첫 지점을 분리선으로 채택한다(자기검증형 — 좌표 하드코딩 없이 해상도 변화에 견딤).
## 행이 비었는지는 행별 '마지막 불투명 x'만 미리 구해두면 O(1) 로 판정된다.
func _find_split(img: Image) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var max_x := PackedInt32Array()
	max_x.resize(h)
	for y in range(h):
		var m := -1
		for x in range(w - 1, -1, -1):
			if img.get_pixel(x, y).a > ALPHA_MIN:
				m = x
				break
		max_x[y] = m
	for split in range(int(w * 0.30), int(w * 0.70), 4):
		var empty := PackedByteArray()
		empty.resize(h)
		for y in range(h):
			empty[y] = 1 if max_x[y] < split else 0
		if _bands(empty, h).size() == 3:
			return split
	return -1


## 옆 칸에서 넘어온 이펙트 잔여물 제거 — 알파>0 픽셀의 연결요소 중 **가장 큰 것(몸통)만**
## 남기고 나머지 섬은 지운다. 3행(주문 시전)의 보랏빛 이펙트가 칸 경계를 넘어 옆 칸
## (뒷모습·옆모습)에 손·빛 조각으로 남는 것을 이렇게 잡는다(실측 확인).
## `casting` 칸만은 그 이펙트가 '자기 것'이라 건너뛴다.
func _keep_largest_component(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(0)
	var best_id := 0
	var best_size := 0
	var next_id := 0
	for sy in range(h):
		for sx in range(w):
			var si := sy * w + sx
			if label[si] != 0 or img.get_pixel(sx, sy).a <= ALPHA_MIN:
				continue
			next_id += 1
			var size := 0
			var stack: Array[Vector2i] = [Vector2i(sx, sy)]
			label[si] = next_id
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				size += 1
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = p + d
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
						continue
					var qi := q.y * w + q.x
					if label[qi] != 0 or img.get_pixel(q.x, q.y).a <= ALPHA_MIN:
						continue
					label[qi] = next_id
					stack.append(q)
			if size > best_size:
				best_size = size
				best_id = next_id
	for y in range(h):
		for x in range(w):
			if label[y * w + x] != best_id:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
