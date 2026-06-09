# 사람이 직접 해야 할 일 (HUMAN_TASKS)

> Claude(=AI)는 코드·문서·로직·다운로드 가능한 모든 자동 작업을 책임지고, 아래 항목들은 **시각 확인·외부 GUI 도구·계정/결제·법무·창작 결정** 등 정말 사람이 직접 해야 하는 일들만 둡니다.
> 일이 새로 생길 때마다 위쪽에 추가하고, 끝낸 건 `[x]`로 체크 + 완료 메모.
> 매 단계마다 "이거 진짜 사람이 해야 하나? 내가 할 수 있나?" 검수 후 등록 — 자동 가능한 건 즉시 처리.

---

## 진행 중

### 🅝 콘텐츠 확장 (A~F) PC 검증 — 맵 흐름·전투 손맛·퀘스트 라인·장비·낮밤 (Godot 에디터 필요)
- [ ] PC `git pull` → Godot 에디터 ▶ 재생 (MainMenu → '새로 시작' 누르면 Village 진입).
- [ ] **맵 흐름**: 마을 우측 베이지 LevelExit → 들판(녹빛) → 우측 다시 LevelExit → 숲(어두운 녹). 숲 우측에 빨간 LevelExit → 보스 아레나(검정 톤). 좌측 LevelExit 로 역귀환. 진입 시 SceneManager 페이드 인/아웃 자연스러운지.
- [ ] **NPC 3명 (마을)**: 어르신(첫 만남 → 쌀떡 3 + 호환 토벌 제안 → 수락하면 main_tiger_lord 시작) / 대장간 어르신(첫 대화에 사이드 완료 + 철검 1) / 아낙(첫 대화에 사이드 부적 시작). Q 키 퀘스트 로그에 항목 잡히는지.
- [ ] **사이드: 부적**: 숲에 들어가면 가운데에 빨간 작은 사각형 — 닿으면 잃어버린 부적 +1 + 콘솔 stage=found. 마을 아낙에 다시 E 누르면 '돌려준다' 선택지가 활성화. 보상 쾌혈환 x2.
- [ ] **메인: 호환 토벌**:
  - 숲 입장 직후 자동으로 단계 to_forest 진행 (콘솔에서 quest_changed 시그널 확인).
  - 보스 아레나 입장 시 boss_arena 단계로 전환.
  - 보스 처치 시 boss_defeated 단계 + 호환 어금니 x1 + 노란 +120 XP 부유 숫자.
  - 마을 어르신과 다시 대화하면 '어금니를 내민다' 선택지 → tooth_show → 보상 옥장도 x1 + 엽전 꾸러미 x2 → tiger_lord_resolved 플래그.
- [ ] **전투 손맛**: 적에게 J 빠르게 3번 → 콤보 1→2→3타. 3타에서 진동·hit-stop 강함. J를 길게 누르고 떼면 강타(데미지 2x). 명중 시 화면 살짝 흔들림.
- [ ] **적 변종**: 도깨비(녹색, 빠름) / 구미호(주황, 시야 넓음) / 저승사자(어두운 회색, 느림+질김) / 호환(주황 큰 박스, 빠른 추격). 각자 HP/속도 체감 다른지.
- [ ] **보스 패턴**: 텔레그래프(깜빡임 0.85s) → 돌진(빠른 좌/우 이동 + 정면 hitbox) → 회복 1.6s → 반복. 360 HP 정도.
- [ ] **장비**: I 키 인벤토리 패널에서 옥장도 옆 [장착] 버튼 → 이후 공격 데미지가 무기 정의값(18)을 베이스로 들어감. 갑옷도 마찬가지.
- [ ] **엽전(소지금)**: 메인 보상으로 엽전 꾸러미 2개 = 100문 + HUD 우상단 'Lv X · XP a/b · 엽전 N' 갱신.
- [ ] **낮/밤**: 약 4.5분 사이클. 시간 지나면 화면 전체가 푸르스름하게 어두워졌다가 새벽에 다시 밝아짐 (CanvasModulate). 게임 일시정지(Esc) 중에는 진행 멈춤.
- [ ] **GitHub Actions**: Settings → Actions 에서 'Godot Web Export' / 'Godot Headless Tests' 두 워크플로 PASS 확인. (실패 시 로그 캡처 부탁드립니다.)

