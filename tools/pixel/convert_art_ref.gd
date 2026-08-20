extends SceneTree
##
## .art_ref_incoming/*.webp|jpg → PNG 정규화 + 크기·모서리 색 리포트.
## 유저가 채팅으로 준 원본(webp)을 추출 파이프라인이 쓰는 PNG 로 바꾸고,
## 배경이 흰지 검은지(모서리 실측)를 함께 찍어 매팅 임계값 판단 근거를 남긴다.
##
## 실행: godot --headless --path . --script res://tools/pixel/convert_art_ref.gd
##

const DIR := "res://.art_ref_incoming/"
const NAMES := ["protagonist_portrait_closeup", "protagonist_portrait_sheet"]


func _init() -> void:
	for nm in NAMES:
		var src := ""
		for ext in ["webp", "png", "jpg"]:
			var p := "%s%s.%s" % [DIR, nm, ext]
			if FileAccess.file_exists(p):
				src = p
				break
		if src.is_empty():
			print("없음: ", nm)
			continue
		var img := Image.load_from_file(src)
		if img == null:
			print("로드 실패: ", src)
			continue
		img.convert(Image.FORMAT_RGBA8)
		var out := "%s%s.png" % [DIR, nm]
		img.save_png(ProjectSettings.globalize_path(out))
		var w := img.get_width()
		var h := img.get_height()
		print("%s  %dx%d  모서리 색: LT=%s RT=%s LB=%s RB=%s" % [
			nm, w, h,
			img.get_pixel(0, 0), img.get_pixel(w - 1, 0),
			img.get_pixel(0, h - 1), img.get_pixel(w - 1, h - 1)])
	quit(0)
