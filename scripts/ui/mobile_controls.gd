extends CanvasLayer
class_name MobileControls
##
## 모바일 터치 컨트롤 — 버튼을 코드로 배치한다.
##
## 설계 원칙:
##  · **엄지 도달 영역**: 왼손=이동(화면 좌하단), 오른손=행동(우하단 클러스터).
##  · **안전영역**: 노치·제스처바를 피해 `DisplayServer.get_display_safe_area()` 만큼 안쪽으로.
##  · **한지·먹 원형 버튼**: 텍스처를 코드로 그려 새 아트 없이 조선풍 톤 유지(눌림 상태 = 단청 적).
##  · **스킬은 아이콘 + 쿨다운 숫자**: HUD 를 보지 않고 손가락 밑에서 바로 상태를 안다.
##  · **멀티터치**: Control 버튼이 아니라 TouchScreenButton — 이동하며 공격이 동시에 먹힌다.
##
## 데스크톱(마우스)에서는 숨고, 터치가 실제로 들어오면 그때 나타난다.
##

const BASE_W := 1280.0
const BASE_H := 720.0
const SKILL_ICON := "res://assets/ui/skill_%s.png"
## 판정원을 그림보다 이만큼 크게 — 손가락이 조금 빗나가도 눌리게.
const HIT_MARGIN := 1.28

# 한지·먹 팔레트 (STYLE_BIBLE 톤)
const C_FILL := Color(0.90, 0.86, 0.76, 0.26)      # 한지빛 (반투명 — 화면을 덜 가림)
const C_EDGE := Color(0.10, 0.09, 0.08, 0.72)      # 먹 테두리
const C_RING := Color(0.72, 0.58, 0.28, 0.55)      # 단청 황(금) 안쪽 실선
const C_FILL_ON := Color(0.66, 0.27, 0.25, 0.52)   # 눌림 — 단청 적
const C_RING_ON := Color(0.95, 0.82, 0.45, 0.95)
const C_TEXT := Color(0.96, 0.94, 0.88, 0.96)

var _is_touch: bool = false
# 스킬 버튼 상태 갱신용 — [{id, icon: TextureRect, cd: Label, dim: Control}]
var _skill_btns: Array = []
var _buttons: Array[TouchScreenButton] = []


## 이 기기에서 터치 컨트롤을 써야 하는가. (HUD 등 다른 UI 도 같은 판정을 쓴다.)
##
## 웹에서는 `DisplayServer.is_touchscreen_available()` 만 믿지 않는다 — 브라우저·기기에
## 따라 false 가 나오는 일이 있어 폰에서 버튼이 통째로 안 보일 수 있다. 그래서
## `navigator.maxTouchPoints` 를 직접 확인하고, 주소에 `?touch=1` 을 붙이면 어느 기기에서든
## 강제로 켠다(PC 브라우저 테스트용. `?touch=0` 이면 강제로 끔).
static func wants_touch_ui() -> bool:
    var forced := _url_touch_override()
    if forced != 0:
        return forced > 0
    if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile"):
        return true
    return _web_touch_points() > 0


## -1=강제 끔, 0=지정 없음, 1=강제 켬
static func _url_touch_override() -> int:
    if not OS.has_feature("web"):
        return 0
    var v = JavaScriptBridge.eval("new URLSearchParams(location.search).get('touch')", true)
    if v == null:
        return 0
    var s := String(v)
    if s == "0" or s.to_lower() == "false":
        return -1
    return 1


static func _web_touch_points() -> int:
    if not OS.has_feature("web"):
        return 0
    var v = JavaScriptBridge.eval("navigator.maxTouchPoints || 0", true)
    return int(v) if v != null else 0


func _ready() -> void:
    _is_touch = wants_touch_ui()
    _build()
    visible = _is_touch
    # 대화 중엔 터치 버튼을 숨겨 말풍선과 겹치지 않고 몰입을 지킨다.
    Dialogue.dialogue_started.connect(func(_s, _t, _c) -> void: visible = false)
    Dialogue.dialogue_ended.connect(func() -> void: visible = _is_touch)
    SkillManager.cooldowns_changed.connect(_update_skills)
    _update_skills()
    # 화면 회전·창 크기 변경 시 재배치
    get_viewport().size_changed.connect(_layout)


# 마우스만 쓰는 데스크톱 브라우저에서는 숨겨 두고, 실제 손가락이 닿으면 그때 켠다.
func _input(event: InputEvent) -> void:
    if _is_touch:
        return
    if event is InputEventScreenTouch or event is InputEventScreenDrag:
        _is_touch = true
        visible = not Dialogue.is_active()


