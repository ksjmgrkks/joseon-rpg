# HANDOFF.md — 조선시대 도트 횡스크롤 RPG · 작업 인수인계

> **이 파일의 역할:** 컴퓨터든 폰이든 어느 기기에서 다시 시작하든, "무슨 게임을 만드는지 + 지금 어디까지 했는지 + 다음에 뭘 할지"를 한 번에 파악하게 해주는 인수인계 문서.
>
> **CLAUDE.md와의 차이:** `CLAUDE.md`=안 바뀌는 규칙/구조/스타일. `HANDOFF.md`=이 게임의 기획 + 매 작업마다 바뀌는 진행 상황.
>
> **Claude Code 운영 규칙:** ① 세션 시작 시 이 파일을 먼저 읽고 상황 파악 ② 작업을 마칠 때 "현재 상태/다음 할 일/완료 로그"를 갱신 ③ 갱신 후 git 커밋 & 푸시.

---

# 🎮 PART 1. 게임 기획 (무엇을 만드는가)

## 한 줄 소개
가상의 조선시대를 배경으로 한 **도트(픽셀아트) 횡스크롤 액션 RPG**. 모바일(휴대폰)용. 은은한 수묵·한지 톤의 미감.

## 컨셉 & 분위기
- **배경:** 가상의 조선풍 세계 (특정 시대는 미확정 — 첫 캐릭터/맵 제작 후 분위기 보고 확정)
- **톤:** 미확정 (진지 사극 / 코믹 / 괴담 중 첫 비주얼 보고 결정)
- **장르:** 횡스크롤 액션 RPG (좌우로 이동하며 진행, 전투 + 성장 + 스토리)
- **플랫폼:** 휴대폰. 개발 중 미리보기는 web export → 폰 브라우저. 터치 조작 전제.

## 비주얼 방향
- **세밀도:** 적당히 디테일이 살아있는 도트 (너무 미니멀하지도, 너무 고해상도도 아님)
- **캐릭터 높이:** 48px (권장 시작값, 첫 캐릭터 보고 조정 가능)
- **타일 크기:** 32x32
- **팔레트:** 제한 팔레트 24~32색, **은은한 수묵·한지 톤** (먹, 한지 베이지, 절제된 채도)
- **모바일 UI:** 터치 버튼은 손가락에 맞게 크게, 손에 가리는 화면 모서리 피하기

## 조선시대 고유 요소 (정체성 — 흔들리면 안 되는 부분)
- **복식:** 양반(도포·갓), 상민(저고리·패랭이), 관리(관복) 구분이 드러나게
- **건축:** 한옥 기와·초가·담장·대문 — 중국/일본풍 혼입 금지
- **문양/UI:** 단청·태극·한지 질감 등 한국적 모티프
- **적/몬스터:** 한국 설화 소재 우선 — 도깨비, 구미호, 저승사자, 호환(호랑이) 등
- **대사:** 사극체로 통일 (현대 말투 금지)
- **텍스트:** 한글 픽셀 폰트 별도 준비 필요 (깨끗한 렌더 확인)

