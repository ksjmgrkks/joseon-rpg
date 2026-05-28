# PROMPTS — 주인공 스프라이트 생성 (Phase 0)

> **목표:** "정답 레퍼런스" 1장 확보 = 전체 스타일의 기준점.
> 흐름: 아래 프롬프트로 5~10장 후보 생성 → 가장 조선풍인 1장 선택 → Aseprite/LibreSprite로 손보정 → `assets/sprites/protagonist/idle.png` 로 커밋.
>
> **중요:** 텍스트만으로는 한국 의복이 중국·일본풍으로 새기 쉽습니다. **레퍼런스 이미지 첨부(i2i 또는 ControlNet)** 가 가능한 도구를 강력 권장.

---

## 0. 사전 준비 — 레퍼런스 4~6장

프롬프트와 함께 도구에 첨부할 자료:

1. **한복 도포·갓 양반 사진** — 조선 후기 원본 사진이나 사극 스틸 컷 (구글 "Joseon dynasty hanbok", "갓 도포 사진")
2. **저고리·바지 평민 차림 사진** — 마찬가지로 사극 스틸 가능
3. **단청 클로즈업 1장** — 팔레트 톤 가이드 (구글 "단청 close-up")
4. **(선택)** 32~64px 픽셀 캐릭터 1장 — 비율/픽셀 밀도 참고
5. **(선택)** `docs/STYLE_BIBLE.md` 의 §1 팔레트 hex 코드 리스트

---

## 1. 코어 프롬프트 (모든 변형에 공통으로 포함)

### Positive
```
[CHARACTER DESCRIPTION HERE] — Korean Joseon dynasty pixel art character sprite,
side-view facing right, 48 pixels tall, limited palette (24-25 colors),
muted ink and hanji tones, soft cream beige base,
1-pixel selective outline (NOT pure black; use a darker shade of the local color),
top-left lighting, 3-step shading (base / shadow / occasional highlight),
no anti-aliasing, sharp clean pixel edges,
authentic Korean hanbok clothing details, distinctly Korean — NOT Chinese, NOT Japanese,
calm idle stance (single frame for now)
```

### Negative
```
chinese clothing, hanfu, manchurian queue,
japanese clothing, kimono, samurai armor, katana, ninja,
anime-style large eyes, chibi 1:1 head ratio,
smooth shading, gradient, gaussian blur, photographic, 3d render,
extra fingers, mutated hands, low-detail mush,
white-glow background, soft glow effects
```

### 보조 키워드 (한국 정체성 강화)
```
hanbok, dopo, jeogori, paji, gat (Korean wide-brim hat), sangtu (topknot),
hwando (Korean sword), dancheong muted colors, hanji paper tones,
ink-painting palette, Joseon dynasty common period
```

---

## 2. 변형 — 세 후보 동시 생성 (가장 잘 잡힌 1장 선택)

> 각 변형의 `[CHARACTER DESCRIPTION HERE]` 부분만 바꿔서 같은 코어로 돌리세요.

### A안 — 방랑 무사 (양반 무사 길)
```
A young Korean wandering swordsman of the Joseon dynasty, around 20s, slim build,
black hair tied in a topknot under a tall black wide-brim hat (gat),
dark gray dopo (long outer robe) over a beige jeogori,
a single-edged Korean sword (hwando) hanging at the hip,
brown leather boots, calm focused expression
```

### B안 — 평민 협객 (상민 검객 길)
```
A young Korean commoner martial artist of the Joseon dynasty, late teens, athletic build,
black hair tied with a simple cloth headband, NO gat (commoner style),
wearing a faded indigo jeogori with patched-knee dark paji (loose trousers),
straw sandals, a wooden short staff strapped to the back,
determined expression
```

### C안 — 학자 (지혜로운 주인공)
```
A young Korean scholar of the Joseon dynasty, mid 20s, slender build,
black hair in topknot under a black gat, white-beige scholar's dopo with subtle dark trim,
holding a folded paper scroll, kind intellectual face,
black leather scholar shoes
```

> 세 후보 다 만들고 → 가장 '한국적'으로 잘 잡힌 1장에서 출발. (분위기·디자인 둘 다 보고 결정)

---

## 3. 도구별 호환 노트

### PixelLab
- **Style:** pixel art, 8-bit
- **Output size:** 48 × 64 (캐릭터 48 + 갓 헤더 여유 16) 또는 64 × 64
- **Custom palette:** STYLE_BIBLE 25색을 `.pal` 또는 hex 리스트로 업로드 (지원 시)
- **Skeleton:** humanoid_side
- **Animation:** 일단 idle 1프레임만. 양산은 스타일 잠근 다음.

