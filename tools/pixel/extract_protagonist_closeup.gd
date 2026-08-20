extends SceneTree
##
## 유저가 외부(비-PixelLab) 생성한 주인공 풀 일러스트(closeup) 배경 제거.
## extract_protagonist_portraits.gd 와 같은 테두리 플러드필+경계 침식 매팅 방식(원리는
## 그 스크립트 상단 주석 참고) — 이 이미지는 그리드가 아니라 단일 프레임이라 별도 스크립트.
##
## 실행: godot --headless --path . --script res://tools/pixel/extract_protagonist_closeup.gd
## 입력: .art_ref_incoming/protagonist_portrait_closeup.jpg (커밋 안 함, .gitignore)
## 출력: assets/ui/portraits/protagonist/signature_full.png
##

const SRC := "res://.art_ref_incoming/protagonist_portrait_closeup.jpg"
const OUT := "res://assets/ui/portraits/protagonist/signature_full.png"
const BG_THRESH := 2.0
const EDGE_ERODE_THRESH := 16.0
const EDGE_ERODE_ITERS := 3

func _luminance(c: Color) -> float:
    return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * 255.0

func _matte_background(img: Image) -> void:
    var w := img.get_width(); var h := img.get_height()
    var visited := PackedByteArray(); visited.resize(w * h)
    var stack: Array[Vector2i] = []
    for x in range(w):
        stack.append(Vector2i(x, 0)); stack.append(Vector2i(x, h - 1))
    for y in range(h):
        stack.append(Vector2i(0, y)); stack.append(Vector2i(w - 1, y))
    while not stack.is_empty():
        var p: Vector2i = stack.pop_back()
        if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h: continue
        var idx := p.y * w + p.x
        if visited[idx] != 0: continue
        visited[idx] = 1
        var c := img.get_pixel(p.x, p.y)
        if _luminance(c) > BG_THRESH: continue
        img.set_pixel(p.x, p.y, Color(c.r, c.g, c.b, 0.0))
        stack.append(Vector2i(p.x+1,p.y)); stack.append(Vector2i(p.x-1,p.y))
        stack.append(Vector2i(p.x,p.y+1)); stack.append(Vector2i(p.x,p.y-1))

func _erode_dark_fringe(img: Image) -> void:
    var w := img.get_width(); var h := img.get_height()
    var to_clear: Array[Vector2i] = []
    for y in range(h):
        for x in range(w):
            var c := img.get_pixel(x, y)
            if c.a <= 0.0: continue
            if _luminance(c) >= EDGE_ERODE_THRESH: continue
            var has_t := false
            for dy in range(-1,2):
                for dx in range(-1,2):
                    if dx==0 and dy==0: continue
                    var nx=x+dx; var ny=y+dy
                    if nx<0 or ny<0 or nx>=w or ny>=h: continue
                    if img.get_pixel(nx,ny).a <= 0.0: has_t = true; break
                if has_t: break
            if has_t: to_clear.append(Vector2i(x,y))
    for p in to_clear:
        var c := img.get_pixel(p.x, p.y)
        img.set_pixel(p.x, p.y, Color(c.r, c.g, c.b, 0.0))

## extract_protagonist_portraits.gd 의 _keep_largest_component 와 동일 — 배경과 연결되지 않은
## 고립된 색 섬(초록 wisp 잔여물 등)을 몸통 하나만 남기고 제거. 침식으로 못 잡는 노이즈용.
func _keep_largest_component(img: Image) -> void:
    var w := img.get_width(); var h := img.get_height()
    var comp := PackedInt32Array(); comp.resize(w * h); comp.fill(-1)
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
                var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
                for d in dirs:
                    var np: Vector2i = p + d
                    if np.x < 0 or np.y < 0 or np.x >= w or np.y >= h: continue
                    var nidx := np.y * w + np.x
                    if comp[nidx] != -1 or img.get_pixel(np.x, np.y).a <= 0.0: continue
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


## extract_protagonist_portraits.gd 의 _strip_bleed_green 과 동일 기준(실측 근거는 그 파일 주석
## 참고) — 로브의 저채도 청록 자수(g<0.20)는 남기고, 채도 높은 초록 얼룩만 직접 걷어낸다.
func _strip_bleed_green(img: Image) -> void:
    var w := img.get_width(); var h := img.get_height()
    for y in range(h):
        for x in range(w):
            var c := img.get_pixel(x, y)
            if c.a <= 0.0: continue
            if c.g < 0.20: continue
            if c.g - minf(c.r, c.b) <= 0.10: continue
            if c.b >= c.g * 0.85: continue
            img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))


func _init() -> void:
    var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
    if img == null:
        push_error("원본 없음(커밋 안 되는 파일 — .art_ref_incoming/ 에 재배치 후 실행): " + SRC)
        quit(1)
        return
    img.convert(Image.FORMAT_RGBA8)
    _matte_background(img)
    for i in range(EDGE_ERODE_ITERS):
        _erode_dark_fringe(img)
    _strip_bleed_green(img)
    _keep_largest_component(img)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
    img.save_png(ProjectSettings.globalize_path(OUT))
    print("saved ", OUT, " ", img.get_width(), "x", img.get_height())
    quit(0)
