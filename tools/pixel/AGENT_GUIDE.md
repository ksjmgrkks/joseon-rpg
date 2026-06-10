# AGENT_GUIDE — 에셋 생성 에이전트 계약서

「호환기담」 의 모든 프로그래매틱 에셋은 이 문서의 규약을 따른다.
스타일 근거: `docs/STYLE_BIBLE.md` (v1 잠금 — 팔레트 25색 강제).

## 0. 환경

- 작업 디렉터리: 프로젝트 루트. Python 3.14 + Pillow 사용 가능 (`python`).
- 생성 스크립트는 `tools/pixel/gen_<이름>.py` 로 저장하고 실행한다 (재현 가능해야 함).
- 모듈 임포트 (스크립트 첫머리에 고정):
  ```python
  import sys, os
  sys.path.insert(0, os.path.dirname(__file__))
  import palette as P
  from core import Canvas, strip, contact_sheet
  ```
- `Canvas.save(path)` 는 팔레트 위반 시 **예외**를 던지고, `<이름>.preview.png`(8배 확대)를 같이 만든다.
- **생성 후 반드시 preview PNG 를 Read 도구로 직접 보고** 형태를 비평·수정하라. 최소 2회 반복.
  (32px 원본은 작아서 안 보인다 — 반드시 .preview.png 를 볼 것.)

## 1. 캐릭터 규격

| 항목 | 값 |
|---|---|
| 프레임 캔버스 | **32 × 64** (보스만 64 × 64) |
| 발바닥 y | **62** (보스 62) |
| 본체 높이 | 48px (y 14~62). 갓/뿔 등 머리장식은 본체 위로 +6~10px |
| 중심축 x | **16** (보스 32). 모든 프레임에서 축 고정 — 프레임 간 흔들리면 안 됨 |
| 바라보는 방향 | **오른쪽** (게임에서 flip_h 로 좌우 전환) |
| 외곽선 | 1px, 검정 단색 금지 — 베이스보다 1~2단 진한 짝색 (`P.SHADE_OF` 참고). 한지 옷엔 `P.INK_SOFT` |
| 광원 | 좌상단 — 음영은 우/하단에 |

## 2. 출력 규약 (통합 단계가 그대로 읽는다 — 어기면 게임에 안 나옴)

캐릭터: `assets/sprites/<캐릭터>/<애님>.png` — **가로 스트립** (`core.strip(frames)`)
그리고 `assets/sprites/<캐릭터>/manifest.json`:
```json
{ "frame_w": 32, "frame_h": 64,
  "anims": { "idle": {"frames": 4, "fps": 5, "loop": true},
             "walk": {"frames": 6, "fps": 9, "loop": true},
             "attack": {"frames": 3, "fps": 12, "loop": false} } }
```

| 대상 | 디렉터리 | 필수 애님 (프레임 수 가이드) |
|---|---|---|
| protagonist | sprites/protagonist/ | idle(4) walk(6) jump(2) attack(3) attack2(3) attack3(4) charge(2) dodge(3) hurt(2) death(5) |
| goblin(도깨비) | sprites/enemies/goblin/ | idle(2) walk(4) attack(3) death(4) |
| fox(구미호) | sprites/enemies/fox/ | idle(4) walk(4) attack(3) death(4) |
| reaper(저승사자) | sprites/enemies/reaper/ | idle(4) walk(4) attack(3) death(4) |
| tiger(호환) | sprites/enemies/tiger/ | idle(2) walk(4) attack(3) death(4) |
| boss(호환 두령, 64×64) | sprites/enemies/boss/ | idle(4) walk(4) telegraph(2) attack(3) heal(3) death(6) |
| NPC 4종 | sprites/npc/<elder·blacksmith·woman·wanderer>/ | idle(2)씩 |

타일/소품: `assets/tilesets/<이름>.png` (32×32 단일 또는 `<이름>_atlas.png`+json)
배경: `assets/sprites/bg/<레이어>.png` (가로 타일링 가능해야 — 좌우 가장자리 연속)
UI: `assets/ui/<이름>.png` / 오디오: `assets/audio/sfx|bgm/<이름>.wav`

## 3. 시각 정체성 (STYLE_BIBLE §6 요약 + 추가)

- **주인공**: 갓(먹색, 넓은 챙) + 한지색 도포 + 청색 갓끈/세조대 + 환도. 떠돌이 무사의 피로감.
- **도깨비**: 뿔 1~2개, `P.RED_BASE` 피부 변형 금지 — 피부는 `P.WOOD_BASE` 계열, 방망이 들기.
- **구미호**: 여우 형태(4족 또는 반인), 꼬리 여러 갈래 실루엣 강조. `P.GOLD_BASE`+한지 톤.
- **저승사자**: 검은 도포+검은 갓, `P.INK` 계열만 + 창백한 `P.PAPER_BRIGHT` 얼굴. 떠 있는 느낌(발 생략 가능).
- **호환(호랑이)**: 4족 호랑이, `P.GOLD_BASE`/`P.GOLD_DEEP` 줄무늬 `P.INK_DARK`. 보스는 더 크고 흉터+핏빛(`P.RED_DEEP`) 눈.
- **금지**: 일본 요괴/중국 환수 모티프, 검정 단색 외곽선, 글로우/블러, 팔레트 외 색.
- 애니메이션: 프레임 간 변화는 팔다리·소품 2~4px 이동이면 충분. 과한 스쿼시 금지.

## 4. 검증 체크리스트 (제출 전 자가 점검)

1. `python tools/pixel/gen_<이름>.py` 가 예외 없이 끝난다 (팔레트 통과).
2. preview 를 Read 로 보고: 실루엣이 한눈에 읽히는가? 캐릭터가 무엇인지 3초 안에 알겠는가?
3. manifest.json 의 frames 수 × frame_w == 스트립 PNG 폭.
4. 모든 프레임에서 발바닥 y=62, 중심축 x=16 유지.
5. contact_sheet 로 전 프레임 한 장 시트를 만들어 마지막으로 확인.
