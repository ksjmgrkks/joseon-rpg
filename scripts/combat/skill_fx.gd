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


func _host() -> Node:
    var tree := get_tree()
    if tree == null:
        return null
    return tree.current_scene


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
