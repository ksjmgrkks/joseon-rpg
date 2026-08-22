# Stage 2 비주얼 리마스터 생성 기록 (2026-08-22)

## 실행 경로

- **Codex 내장 이미지 생성기 기본 모드**로 제작했다. 별도 PixelLab 캐릭터/애니메이션 생성은 사용하지 않았다.
- 원본은 `.art_gen/stage2/`(git 제외)에 보관하고, `tools/pixel/process_stage2_remaster.gd`가 배경 매팅·Nearest 규격화·지면 atlas 조립·소품 시트 분리를 재현한다.
- 최종 게임 자산은 `assets/sprites/bg/stage2/`, `assets/tilesets/side/shadow_forest.png`, `assets/tilesets/stage2/`에 저장되어 git에 포함된다.
- 생성 결과 식별자와 원본 매핑:
  - `exec-50324d4b-0d66-4183-9af5-61066eddddf8.png` → `mtn_far_source.png`
  - `exec-d28e5c5c-ba7d-42f5-9510-9cfedbc8fa54.png` → `mtn_mid_source.png`
  - `exec-f1885eaa-fe31-4db9-8362-fd2973acf7aa.png` → `mtn_near_source.png`
  - `exec-557cc3f2-dd23-4cfa-b0f4-f0d6d51d18b1.png` → `shadow_forest_source.png`
  - `exec-d8374a1f-d615-4a2b-8e8a-4284f24803ae.png` → `forest_props_source.png`
  - `exec-f66fe665-212a-42ad-a597-5c41f26244e2.png` → `ritual_props_source.png`
  - `exec-29b2b109-2a70-4d6d-9f09-bbf04ac5e648.png` → `geuseondae_shadow_source.png`
  - `exec-0c163e98-23f2-43bb-ba71-16cc07f73a24.png` → `jangseung_sealed_source.png`
  - `exec-0dd06b47-3700-452e-8d38-b441c0b0b7d5.png` → `mtn_near_fixed_source.png`
  - `exec-1fe95d75-8fb7-4276-8b15-5a0a413706c1.png` → `mtn_mid_fixed_source.png`

## 공통 제약

모든 프롬프트에 다음 방향을 공통 적용했다.

> Premium hand-crafted 16-bit pixel art for a side-scrolling action RPG; crisp hard-edged pixels; limited charcoal, deep indigo, muted celadon, weathered hemp, and cold hanji palette; moonless late-Joseon Korean folk-horror; restrained rather than gory; orthographic side view; authentic Korean red pines and village ritual forms only; no Japanese or Chinese motifs, no torii, paifang, pagoda, western cemetery, skulls, gore, text, border, logo, or watermark.

## 최종 프롬프트 세트

### 배경 원경 — `assets/sprites/bg/stage2/far.png`

> A very wide far-background layer for a late-Joseon Korean mountain forest at moonless night: low overlapping ink-wash ridges, sparse distant red-pine silhouettes and thin ground mist, calm readable ridge rhythm, transparent sky, low contrast charcoal and indigo with a trace of muted celadon, mirrored-tile-compatible side edges, no structures, people, monsters, or bright moon.

### 배경 중경 — `assets/sprites/bg/stage2/mid.png`

> A wide haunted Korean red-pine forest ridge for the middle parallax layer: crooked wind-shaped native pines, exposed roots, a few torn white funeral-cloth strips tied to branches, pockets of cold ink mist, transparent sky and gaps, medium contrast, solemn folktale atmosphere, never bamboo, sakura, torii, or fantasy conifers.

### 배경 근경 — `assets/sprites/bg/stage2/near.png`

> A wide shallow foreground silhouette strip of gnarled roots, thorn brush and hooked pine branches with sparse frayed hemp ribbons, transparent above and between forms, dark charcoal/indigo, irregular but gameplay-readable negative space, no gore, bones, skulls, graves, western cemetery imagery, or non-Korean ritual symbols.

### 그슨대 숲 지면 — `assets/tilesets/side/shadow_forest.png`

> A long seamless orthographic side-view cross section of a cursed Korean pine forest floor: eight varied walkable surface sections of pine needles, hooked roots, charcoal soil, flat slate and thin fungal threads; deep continuous packed-earth fill below with tangled roots and embedded dark stones; no bricks, masonry, grass lawn, bright saturation, perspective, or visible rectangular tile boundaries.

### 숲 소품 시트 — `assets/tilesets/stage2/{pine_crooked,pine_split,root_arch,boulder_slate,thorn_brush,shadow_puddle,sotdae_broken,jangseung_broken,backward_footprints}.png`

> Strict 3×3 transparent prop atlas, one isolated prop per equal cell on a shared baseline. Row 1: crooked Korean red pine; split dead Korean pine; low tangled-root arch. Row 2: low slate boulder; dense thorn brush; flat supernatural shadow puddle. Row 3: broken Korean sotdae; broken stern closed-mouth jangseung; a short trail of small child footprints pointing backward. Shared cold upper-left night lighting and pixel density, no scenery rectangles, labels, cast-shadow plates, or non-Korean motifs.

### 의례 소품 시트 — `assets/tilesets/stage2/{seonang_cairn,straw_effigy,geumjul_ruin,stone_lantern_unlit,offering_bowl,sacred_stump}.png`

