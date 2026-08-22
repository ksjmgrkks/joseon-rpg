# 4스테이지 「끊긴 상여길」 아트 생성 기록

## 방향

- 조선 후기풍 산골의 눈 덮인 상여길. 수묵 괴담 사극 톤이며 시신·유혈·과한 공포는 배제한다.
- 색은 월광 남색, 먹빛, 눈빛 회백색, 바랜 단청 적갈색·청록색만 사용한다.
- 한국식 상여·꼭두·서낭나무·상장·봉분을 사용하고 중국/일본 장례 건축과 복식은 금지한다.
- 게임 출력은 Nearest 필터의 픽셀아트이며 컷아웃 에셋은 투명 배경을 보장한다.

## 생성 도구

이 세션에서는 PixelLab 연결이 제공되지 않아 Codex 내장 고품질 ImageGen으로 원본을 만들었다.
원본은 `.art_gen/stage4/`에서 후처리했으며 실제 게임 파일은 `assets/` 아래에 저장한다.

## 최종 프롬프트

### 일반 적 4종 atlas

> Premium hand-crafted Korean folklore pixel art sprite atlas for a Joseon-era side-scrolling action RPG. Strict 4x4 grid, exactly one isolated full-body creature in each cell, transparent background, no text, no UI, consistent east-facing side view and ground line. Rows: stern wooden guide kkokdu doll in gat and faded robe; frightening acrobat/clown kkokdu with carved mask, no smile; adult pallbearer shadow in white mourning clothes carrying a bier pole; floating Korean paper funeral-flower spirit. Columns: idle, walk, attack, death. Moonlit indigo, charcoal, snow-white and restrained faded dancheong palette, crisp pixel clusters, black contour, no child monster, no cute expression, no Chinese or Japanese motifs.

### 중간보스 꼭두 장군

> Premium Joseon Korean folklore pixel art boss sprite sheet, strict 3x2 grid, transparent background, no text. The same stern kkokdu general riding a traditional carved wooden kkokdu horse in every cell; frightening carved face, gat-like headgear, faded dancheong armor, spear and small funeral bell. East-facing side view, consistent proportions and ground line. Six poses: idle, horse step, spear thrust, wide spear sweep, three-bell telegraph, defeated collapse. Larger than normal monsters but clearly smaller than the final boss. Moonlit indigo, charcoal, muted red and teal, crisp high-detail pixel art; no Western knight, no samurai, no Chinese armor, no smile.

### 최종보스 상여귀

> Premium high-detail pixel art boss sprite sheet for a Joseon-era Korean folklore side-scroller, strict 3x2 grid, transparent background, no text. An EMPTY possessed traditional Korean funeral bier, with wooden poles, faded dancheong carving, white mourning ribbons, paper flowers and brass bells; no corpse, no gore, no humans carrying it. Massive ominous silhouette. Six east-facing side-view poses: dormant hover, swaying approach, procession charge, pole sweep, ribbon-and-paper-flower summon, collapse and release. Moonlit snow palette with charcoal and muted dancheong, crisp readable pixels, consistent ground line; explicitly not a Chinese palanquin or Japanese mikoshi.

### 설경 패럴랙스

> Premium Korean ink-wash pixel art parallax source atlas, strict 1x3 horizontal bands and no text. A snowbound Joseon mountain funeral road at moonlit night. Top band: distant layered snowy Korean ridges and crescent moon; middle: dark red-pine slopes, stone cairns and a winding pass; bottom: near roots, snowbanks, mourning paper strips and sparse funeral-road silhouettes. Transparent sky around silhouettes where possible, limited moonlit indigo/charcoal/snow palette, crisp pixel clusters, no buildings from China or Japan, no modern objects.

### 소품 9종

> Premium Korean folklore pixel art prop atlas for a Joseon side-scrolling RPG, strict 3x3 grid, one isolated object per cell, transparent background, no text, consistent ground line. Row 1: snow-covered Korean red pine; stacked granite cairns; seonang sacred tree with white paper strips. Row 2: abandoned traditional Korean funeral-bier rest; tall white mourning banner; wooden post with exactly three brass funeral bells. Row 3: unfinished low burial mound; small snowy stone-and-log pass bridge; cluster of Korean paper funeral flowers. Moonlit indigo, charcoal, snow-white, faded dancheong, crisp detailed pixels, no Chinese/Japanese motifs.

### 설원 지면

> Wide opaque seamless side-view pixel-art terrain cross-section for a Joseon mountain pass in winter. Thin irregular snow crust over dark Korean granite, frozen soil, roots and small stones, enough vertical depth for a 256x224 side-scroller terrain atlas. Moonlit indigo and charcoal, restrained snow highlights, crisp nearest-neighbor pixel clusters, no text, no objects, no checkerboard.

### 스테이지 선택 카드

> Premium square pixel-art key art for a Joseon Korean folklore action RPG stage-select card. A narrow snow-covered mountain funeral road under a crescent moon, an empty traditional Korean funeral bier stopped in the distance, tiny carved kkokdu silhouettes and three hanging brass bells, deep red-pine ridges and drifting snow. Elegant mysterious ink-wash composition, moonlit indigo/charcoal/snow with tiny faded dancheong accents, no characters in foreground, no corpse, no gore, no text, no border, no UI, no Chinese or Japanese motifs.

## 후처리/출력

- `tools/pixel/process_stage4.gd`: 셀별 밝은 외부 매트 제거, 내부 흰색 복구, Nearest 축소, strip 조립.
- 배경은 좌우 절반 알파 감쇠 후 런타임 50% 중첩 크로스페이드한다.
- 일반 적 96×96, 꼭두 장군 192×160, 상여귀 320×240, 카드 160×160.
- 최종 출력: `assets/sprites/enemies/{kkokdu_*,pallbearer_shadow,paper_flower_spirit,sangyeogwi}`,
  `assets/sprites/bg/stage4`, `assets/tilesets`, `assets/ui/stage_cards/stage4_funeral_pass.png`.
