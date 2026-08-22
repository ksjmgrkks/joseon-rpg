extends SceneTree
## Stage 2 런타임 시트에 남은 생성형 흰/연회색 체크무늬를 제거한다.
##
## 원본 생성 파일이 없는 PC에서도 pull 직후 최종 시트를 안전하게 복구할 수 있게
## 프레임 단위로 처리한다. 기본 실행은 shots/ 아래에 미리보기만 만들고,
## `--apply`를 붙였을 때만 실제 assets 파일을 덮어쓴다.

const AWAKENED_DIR := "res://assets/sprites/enemies/jangseung_awakened/"
const PREVIEW_DIR := "res://shots/transparency/alpha_preview/jangseung_awakened/"
const BACKUP_DIR := "res://shots/transparency/alpha_backup/jangseung_awakened/"
const ANIMATIONS := ["idle", "walk", "telegraph", "attack", "death"]
const FRAME_SIZE := Vector2i(176, 192)

# 각성 장승 프롬프트는 밝은 연기 대신 무광 검댕을 요구한다. 나무·짚·밧줄은
# 색차가 큰 갈색이라 이 범위에 들어오지 않고, 흰/연회색 무채색 잔여물만 제거된다.
const MATTE_FLOOR := 0.68
const MATTE_SPREAD := 0.16


func _init() -> void:
    var apply := "--apply" in OS.get_cmdline_user_args()
    var output_dir := AWAKENED_DIR if apply else PREVIEW_DIR
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
    if apply:
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP_DIR))
    var removed_total := 0
    for anim_name_value in ANIMATIONS:
        var anim_name := String(anim_name_value)
        var path: String = AWAKENED_DIR + anim_name + ".png"
        var image := Image.load_from_file(path)
        if image == null or image.is_empty():
            push_error("[Stage2Alpha] cannot load %s" % path)
            quit(1)
            return
        image.convert(Image.FORMAT_RGBA8)
        if image.get_height() != FRAME_SIZE.y or image.get_width() % FRAME_SIZE.x != 0:
            push_error("[Stage2Alpha] invalid sheet size %s: %s" % [path, image.get_size()])
            quit(1)
            return
        if apply:
            var backup_path: String = BACKUP_DIR + anim_name + ".png"
            if not FileAccess.file_exists(backup_path):
                image.save_png(ProjectSettings.globalize_path(backup_path))
        var removed := _clear_light_neutral(image)
        removed_total += removed
        var out_path: String = output_dir + anim_name + ".png"
        var err := image.save_png(ProjectSettings.globalize_path(out_path))
        if err != OK:
            push_error("[Stage2Alpha] cannot save %s: %s" % [out_path, err])
            quit(1)
            return
        print("[Stage2Alpha] %s: %d matte pixels removed" % [anim_name, removed])
    print("[Stage2Alpha] %s complete: %d pixels" % ["apply" if apply else "preview", removed_total])
    quit()


func _clear_light_neutral(image: Image) -> int:
    var removed := 0
    for y in image.get_height():
        for x in image.get_width():
            var c := image.get_pixel(x, y)
            if c.a <= 0.001:
                continue
            var hi := maxf(c.r, maxf(c.g, c.b))
            var lo := minf(c.r, minf(c.g, c.b))
            if lo >= MATTE_FLOOR and hi - lo <= MATTE_SPREAD:
                image.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
                removed += 1
    return removed