### 🅜 Phase 3 시스템 PC 검증 — MainMenu/Quest/스탯/GameOver (Godot 에디터 필요)
- [ ] PC `git pull` → Godot 에디터 ▶ 재생 (`run/main_scene = MainMenu` 이므로 자동으로 메인 메뉴부터).
- [ ] **메인 메뉴**: '새로 시작' → 페이드 → TestLevel. '설정' → 슬라이더 만져보고 SFX 즉시 반응(파일이 있으면). '이어하기'는 슬롯 1 저장본 있을 때만 활성.
- [ ] **퀘스트(Q 키)**: TestLevel에서 Villager에 E 누르면 자동으로 '마을 어르신과 첫 인사' 퀘스트 시작. outro 도달 시 완료 + 쌀떡 ×3 자동 지급(I 키로 확인). Q 키로 퀘스트 로그에 '진행 중'→'완료' 이동 확인.
- [ ] **레벨/XP**: 좌상단 HUD에 'Lv 1 · XP 0/100'. Dummy/Patroller 처치 시 +8/+14 XP 노란 숫자가 떠오르고 HUD 갱신. 한 마리만 잡아도 LEVEL UP 직전. 임계치 넘으면 콘솔 'LEVEL UP → 2' + PICKUP SFX.
- [ ] **사망/Game Over**: 디버거 콘솔에서 `Player.health.take_damage(150)` 등으로 강제 사망 → 'GameOverScreen' 어두운 오버레이 + '이어하기 (마지막 저장)' (저장본 없으면 비활성) + '메인 메뉴로' 두 버튼. 이어하기 → 슬롯 1 로드 + 씬 리로드. 메인 메뉴 → MainMenu로.
- [ ] (선택) 헤드리스: `godot --headless res://tests/test_quests.tscn` → `=== 3/3 passed ===`.

### 🅚 Phase 2 시스템 PC 검증 — Save·Inventory·Flags·Pause·AI (Godot 에디터 필요)
- [ ] PC `git pull` → `TestLevel.tscn` ▶ 재생.
- [ ] **인벤토리(I 키)** — 패널 토글, 보따리 비어 있음 표시. Inventory.add 콘솔로 시연하려면:
  ```
  # Godot 디버거 콘솔에서:
  Inventory.add("rice_bun", 5)
  Inventory.add("potion_minor", 3)
  ```
  → I 키로 다시 열어 항목 보이는지 + '사용' 버튼 누르면 HP 바 +10/+30 회복하고 1개 차감.
- [ ] **대화 분기 + 플래그** — Villager NPC에 E. 첫 회 선택지 2개. outro 보고 닫힘. 다시 E 누르면 '또 뵙습니다.' 선택지 1개 추가됨(if_flag 'talked_to_villager').
- [ ] **AI Patroller** — TestLevel 오른쪽(x=1000)의 보라기 적이 좌우로 왕복(Patrol) → 가까이 가면 추격(Chase) → 멀어지면 Idle.
- [ ] **일시정지(Esc)** — 메뉴 뜨고 게임 멈춤. '저장(슬롯 1)' → 상태 '슬롯 1에 저장됨'. '계속하기' 누르면 다시 진행.
- [ ] **세이브 로드 round-trip** — 인벤토리에 뭐 넣고 Esc → 저장 → 게임 재시작 → 같은 슬롯 SaveManager.load(1) 호출(테스트는 디버거에서) → 인벤토리/HP/플래그 복원되는지.
- [ ] (선택) 헤드리스 자동 테스트:
  ```bash
  godot --headless res://tests/test_save.tscn
  godot --headless res://tests/test_inventory.tscn
  godot --headless res://tests/test_flags.tscn
  # 각각 3~4건 PASS, 종료코드 0 기대
  ```

### 🅛 오디오 파일 떨어뜨리기 (선택, 분위기 작업)
> Audio.play_sfx 호출은 이미 코드에 박혀 있고, 같은 이름의 파일이 없으면 조용히 무시. 파일만 두면 자동으로 들리기 시작.

- [ ] `assets/audio/sfx/` 에 다음 6개 짧은 wav/ogg 떨어뜨리기 (이름 정확히):
  - `attack.wav` — 공격 swing
  - `hit.wav` — 적 피격
  - `hurt.wav` — (선택) 플레이어 피격용 — 아직 hook 없음, 추후
  - `die.wav` — 사망
  - `pickup.wav` — 아이템 획득 (추후 hook)
  - `potion.wav` — 소모품 사용
