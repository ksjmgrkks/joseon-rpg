extends Node
##
## SpriteDb autoload — 생성 파이프라인의 manifest.json 을 SpriteFrames 로 변환·캐시.
##
## 규약 (tools/pixel/AGENT_GUIDE.md §2):
##   assets/sprites/<sheet>/<anim>.png   — 가로 스트립
##   assets/sprites/<sheet>/manifest.json — { "frame_w", "frame_h", "anims": { name: {frames,fps,loop} } }
##
## 사용: var sf := SpriteDb.frames("protagonist")   /   frames("enemies/goblin")
##

var _cache: Dictionary = {}


func frames(sheet: String) -> SpriteFrames:
    if _cache.has(sheet):
        return _cache[sheet]
    var dir := "res://assets/sprites/%s" % sheet
    var manifest := _read_manifest(dir + "/manifest.json")
    if manifest.is_empty():
        return null
    var fw := int(manifest.get("frame_w", 32))
    var fh := int(manifest.get("frame_h", 64))
    var anims: Dictionary = manifest.get("anims", {})

    var sf := SpriteFrames.new()
    for anim_name in anims:
        var meta: Dictionary = anims[anim_name]
        var tex_path := "%s/%s.png" % [dir, anim_name]
        if not ResourceLoader.exists(tex_path):
            push_warning("[SpriteDb] 스트립 없음: %s" % tex_path)
            continue
        var strip_tex: Texture2D = load(tex_path)
        var count := int(meta.get("frames", 1))
        if anim_name != "default" and not sf.has_animation(anim_name):
            sf.add_animation(anim_name)
        sf.set_animation_speed(anim_name, float(meta.get("fps", 6)))
        sf.set_animation_loop(anim_name, bool(meta.get("loop", true)))
        for i in range(count):
            var at := AtlasTexture.new()
            at.atlas = strip_tex
            at.region = Rect2(i * fw, 0, fw, fh)
            sf.add_frame(anim_name, at)
    if sf.has_animation("default") and not anims.has("default"):
        sf.remove_animation("default")
    _cache[sheet] = sf
    return sf


## manifest 의 메타(프레임 크기 등)가 필요할 때.
func manifest(sheet: String) -> Dictionary:
    return _read_manifest("res://assets/sprites/%s/manifest.json" % sheet)


func _read_manifest(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return {}
    var parsed = JSON.parse_string(f.get_as_text())
    f.close()
    return parsed if parsed is Dictionary else {}
