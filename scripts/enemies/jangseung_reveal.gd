extends "res://scripts/enemies/boss.gd"
class_name JangseungReveal
##
## 비틀린 장승 중간보스 — 처음에는 움직이지 않는 수호 장승으로 위장한다.
## 가까이서 "찾기"를 누르거나 부적불로 비춘 뒤에만 팔다리가 돋고 교전한다.
##

@export var interact_range: float = 92.0
@export var revealed_sheet: String = "enemies/jangseung_gwi"
@export var revealed_sprite_scale: float = 1.28
@export var revealed_foot_offset: float = -28.8
@export var revealed_attack_damage: float = 15.0

var _disguised: bool = true
var _in_interact_range: bool = false
var _interact_prompt: Label = null


func _ready() -> void:
    super._ready()
    attack_damage = 0.0
    health.shield_charges = 999
    _build_interact_prompt()
    for child in get_children():
        if child is EnemyHpBar:
            (child as EnemyHpBar).visible = false


func _physics_process(delta: float) -> void:
    _update_interact_prompt()
    if _disguised:
        if not is_on_floor():
            velocity.y += 980.0 * delta
        velocity.x = 0.0
        move_and_slide()
        return
    super._physics_process(delta)


func _build_interact_prompt() -> void:
    var label := Label.new()
    label.text = "찾기"
    label.add_theme_font_size_override("font_size", 18)
    label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.62))
    label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    label.add_theme_constant_override("outline_size", 5)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.position = Vector2(-22, -118)
    label.z_index = 40
    label.visible = false
    add_child(label)
    _interact_prompt = label


func _update_interact_prompt() -> void:
    if not _disguised or _state == State.DEAD:
        if _interact_prompt:
            _interact_prompt.visible = false
        _in_interact_range = false
        return
    var player := _player()
    var near := player != null and global_position.distance_to(player.global_position) <= interact_range
    _in_interact_range = near
    if _interact_prompt:
        _interact_prompt.visible = near


func _unhandled_input(event: InputEvent) -> void:
    if not _disguised or not _in_interact_range or _state == State.DEAD:
        return
    if Dialogue and Dialogue.is_active():
        return
    if event.is_action_pressed("interact"):
        _reveal()
        get_viewport().set_input_as_handled()


func _on_talisman_hit(damage: float, attacker: Node) -> bool:
    if _disguised:
        _reveal()
        return true
    # 정체가 드러난 뒤에는 일반 적과 마찬가지로 부적 피해를 정상 처리한다.
    var kb := 140.0
    if attacker is Node2D:
        kb = 140.0 * signf(global_position.x - (attacker as Node2D).global_position.x)
    return Hurtbox.deal(self, damage, kb, attacker)


func _reveal() -> void:
    if not _disguised:
        return
    _disguised = false
    _in_interact_range = false
    if _interact_prompt:
        _interact_prompt.visible = false
    health.shield_charges = 0
    attack_damage = revealed_attack_damage
    if sprite and is_instance_valid(sprite):
        sprite.set_sheet(revealed_sheet, revealed_sprite_scale, revealed_foot_offset)
        sprite.modulate = Color.WHITE
        _spr_base_scale = sprite.scale
        SkillFx.hit_flash(sprite, Color.WHITE, 0.3)
    if _warn:
        _warn.position.y = -154.0
    for child in get_children():
        if child is EnemyHpBar:
            (child as EnemyHpBar).visible = true
            (child as EnemyHpBar).call_deferred("_fit_to_host", self, true)
    SkillFx.impact(global_position + Vector2(0, -42), true)
    ScreenFx.shake(10.0, 0.28)
    Audio.play_sfx(Sfx.WARD)