## 기술 스택
- **엔진:** Godot 4.x — **GDScript 전용** (C# 금지: web export 불가)
- **렌더러:** Compatibility (모바일·웹 호환 최적)
- **배포:** 깃헙 레포 + web export(HTML5). 미리보기는 GitHub Pages 등 정적 호스팅.
- **개발 방식:** 폰(텔레그램+Claude Code) 중심 + 필요 시 PC. 시각 작업은 web export로 눈 확인.

## 핵심 시스템 (만들 것)
- 플레이어 이동/점프 (횡스크롤)
- 전투 (적 AI, 피격/넉백, 스킬 또는 콤보)
- 인벤토리 / 아이템 / 장비
- 세이브/로드
- 대화 / 퀘스트 시스템 (분기형으로 시작, LLM 연동은 추후 검토)
- UI/HUD (모바일 터치, 한지·먹 테마)

## 제작 단계 (로드맵 요약)
- **Phase 0** 스타일 바이블 — 주인공 스프라이트 1종 확정 (전체 스타일의 기준점)
- **Phase 1** 수직 슬라이스 — 주인공이 한 맵에서 걷고·싸우고·대화하는 10분 구간
- **Phase 2** 핵심 시스템 — 전투/인벤토리/세이브/대화 구축
- **Phase 3** 콘텐츠 양산 — 맵·적·스토리·사운드 확장
- **Phase 4** 폴리시 & 출시 — 밸런싱·버그·스토어

> 상세 로드맵은 별도 문서(`조선시대_도트_RPG_제작_로드맵.md`) 참조.

## 핵심 원칙 (반복해서 지킬 것)
1. **레퍼런스 우선** — 텍스트 프롬프트만으론 조선풍이 중국/일본풍으로 샘. 캐릭터 베이스 먼저 확정 후 그걸 기준으로 확장.
2. **스타일 먼저 잠그고 양산은 나중에.**
3. **AI 출력 = 초안.** 도트는 손보정 단계 필수 (일관성·서브픽셀 깨짐).
4. **수직 슬라이스부터.** 10분이 재밌은지 확인 후 양산.
5. **작게 쪼개기 + git 커밋으로 통제력 유지** (폰에선 코드 정독이 어려우므로).

---

# 📍 PART 2. 현재 상황 (어디까지 했는가)

## 현재 상태 (한 줄 요약)
> **지금 여기:** Phase 0~3 + 콘텐츠 확장 트랙 A~F까지 **아트 무관 영역 끝**. 맵 3종(마을·들판·숲) + 보스 아레나 + 입출구/명명 스폰, 적 변종 4종(도깨비·구미호·저승사자·호환) + 보스(호환 두령) 패턴, 메인 5단계 퀘스트(호환 토벌) + 사이드 2종(잃어버린 부적·대장간 인사), 콤보/차지/스크린쉐이크/히트스톱, 장비(무기·방어구)·소지금·낮밤 사이클, GitHub Actions Web export + 헤드리스 테스트 워크플로 자동화. 헤드리스 테스트 11종(40+ 케이스). **이제 사용자 손이 꼭 필요한 것:** ① 주인공 스프라이트 1장 생성·손보정(`HUMAN_TASKS 🅑·🅒`) ② PC Godot에서 폰트/씬 임포트 + 시각 검증(`🅖~🅜`) ③ (선택) SFX 파일 떨어뜨리기(`🅛`) ④ 시대·톤 확정(`🅓`) ⑤ GitHub Pages/Cloudflare Pages 호스팅 연결(`🅔`).

## 바로 다음 할 일 (Next Action)
> 1. ~~깃헙 레포 + Godot 골격~~ ✅
> 2. ~~Phase 0 자동 셋업 (CLAUDE 잠금·폰트·STYLE_BIBLE·프롬프트)~~ ✅
> 3. ~~Phase 1 시스템 골격~~ ✅
> 4. ~~Phase 2 핵심 시스템 (Save·Inventory·Flags·AI·Pause·Audio)~~ ✅
> 5. ~~Phase 3 게임 흐름 (SceneManager·MainMenu·Quest·Stats·GameOver)~~ ✅
> 6. ~~콘텐츠 확장 A~F (맵 다수·전투 콘텐츠·퀘스트 라인·장비/경제/낮밤·CI)~~ ✅
> 7. **사용자: 주인공 스프라이트 생성 + Phase 1/2/3 + 콘텐츠 확장 시각 검증** ← 사람만 가능
>    - a. `docs/PROMPTS_PROTAGONIST.md` 프롬프트로 AI 후보 5~10장 → 1장 선택 → Aseprite/LibreSprite로 손보정 → `assets/sprites/protagonist/idle.png` 커밋
>    - b. PC Godot 에디터 → 폰트 임포트 설정 + 메인 메뉴 ▶ → 마을→들판→숲→보스→귀환 흐름 + 인벤토리/장비/엽전/낮밤/콤보·차지·shake 시각 확인 (HUMAN_TASKS 🅖~🅝)
>    - c. 시대·톤 확정 → Claude에게 알리면 STYLE_BIBLE 잠금 + HANDOFF/CLAUDE 갱신
>    - d. GitHub Actions 워크플로 실행 결과 확인 (Settings → Actions → Web Export). Pages 배포까지 켤지 결정.
> 8. (사용자 a 완료 후 Claude) AnimationPlayer 연결: 걷기/점프/공격/콤보/사망 애니메이션 → 스프라이트 가져와 player.gd 연동.
> 9. (이후) 타일셋으로 placeholder 박스 교체 → BGM → 폰 미리보기.

## 대기 / 막힌 것 (Blocked / Waiting)
> - 캐릭터 스프라이트 에셋 없음 (Phase 0에서 생성)
> - 시대·분위기 톤 미확정 (첫 캐릭터 보고 결정)
> - 개발용 상시 환경(집 PC 원격 or 클라우드 서버) 결정 필요

---

# 🗂️ PART 3. 빠른 참조 & 진행 로그

## 프로젝트 정보
- **레포 주소:** https://github.com/ksjmgrkks/joseon-rpg (private)
- **메인 브랜치:** main
- **상세 규칙:** `CLAUDE.md` 참조 / **상세 로드맵:** `조선시대_도트_RPG_제작_로드맵.md` 참조

## 완료된 작업 로그 (최신이 위로)
> 작업 마칠 때마다 한 줄씩 위에 추가 (날짜 + 한 일).

- **2026-06-09** — 콘텐츠 확장 6 트랙 (사용자 지시: A~F 일괄). ① **C** 맵/씬 전환: SceneManager.change_scene_to(path,entry) + LevelExit/LevelEntry, Village/TestLevel/Forest/BossArena 4씬, 명명 스폰 마커. ② **B** 전투 콘텐츠: ScreenFx autoload(shake/hit_stop) + Player 콤보(1-2-3타)·차지(누르고 떼면 강타) + 적 변종 4종(도깨비/구미호/저승사자/호환) + 보스 호환 두령(텔레그래프→돌진→회복 패턴). ③ **A** 퀘스트 라인: 메인 main_tiger_lord(5단계, 사이드 부적·대장간 2종 포함), Pickup/QuestTrigger 제너릭 Area2D, 어르신 대화에 if_quest_stage 분기로 어금니 보고 노드 추가. ④ **D** 장비/경제/낮밤: Equipment autoload(weapon/armor 슬롯, 인벤토리 패널 [장착] 버튼) + PlayerStats.gold + HUD 엽전 표시 + TimeManager(낮/밤 270초 사이클) + WorldTint autoload(CanvasModulate 자동 갱신). ⑤ **E** CI: GitHub Actions 두 워크플로(Web export + 헤드리스 테스트 전체), export_presets.cfg Web 프리셋 포함. ⑥ **F** 테스트 +4종(test_scene 3건, test_questline 3건, test_equipment 5건, test_pickup_fx 4건) — 총 11종 40+ 케이스.
- **2026-05-29 (후속)** — Phase 3 아트 무관 시스템 4단계: ① SceneManager(페이드 인/아웃) + MainMenu + SettingsMenu(볼륨 슬라이더 3종) — `run/main_scene` 변경 (`5d2f75f` + fix `8d2d642`). ② QuestManager + QuestLog UI(Q 키) + 대화 quest action(start/set_stage/complete/give_item) + choice 조건(if_quest_active/completed/stage) — 샘플 villager 에 적용, rewards.items 자동 지급 (`05815c1` + fix `2bc5d61`). ③ PlayerStats autoload(레벨/XP 곡선) + FloatingNumber(부유 데미지/XP 숫자) + PlayerHud 에 Lv/XP 표시 + Dummy/Patroller xp_reward 통합 (`f73f976`). ④ GameOverScreen — 사망 시 이어하기(슬롯1 로드+리로드) / 메인 메뉴 선택 (`fb208ef`). 헤드리스 테스트 +1종(quests, 3건).
- **2026-05-29** — Phase 2 아트 무관 시스템 6단계: ① SaveManager autoload — JSON 슬롯·save_requested/loaded 시그널 패턴 (`e864b46`). ② Inventory + items.json(5종) + InventoryPanel UI(I 키 토글) — SaveManager 자동 연동 (`aeaf970`, fix `4107c7e`). ③ Flags autoload + Dialogue actions/if_flag 확장 — 'set_flag' 액션 + 'if_flag/unless_flag' 조건 choices, 샘플 villager에 적용 (`720dbf4`, fix `8c44b07`). ④ 적 AI 상태머신 — AIState·StateMachine·Idle/Patrol/Chase + Patroller 적 (`234541b`). ⑤ 일시정지 메뉴(Esc) + 인벤토리 소모품 '사용' 버튼 — process_mode=ALWAYS, 슬롯 1 저장 버튼 (`5d2d6dc`, fix `41ae097`). ⑥ AudioManager autoload + SFX 6종 상수 + 공격/피격/사망/포션 hook (`546dc8a`, fix `ec324ac`). 헤드리스 테스트 추가 3종(save·inventory·flags = 11건).
- **2026-05-28** — Phase 1 골격 5단계: ① 입력 매핑(5 액션) + Player(중력/이동/점프) + TestLevel + 헤드리스 테스트(`0cb8858`). ② NPC + 분기형 대화 시스템(autoload Dialogue/DialogueBalloon · 샘플 JSON · 테스트 4건) (`f3b7426`). ③ 전투 컴포넌트(Hitbox/Hurtbox/HealthComponent) + 공격 hitbox + Dummy 적 + 전투 테스트 3건 (`55c1cfd`). ④ 모바일 터치 컨트롤(TouchScreenButton 5종 · 데스크탑 자동 숨김 · 원형 SVG placeholder) (`ee1129c`). ⑤ Player HUD HP 바 (`83ff048`). 모두 푸시 완료.
- **2026-05-28** — Phase 0 자동 셋업 4단계: ① CLAUDE.md placeholder 잠금 ② Galmuri 픽셀 폰트(11/9) + OFL 라이선스 자동 다운로드·배치 ③ `docs/STYLE_BIBLE.md` v0 (팔레트 25색·48px 비율·아웃라인·음영·Aseprite 파이프라인) ④ `docs/PROMPTS_PROTAGONIST.md` (코어 + A/B/C 변형 + 도구별 호환 + 실패 패턴). `docs/HUMAN_TASKS.md` 신설·정제.
- **2026-05-28** — 깃헙 private 레포 생성 + Godot 4 GDScript 골격 푸시 (project.godot · 1280×720 landscape · GL Compatibility · Nearest 필터 · 폴더 구조 · README · CLAUDE.md · 로드맵 문서).

## 시스템별 진행 현황
- [x] 깃헙 레포 + Godot 프로젝트 셋업 (2026-05-28)
- [ ] 주인공 스프라이트 1종 (Phase 0 스타일 확정) — 사용자 작업 대기 (`HUMAN_TASKS.md` 🅑·🅒)
- [x] 플레이어 이동/점프 — 골격 완성, AnimationPlayer는 스프라이트 후 (2026-05-28)
- [x] 전투(기본) — Hitbox/Hurtbox/HealthComponent/Dummy/Patroller + 상태머신(Idle/Patrol/Chase) (2026-05-28~29). 콤보·스킬·다양한 적 비주얼은 추후.
- [x] 인벤토리/아이템 — InventoryManager·items.json(5종)·InventoryPanel(I 키)·소모품 사용 + Save 연동 (2026-05-29)
- [x] 세이브/로드 — SaveManager 슬롯 기반 JSON, Inventory/Flags/Audio 자동 연동, 일시정지 메뉴에서 저장 (2026-05-29)
- [x] 대화/퀘스트 — 분기 대화 + Flags(set_flag 액션·if_flag 조건) 통합 (2026-05-28~29). 본격 퀘스트 라인은 추후.
- [x] UI/HUD (모바일 터치) — HP 바 + 5개 터치 컨트롤 + 인벤토리 패널 + 일시정지 메뉴 (2026-05-28~29). 한지·먹 톤 스킨은 폰트 임포트 후.
- [x] 오디오 — AudioManager + SFX 호출 hook (파일 미존재 시 no-op) (2026-05-29). 실 사운드 파일 떨어뜨리는 건 사용자(`HUMAN_TASKS 🅛`).
- [x] 게임 흐름 — MainMenu → 새로 시작/이어하기 → TestLevel → 사망 시 GameOverScreen → 이어하기/메인 메뉴. 설정 메뉴 볼륨 슬라이더(Master/SFX/BGM). 일시정지 메뉴에서 슬롯 1 저장 (2026-05-29).
- [x] 퀘스트 — QuestManager + QuestLog(Q 키) + 대화 quest action·condition + rewards 자동 지급 (2026-05-29). 메인 5단계 main_tiger_lord + 사이드 2종 (2026-06-09).
- [x] 스탯/성장 — PlayerStats 레벨/XP 곡선 + FloatingNumber 부유 숫자 + HUD 레벨/XP/엽전 표시 (2026-05-29~06-09).
- [x] 맵/씬 전환 — SceneManager.change_scene_to(path, entry), LevelExit/LevelEntry, Village/TestLevel/Forest/BossArena 4씬 (2026-06-09).
- [x] 전투 콘텐츠 — 콤보(1-2-3)/차지/ScreenFx shake+hit_stop, 적 변종 4종 + 보스 패턴 (2026-06-09).
- [x] 장비/경제 — Equipment autoload(weapon/armor) · PlayerStats.gold · 인벤토리 [장착] 버튼 · Pickup 의 gold 환산 (2026-06-09).
- [x] 낮/밤 — TimeManager 사이클 + WorldTint(CanvasModulate) 자동 색감 변화 (2026-06-09).
- [x] CI — GitHub Actions Web export 워크플로 + 헤드리스 테스트 워크플로 + export_presets.cfg Web 프리셋 (2026-06-09).
- [ ] web export 빌드 + 폰 미리보기 — Actions 실행 결과는 자동, 폰 확인은 사용자 PC/모바일
- [ ] GitHub Pages 배포 — 워크플로에 주석으로 준비, Settings → Pages 에서 켜면 활성화

## 다음 세션에게 남기는 메모
- 폰(텔레그램+Claude Code)과 PC를 오가며 작업하므로 이 파일을 항상 최신으로 유지하는 게 생명줄.
- 시각 확인 필요한 작업은 "완료"로 단정하지 말 것 — web export 또는 PC로 눈 확인 필요하다고 메모.

## 세션 종료 체크리스트 (매번)
- [ ] "현재 상태" 한 줄 갱신
- [ ] "바로 다음 할 일" 갱신
- [ ] "완료된 작업 로그"에 이번 작업 추가
- [ ] git 커밋 & 푸시
