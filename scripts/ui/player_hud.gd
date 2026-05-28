extends CanvasLayer
##
## Player HUD — 좌상단 HP 바. 'player' 그룹의 첫 노드를 찾아 HealthComponent에 연결.
## Phase 1 임시: 기본 ProgressBar 스타일. 한지·먹 톤 스킨은 폰트 임포트 후 폴리시.
##

@onready var hp_bar: ProgressBar = $Panel/Margin/VBox/HPRow/Bar
@onready var hp_label: Label = $Panel/Margin/VBox/HPRow/Label


func _ready() -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player == null:
        visible = false
        return
    var health: HealthComponent = player.get_node_or_null("HealthComponent")
    if health == null:
        visible = false
        return
    _update_hp(health.hp, health.max_hp)
    health.hp_changed.connect(_update_hp)


func _update_hp(hp: float, max_hp: float) -> void:
    hp_bar.max_value = max_hp
    hp_bar.value = hp
    hp_label.text = "%d / %d" % [int(hp), int(max_hp)]
