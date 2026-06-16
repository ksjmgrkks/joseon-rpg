extends Node
##
## SkillFx autoload — 스킬·타격 시각 이펙트를 코드로 생성(별도 아트 불필요).
## 모든 이펙트는 current_scene 에 부착돼 트윈으로 페이드/소멸하며 스스로 queue_free.
## 색은 STYLE_BIBLE 팔레트 톤(먹/금/한지/단청)을 따른다.
##
## API:
##   SkillFx.slash(pos, facing_right)            — 일섬: 전방 초승달 참격 궤적
##   SkillFx.spin(pos)                            — 회천격: 회전하는 원형 베기
##   SkillFx.impact(pos, big=false)               — 적중 임팩트(불꽃 스파크)
##   SkillFx.attach_ward(player) -> Node2D        — 호신부: 부적 오라(반환값을 해제하면 사라짐)
##

const GOLD := Color(0.79, 0.66, 0.34)
const BRIGHT := Color(0.96, 0.92, 0.85)
const RED := Color(0.66, 0.27, 0.25)
const BLUE := Color(0.25, 0.42, 0.49)
const INK := Color(0.10, 0.086, 0.07)
const MAGE := Color(0.55, 0.42, 0.78)   # 마(魔)의 보랏빛 — 마창 기운


func _host() -> Node:
    var tree := get_tree()
    if tree == null:
        return null
    return tree.current_scene


# ════════════ 창 마검사 콤보 — 1·2·3타 모션/이펙트 차별 ════════════
func combo(pos: Vector2, facing_right: bool, step: int) -> void:
    match step:
        1: _spear_thrust(pos, facing_right)
        2: _spear_sweep(pos, facing_right)
        _: _spear_spin(pos)


# 1타 — 빠른 직선 찌르기 (창대 + 보랏빛 기운 + 끝 섬광)
func _spear_thrust(pos: Vector2, facing_right: bool) -> void:
    var host := _host()
    if host == null:
        return
    var dir := 1.0 if facing_right else -1.0
    var shaft := Line2D.new()
    shaft.width = 5.0
    shaft.default_color = BRIGHT
    shaft.begin_cap_mode = Line2D.LINE_CAP_ROUND
    shaft.end_cap_mode = Line2D.LINE_CAP_ROUND
    shaft.points = PackedVector2Array([Vector2(dir * 4, 0), Vector2(dir * 62, 0)])
    shaft.global_position = pos
    shaft.z_index = 30
    host.add_child(shaft)
    # 보랏빛 마기 잔상 + 창끝 마름모 섬광
    var aura := shaft.duplicate() as Line2D
    aura.width = 11.0
    aura.default_color = Color(MAGE.r, MAGE.g, MAGE.b, 0.5)
    host.add_child(aura); aura.global_position = pos
    var tip := Polygon2D.new()
    tip.polygon = PackedVector2Array([Vector2(0, -7), Vector2(11, 0), Vector2(0, 7), Vector2(-11, 0)])
    tip.color = BRIGHT
    tip.position = pos + Vector2(dir * 62, 0)
    tip.z_index = 31
    host.add_child(tip)
    for n: Node2D in [shaft, aura, tip]:
        var tw := n.create_tween()
        tw.tween_property(n, "position:x", n.position.x + dir * 18.0, 0.12)
        tw.parallel().tween_property(n, "modulate:a", 0.0, 0.14)
        tw.tween_callback(n.queue_free)


# 2타 — 넓은 횡소(가로 휘둘러베기) — 큰 초승달
func _spear_sweep(pos: Vector2, facing_right: bool) -> void:
    var host := _host()
    if host == null:
        return
    var dir := 1.0 if facing_right else -1.0
    var arc := Line2D.new()
    arc.width = 8.0
    arc.default_color = BRIGHT
    arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
    arc.end_cap_mode = Line2D.LINE_CAP_ROUND
    var pts := PackedVector2Array()
    for i in range(11):
        var t := i / 10.0
        var a := lerpf(-1.1, 1.1, t)             # 위→아래 부채
        pts.append(Vector2(dir * cos(a) * 60.0, sin(a) * 40.0))
    arc.points = pts
    var wc := Curve.new()
    wc.add_point(Vector2(0.0, 0.15)); wc.add_point(Vector2(0.5, 1.0)); wc.add_point(Vector2(1.0, 0.15))
    arc.width_curve = wc
    arc.global_position = pos
    arc.z_index = 30
    host.add_child(arc)
    var glow := arc.duplicate() as Line2D
    glow.width = 3.0
    glow.default_color = MAGE
    host.add_child(glow); glow.global_position = pos
    for n: Node2D in [arc, glow]:
        var tw := n.create_tween()
        tw.tween_property(n, "scale", Vector2(1.25, 1.25), 0.16)
        tw.parallel().tween_property(n, "modulate:a", 0.0, 0.18)
        tw.tween_callback(n.queue_free)


