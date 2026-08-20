extends SceneTree
##
## 유저가 외부(비-PixelLab)에서 만들어 온 주인공 대형 일러스트(클로즈업)를
## assets/ui/portraits/protagonist/signature_full.png 로 넣는다.
##
## 실행: godot --headless --path . --script res://tools/pixel/extract_protagonist_closeup.gd
## 입력: .art_ref_incoming/protagonist_portrait_closeup.png (커밋 안 함 — .gitignore)
##
## 2026-08-21 재작성: 이전 판은 검은 배경 JPEG 를 플러드필로 매팅했으나(초록 프린지가
## 남는 원인), 새 원본은 배경이 이미 알파 0 이라 **내용 bbox 로 자르기만** 하면 된다.
##

const SRC := "res://.art_ref_incoming/protagonist_portrait_closeup.png"
const OUT := "res://assets/ui/portraits/protagonist/signature_full.png"
const PAD := 2


func _init() -> void:
	var img := Image.load_from_file(SRC)
	if img == null:
		push_error("원본 없음: %s" % SRC)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var used := img.get_used_rect()
	if used.size.x <= 0:
		push_error("내용이 없다(전부 투명) — 원본이 맞는지 확인")
		quit(1)
		return
	used = used.grow(PAD).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	var out := img.get_region(used)
	out.save_png(ProjectSettings.globalize_path(OUT))
	print("signature_full  %dx%d (원본 %dx%d 에서 크롭)" % [
		out.get_width(), out.get_height(), img.get_width(), img.get_height()])
	quit(0)
