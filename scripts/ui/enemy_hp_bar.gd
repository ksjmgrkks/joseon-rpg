extends Node2D
class_name EnemyHpBar
##
## 적 머리 위 HP 바. 피격 시 보였다가 일정 시간 뒤 다시 숨김.
##
## 사용: 적 _ready() 에서 EnemyHpBar.attach_to(self, health) 호출.
##

const SHOW_SECONDS := 2.0
const BAR_WIDTH := 36
const BAR_HEIGHT := 4
const Y_OFFSET := -28

var _bar: ColorRect
var _bg: ColorRect
var _hide_timer: float = 0.0
var _max_hp: float = 1.0


static func attach_to(host: Node2D, health: HealthComponent) -> EnemyHpBar:
    var b := EnemyHpBar.new()
    b.position = Vector2(0, Y_OFFSET)
    host.add_child(b)
    b._max_hp = health.max_hp
    health.hp_changed.connect(b._on_hp_changed)
    return b


func _ready() -> void:
    z_index = 5
    # 먹 프레임(금테) — 새긴 듯한 테두리
    var frame := ColorRect.new()
    frame.position = Vector2(-BAR_WIDTH / 2.0 - 1, -1)
    frame.size = Vector2(BAR_WIDTH + 2, BAR_HEIGHT + 2)
    frame.color = Color(0.6, 0.498, 0.251, 0.8)   # 단청 황(금) 깊은 톤
    add_child(frame)
    _bg = ColorRect.new()
    _bg.position = Vector2(-BAR_WIDTH / 2.0, 0)
    _bg.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
    _bg.color = Color(0.102, 0.086, 0.071, 0.9)    # 먹(최심)
    add_child(_bg)
    _bar = ColorRect.new()
    _bar.position = Vector2(-BAR_WIDTH / 2.0, 0)
    _bar.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
    _bar.color = Color(0.659, 0.271, 0.247, 1)     # 단청 적
    add_child(_bar)
    visible = false


func _process(delta: float) -> void:
    if _hide_timer > 0.0:
        _hide_timer = maxf(0.0, _hide_timer - delta)
        if _hide_timer <= 0.0:
            visible = false


func _on_hp_changed(hp: float, max_hp: float) -> void:
    _max_hp = max_hp
    if _bar:
        var ratio := clampf(hp / max_hp, 0.0, 1.0)
        _bar.size.x = BAR_WIDTH * ratio
    visible = true
    _hide_timer = SHOW_SECONDS