# 3타 — 회전베기 피니시 (전방위 원 + 방사 마기 가시) — 가장 화려
func _spear_spin(pos: Vector2) -> void:
    var host := _host()
    if host == null:
        return
    var ring := Line2D.new()
    ring.width = 9.0
    ring.default_color = BRIGHT
    ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
    ring.end_cap_mode = Line2D.LINE_CAP_ROUND
    var rp := PackedVector2Array()
    for i in range(25):
        var a := TAU * i / 24.0
        rp.append(Vector2(cos(a), sin(a)) * 46.0)
    ring.points = rp
    ring.global_position = pos + Vector2(0, -16)
    ring.z_index = 30
    ring.scale = Vector2(0.4, 0.4)
    host.add_child(ring)
    # 방사 마기 가시 8방향
    var spikes := Node2D.new()
    spikes.position = pos + Vector2(0, -16)
    spikes.z_index = 29
    host.add_child(spikes)
    for i in range(8):
        var a := TAU * i / 8.0
        var sp := Line2D.new()
        sp.width = 4.0
        sp.default_color = MAGE
        sp.points = PackedVector2Array([Vector2(cos(a), sin(a)) * 20.0, Vector2(cos(a), sin(a)) * 58.0])
        spikes.add_child(sp)
    var tw := ring.create_tween()
    tw.tween_property(ring, "scale", Vector2(1.5, 1.5), 0.24).set_trans(Tween.TRANS_QUAD)
    tw.parallel().tween_property(ring, "rotation", TAU, 0.24)
    tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.24)
    tw.tween_callback(ring.queue_free)
    var tw2 := spikes.create_tween()
    tw2.tween_property(spikes, "scale", Vector2(1.5, 1.5), 0.22)
    tw2.parallel().tween_property(spikes, "modulate:a", 0.0, 0.22)
    tw2.tween_callback(spikes.queue_free)


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
    # 2) 확장하는 마기 충격파 링 3겹
    for k in range(3):
        var ring := Line2D.new()
        ring.width = 8.0 - k * 1.5
        ring.default_color = MAGE if k % 2 == 0 else BRIGHT
        var rp := PackedVector2Array()
        for i in range(33):
            var a := TAU * i / 32.0
            rp.append(Vector2(cos(a), sin(a)) * 40.0)
        ring.points = rp
        ring.global_position = center
        ring.z_index = 38
        ring.scale = Vector2(0.2, 0.2)
        host.add_child(ring)
        var tw := ring.create_tween()
        tw.tween_interval(k * 0.1)
        tw.tween_property(ring, "scale", Vector2(4.5, 4.5), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
        tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.5)
        tw.tween_callback(ring.queue_free)
    # 3) 하늘에서 쏟아지는 귀신 창 12자루(방사)
    var spears := Node2D.new()
    spears.position = center
    spears.z_index = 39
    host.add_child(spears)
    for i in range(12):
        var a := TAU * i / 12.0 - PI / 2.0
        var dirv := Vector2(cos(a), sin(a))
        var sp := Line2D.new()
        sp.width = 5.0
        sp.default_color = BRIGHT
        sp.begin_cap_mode = Line2D.LINE_CAP_ROUND
        sp.end_cap_mode = Line2D.LINE_CAP_ROUND
        sp.points = PackedVector2Array([dirv * 30.0, dirv * 300.0])
        sp.modulate.a = 0.0
        spears.add_child(sp)
        var aura := sp.duplicate() as Line2D
        aura.width = 12.0
        aura.default_color = Color(MAGE.r, MAGE.g, MAGE.b, 0.5)
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
    # 4) 중심 기둥 섬광
    impact(center, true)


