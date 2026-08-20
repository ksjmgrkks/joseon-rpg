extends SceneTree
##
## 유저가 외부(비-PixelLab) 생성한 주인공 초상화 시트에서 표정 9종을 잘라
## 검정 배경을 투명화(테두리 플러드필)하고, 컷 경계의 JPEG 잔여 노이즈를 정리해
## assets/ui/portraits/protagonist/*.png 로 저장한다.
##
## 실행: godot --headless --path . --script res://tools/pixel/extract_protagonist_portraits.gd
##
## 배경 제거 방식: 셀 자기 테두리(둘레 전체)에서 시작하는 4방향 플러드필로 '어두운 배경'만
## 투명화 — 캐릭터 옷(검정 도포)이 테두리에 닿지 않는 한 옷 내부는 그대로 불투명 유지된다.
## 이어서 경계 픽셀 중 어둡고(밝기<EDGE_ERODE_THRESH) 투명 이웃이 있는 픽셀을 1px 침식해
## 사용자가 지적한 "초록색 노이즈"(JPEG 압축 경계 잔상) 프린지를 제거한다.
##

const SRC := "res://.art_ref_incoming/protagonist_portrait_sheet.jpg"
const OUT_DIR := "res://assets/ui/portraits/protagonist"
## 실측(probe_luminance.gd): 진짜 배경은 (0,0,0)=lum 0.0, 캐릭터 최암부(모자/로브 그림자)도
## lum 10~34 라 배경보다 훨씬 밝다 — 예전 임계값(24)은 캐릭터 어두운 영역까지 배경으로 오인해
## 큰 구멍을 냈다(교훈: 반드시 실측 후 임계값 결정). 배경은 아주 낮게, 침식은 여러 번 얕게.
const BG_THRESH := 2.0           # 이보다 어두우면 '배경'으로 간주(플러드필 통과) — 진짜 배경은 0
const EDGE_ERODE_THRESH := 16.0  # 경계 침식 대상 밝기 상한(캐릭터 최암부 10~34보다 낮게 잡아 보존)
const EDGE_ERODE_ITERS := 3      # 침식 반복 횟수 — JPEG 링잉 폭만큼만 얕게 깎음(2차 피드백으로 1회 추가)

## 2차 피드백("초록색 노이즈 남아있음") 원인: 옆 칸(casting/profile_staff)의 초록 이펙트 wisp가
## 밝기(lum>2)를 가져 테두리 플러드필을 통과하지 못하고, 배경에서 캐릭터 몸통과 연결되지 않은
## '섬'으로 뚝 떨어져 남았다 — 침식/색상 판정으로는 못 잡는다(어둡지 않고 색도 없음).
## 해결: 매팅 후 알파>0 픽셀의 연결요소를 구해 가장 큰 것(몸통)만 남기고 나머지 섬은 전부 지운다.
## 단, casting/profile_staff 두 칸은 초록 이펙트 자체가 '자기 것'(의도된 디자인)이라 건너뛴다.
const SKIP_COMPONENT_CLEAN := ["casting", "profile_staff"]

const GRID_X0 := 610
const GRID_X1 := 1275
const GRID_Y0 := 25
const GRID_Y1 := 795

# (row, col) -> 파일명 (실제 그리드 내용 육안 확인 후 명명)
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

## 원본 시트는 칸끼리 여백 없이 붙어 있어, 옆 칸의 이펙트(초록 도깨비불류 wisp)가
## 매팅 후에도 가장자리에 살짝 남는 칸이 있다(육안 확인, probe 결과). 캐릭터 본체가 각 칸
## 중앙에 여유 있게 들어있는 칸은 안쪽으로 살짝 더 잘라 이웃 이펙트 잔여물을 제거한다.
## 이펙트가 '자기 것'인 칸(casting/profile_staff)은 트림하지 않는다.
## key -> [left, top, right, bottom] px
const CELL_TRIM := {
    "0_0": [16, 4, 4, 4],
    "0_1": [16, 4, 4, 4],
    "0_2": [12, 4, 4, 4],
    "1_0": [4, 4, 65, 4],
    "1_1": [16, 4, 4, 4],
    "1_2": [10, 4, 4, 4],
    "2_0": [8, 4, 50, 4],
    "2_1": [0, 0, 0, 0],
    "2_2": [0, 0, 0, 0],
}