### a1.art
- **Style cluster:** pixel art
- **Consistency mode:** ON (스타일 유지 강제)
- **Reference attach:** §0의 한복 사진 + STYLE_BIBLE 팔레트

### Midjourney / Stable Diffusion (SDXL)
- 코어 프롬프트 뒤에 추가:
  - **Midjourney:** `--ar 1:1 --stylize 100 --no chinese, japanese`
  - **SDXL/ComfyUI:** Sampler `DPM++ 2M Karras`, Steps 28, CFG 6~7
- ControlNet 가능 시: 위 §0의 한복 레퍼런스를 ControlNet reference 모드로 첨부.
- 후처리는 STYLE_BIBLE 팔레트로 클램프 — Aseprite 또는 PIL 스크립트(Claude에게 요청 가능).

---

## 4. 결과물 처리 절차

1. 위 프롬프트로 도구별로 5~10장 생성 (A/B/C 변형 골고루)
2. 가장 조선풍 1장 선택 → 다운로드 (.png)
3. Aseprite/LibreSprite/Pixelorama 열기 → 가져오기
4. 캔버스를 **48 × 64** 로 정리 (캐릭터 48 + 갓 헤더 16)
5. `Sprite → Color Mode → Indexed` → STYLE_BIBLE §1 팔레트 강제
6. 1px 외곽선 일관성 확인 + 서브픽셀 어긋남 손보정
7. 저장: `assets/sprites/protagonist/idle.png` (8-bit Indexed, 투명 배경)
8. Claude에게 알려주면:
   - STYLE_BIBLE 잠금 처리 ("잠정 v0" → "확정")
   - HANDOFF/CLAUDE.md 의 "시대·톤 미확정" 업데이트
   - Phase 1 진입 (걷기/점프 애니메이션 4~8프레임, 기본 씬·플레이어 노드)

---

## 5. 흔한 실패 패턴 (피하기)

| 증상 | 원인 | 해법 |
|---|---|---|
| 옷자락이 한푸처럼 너무 화려 | "Korean"만 적고 "NOT Chinese" 빠뜨림 | Negative에 `hanfu`, `chinese clothing` 명시 + 한복 레퍼런스 첨부 |
| 검이 일본도(katana)처럼 휨 | 검 묘사를 그냥 "sword"로 적음 | `hwando, single-edged Korean sword, straight blade` |
| 갓이 사무라이 모자처럼 좁음 | "hat"만 적음 | `tall wide-brim black gat, Korean traditional hat` |
| 색감이 너무 채도 높음 | "vibrant" 같은 키워드 포함 | "muted, ink-painting palette, low saturation" 강조 |
| 머리만 크게 (chibi) | 기본 모델 anime 편향 | `1:6 head-body ratio, NOT chibi, NOT anime` |
| 픽셀이 흐림 | 일반 모델이 AA 자동 | `sharp pixel edges, no anti-aliasing, no blur` |

---

## 6. 빠른 사본 (복사용 — 영문, 한 덩어리)

> 아래를 한 번에 복사해서 도구에 넣고 `[CHAR]` 부분만 A/B/C 변형으로 바꿔 사용.

**Positive:**
```
[CHAR] — Korean Joseon dynasty pixel art character sprite, side-view facing right, 48 pixels tall, limited palette of 24 colors, muted ink and hanji tones, soft cream beige base, 1-pixel selective outline using a darker shade of the local color (NOT pure black), top-left lighting, 3-step shading (base/shadow/highlight), no anti-aliasing, sharp clean pixel edges, authentic Korean hanbok clothing details, distinctly Korean — NOT Chinese, NOT Japanese, calm idle stance, single frame, transparent background
```

**Negative:**
```
chinese, hanfu, manchurian queue, japanese, kimono, samurai armor, katana, ninja, anime-style large eyes, chibi proportions, smooth shading, gradient, blur, photographic, 3d render, extra fingers, white glow background
```

**`[CHAR]` 변형:**
- A: `A young Korean Joseon-dynasty wandering swordsman in his early 20s, slim build, topknot under a tall black wide-brim gat, dark gray dopo over beige jeogori, hwando sword at hip, brown leather boots, calm focused face`
- B: `A young Korean Joseon-dynasty commoner martial artist in his late teens, athletic, black hair with a simple cloth headband (no gat), faded indigo jeogori, patched dark paji trousers, straw sandals, wooden short staff on back, determined face`
- C: `A young Korean Joseon-dynasty scholar in his mid 20s, slender, topknot under a black gat, white-beige scholar's dopo with subtle dark trim, holding a folded paper scroll, intellectual kind face, black scholar shoes`