> Strict 3×2 transparent late-Joseon Korean village-ritual prop atlas, one isolated object per equal cell on a common baseline. Row 1: seonang stone cairn with worn cloth strips; small straw effigy; torn geumjul between short wooden stakes. Row 2: unlit Korean granite stone lantern; low offering bowl with scattered millet; blackened sacred pine stump wrapped in frayed hemp. Solemn weathered materials, no writing, faces, blood, torii, shimenawa, Chinese gate, pagoda, or modern objects.

### 일반 그슨대 발견 후 본체 — `assets/sprites/enemies/geuseondae_shadow/`

> Strict 4-row × 5-column transparent pixel-art animation grid for one ordinary Geuseondae true form. Adult-height but smaller than the elder boss, a hunched ink-shadow spirit with stretched limbs, trailing soot edges and one restrained cold celadon glint. Row 1 idle breathing, row 2 creeping walk, row 3 hooked-arm attack, row 4 dissolving death; five consecutive readable frames per row, identical cell size and foot baseline. Charcoal, deep indigo and muted celadon only; no child body, no weapon, no gore, no text, no scenery, no frame borders, no Japanese or Chinese motifs.

발견 전에는 기존의 작고 애처로운 아이 형상을 유지하고, `찾기` 또는 부적불 뒤에는 위 시트로 즉시 교체한다. `Echo`와 `Gloom`은 같은 본체 계열을 쓰되 크기와 냉청색·먹보랏빛 틴트로 전투 변주를 구분한다.

### 중간 보스 발견 전 장승 — `assets/sprites/enemies/jangseung_sealed/`

> Strict 1-row × 5-column transparent pixel-art strip of an ordinary stationary late-Joseon Korean guardian jangseung before possession is revealed. A planted weathered wooden post with stern closed face, small straw cap, faded hemp rope and cloth scraps, no arms and no legs; only a barely visible dark seam and subtle cloth/eye flicker across five restrained idle frames. Shared baseline and equal cells, orthographic side view, no attack pose, no monster limbs, no writing, no scenery rectangle, no torii, shimenawa, pagoda, Chinese guardian, logo or watermark.

발견 뒤에는 기존 `jangseung_gwi` 시트로 바뀌어 팔다리가 돋고 체력바·공격 AI가 함께 활성화된다. 위장 상태에서는 이동·공격·체력바가 꺼지고 `찾기`만 노출한다.

### 잘린 나무 경계 보정 — `assets/sprites/bg/stage2/{mid,near}.png`

> Precise edge cleanup of the supplied haunted Korean forest parallax layer. Preserve the central forest composition, palette, pixel density, mist and transparent gaps. Remove the upright tree trunk cut by the left boundary (and any partial trunk at the right boundary); replace only those edge fragments with low Korean pine roots, brush and shallow branch silhouettes that taper into transparent side gutters. No new tall object may touch either vertical image boundary; no new motifs, text, border or opaque sky.

중경과 근경을 각각 같은 원칙으로 다시 생성·후처리했다. 런타임 출력의 좌우 상단 45%에 불투명 픽셀이 닿지 않는 회귀 테스트를 추가해, 소스 경계의 굵은 나무가 화면 끝에서 반쪽으로 보이는 문제를 막는다.

## 후처리 및 런타임 규격

- 배경: `640×180 / 640×240 / 640×180`, Nearest 규격화, 원·중·근경 런타임 알파 `0.72 / 0.82 / 0.68`.
- 지면: `256×224` atlas — 상단 `256×32` 표면 8변형, 하단 `256×192` 연속 뿌리 속재질.
- 소품: 15종을 셀별 알파 영역으로 분리하고 하단 중앙 정렬. `root_arch`를 납작하게 규격화한 16번째 파생 자산 `root_platform.png`은 떠 있는 뿌리 발판에 반복 사용한다.
- 생성기가 실제 알파 대신 넣은 흰/연회색 체크무늬는 바깥과 이어진 밝은 중성색만 flood-fill하고 잔여 밝은 중성색을 제거해 투명화한다.
- 그슨대 일반형·`Echo`·`Gloom`은 발견 전에는 같은 아이 형상 위장을 공유하지만, 발견 뒤에는 성인 키의 먹그림자 본체로 전환한다. 노괴는 더 크고 가지뿔이 난 별도 본체라 일반형과도 즉시 구분된다.
- 중간 보스 `Jangseung`은 발견 전의 평범한 수호 장승과 발견 후의 보행 괴물 시트를 완전히 분리했다.

## 서사/구간 설계

1. **끊어진 서낭 경계:** 머리 위에 `찾기`가 뜨면 화면의 **찾기 버튼**을 누르도록 직접 안내하고, 부적불은 안전한 원거리 대안임을 학습.
2. **되우는 길:** 앞에서 들리는 울음과 뒤로 난 발자국으로 메아리 변종을 예고.
3. **마른 당산터:** 마을의 실패한 금줄·서낭 의식과 뒤틀린 장승을 환경 서사로 제시.
4. **이름 잃은 길:** 여러 아이의 울음을 짚인형에 묶은 길에서 세 그슨대 변종을 혼합.
5. **울음골 빈터:** 이름을 요구하는 노괴와 대치하고, 처치 뒤 “이름 없는 혼에게도 돌아갈 길은 있다”로 해원.