- [ ] BGM은 `assets/audio/bgm/` 아래 두고 코드에서 `Audio.play_bgm("res://assets/audio/bgm/village.ogg")` 호출.
- [ ] AI/사용자 생성 음원 사용 시 라이선스 확인.

### 🅙 Phase 1-4 모바일 터치 컨트롤 PC/모바일 검증
- [ ] PC에선 키보드 동작은 그대로. TestLevel 재생 시 데스크탑에선 터치 버튼이 **숨겨져 있어야 정상** (DisplayServer.is_touchscreen_available() 기준).
- [ ] 폰 미리보기(web export): 우측 하단 점프(큰 원) · 공격(공격) · E(상호작용), 좌측 하단 ← / → 두 버튼이 떠있고 누르면 Player가 같은 동작 수행하는지.
- [ ] (선택) 디자인 폴리시: `assets/ui/touch_button.svg`(원형 placeholder) 자리에 한지·먹 톤의 실제 터치 버튼 텍스처 교체.

### 🅘 Phase 1-3 전투 시스템 PC 검증 (Godot 에디터 필요)
- [ ] PC `git pull` → Godot 에디터 `scenes/levels/TestLevel.tscn` ▶ 재생
  - 회색 Player + 갈색 NPC + 푸르스름한 Dummy 적 보이는지
  - Dummy 근처로 가서 `J`(공격) → Dummy가 옅은 빨강 깜빡 + 옆으로 살짝 밀리고 위로 살짝 떠오름 → 콘솔에 `[Dummy] HP 25 / 40` 식 출력
  - 3번 정도 더 때리면 Dummy `[Dummy] died` 출력 + 사라짐
- [ ] (선택) 헤드리스 자동 테스트:
  ```bash
  godot --headless res://tests/test_combat.tscn
  # 기대: === 3/3 passed === 종료코드 0
  ```

### 🅗 Phase 1-2 대화 시스템 PC 검증 (Godot 에디터 필요)
- [ ] PC에서 `git pull` 후 Godot 에디터 열기
- [ ] `scenes/levels/TestLevel.tscn` ▶ 재생
  - 회색 placeholder 사각형(Player) + 갈색 placeholder(Villager NPC) 보이는지
  - 플레이어가 NPC 근처에 갈 때 → `E` 키 → 대화창(`마을 어르신 — 어디서 왔는가, 젊은이?`) 뜨는지
  - 선택지 두 개 보이고, 클릭하면 다음 대사로 진행 → outro → 닫힘
- [ ] (선택) 헤드리스 자동 테스트:
  ```bash
  godot --headless res://tests/test_dialogue.tscn
  # 기대: === 4/4 passed === 종료코드 0
  ```
- [ ] UI가 아직 기본 폰트라 한글이 약간 못생기게 보일 수 있음 — Galmuri 임포트(`HUMAN_TASKS 🅐`) 후 다시 보면 정상.

### 🅖 Phase 1 골격 PC 검증 (Godot 에디터 필요)
> Claude가 입력맵·Player·TestLevel·헤드리스 테스트 골격까지 짜놨음. 한 번 PC에서 확인 + (선택) 헤드리스 자동 테스트 실행.

- [ ] PC Godot 4.x 에디터로 `~/projects/joseon-rpg` 프로젝트 열기 (또는 PC 작업 경로)
- [ ] `scenes/levels/TestLevel.tscn` 더블클릭 → 우상단 ▶ 재생 → 다음 동작 확인:
  - A/← 키로 왼쪽, D/→ 키로 오른쪽 이동
  - Space/W/↑ 키로 점프 (지면에서만)
  - 좌우 이동 시 placeholder 사각형이 flip (sprite.flip_h)
  - 카메라가 플레이어를 따라가는지
- [ ] (선택) 헤드리스 자동 테스트 실행:
  ```bash
  godot --headless res://tests/test_player_movement.tscn
  # 기대 출력: === 3/3 passed === 종료코드 0
  ```
- [ ] 이상 있으면 Claude한테 알려주기. 정상이면 위 체크박스 [x] + 한 줄 노트.

