# 스테이지 선택 카드 — PixelLab Pro 생성 기록

## 공통 설정

- 도구/모드: PixelLab Pro
- 출력: 160×160px, 후보 4장씩, 불투명 환경 일러스트
- 비용: 카드당 25 generations, 총 75 generations
- 런타임 표기: 그림에는 글자를 굽지 않고 Godot UI가 장·이름·설명·우두머리를 표시

## 1장 — 물이 잠긴 골짜기

- seed: `1201`
- job: `01b0dec9-1164-4a66-8939-a22c94ba24e2`
- 선택: index `0`
- 저장: `res://assets/ui/stage_cards/stage1_flooded_valley.png`

```text
A premium vertical game stage-selection card illustration showing a naturally flooded mountain valley in late Joseon Korea: shallow dark water winding through a steep pine valley, a partially collapsed small Korean shrine with tiled roof, wet granite rocks and reeds, layered ink-wash mountains disappearing into mist, one subtle immense drowned-spirit silhouette barely visible in the far fog. Refined 16-bit pixel art with deliberate hand-placed pixels, restrained ink black, slate blue, muted jade and hanji beige palette, eerie but calm Korean folk-tale mood, cinematic depth, strong readable silhouette at thumbnail size. Environment only. No frame, no border, no text, no letters, no UI, no logo, no watermark, no modern objects, no Chinese or Japanese architecture.
```

## 2장 — 그슨대 숲

- seed: `2202`
- job: `776428a9-78a0-4002-afaf-0580d16ed73d`
- 선택: index `3`
- 저장: `res://assets/ui/stage_cards/stage2_geuseondae_forest.png`

```text
A premium vertical game stage-selection card illustration showing the haunted Geuseondae forest in late Joseon Korea: dense crooked Korean red pines at midnight, a severe weathered jangseung guardian post, low blue-gray ground fog, tangled roots and a narrow path disappearing into blackness, one extremely tall indistinct shadow spirit with long arms hidden between the trunks. Refined 16-bit pixel art with deliberate hand-placed pixels, restrained ink black, charcoal, moonlit indigo and desaturated pine green palette, eerie but quiet Korean folk-tale mood, cinematic depth, strong readable silhouette at thumbnail size. Environment-led composition. No frame, no border, no text, no letters, no UI, no logo, no watermark, no modern objects, no Chinese or Japanese architecture.
```

## 3장 — 폐허가 된 저잣거리

- seed: `3303`
- job: `4be3518a-690b-4363-8a78-057c01a8bccf`
- 선택: index `1`
- 저장: `res://assets/ui/stage_cards/stage3_ruined_market.png`

```text
A premium vertical game stage-selection card illustration showing an abandoned late-Joseon Korean marketplace at night: collapsed wooden stalls, a thatched shop and a tiled-roof shop, torn hanji awnings, warm paper lanterns, scattered brass coins and jars, faint blue dokkaebi ghost-fire curling through the empty market lane, one subtle horned club-bearing dokkaebi silhouette deep in the scene. Refined 16-bit pixel art with deliberate hand-placed pixels, restrained ink black, deep umber, burnt orange, tarnished gold and ghost-fire blue palette, mischievous but ominous Korean folk-tale mood, cinematic depth, strong readable silhouette at thumbnail size. Environment-led composition. No frame, no border, no text, no letters, no UI, no logo, no watermark, no modern objects, no Chinese or Japanese architecture.
```

## 후처리 메모

PixelLab 출력 가장자리에 회색 매트가 일부 포함되어 있다. PNG를 다시 굽지 않고
`scripts/ui/stage_select.gd`에서 `AtlasTexture.region`으로 1장 좌우 1px, 2장 좌 10px/우 1px,
3장 좌우 1px를 잘라 표시한다. 최종 렌더는 `shots/verify/stage_select_cards.png`로 확인했다.
