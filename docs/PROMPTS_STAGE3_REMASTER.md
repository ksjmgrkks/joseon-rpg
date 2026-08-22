# Stage 3 폐저자 리마스터 생성 기록 (2026-08-22)

## 실행 경로

- 생성 도구: **Codex 내장 고품질 이미지 생성기(ImageGen)**.
- 생성 원본: `.art_gen/stage3/`(git 제외). 원본 파일명은 `*_source.png`로 통일했다.
- 후처리: `tools/pixel/process_stage3_remaster.gd`가 체크무늬 매팅, Nearest 축소, 지면 atlas 조립, 3×3 소품 분리, 적 애니메이션 strip 조립을 수행한다.
- 최종 게임 자산: `assets/sprites/bg/stage3/`, `assets/tilesets/side/market.png`, `assets/tilesets/market_*.png`, `assets/tilesets/dokkaebi_brazier.png`, `assets/tilesets/ssireum_ring.png`, `assets/sprites/enemies/dokkaebi_{minion,brute,fire}/`.

## 공통 제약

모든 생성 프롬프트에 다음 방향을 공통 적용했다.

> Premium hand-crafted 16-bit pixel art for an orthographic side-scrolling action RPG; crisp hard-edged pixel clusters; nearest-neighbor look; limited 24-color charcoal, soot-brown, old hanji, muted indigo, and cold dokkaebi-blue palette; restrained Joseon Korean folk-horror; no modern objects, Japanese or Chinese architectural motifs, text, labels, borders, logos, watermarks, blur, or smooth vector gradients.

## 최종 프롬프트 세트

### 장터 원경 — `market_far_source.png` → `assets/sprites/bg/stage3/far.png`

> A very wide distant silhouette of a ruined late-Joseon Korean mountain market village at midnight: uneven tiled hanok rooflines, one low pass gate, thin leafless trees, remote charcoal ridges and sparse pinprick lanterns. The market must feel deserted and cursed, not festive. Low contrast, broad quiet shapes, transparent sky, seamless mirrored side edges, no people or monsters.

### 장터 중경 — `market_mid_source.png` → `assets/sprites/bg/stage3/mid.png`

> A very wide middle-distance layer of abandoned Joseon market buildings viewed straight from the side: overlapping giwa roofs, timber shop fronts, torn awnings, crooked sign frames without writing, jars, stacked shutters and narrow alleys. Medium contrast with cold moonlight and tiny restrained amber interiors, transparent above the roofs, continuous baseline, tile-friendly left and right edges.

### 장터 근경 — `market_near_source.png` → `assets/sprites/bg/stage3/near.png`

> A shallow wide foreground silhouette strip for a ruined Joseon night market: collapsed stall edges, low broken carts, baskets, jars, ropes, scraps of straw mat and sparse weeds. Keep the upper two thirds transparent and the playable silhouettes low, deep charcoal with sparse blue rim light, no complete characters or tall view-blocking props.

### 폐저자 지면 — `market_ground_source.png` → `assets/tilesets/side/market.png`

> A seamless orthographic side-view ground cross section for an abandoned Joseon market street. The walkable top is irregular packed earth mixed with worn straw, broken giwa fragments, cart-wheel ruts and a few embedded flat stones; below is compact dark brown soil with small roots, pebbles and buried rubble. One continuous natural cross section, never brickwork or a repeating checkerboard, transparent air above.

### 장터 소품 3×3 atlas — `market_props_source.png`

> Create a strict 3×3 transparent prop atlas with one isolated object in each equal cell, identical pixel density, cold upper-left moonlight and a shared bottom baseline. Row 1: collapsed timber market stall with torn straw mat; intact but deserted canopy stall; broken two-wheel handcart. Row 2: round Korean stone-and-wood market well; low oval ssireum sand ring; stacked jars, baskets and tied bundles. Row 3: old balance scale with empty rice measure and stone weight; iron brazier holding a small cold blue dokkaebi flame; narrow weathered market banner with no writing. Joseon Korean forms only, no scenery, cast shadows, labels or Japanese festival motifs.

### 도깨비불 2×3 atlas — `dokkaebi_fire_source.png`