func _luminance(c: Color) -> float:
    return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * 255.0


## 테두리 플러드필로 배경을 투명화. img 는 RGBA8 이어야 함(호출 전 convert).
func _matte_background(img: Image) -> void:
    var w := img.get_width()
    var h := img.get_height()
    var visited := PackedByteArray()
    visited.resize(w * h)
    var stack: Array[Vector2i] = []

    for x in range(w):
        stack.append(Vector2i(x, 0))
        stack.append(Vector2i(x, h - 1))
    for y in range(h):
        stack.append(Vector2i(0, y))
        stack.append(Vector2i(w - 1, y))

    while not stack.is_empty():
        var p: Vector2i = stack.pop_back()
        if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
            continue
        var idx := p.y * w + p.x
        if visited[idx] != 0:
            continue
        visited[idx] = 1
        var c := img.get_pixel(p.x, p.y)
        if _luminance(c) > BG_THRESH:
            continue
        img.set_pixel(p.x, p.y, Color(c.r, c.g, c.b, 0.0))
        stack.append(Vector2i(p.x + 1, p.y))
        stack.append(Vector2i(p.x - 1, p.y))
        stack.append(Vector2i(p.x, p.y + 1))
        stack.append(Vector2i(p.x, p.y - 1))


## 알파 경계에서 1px 침식 — 어둡고(EDGE_ERODE_THRESH 미만) 투명 이웃이 있는 픽셀만 제거.
## (트림 등 밝은 색은 보존, 배경-캐릭터 경계의 어두운 JPEG 잔상만 정리)
func _erode_dark_fringe(img: Image) -> void:
    var w := img.get_width()
    var h := img.get_height()
    var to_clear: Array[Vector2i] = []
    for y in range(h):
        for x in range(w):
            var c := img.get_pixel(x, y)
            if c.a <= 0.0:
                continue
            if _luminance(c) >= EDGE_ERODE_THRESH:
                continue
            var has_transparent_neighbor := false
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if dx == 0 and dy == 0:
                        continue
                    var nx := x + dx
                    var ny := y + dy
                    if nx < 0 or ny < 0 or nx >= w or ny >= h:
                        continue
                    if img.get_pixel(nx, ny).a <= 0.0:
                        has_transparent_neighbor = true
                        break
                if has_transparent_neighbor:
                    break
            if has_transparent_neighbor:
                to_clear.append(Vector2i(x, y))
    for p in to_clear:
        var c := img.get_pixel(p.x, p.y)
        img.set_pixel(p.x, p.y, Color(c.r, c.g, c.b, 0.0))