# ── 일섬: 전방으로 길게 베는 초승달 궤적 ──────────────────────
func slash(pos: Vector2, facing_right: bool, color: Color = BRIGHT) -> void:
    var host := _host()
    if host == null:
        return
    var dir := 1.0 if facing_right else -1.0
    var line := Line2D.new()
    line.width = 7.0
    line.default_color = color
    line.begin_cap_mode = Line2D.LINE_CAP_ROUND
    line.end_cap_mode = Line2D.LINE_CAP_ROUND
    line.joint_mode = Line2D.LINE_JOINT_ROUND
    # 초승달 호 — 위에서 아래로 베어 내리는 곡선
    var pts := PackedVector2Array()
    for i in range(9):
        var t := i / 8.0
        var x := dir * lerpf(6.0, 56.0, t)
        var y := -26.0 + 52.0 * t * t            # 위→아래 가속 곡선
        pts.append(Vector2(x, y))
    line.points = pts
    # 폭 곡선 — 가운데가 두껍게
    var wc := Curve.new()
    wc.add_point(Vector2(0.0, 0.2))
    wc.add_point(Vector2(0.5, 1.0))
    wc.add_point(Vector2(1.0, 0.15))
    line.width_curve = wc
    line.global_position = pos
    line.z_index = 30
    host.add_child(line)
    var tw := line.create_tween()
    tw.tween_property(line, "scale", Vector2(1.25, 1.25), 0.18)
    tw.parallel().tween_property(line, "modulate:a", 0.0, 0.18)
    tw.tween_callback(line.queue_free)
    # 잔광 — 금빛 가는 선 하나 더
    var glow := line.duplicate() as Line2D
    glow.width = 2.0
    glow.default_color = GOLD
    host.add_child(glow)
    glow.global_position = pos
    var tw2 := glow.create_tween()
    tw2.tween_property(glow, "modulate:a", 0.0, 0.22)
    tw2.tween_callback(glow.queue_free)


# ── 회천격: 플레이어를 중심으로 한 회전 원형 베기 ─────────────
func spin(pos: Vector2, color: Color = BRIGHT) -> void:
    var host := _host()
    if host == null:
        return
    var ring := Line2D.new()
    ring.width = 6.0
    ring.default_color = color
    ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
    ring.end_cap_mode = Line2D.LINE_CAP_ROUND
    var pts := PackedVector2Array()
    var seg := 22
    for i in range(seg + 1):
        var a := lerpf(-PI * 0.5, PI * 1.6, i / float(seg))   # 거의 한 바퀴
        pts.append(Vector2(cos(a), sin(a)) * 30.0)
    ring.points = pts
    ring.global_position = pos + Vector2(0, -18)
    ring.z_index = 30
    ring.scale = Vector2(0.4, 0.4)
    host.add_child(ring)
    var tw := ring.create_tween()
    tw.tween_property(ring, "scale", Vector2(1.3, 1.3), 0.22).set_trans(Tween.TRANS_QUAD)
    tw.parallel().tween_property(ring, "rotation", TAU, 0.22)
    tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.22)
    tw.tween_callback(ring.queue_free)


# ── 적중 임팩트: 짧은 스파크 별 ──────────────────────────────
func impact(pos: Vector2, big: bool = false) -> void:
    var host := _host()
    if host == null:
        return
    var n := 6 if big else 4
    var length := 18.0 if big else 11.0
    var root := Node2D.new()
    root.global_position = pos
    root.z_index = 31
    host.add_child(root)
    for i in range(n):
        var a := TAU * i / float(n) + (0.4 if big else 0.0)
        var spoke := Line2D.new()
        spoke.width = 3.0 if big else 2.0
        spoke.default_color = GOLD if (i % 2 == 0) else BRIGHT
        spoke.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(a), sin(a)) * length])
        spoke.begin_cap_mode = Line2D.LINE_CAP_ROUND
        spoke.end_cap_mode = Line2D.LINE_CAP_ROUND
        root.add_child(spoke)
    var tw := root.create_tween()
    tw.tween_property(root, "scale", Vector2(1.5, 1.5), 0.16).set_trans(Tween.TRANS_QUAD)
    tw.parallel().tween_property(root, "modulate:a", 0.0, 0.16)
    tw.tween_callback(root.queue_free)


# ── 호신부: 플레이어를 도는 부적 오라 (반환 노드를 free 하면 사라짐) ──
func attach_ward(player: Node2D) -> Node2D:
    var ward := Node2D.new()
    ward.z_index = 20
    player.add_child(ward)
    ward.position = Vector2(0, -16)
    # 회전하는 부적 3장 (작은 한지 사각 + 붉은 획)
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
    # 은은한 가호 링
    var halo := Line2D.new()
    halo.width = 2.0
    halo.default_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.5)
    var hp := PackedVector2Array()
    for i in range(25):
        var a := TAU * i / 24.0
        hp.append(Vector2(cos(a), sin(a)) * 28.0)
    halo.points = hp
    ward.add_child(halo)
    # 천천히 회전 (무한)
    var tw := ward.create_tween().set_loops()
    tw.tween_property(ward, "rotation", TAU, 2.2)
    return ward
