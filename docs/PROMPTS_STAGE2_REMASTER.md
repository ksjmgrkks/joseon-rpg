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

## 후처리 및 런타임 규격

- 배경: `640×180 / 640×240 / 640×180`, Nearest 규격화, 원·중·근경 런타임 알파 `0.72 / 0.82 / 0.68`.
- 지면: `256×224` atlas — 상단 `256×32` 표면 8변형, 하단 `256×192` 연속 뿌리 속재질.
- 소품: 15종을 셀별 알파 영역으로 분리하고 하단 중앙 정렬. `root_arch`를 납작하게 규격화한 16번째 파생 자산 `root_platform.png`은 떠 있는 뿌리 발판에 반복 사용한다.
- 생성기가 실제 알파 대신 넣은 흰/연회색 체크무늬는 바깥과 이어진 밝은 중성색만 flood-fill하고 잔여 밝은 중성색을 제거해 투명화한다.
- 그슨대 일반형·`Echo`·`Gloom`은 같은 아이 형상 위장을 공유한다. 정체를 섣불리 구분시키지 않고 이동 속도·체력·공격력·노출색으로 전투 리듬만 달리하려는 의도다.

## 서사/구간 설계

1. **끊어진 서낭 경계:** 칼을 먼저 쓰지 말고 발밑 그림자를 `조사`, 부적불은 안전한 원거리 대안임을 학습.
2. **되우는 길:** 앞에서 들리는 울음과 뒤로 난 발자국으로 메아리 변종을 예고.
3. **마른 당산터:** 마을의 실패한 금줄·서낭 의식과 뒤틀린 장승을 환경 서사로 제시.
4. **이름 잃은 길:** 여러 아이의 울음을 짚인형에 묶은 길에서 세 그슨대 변종을 혼합.
5. **울음골 빈터:** 이름을 요구하는 노괴와 대치하고, 처치 뒤 “이름 없는 혼에게도 돌아갈 길은 있다”로 해원.
