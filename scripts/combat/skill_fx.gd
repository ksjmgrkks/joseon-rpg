extends Node
##
## SkillFx autoload — 스킬·타격 시각 이펙트를 코드로 생성(별도 아트 불필요).
## 모든 이펙트는 current_scene 에 부착돼 트윈으로 페이드/소멸하며 스스로 queue_free.
## 색은 STYLE_BIBLE 팔레트 톤(먹/금/한지/단청)을 따른다.
##
## API:
##   SkillFx.combo(pos, facing_right, step)       — 콤보 1·2·3타 (찌름/횡소/회전)
##   SkillFx.ultimate(pos)                        — 궁극기 귀창 강림
##   SkillFx.slash(pos, facing_right[, color])    — 일섬: 전방 초승달 참격
##   SkillFx.spin(pos[, color])                   — 회천격: 회전 원형 베기
##   SkillFx.impact(pos, big=false)               — 적중 임팩트(불꽃 스파크+링)
##   SkillFx.attach_ward(player) -> Node2D        — 호신부: 부적 오라
##   SkillFx.afterimage(sprite[, tint, life])     — 잔상 1장(현재 프레임 복제)
##   SkillFx.afterimage_burst(sprite, tint, n, t) — 잔상 연속(모션 트레일)
##

const GOLD := Color(0.79, 0.66, 0.34)
const BRIGHT := Color(0.96, 0.92, 0.85)
const RED := Color(0.66, 0.27, 0.25)
const BLUE := Color(0.25, 0.42, 0.49)
const INK := Color(0.10, 0.086, 0.07)
const MAGE := Color(0.55, 0.42, 0.78)   # 마(魔)의 보랏빛 — 마창 기운
const MAGE_HOT := Color(0.72, 0.55, 0.98)

# ── PixelLab 페인티드 VFX 텍스처 (지연 로드·캐시) ──
# 파일이 없으면 null 을 캐시 → 페인티드 레이어만 건너뛰고 기존 코드 이펙트는 그대로.
var _tex_cache: Dictionary = {}

func _fx_tex(tex_name: String) -> Texture2D:
    if _tex_cache.has(tex_name):
        return _tex_cache[tex_name]
    var path := "res://assets/sprites/fx/%s.png" % tex_name
    var t: Texture2D = null
    if ResourceLoader.exists(path):
        t = load(path)
    _tex_cache[tex_name] = t
    return t