## 알파>0 픽셀들의 4방향 연결요소 중 가장 큰 것(=캐릭터 몸통)만 남기고 나머지(색이 있든 없든
## 배경에 고립된 섬 전부)를 투명화한다. 초록 wisp 잔여물처럼 밝아서(lum>2) 플러드필도 못 뚫고
## 어둡지도 않아서(lum>=16) 침식도 못 잡는 '색 있는 섬' 노이즈에 유일하게 먹히는 방법.
func _keep_largest_component(img: Image) -> void:
    var w := img.get_width()
    var h := img.get_height()
    var comp := PackedInt32Array()
    comp.resize(w * h)
    comp.fill(-1)
    var sizes: Array[int] = []
    for sy in range(h):
        for sx in range(w):
            var start_idx := sy * w + sx
            if comp[start_idx] != -1 or img.get_pixel(sx, sy).a <= 0.0:
                continue
            var cid := sizes.size()
            var count := 0
            var stack: Array[Vector2i] = [Vector2i(sx, sy)]
            comp[start_idx] = cid
            while not stack.is_empty():
                var p: Vector2i = stack.pop_back()
                count += 1
                var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
                for d in dirs:
                    var np: Vector2i = p + d
                    if np.x < 0 or np.y < 0 or np.x >= w or np.y >= h:
                        continue
                    var nidx := np.y * w + np.x
                    if comp[nidx] != -1 or img.get_pixel(np.x, np.y).a <= 0.0:
                        continue
                    comp[nidx] = cid
                    stack.append(np)
            sizes.append(count)
    if sizes.is_empty():
        return
    var largest_cid := 0
    for i in range(1, sizes.size()):
        if sizes[i] > sizes[largest_cid]:
            largest_cid = i
    for y in range(h):
        for x in range(w):
            var idx := y * w + x
            if comp[idx] != -1 and comp[idx] != largest_cid:
                var c := img.get_pixel(x, y)
                img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))


## 3차 조치: 남은 초록 얼룩은 몸통과 픽셀이 이어져 있어(연결요소 정리로도 안 잡힘) — 실측
## (probe_green.gd/probe_trim.gd) 결과, 시트 왼쪽 전신 일러스트의 지팡이 결정 초록빛이 그리드
## 0열 칸 왼쪽 경계로 번져 들어온 것으로, 로브의 진짜 청록 자수(저채도, g<0.20)보다 훨씬
## 채도 높고 밝다(g>=0.20, g가 r·b보다 뚜렷이 높음). 이 색 시그니처로만 직접 걷어낸다.
## (casting/profile_staff 두 칸은 초록 이펙트 자체가 디자인이라 건너뜀 — 같은 skip 목록 재사용)
func _strip_bleed_green(img: Image) -> void:
    var w := img.get_width()
    var h := img.get_height()
    for y in range(h):
        for x in range(w):
            var c := img.get_pixel(x, y)
            if c.a <= 0.0:
                continue
            if c.g < 0.20:
                continue
            if c.g - minf(c.r, c.b) <= 0.10:
                continue
            if c.b >= c.g * 0.85:
                continue
            img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))


func _process_and_save(img: Image, out_path: String, skip_component_clean: bool) -> void:
    img.convert(Image.FORMAT_RGBA8)
    _matte_background(img)
    for i in range(EDGE_ERODE_ITERS):
        _erode_dark_fringe(img)
    if not skip_component_clean:
        _strip_bleed_green(img)
        _keep_largest_component(img)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
    img.save_png(ProjectSettings.globalize_path(out_path))
    print("saved: ", out_path, "  ", img.get_width(), "x", img.get_height())


func _init() -> void:
    var sheet := Image.load_from_file(ProjectSettings.globalize_path(SRC))
    if sheet == null:
        push_error("시트 로드 실패: " + SRC)
        quit(1)
        return

    var cell_w := float(GRID_X1 - GRID_X0) / 3.0
    var cell_h := float(GRID_Y1 - GRID_Y0) / 3.0

    for row in range(3):
        for col in range(3):
            var key := "%d_%d" % [row, col]
            var name: String = CELL_NAMES.get(key, key)
            var trim: Array = CELL_TRIM.get(key, [0, 0, 0, 0])
            var x0 := int(GRID_X0 + col * cell_w) + int(trim[0])
            var y0 := int(GRID_Y0 + row * cell_h) + int(trim[1])
            var cw := int(cell_w) - int(trim[0]) - int(trim[2])
            var ch := int(cell_h) - int(trim[1]) - int(trim[3])
            var crop := sheet.get_region(Rect2i(x0, y0, cw, ch))
            _process_and_save(crop, "%s/%s.png" % [OUT_DIR, name], SKIP_COMPONENT_CLEAN.has(name))

    quit(0)
