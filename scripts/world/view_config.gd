extends Node
##
## ViewConfig autoload — 카메라 배율(시야) 설정 저장/복원.
##
## 배경: "화면이 멀어서 몰입이 안 된다, 더 확대해서 보고 싶다"는 피드백(2026-08-22).
##
## 도트 게임의 일반적인 해법은 두 가지다.
##   ① **가상 해상도 자체를 바꾼다** — 1280x720 대신 854x480 으로 그리고 창에 정수배로 늘림.
##      픽셀이 깨지지 않아 가장 '정직'하지만, UI 좌표계까지 통째로 바뀌어 HUD·대화창·
##      시작화면 배치를 전부 다시 잡아야 한다.
##   ② **카메라 배율만 바꾼다** — 월드만 확대되고 UI(CanvasLayer)는 그대로.
##      스타듀밸리·테라리아의 줌 슬라이더가 이 방식이다.
## 여기서는 ②를 쓴다. 이 게임은 이미 stretch mode=viewport + aspect=expand 라 창 크기에
## 따라 비정수 배율로 늘어나고 있어서, ① 이 주는 픽셀 퍼펙트 이점을 어차피 못 누린다.
## 반면 ②는 공들여 맞춘 UI 배치를 하나도 건드리지 않는다.
##
## 저장 위치는 세이브 슬롯이 아니라 user:// — 새로 시작/이어하기와 무관한 '기기 설정'이다
## (TouchLayoutConfig 와 같은 성격).
##

const CFG_PATH := "user://view.cfg"
const SECTION := "view"

## 고를 수 있는 배율. 값이 클수록 확대(=화면에 보이는 월드가 좁아짐).
## 1.5 를 넘기면 횡스크롤에서 앞을 못 봐 적 접근을 놓치므로 여기까지만 연다.
const PRESETS := [1.0, 1.25, 1.5]
const LABEL_KEYS := ["view.normal", "view.large", "view.huge"]
## 기본값을 1.5 로 둔다(2026-08-22 사용자 결정) — 1.0 은 화면이 멀어 몰입이 안 된다는
## 피드백이 반복됐다. 이미 저장된 설정이 있으면 그 값이 우선한다.
const DEFAULT_ZOOM := 1.5

signal zoom_changed(zoom: float)

var zoom: float = DEFAULT_ZOOM


func _ready() -> void:
	_load()


## 현재 배율이 PRESETS 의 몇 번째인지(설정 화면 순환용). 못 찾으면 0.
func preset_index() -> int:
	for i in range(PRESETS.size()):
		if is_equal_approx(PRESETS[i], zoom):
			return i
	return 0


func set_preset(index: int) -> void:
	set_zoom(float(PRESETS[posmod(index, PRESETS.size())]))


func set_zoom(z: float) -> void:
	var clamped := clampf(z, PRESETS[0], PRESETS[PRESETS.size() - 1])
	if is_equal_approx(clamped, zoom):
		return
	zoom = clamped
	_save()
	zoom_changed.emit(zoom)
	apply_to_current()


## 지금 활성화된 카메라에 배율을 반영한다. 씬을 새로 세울 때/설정을 바꿀 때 호출.
## 컷신은 자기 씬에 전용 카메라를 따로 세우므로(연출 의도) 여기서 건드리지 않는다.
func apply_to_current() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var cam := tree.root.get_viewport().get_camera_2d()
	if cam == null or not cam.is_in_group("player_cam"):
		return
	cam.zoom = Vector2(zoom, zoom)
	# offset 도 같이 보정하지 않으면 확대할수록 지면선이 화면 아래로 밀려 하늘만 보인다.
	var base: Vector2 = cam.get_meta("base_offset", Vector2.ZERO)
	cam.offset = base / zoom


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return
	zoom = clampf(float(cfg.get_value(SECTION, "zoom", DEFAULT_ZOOM)),
		PRESETS[0], PRESETS[PRESETS.size() - 1])


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "zoom", zoom)
	cfg.save(CFG_PATH)