> Create exactly six animation poses of the same Korean dokkaebi fire in a strict 3×2 transparent grid. It is a floating cold-blue ghost flame with a small soot-dark core and restrained pale cyan edge, eerie rather than cute. Poses progress from compact idle flicker through stretched movement to a bright gathered telegraph and forward-firing attack. Same scale and center in every cell, no face, limbs, lantern, smoke cloud, scenery, border or text.

### 장터 도깨비 3×3 pose atlas — `dokkaebi_minion_source.png`

> Create one original adult Korean dokkaebi market thug in a strict 3×3 transparent pose atlas, facing right. Stocky but smaller than the player's major bosses, short dark horns, broad adult face, rough tied hair, worn brown jeogori and baji, rope belt, straw shoes, and a compact wooden club. Row 1: three idle poses; row 2: three walk poses; row 3: clear attack telegraph, horizontal club strike, defeated collapse. Keep identity, costume, palette, camera, scale and foot baseline identical. Never a child, shirtless generic goblin, oni, samurai, Chinese demon, or cartoon mascot.

### 곤봉 도깨비 3×3 pose atlas — `dokkaebi_brute_source.png`

> Create the same large adult Korean dokkaebi ssireum enforcer in a strict 3×3 transparent pose atlas, facing right. He is visibly larger than the common dokkaebi but smaller than the final chief: thick neck and arms, short dark horns, stern Korean folk-mask-like face, sleeveless dark indigo work vest over muted rust sleeves, loose gray baji, cloth belt, straw shoes, and an oversized gnarled wooden club. Row 1: three heavy idle poses; row 2: three stomping walk poses; row 3: raised-club telegraph, sweeping strike, knocked-down defeat. Preserve exact identity and baseline; no armor, oni styling, sumo mawashi, gore, scenery, labels or extra figures.

## 후처리 규격

- 패럴랙스: `640×190 / 640×220 / 640×150`, Nearest 축소. 런타임 alpha는 원·중·근경 `0.42 / 0.68 / 0.50`.
- 지면: `256×224` atlas. 위 `256×32`는 32px 표면 8변형, 아래 `256×192`는 연속 속재질.
- 소품: 각 3×3 셀의 알파 사용 영역을 추출해 지정 캔버스의 하단 중앙에 맞춘다.
- 일반 도깨비: 프레임 `80×80`, idle 4 / walk 6 / telegraph 3 / attack 4 / death 4.
- 곤봉 도깨비: 프레임 `128×128`, idle 4 / walk 6 / telegraph 3 / attack 4 / death 4.
- 도깨비불: 프레임 `64×64`, 각 애니메이션 3~6프레임.
- 생성기가 투명도 대신 그린 흰색·연회색 체크무늬는 밝은 중성색 매팅으로 실제 알파로 변환했다.

## 도깨비 대장 PixelLab Pro 리마스터 (2026-08-22)

- 생성 모드: **PixelLab Pro**, 8방향 캐릭터 `128×128`; 게임에는 side-view `east` 방향을 사용.
- 최종 캐릭터 ID: `6ce3aa1d-576d-4597-ae37-53c9e02e0ec5` (`Dokkaebi Chief Remaster Pro B2`).
- 애니메이션: idle / walk / telegraph / attack / death, 각 `east` 4프레임 Pro 생성.
- 최종 animation group: idle `f3129d47-726c-477f-956f-5f8e76aafbd2`, walk `c64036ce-0fa1-4906-b61d-a2284e142d9d`, telegraph `4fe4c6ee-ffab-46c6-a6bb-f92b113dd394`, attack `2a1f403a-5f7c-43c5-a21e-f90401cef16c`, death `b53bf278-c4e8-446d-b712-869cb4498527`.
- 최종 런타임 에셋 비용: 선택 캐릭터 40 generations + 성공 애니메이션 5종 × 20 = 140 generations. 탈락한 첫 Pro 후보 40을 포함한 이번 작업의 실제 잔여량 변화는 791→611, 총 180 generations다. 최초 idle 작업 한 건은 0%에서 고착되어 서버가 취소를 거부했고 현재 사용량에는 반영되지 않았다. 나중에 처리되면 20 generations가 추가될 수 있으며, 런타임에는 완료된 `idle_retry` 결과만 사용한다.
- 탈락안: `3238e881-ca39-41fe-aae9-fe598ddbf73d`는 조선 복식은 좋았으나 인간 장사꾼처럼 온순해 보였고, 기존 보스 스타일 참조안은 153×155 유효 크기가 Pro 상한 128을 넘어 생성되지 않았다.