# ────────────────────────── 배치 ──────────────────────────

func _build() -> void:
    # 왼손 — 이동
    _add_button("move_left", "◀", 58.0)
    _add_button("move_right", "▶", 58.0)
    _add_button("interact", "조사", 42.0)
    # 오른손 — 행동
    _add_button("attack", "공격", 66.0)
    _add_button("jump", "점프", 54.0)
    _add_button("dodge", "회피", 50.0)
    # 스킬 1~4 — 아이콘 + 쿨다운. slot 순으로 정렬해 1번이 엄지에 가장 가깝게 온다.
    var defs: Array = []
    for id in SkillManager.all_ids():
        defs.append({"id": String(id), "slot": int(SkillManager.get_def(id).get("slot", 1))})
    defs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["slot"]) < int(b["slot"]))
    for d in defs:
        var btn := _add_button("skill_%d" % int(d["slot"]), "", 40.0)
        _attach_skill_face(btn, String(d["id"]), 40.0)
    _layout()


## 안전영역(노치·제스처바) 안쪽 여백 — 뷰포트 좌표계로 환산. (l, t, r, b)
func _safe_insets() -> Vector4:
    var vp := get_viewport().get_visible_rect().size
    var win := Vector2(DisplayServer.window_get_size())
    if win.x <= 0.0 or win.y <= 0.0:
        return Vector4.ZERO
    var safe := DisplayServer.get_display_safe_area()
    if safe.size.x <= 0 or safe.size.y <= 0:
        return Vector4.ZERO
    # 안전영역이 창보다 크면(데스크톱) 무시
    var l := maxf(0.0, float(safe.position.x))
    var t := maxf(0.0, float(safe.position.y))
    var r := maxf(0.0, win.x - float(safe.position.x + safe.size.x))
    var b := maxf(0.0, win.y - float(safe.position.y + safe.size.y))
    var kx := vp.x / win.x
    var ky := vp.y / win.y
    return Vector4(l * kx, t * ky, r * kx, b * ky)


## 버튼 중심 좌표를 화면 크기·안전영역에 맞춰 다시 계산.
func _layout() -> void:
    var vp := get_viewport().get_visible_rect().size
    var ins := _safe_insets()
    var w := vp.x - ins.z
    var h := vp.y - ins.w
    var l := ins.x

    # 버튼이 커진 만큼(판정원 기준) 간격도 넓혀 서로 판정이 겹치지 않게 둔다.
    _place("move_left", Vector2(l + 122.0, h - 120.0))
    _place("move_right", Vector2(l + 275.0, h - 120.0))
    _place("interact", Vector2(l + 100.0, h - 268.0))

    _place("attack", Vector2(w - 142.0, h - 128.0))
    _place("jump", Vector2(w - 300.0, h - 104.0))
    _place("dodge", Vector2(w - 320.0, h - 250.0))   # 스킬 줄 아래·점프 위

    # 스킬 4개 — 행동 클러스터 위 가로 한 줄(오른쪽부터 1→4)
    var sx := w - 104.0
    var sy := h - 380.0
    for i in range(_skill_btns.size()):
        _place(String(_skill_btns[i]["action"]), Vector2(sx - 108.0 * i, sy))


func _place(action: String, center: Vector2) -> void:
    for b in _buttons:
        if b.action == action:
            var r: float = b.get_meta("radius", 40.0)
            b.position = center - Vector2(r, r)
            return


# ────────────────────────── 버튼 만들기 ──────────────────────────

## 그려지는 원(radius)보다 판정원을 HIT_MARGIN 배 크게 잡는다 — 손가락이 조금 빗나가도
## 눌리도록. 텍스처를 판정원 크기 캔버스에 '가운데 정렬'로 그려서 그림과 판정이 동심원이 된다.
func _add_button(action: String, label: String, radius: float) -> TouchScreenButton:
    var hit := radius * HIT_MARGIN
    var b := TouchScreenButton.new()
    b.action = action
    b.texture_normal = _circle_tex(radius, hit, C_FILL, C_EDGE, C_RING)
    b.texture_pressed = _circle_tex(radius, hit, C_FILL_ON, C_EDGE, C_RING_ON)
    var shape := CircleShape2D.new()
    shape.radius = hit
    b.shape = shape
    # ⚠ shape_centered=true 여야 판정원이 **텍스처 가운데**에 놓인다.
    # false 면 판정원 중심이 텍스처 좌상단 꼭짓점으로 가서, 보이는 버튼과 반지름만큼
    # 어긋난 허공을 눌러야 반응한다(폰에서 '버튼이 안 눌리는' 원인이었음).
    b.shape_centered = true
    b.passby_press = true             # 손가락을 끌어 다른 버튼으로 넘어가도 눌린다(좌↔우 이동)
    b.set_meta("radius", hit)         # 배치·테스트는 판정 반지름 기준
    b.set_meta("draw_radius", radius)
    add_child(b)
    _buttons.append(b)
    if label != "":
        var lbl := Label.new()
        lbl.text = label
        lbl.size = Vector2(hit * 2.0, hit * 2.0)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
        lbl.add_theme_font_size_override("font_size", int(radius * 0.52))
        lbl.add_theme_color_override("font_color", C_TEXT)
        lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
        lbl.add_theme_constant_override("outline_size", 4)
        b.add_child(lbl)
    return b


