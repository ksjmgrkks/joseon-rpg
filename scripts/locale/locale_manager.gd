extends Node
##
## LocaleManager autoload — 간단한 키→문자열 매핑 기반 다국어 스캐폴드.
##
## 사용:
##   Locale.t("menu.new") -> "새로 시작"  (ko)
##   Locale.t_format("hud.lv", [3])
##   Locale.set_locale("en")
##
## 설계상 SaveManager 와는 무관 — 옵션 메뉴에서 set_locale 만 호출하면 됨.
## 향후 Godot 의 tr() / .translation 체계로 마이그레이션할 수 있음(키 그대로).
##

signal locale_changed(locale: String)

const LOCALES_DIR := "res://assets/locale/"
const DEFAULT_LOCALE := "ko"

var _locale: String = DEFAULT_LOCALE
var _strings: Dictionary = {}


func _ready() -> void:
    _load(_locale)


func set_locale(locale: String) -> void:
    if locale == _locale:
        return
    if _load(locale):
        _locale = locale
        locale_changed.emit(_locale)


func current() -> String:
    return _locale


func t(key: String) -> String:
    return String(_strings.get(key, key))


func t_format(key: String, args: Array) -> String:
    var s := t(key)
    if args.is_empty():
        return s
    return s % args


func _load(locale: String) -> bool:
    var path := "%s%s.json" % [LOCALES_DIR, locale]
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        push_warning("[Locale] cannot open: %s" % path)
        return false
    var raw := f.get_as_text()
    f.close()
    var data = JSON.parse_string(raw)
    if not (data is Dictionary):
        push_error("[Locale] invalid JSON: %s" % path)
        return false
    _strings = data
    return true