### 🅰️ Godot 폰트 임포트 설정 (PC Godot GUI 필요)
> 폰트 파일·라이선스는 AI가 quiple/galmuri 공식 배포본에서 받아 레포에 이미 포함시켰음 (`assets/fonts/Galmuri11.ttf` · `Galmuri9.ttf` · `OFL.txt` · `OFL-ko.md`). 다운로드 단계는 자동 처리 완료, 임포트 설정만 남음.

- [ ] PC Godot 4.x 에디터 열기 → `assets/fonts/Galmuri11.ttf` 클릭 → Import 탭 → `assets/fonts/README.md` §4 표대로 잠그고 Reimport
  - Antialiased: Off / Hinting: None / Subpixel: Disabled / Fixed Size: **11**
- [ ] 같은 작업을 `Galmuri9.ttf` 에도 (Fixed Size **9**)
- [ ] 자동 생성된 `.import` 파일들 commit & push (또는 Claude에게 시켜도 됨)

---

## 대기 (Phase 0 진행 따라 활성화)

### 🅑 AI 주인공 스프라이트 생성 (Step 4 프롬프트 나온 뒤)
- [ ] 생성 도구 한 개 고르기 — PixelLab(추천: 스켈레톤+애니메이션) / a1.art(스타일 일관성) / Midjourney·SDXL(스타일 톤만)
- [ ] 도구 계정·결제(있으면) 처리
- [ ] Step 4 프롬프트 세트로 후보 N장 생성 (5~10장)
- [ ] 가장 '조선풍' 한 1장 선택

### 🅒 도트 손보정 (Phase 0 핵심)
- [ ] 픽셀아트 에디터 1개 설치 — 옵션:
  - **Aseprite** (Steam/itch.io 약 $20, 사실상 표준) ← 권장
  - **LibreSprite** (Aseprite 무료 포크, 기능 거의 동일)
  - **Pixelorama** (무료·오픈소스·크로스플랫폼)
- [ ] 위에서 선택한 1장을 도구로 옮겨 보정 — 픽셀 정렬·`docs/STYLE_BIBLE.md` 팔레트 클램프·서브픽셀 깨짐 정리
- [ ] 완성본을 `assets/sprites/protagonist/idle.png` 같은 식으로 레포에 커밋
  > 팔레트 클램프(자동 색 강제)만 필요하면 Claude에게 시켜주세요 — Pillow 스크립트로 일괄 처리 가능. 손맛·자연스러움 보정은 사람이 필수.

### 🅓 시대·톤 확정 (Phase 0 끝)
- [ ] 첫 캐릭터 보고 시대 결정 (조선 초/중/말)
- [ ] 톤 결정 (진지 사극 / 코믹 / 괴담)
- [ ] HANDOFF.md, CLAUDE.md 의 "미확정" 표시 제거 → Claude에게 알려주면 갱신

---

## 운영 / 배포 결정 (Phase 1 진입 전후)

### 🅔 정적 호스팅 선택 (Phase 1 진입 시점)
- [ ] 어느 정도까지 공개할지 결정 (private 유지 vs public 전환)
- [ ] 호스팅 한 곳 선택 — 옵션:
  - **Cloudflare Pages**(무료, private repo도 OK, 한국 지연 양호) ← 1순위 추천
  - **Vercel**(이미 gnf에서 쓰고 있음. private 무료 가능, 익숙함의 장점)
  - **Netlify**(무료, 익숙)
  - **GitHub Pages**(무료지만 private 레포는 Pro 필요. public이면 가장 쉬움)
- [ ] 계정 연결만 해주시면 빌드 자동화(GitHub Action 또는 호스팅 자체 빌드)는 Claude가 잡음

### 🅕 라이선스 검수 (출시 직전)
- [ ] 사용한 AI 도구별 상업적 이용 라이선스 확인 (PixelLab/a1.art/Midjourney 등)
- [ ] 폰트 라이선스 파일 빌드에 동봉되는지 확인
- [ ] BGM·효과음 AI 생성 시 라이선스도 같은 절차

---

## 완료
> 작업이 끝난 항목은 `[x]` 체크 후 이쪽으로 옮겨 둠.

- [x] **폰트 파일 다운로드 + 라이선스 동봉** (2026-05-28) — Claude가 quiple/galmuri 공식 배포본에서 `Galmuri11.ttf · Galmuri9.ttf · OFL.txt · OFL-ko.md` 를 `assets/fonts/` 에 자동 배치. 사람 작업 불필요로 판명되어 자동 처리.
