# Stage 1 비주얼 리마스터 생성 기록 (2026-08-22)

## 실행 경로

- 이 세션에서는 이전 PixelLab MCP 연결이 노출되지 않아 **Codex 내장 고품질 이미지 생성기**를 사용했다.
- 생성 원본은 `.art_gen/stage1/`(git 제외)에 저장했고, `tools/pixel/process_stage1_remaster.gd`가 체크무늬 매팅·규격 축소·atlas 조립·소품 분리를 수행한다.
- 최종 게임 자산은 `assets/sprites/bg/stage1/`, `assets/tilesets/side/`, `assets/tilesets/`에 저장되어 git에 포함된다.

## 공통 제약

모든 프롬프트에 다음 방향을 공통 적용했다.

> premium hand-crafted 16-bit pixel art; crisp hard-edged pixels; limited 20–24 color palette; restrained sumukhwa/hanji tone; orthographic side view; Joseon Korean forms only; no Japanese or Chinese architectural motifs; no text, border, logo, or watermark

## 최종 프롬프트 세트

### 배경 원경 — `assets/sprites/bg/stage1/far.png`

> A very wide distant Korean mountain range silhouette for a Joseon-era side-scrolling action RPG, layered far ridges fading into cold blue-gray predawn mist, low mountain base aligned along the bottom, broad calm ridge rhythm, mirrored-tile-compatible edges, transparent sky, low contrast charcoal/hanji-gray palette, sparse dithering, no buildings or people.

### 배경 중경 — `assets/sprites/bg/stage1/mid.png`

> A very wide Korean pine-covered middle-distance ridge: irregular clusters of native Korean red pines, sparse bare trunks, cold blue-charcoal twilight, transparent sky, medium contrast, clear layered silhouette at game scale, mirrored-tile-compatible edges, no buildings or fantasy ornaments.

### 배경 근경 — `assets/sprites/bg/stage1/near.png`

> A wide shallow Korean forest-floor silhouette strip occupying only the bottom third: uneven earthen bank, sparse dry grass, low reeds, small stones, exposed roots, a few short pine saplings, deep charcoal foreground, transparent above and between plants, no tall trees or clutter.

### 흙 지면 — `assets/tilesets/side/earth.png`

> A seamless orthographic side-view packed-earth cross section: transparent air above a thin uneven lip of sparse muted grass; compact layered dark umber and clay-brown soil below with tiny roots and occasional pebbles; no bricks, masonry, perspective, orange saturation, or obvious repeated blocks.

### 산악 지면 — `assets/tilesets/side/cliff.png`

> A seamless orthographic Korean mountain-cliff cross section with dark moss and hardy grass on top, then continuous natural granite bedrock: broad angular strata, long irregular fractures, diagonal fault lines, compact dark earth seams; it must read as one cliff face, never stacked stones, cobblestone, or castle masonry.

### 폐사지 지면 — `assets/tilesets/side/ruins.png`

> A seamless orthographic ruined Joseon shrine courtyard cross section: large worn dark granite flagstones on the walkable surface; charcoal earth below with fractured foundation slabs, sparse moss, hairline cracks, and buried rubble; no bright white wall, repeating rectangular masonry, Japanese shrine paving, or Chinese palace motifs.

### 자연물 시트 — `assets/tilesets/{pine,dead_tree,dead_tree_tall,boulder,boulder_moss,reed,driftwood}.png`

> Strict 3×3 transparent prop atlas. Row 1: wind-shaped Korean red pine; gnarled leafless dead tree; taller split-trunk dead pine. Row 2: low gray granite boulder; low mossy granite boulder; dry river reeds. Row 3: pale weathered driftwood; empty; empty. One isolated prop per equal cell, shared cold upper-left lighting and pixel density, common baseline, no ground patches or cast shadows; boulders low and wide.

### 의례물 시트 — `assets/tilesets/{jangseung,sotdae,shrine_ruin,seokdeung,lantern,mul_deung}.png`

> Strict 3×2 transparent Joseon ritual prop atlas. Row 1: weathered jangseung with a stern frightening closed-mouth face, never smiling; traditional wooden sotdae with a simple carved bird; collapsed small Joseon mountain shrine with broken giwa roof and timber. Row 2: mossy granite seokdeung; small rectangular hanji lantern with dark wood frame and faint amber glow; low floating memorial water lantern on a tiny raft with folded hanji lotus petals and no writing. Solemn cold blue-charcoal twilight, restrained amber highlights, no torii, paifang, pagoda, labels, or text.

## 후처리 규격

- 배경: `640×180 / 640×220 / 640×160`, Nearest 축소, 원·중·근경 알파 `0.48 / 0.62 / 0.45`.
- 지면: `256×224` atlas — 상단 `256×32` 표면 8변형, 하단 `256×192` 연속 속재질.
- 소품: 각 셀의 알파 사용 영역을 추출해 게임 캔버스에 하단 중앙 정렬.
- 생성기가 투명도 대신 넣은 흰/연회색 체크무늬는 밝은 중성색 매팅으로 실제 알파로 변환.