### 최종 캐릭터 프롬프트

> A horrifying, unmistakably Korean Joseon folk-horror dokkaebi chief, the inhuman ruler of a cursed night market. Full-body side-view boss sprite. He must look supernatural at first glance, not like a painted human merchant: a huge hunched silhouette about three heads tall, shoulders extremely broad beneath layered cloth, long heavy arms and thick claw-like hands. NO HORNS. His oversized nonhuman face is formed like an ancient Korean gwimyeonwa monster roof tile and a warped Hahoe mask: deep empty black eye sockets with tiny cold-blue pupils, crushed broad nose, heavy arched brows, enormous asymmetrical mouth, protruding blunt fangs, cracked soot-red clay skin, wild black mane tied into a broken Joseon sangtu. Frayed straw and paper talismans are tangled in his hair. He wears a grimy charcoal jangsam/durumagi over a torn ochre hemp jeogori, very loose indigo-gray baji, thick rope belt hung with old yeopjeon coins, brass bells and fraudulent market weights, cloth puttees and straw shoes. No exposed torso. He grips an enormous crooked Korean zelkova dokkaebi bangmangi like a defensive barrier across his front: ancient knotted wood carved with subtle taegeuk, cloud and goblin-face motifs, wrapped with straw rope and tarnished brass rings, leaking sparse blue dokkaebi fire from the knots. Make the face, hands, club, coin belt and Korean clothing readable at 128px. Threatening low forward lean, as if he will block the path and devour unpaid debt. Limited charcoal ink, burnt umber, old hanji, dark indigo, dull cinnabar and icy ghost-blue. Crisp high-detail pixel art, solemn Korean ghost-story terror, no comedy. Transparent background. Absolutely no Japanese oni, horns, samurai, sumo, Chinese demon robe, Western orc, bodybuilder anatomy, fantasy armor, leather armor, spiked bat, bare chest, leopard skin, crown, modern object, text, scenery, cast shadow, extra figure or watermark.

### 최종 애니메이션 프롬프트

- **idle:** A seamless ominous breathing guard loop for this exact Korean dokkaebi chief. He remains rooted in place in the same low defensive stance, holding the crooked zelkova bangmangi horizontally across his belly. His shoulders rise and fall once with a slow heavy breath; the ragged charcoal durumagi hem, wild sangtu hair, yeopjeon coin belt and tiny brass bells make only subtle secondary motion; sparse cold-blue flames pulse gently on the club knots. Both straw-shod feet stay fixed to one baseline for every frame. No step, strike, jump, extra prop or extra character.
- **walk:** A slow terrifying forward walk to the right. The hunched Korean dokkaebi chief takes heavy deliberate steps while keeping the huge zelkova bangmangi across his front as a defensive barrier. Long arms, loose baji, straw shoes, hair and coin belt move with weight. No running, jumping or weapon swing; same costume and face.
- **telegraph:** A clear threatening attack wind-up. From his low guard, the Korean dokkaebi chief plants both feet, draws the huge zelkova bangmangi back across one shoulder, lowers his head so the black eye sockets face forward, and gathers cold-blue dokkaebi fire around the club knots. Final pose holds at maximum anticipation. No strike yet, no jump.
- **attack:** One brutal horizontal bangmangi sweep to the right. The Korean dokkaebi chief rotates his entire hunched body from the planted rear foot, swings the enormous crooked zelkova club across chest height, cloth and coin belt trailing with force, cold-blue fire smearing briefly from the wood knots, then ends in a low follow-through. No projectile, no extra figure, no jump.
- **death:** A solemn non-gory defeat. The Korean dokkaebi chief staggers as the blue fire goes out, loses the huge zelkova bangmangi from his hands, drops to one knee, then collapses heavily to the side with his face and Korean clothing still recognizable. Coins settle on the ground. No dismemberment, blood, explosion, smoke replacement or extra figure.
