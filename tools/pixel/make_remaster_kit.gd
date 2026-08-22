extends SceneTree
##
## 외주/외부 이미지 모델(나노바나나 등)에 "주인공 도트 리마스터"를 맡길 때 넘길
## 참고 이미지 묶음을 만든다.
##
## 실행: godot --headless --path . --script res://tools/pixel/make_remaster_kit.gd
## 출력: shots/remaster_kit/
##   · protagonist_ref_full.png   — 새 일러스트에서 대형 전신만 잘라낸 캐릭터 기준 이미지
##   · current_all_anims.png      — 현재 도트 11종 애니를 한 장에 모은 대조표(행=애니)
##   · current_<anim>.png         — 애니별 원본 스트립 사본(모델에 그대로 물릴 입력)
##
## 프레임 규격(256x256)과 프레임 수는 manifest.json 이 기준 — 리마스터 결과가 이 규격을
## 벗어나면 SpriteDb 가 프레임을 잘못 자른다(그래서 프롬프트에도 같은 수치를 박아야 한다).
##

const SHEET := "res://.art_ref_incoming/protagonist_portrait_sheet.png"
const SPR_DIR := "res://assets/sprites/protagonist_custom"
const OUT_DIR := "res://shots/remaster_kit"
const CONTACT_SCALE := 0.5
# 대조표 행 순서(위→아래). 프롬프트에서 이 순서를 그대로 부른다.
const ORDER := ["idle", "walk", "run", "jump", "dodge", "charge",
	"attack", "attack2", "attack3", "hurt", "death"]


func _init() -> void:
	var out_abs := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(out_abs)

	# ① 새 일러스트에서 왼쪽 대형 전신만 — 9칸 그리드가 같이 들어가면 모델이 헷갈린다.
	var sheet := Image.load_from_file(SHEET)
	if sheet != null:
		sheet.convert(Image.FORMAT_RGBA8)
		# 그리드 시작 x 는 extract_protagonist_portraits.gd 와 같은 근거(실측 737)보다
		# 살짝 왼쪽에서 끊어 술자락까지 포함시킨다.
		var fig := sheet.get_region(Rect2i(0, 0, 720, sheet.get_height()))
		var used := fig.get_used_rect()
		fig = fig.get_region(used)
		fig.save_png(out_abs + "/protagonist_ref_full.png")
		print("protagonist_ref_full.png %dx%d" % [fig.get_width(), fig.get_height()])

	# ② 애니별 스트립 사본 + 대조표
	var man := _manifest()
	var fw := int(man.get("frame_w", 256))
	var fh := int(man.get("frame_h", 256))
	var anims: Dictionary = man.get("anims", {})
	var max_frames := 0
	for a in ORDER:
		if anims.has(a):
			max_frames = maxi(max_frames, int(anims[a]["frames"]))

	var sheet_w := int(fw * max_frames * CONTACT_SCALE)
	var sheet_h := int(fh * ORDER.size() * CONTACT_SCALE)
	var contact := Image.create(sheet_w, sheet_h, false, Image.FORMAT_RGBA8)
	contact.fill(Color(0, 0, 0, 0))

	var row := 0
	for a in ORDER:
		var p := "%s/%s.png" % [SPR_DIR, a]
		if not FileAccess.file_exists(p):
			print("없음: ", a)
			continue
		var strip := Image.load_from_file(p)
		strip.convert(Image.FORMAT_RGBA8)
		strip.save_png(out_abs + "/current_%s.png" % a)
		var small := strip.duplicate() as Image
		small.resize(int(strip.get_width() * CONTACT_SCALE), int(strip.get_height() * CONTACT_SCALE),
			Image.INTERPOLATE_NEAREST)
		contact.blit_rect(small, Rect2i(0, 0, small.get_width(), small.get_height()),
			Vector2i(0, int(row * fh * CONTACT_SCALE)))
		print("  %-8s %d프레임 %dx%d" % [a, int(anims[a]["frames"]), strip.get_width(), strip.get_height()])
		row += 1

	contact.save_png(out_abs + "/current_all_anims.png")
	print("current_all_anims.png %dx%d (행 순서: %s)" % [sheet_w, sheet_h, ", ".join(ORDER)])
	quit(0)


func _manifest() -> Dictionary:
	var f := FileAccess.open("%s/manifest.json" % SPR_DIR, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	return d if d is Dictionary else {}