## 페인티드 VFX 스프라이트 1장 — PixelLab 아트를 스케일 업/회전/페이드로 짧게 연출.
## scale_from→scale_to 로 커지며 사라진다. spin!=0 이면 회전, drift 로 진행 방향 이동.
func _painted(tex_name: String, pos: Vector2, scale_from: float, scale_to: float, life: float,
        flip: bool = false, rot: float = 0.0, spin: float = 0.0, tint: Color = Color.WHITE,
        z: int = 32, drift: Vector2 = Vector2.ZERO) -> Sprite2D:
    var host := _host()
    var tex := _fx_tex(tex_name)
    if host == null or tex == null:
        return null
    var s := Sprite2D.new()
    s.texture = tex
    s.global_position = pos
    s.flip_h = flip
    s.rotation = rot
    s.scale = Vector2(scale_from, scale_from)
    s.modulate = tint
    s.z_index = z
    s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    host.add_child(s)
    var tw := s.create_tween()
    tw.tween_property(s, "scale", Vector2(scale_to, scale_to), life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    if spin != 0.0:
        tw.parallel().tween_property(s, "rotation", rot + spin, life)
    if drift != Vector2.ZERO:
        tw.parallel().tween_property(s, "global_position", pos + drift, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tw.parallel().tween_property(s, "modulate:a", 0.0, life)
    tw.tween_callback(s.queue_free)
    return s


## 몬스터 출혈 — 피격 지점에서 핏방울이 진행 방향으로 튀고, 작은 얼룩이 남는다.
## 게임 톤(은은한 괴담)에 맞춰 절제: 작게·짧게.
func bleed(pos: Vector2, facing_right: bool, big: bool = false) -> void:
    var dir := 1.0 if facing_right else -1.0
    var spray := 0.62 if big else 0.46
    # 튀는 핏방울(진행 방향으로 약간 드리프트)
    _painted("blood_spray", pos, spray * 0.7, spray, 0.32, not facing_right, 0.0, 0.0,
        Color(1, 1, 1, 0.9), 33, Vector2(dir * 14.0, -4.0))
    # 작게 남는 얼룩(아래로 살짝 가라앉으며 사라짐)
    _painted("blood_splat", pos + Vector2(dir * 6.0, 4.0), (0.5 if big else 0.36), (0.62 if big else 0.46), 0.5,
        false, 0.0, 0.0, Color(1, 1, 1, 0.85), 18, Vector2(0, 6.0))


func _host() -> Node:
    var tree := get_tree()
    if tree == null:
        return null
    return tree.current_scene


# ── 공통 헬퍼: Line2D 한 줄 ───────────────────────────────────
func _line(pts: PackedVector2Array, width: float, color: Color, z: int = 30) -> Line2D:
    var ln := Line2D.new()
    ln.width = width
    ln.default_color = color
    ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
    ln.end_cap_mode = Line2D.LINE_CAP_ROUND
    ln.joint_mode = Line2D.LINE_JOINT_ROUND
    ln.points = pts
    ln.z_index = z
    return ln


# 가운데가 두꺼운 폭 곡선
func _belly_curve() -> Curve:
    var wc := Curve.new()
    wc.add_point(Vector2(0.0, 0.15))
    wc.add_point(Vector2(0.5, 1.0))
    wc.add_point(Vector2(1.0, 0.15))
    return wc


# ════════════ 캐릭터 잔상(애프터이미지) — PixelLab 아트를 모션에 활용 ════════════
## 현재 AnimatedSprite2D 프레임을 그대로 복제한 색조 잔상 1장. life 초에 걸쳐 사라짐.
func afterimage(sprite: AnimatedSprite2D, tint: Color = MAGE, life: float = 0.22) -> void:
    var host := _host()
    if host == null or sprite == null or sprite.sprite_frames == null:
        return
    if not sprite.sprite_frames.has_animation(sprite.animation):
        return
    var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
    if tex == null:
        return
    var ghost := Sprite2D.new()
    ghost.texture = tex
    ghost.centered = sprite.centered
    ghost.offset = sprite.offset
    ghost.flip_h = sprite.flip_h
    ghost.global_position = sprite.global_position
    ghost.global_scale = sprite.global_scale
    ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    ghost.modulate = Color(tint.r, tint.g, tint.b, 0.5)
    ghost.z_index = sprite.z_index - 1
    host.add_child(ghost)
    var tw := ghost.create_tween()
    tw.tween_property(ghost, "modulate:a", 0.0, life)
    tw.tween_callback(ghost.queue_free)


## 모션 트레일 — total 초 동안 n 장의 잔상을 일정 간격으로 남긴다(fire-and-forget).
func afterimage_burst(sprite: AnimatedSprite2D, tint: Color = MAGE, n: int = 4, total: float = 0.22) -> void:
    if sprite == null or n <= 0:
        return
    var gap := total / float(n)
    for i in range(n):
        afterimage(sprite, tint, 0.20)
        await get_tree().create_timer(gap).timeout
        if not is_instance_valid(sprite):
            return


# ════════════ 창 마검사 콤보 — 1·2·3타 모션/이펙트 차별 ════════════
func combo(pos: Vector2, facing_right: bool, step: int) -> void:
    match step:
        1: _spear_thrust(pos, facing_right)
        2: _spear_sweep(pos, facing_right)
        _: _spear_spin(pos)


# 1타 — 빠른 직선 찌르기 (창대 + 보랏빛 기운 + 끝 섬광 + 속도선)
func _spear_thrust(pos: Vector2, facing_right: bool) -> void:
    var host := _host()
    if host == null:
        return
    var dir := 1.0 if facing_right else -1.0
    var root := Node2D.new()
    root.global_position = pos
    root.z_index = 30
    host.add_child(root)
    # PixelLab 페인티드 창격(주역) — 기존 코드 창대/속도선이 받쳐줌. tip 이 진행 방향을 향하게 flip.
    _painted("thrust_lance", pos + Vector2(dir * 30.0, 0), 0.42, 0.56, 0.16, facing_right, 0.0, 0.0,
        Color(1, 1, 1, 0.95), 31, Vector2(dir * 18.0, 0))
    # 굵은 보랏빛 마기 잔상 → 그 위에 밝은 창대
    var aura := _line(PackedVector2Array([Vector2(dir * 2, 0), Vector2(dir * 70, 0)]), 13.0,
        Color(MAGE.r, MAGE.g, MAGE.b, 0.45), 29)
    root.add_child(aura)
    var shaft := _line(PackedVector2Array([Vector2(dir * 4, 0), Vector2(dir * 66, 0)]), 5.0, BRIGHT, 31)
    root.add_child(shaft)
    # 속도선 3가닥(위/중/아래)
    for off in [-9.0, 0.0, 9.0]:
        var sp := _line(PackedVector2Array([Vector2(dir * 14, off), Vector2(dir * 46, off)]), 2.0,
            Color(BRIGHT.r, BRIGHT.g, BRIGHT.b, 0.6), 30)
        root.add_child(sp)
    # 창끝 마름모 섬광
    var tip := Polygon2D.new()
    tip.polygon = PackedVector2Array([Vector2(0, -8), Vector2(13, 0), Vector2(0, 8), Vector2(-13, 0)])
    tip.color = MAGE_HOT
    tip.position = Vector2(dir * 70, 0)
    tip.z_index = 32
    root.add_child(tip)
    var tw := root.create_tween()
    tw.tween_property(root, "position:x", root.position.x + dir * 22.0, 0.12)
    tw.parallel().tween_property(root, "modulate:a", 0.0, 0.15)
    tw.tween_callback(root.queue_free)


# 2타 — 넓은 횡소(가로 휘둘러베기) — 큰 초승달 + 다중 잔상 + 꽃잎 스파크
func _spear_sweep(pos: Vector2, facing_right: bool) -> void:
    var host := _host()
    if host == null:
        return
    var dir := 1.0 if facing_right else -1.0
    var root := Node2D.new()
    root.global_position = pos
    root.z_index = 30
    host.add_child(root)
    # PixelLab 페인티드 초승달(주역) — 아래 코드 디테일(꽃잎/잔상)이 받쳐줌
    _painted("slash_wide", pos, 0.42, 0.66, 0.2, not facing_right, -0.12 * dir, 0.0, Color(1, 1, 1, 0.95), 31)
    var wc := _belly_curve()
    # 3겹 초승달(보라 굵게 → 밝게) — 약간씩 각도 오프셋해 잔상감
    var layers := [
        [13.0, Color(MAGE.r, MAGE.g, MAGE.b, 0.40), -0.18],
        [8.0, MAGE_HOT, -0.07],
        [4.0, BRIGHT, 0.0],
    ]
    for L in layers:
        var pts := PackedVector2Array()
        for i in range(13):
            var t := i / 12.0
            var a := lerpf(-1.15, 1.15, t) + float(L[2])
            pts.append(Vector2(dir * cos(a) * 62.0, sin(a) * 42.0))
        var arc := _line(pts, float(L[0]), L[1], 30)
        arc.width_curve = wc
        root.add_child(arc)
    # 호를 따라 튀는 꽃잎 스파크
    for i in range(6):
        var t := (i + 0.5) / 6.0
        var a := lerpf(-1.0, 1.0, t)
        var petal := Polygon2D.new()
        petal.polygon = PackedVector2Array([Vector2(0, -3), Vector2(5, 0), Vector2(0, 3), Vector2(-5, 0)])
        petal.color = GOLD if i % 2 == 0 else BRIGHT
        petal.position = Vector2(dir * cos(a) * 66.0, sin(a) * 46.0)
        petal.z_index = 31
        root.add_child(petal)
    var tw := root.create_tween()
    tw.tween_property(root, "scale", Vector2(1.3, 1.3), 0.18).set_trans(Tween.TRANS_QUAD)
    tw.parallel().tween_property(root, "modulate:a", 0.0, 0.2)
    tw.tween_callback(root.queue_free)


# 3타 — 회전베기 피니시 (2겹 링 + 방사 마기 가시 12 + 지면 먼지) — 가장 화려
func _spear_spin(pos: Vector2) -> void:
    var host := _host()
    if host == null:
        return
    var center := pos + Vector2(0, -16)
    var root := Node2D.new()
    root.global_position = center
    root.z_index = 30
    host.add_child(root)
    # PixelLab 페인티드 소용돌이(주역) — 회전하며 커진다
    _painted("slash_swirl", center, 0.45, 0.82, 0.26, false, 0.0, TAU * 0.6, Color(1, 1, 1, 0.95), 31)
    # 2겹 회전 링
    for k in range(2):
        var rp := PackedVector2Array()
        for i in range(25):
            var a := TAU * i / 24.0
            rp.append(Vector2(cos(a), sin(a)) * (50.0 - k * 12.0))
        var ring := _line(rp, 9.0 - k * 3.0, BRIGHT if k == 0 else MAGE_HOT, 31 - k)
        root.add_child(ring)
    # 방사 마기 가시 12
    for i in range(12):
        var a := TAU * i / 12.0
        var sp := _line(PackedVector2Array([Vector2(cos(a), sin(a)) * 18.0, Vector2(cos(a), sin(a)) * 60.0]),
            4.0, MAGE, 29)
        root.add_child(sp)
    var tw := root.create_tween()
    tw.tween_property(root, "scale", Vector2(1.55, 1.55), 0.26).set_trans(Tween.TRANS_QUAD)
    tw.parallel().tween_property(root, "rotation", TAU, 0.26)
    tw.parallel().tween_property(root, "modulate:a", 0.0, 0.26)
    tw.tween_callback(root.queue_free)
    # 지면 먼지(아래 좌우로 퍼지는 납작 호)
    _ground_dust(pos)


# 지면 먼지 — 발밑에서 좌우로 번지는 납작한 호
func _ground_dust(pos: Vector2) -> void:
    var host := _host()
    if host == null:
        return
    var dust := _line(PackedVector2Array(), 5.0, Color(GOLD.r, GOLD.g, GOLD.b, 0.5), 19)
    var pts := PackedVector2Array()
    for i in range(11):
        var t := i / 10.0
        pts.append(Vector2(lerpf(-34.0, 34.0, t), -sin(t * PI) * 8.0))
    dust.points = pts
    dust.global_position = pos
    host.add_child(dust)
    var tw := dust.create_tween()
    tw.tween_property(dust, "scale", Vector2(1.4, 0.7), 0.22)
    tw.parallel().tween_property(dust, "modulate:a", 0.0, 0.24)
    tw.tween_callback(dust.queue_free)


# ════════════ 궁극기 '귀창 강림' — 매우 화려한 광역 연출 ════════════
func ultimate(pos: Vector2) -> void:
    var host := _host()
    if host == null:
        return
    var center := pos + Vector2(0, -16)
    # 1) 화면 섬광(보랏빛→흰빛 페이드)
    var flash := ColorRect.new()
    flash.color = Color(0.7, 0.6, 0.95, 0.0)
    flash.anchor_right = 1.0
    flash.anchor_bottom = 1.0
    flash.z_index = 40
    var cl := CanvasLayer.new()
    cl.layer = 50
    cl.add_child(flash)
    host.add_child(cl)
    var ft := flash.create_tween()
    ft.tween_property(flash, "color:a", 0.55, 0.08)
    ft.tween_property(flash, "color:a", 0.0, 0.5)
    ft.tween_callback(cl.queue_free)
    # 2) 확장하는 마기 충격파 링 4겹
    for k in range(4):
        var rp := PackedVector2Array()
        for i in range(33):
            var a := TAU * i / 32.0
            rp.append(Vector2(cos(a), sin(a)) * 40.0)
        var ring := _line(rp, 9.0 - k * 1.5, MAGE if k % 2 == 0 else BRIGHT, 38)
        ring.global_position = center
        ring.scale = Vector2(0.2, 0.2)
        host.add_child(ring)
        var tw := ring.create_tween()
        tw.tween_interval(k * 0.09)
        tw.tween_property(ring, "scale", Vector2(5.0, 5.0), 0.55).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.55)
        tw.tween_callback(ring.queue_free)
    # 3) 하늘에서 쏟아지는 귀신 창 12자루(방사)
    var spears := Node2D.new()
    spears.position = center
    spears.z_index = 39
    host.add_child(spears)
    for i in range(12):
        var a := TAU * i / 12.0 - PI / 2.0
        var dirv := Vector2(cos(a), sin(a))
        var sp := _line(PackedVector2Array([dirv * 30.0, dirv * 300.0]), 5.0, BRIGHT, 39)
        sp.modulate.a = 0.0
        spears.add_child(sp)
        var aura := _line(PackedVector2Array([dirv * 30.0, dirv * 300.0]), 12.0,
            Color(MAGE.r, MAGE.g, MAGE.b, 0.5), 38)
        aura.modulate.a = 0.0
        spears.add_child(aura)
        for n: Line2D in [aura, sp]:
            var tw := n.create_tween()
            tw.tween_interval(0.05 + i * 0.02)
            tw.tween_property(n, "modulate:a", 1.0, 0.06)
            tw.tween_interval(0.18)
            tw.tween_property(n, "modulate:a", 0.0, 0.22)
    var clean := spears.create_tween()
    clean.tween_interval(1.0)
    clean.tween_callback(spears.queue_free)
    # 4) 중심 기둥 섬광 + 지면 먼지
    impact(center, true)
    _ground_dust(pos)


# ── 일섬: 전방으로 길게 베는 초승달 궤적 (2겹 + 속도선 + 코어) ──────
func slash(pos: Vector2, facing_right: bool, color: Color = BRIGHT) -> void:
    var host := _host()
    if host == null:
        return
    var dir := 1.0 if facing_right else -1.0
    var root := Node2D.new()
    root.global_position = pos
    root.z_index = 30
    host.add_child(root)
    # PixelLab 페인티드 초승달(주역, 일섬 참격)
    _painted("slash_crescent", pos, 0.4, 0.7, 0.2, not facing_right, -0.1 * dir, 0.0, Color(1, 1, 1, 0.95), 31)
    var wc := _belly_curve()
    # 보라 잔상 호 → 밝은 코어 호
    for L in [[10.0, Color(MAGE.r, MAGE.g, MAGE.b, 0.45)], [7.0, color], [2.0, GOLD]]:
        var pts := PackedVector2Array()
        for i in range(9):
            var t := i / 8.0
            var x := dir * lerpf(6.0, 60.0, t)
            var y := -28.0 + 56.0 * t * t
            pts.append(Vector2(x, y))
        var line := _line(pts, float(L[0]), L[1], 30)
        line.width_curve = wc
        root.add_child(line)
    # 전방 속도선
    for off in [-16.0, 0.0, 16.0]:
        var sp := _line(PackedVector2Array([Vector2(dir * 20, off * 0.4), Vector2(dir * 58, off * 0.4 + 6)]),
            2.0, Color(BRIGHT.r, BRIGHT.g, BRIGHT.b, 0.55), 29)
        root.add_child(sp)
    var tw := root.create_tween()
    tw.tween_property(root, "scale", Vector2(1.3, 1.3), 0.2)
    tw.parallel().tween_property(root, "modulate:a", 0.0, 0.2)
    tw.tween_callback(root.queue_free)


# ── 회천격: 플레이어를 중심으로 한 회전 원형 베기 (2겹 + 가시) ────
func spin(pos: Vector2, color: Color = BRIGHT) -> void:
    var host := _host()
    if host == null:
        return
    var center := pos + Vector2(0, -18)
    var root := Node2D.new()
    root.global_position = center
    root.z_index = 30
    host.add_child(root)
    # PixelLab 페인티드 소용돌이(주역, 회천격 회전베기)
    _painted("slash_swirl", center, 0.42, 0.78, 0.24, false, 0.0, TAU, Color(1, 1, 1, 0.95), 31)
    for k in range(2):
        var pts := PackedVector2Array()
        var seg := 22
        for i in range(seg + 1):
            var a := lerpf(-PI * 0.5, PI * 1.6, i / float(seg))
            pts.append(Vector2(cos(a), sin(a)) * (34.0 - k * 9.0))
        var ring := _line(pts, 6.0 - k * 2.0, color if k == 0 else MAGE_HOT, 30)
        root.add_child(ring)
    for i in range(8):
        var a := TAU * i / 8.0
        var sp := _line(PackedVector2Array([Vector2(cos(a), sin(a)) * 14.0, Vector2(cos(a), sin(a)) * 40.0]),
            3.0, MAGE, 29)
        root.add_child(sp)
    var tw := root.create_tween()
    tw.tween_property(root, "scale", Vector2(1.35, 1.35), 0.24).set_trans(Tween.TRANS_QUAD)
    tw.parallel().tween_property(root, "rotation", TAU, 0.24)
    tw.parallel().tween_property(root, "modulate:a", 0.0, 0.24)
    tw.tween_callback(root.queue_free)


# ── 적중 임팩트: 스파크 별 + 확장 링 ─────────────────────────
func impact(pos: Vector2, big: bool = false) -> void:
    var host := _host()
    if host == null:
        return
    var n := 8 if big else 5
    var length := 20.0 if big else 12.0
    var root := Node2D.new()
    root.global_position = pos
    root.z_index = 31
    host.add_child(root)
    # PixelLab 페인티드 스파크 별(주역) — 적중 섬광
    _painted("spark_burst" if big else "spark_star", pos, 0.26, (0.6 if big else 0.46),
        (0.22 if big else 0.16), false, 0.0, (0.5 if big else 0.0), Color(1, 1, 1, 0.95), 33)
    # 중심 섬광 점
    var core := Polygon2D.new()
    var cpts := PackedVector2Array()
    var cr := 6.0 if big else 4.0
    for i in range(8):
        var a := TAU * i / 8.0
        cpts.append(Vector2(cos(a), sin(a)) * cr)
    core.polygon = cpts
    core.color = BRIGHT
    root.add_child(core)
    # 방사 스파크
    for i in range(n):
        var a := TAU * i / float(n) + (0.4 if big else 0.0)
        var spoke := _line(PackedVector2Array([Vector2.ZERO, Vector2(cos(a), sin(a)) * length]),
            3.0 if big else 2.0, GOLD if (i % 2 == 0) else BRIGHT, 31)
        root.add_child(spoke)
    # 확장 링
    var rp := PackedVector2Array()
    for i in range(17):
        var a := TAU * i / 16.0
        rp.append(Vector2(cos(a), sin(a)) * (length * 0.7))
    var ring := _line(rp, 2.5 if big else 1.5, MAGE_HOT, 30)
    root.add_child(ring)
    var tw := root.create_tween()
    tw.tween_property(root, "scale", Vector2(1.6, 1.6), 0.16).set_trans(Tween.TRANS_QUAD)
    tw.parallel().tween_property(root, "modulate:a", 0.0, 0.16)
    tw.tween_callback(root.queue_free)


# ── 호신부: 플레이어를 도는 부적 오라 (반환 노드를 free 하면 사라짐) ──
func attach_ward(player: Node2D) -> Node2D:
    var ward := Node2D.new()
    ward.z_index = 20
    player.add_child(ward)
    ward.position = Vector2(0, -16)
    for i in range(3):
        var holder := Node2D.new()
        holder.rotation = TAU * i / 3.0
        ward.add_child(holder)
        var paper := Polygon2D.new()
        paper.polygon = PackedVector2Array([
            Vector2(-3, -5), Vector2(3, -5), Vector2(3, 5), Vector2(-3, 5)])
        paper.color = BRIGHT
        paper.position = Vector2(0, -26)
        holder.add_child(paper)
        var mark := Line2D.new()
        mark.width = 1.0
        mark.default_color = RED
        mark.points = PackedVector2Array([Vector2(0, -30), Vector2(0, -22)])
        holder.add_child(mark)
    var halo := Line2D.new()
    halo.width = 2.0
    halo.default_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.5)
    var hp := PackedVector2Array()
    for i in range(25):
        var a := TAU * i / 24.0
        hp.append(Vector2(cos(a), sin(a)) * 28.0)
    halo.points = hp
    ward.add_child(halo)
    var tw := ward.create_tween().set_loops()
    tw.tween_property(ward, "rotation", TAU, 2.2)
    return ward