## 스킬 버튼 얼굴 — 아이콘 + 쿨다운 숫자(잠김이면 '잠김').
func _attach_skill_face(b: TouchScreenButton, id: String, radius: float) -> void:
    # 아이콘은 '그려지는 원' 안쪽에, 노드 좌표는 판정원(더 큰 캔버스) 기준이라 여백을 더한다.
    var hit: float = float(b.get_meta("radius", radius))
    var inset := hit - radius
    var pad := inset + radius * 0.3
    var icon := TextureRect.new()
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    icon.position = Vector2(pad, pad)
    icon.size = Vector2(hit * 2.0 - pad * 2.0, hit * 2.0 - pad * 2.0)
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var path := SKILL_ICON % id
    if ResourceLoader.exists(path):
        icon.texture = load(path)
    b.add_child(icon)

    var cd := Label.new()
    cd.size = Vector2(hit * 2.0, hit * 2.0)
    cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cd.add_theme_font_size_override("font_size", int(radius * 0.7))
    cd.add_theme_color_override("font_color", C_TEXT)
    cd.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    cd.add_theme_constant_override("outline_size", 5)
    cd.visible = false
    b.add_child(cd)

    _skill_btns.append({"id": id, "action": b.action, "icon": icon, "cd": cd})


## 스킬 상태 — 잠김: 어둡게 '잠김', 쿨다운: 어둡게 + 남은 초, 준비: 밝게.
func _update_skills() -> void:
    for s in _skill_btns:
        var id: String = s["id"]
        var icon: TextureRect = s["icon"]
        var cd_lbl: Label = s["cd"]
        if not is_instance_valid(icon) or not is_instance_valid(cd_lbl):
            continue
        if not SkillManager.is_unlocked(id):
            icon.modulate = Color(1, 1, 1, 0.25)
            cd_lbl.visible = true
            cd_lbl.text = "잠김"
            cd_lbl.add_theme_font_size_override("font_size", 15)
        else:
            var left := SkillManager.cooldown_left(id)
            if left > 0.0:
                icon.modulate = Color(1, 1, 1, 0.35)
                cd_lbl.visible = true
                cd_lbl.text = "%d" % int(ceilf(left))
                cd_lbl.add_theme_font_size_override("font_size", 24)
            else:
                icon.modulate = Color.WHITE
                cd_lbl.visible = false


# ────────────────────────── 버튼 텍스처(코드 생성) ──────────────────────────

## 한지 원 + 먹 테두리 + 안쪽 금빛 실선. 새 아트 없이 톤을 맞추기 위해 직접 그린다.
## 가장자리는 1px 부드럽게(계단 방지) — UI 라 픽셀 그리드 규칙의 예외.
func _circle_tex(radius: float, canvas_r: float, fill: Color, edge: Color, ring: Color) -> ImageTexture:
    var size := int(canvas_r * 2.0)
    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var c := Vector2(canvas_r, canvas_r)
    var edge_w := maxf(2.0, radius * 0.075)
    var ring_r := radius - edge_w - maxf(2.0, radius * 0.09)
    for y in size:
        for x in size:
            var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
            var px := Color(0, 0, 0, 0)
            if d <= radius - edge_w:
                px = fill
                # 안쪽 금빛 실선(1.5px)
                if absf(d - ring_r) <= 0.9:
                    px = ring
            elif d <= radius:
                px = edge
                # 바깥 1px 부드럽게
                if d > radius - 1.0:
                    px.a *= clampf(radius - d, 0.0, 1.0)
            if px.a > 0.0:
                img.set_pixel(x, y, px)
    return ImageTexture.create_from_image(img)
