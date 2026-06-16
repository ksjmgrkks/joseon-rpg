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
> **지금 여기:** **1스테이지 튜토리얼화 + 컨트롤·대화·음악·배경 개선 (2026-06-12, 5차).** ① 기본 키 재배치: **공격 Ctrl, 점프 Alt, 상호작용/넘기기 Space**(+보조 X/W/E). ② 대화 교착 버그 해결(숨겨진 선택지로 advance 막히던 문제). ③ **1막을 퀘스트 받기 없는 튜토리얼 가닥으로 재구성**: 프롤로그→마을 어귀(이동·공격 튜토)→산기슭(점프·콤보)→깊은 숲(스킬)→절벽 보스. 각 구간은 **적을 모두 베야 결계(전투 게이트)가 풀려** 다음으로, 보스 처치 시 **곧바로 2막(고을)로 전환**. 퀘스트는 스테이지 진입 시 자동 시작(받으러 안 다님), 쓸데없는 사이드 퀘스트는 1막에서 비노출. ④ **BGM 전곡 재작곡**(드론→가야금 가락+굿거리/세마치/자진모리 장단). ⑤ 배경 한국화(보름달+동양화 구름띠). 전체 흐름 12 스테이지(튜토 3 + 산신당/절벽 + 고을 3 + 신산 3) 3막. 헤드리스 테스트 17종 그린, 월드 연결성 검증 OK.
> **이전(4차):** 대형 캠페인 확장 — 10 스테이지 3막. 데이터 기반 스테이지 빌더(`scripts/world/stage.gd` + `assets/stages/*.json`) 도입으로 스테이지 양산. 전체 동선: 타이틀→프롤로그→**[1막 산골]** 마을→들판→숲→산신당 터→절벽(호환 두령)→**[2막 고을]** 저잣거리→관아 동헌→폐사지→**[3막 신산]** 산길→제단(**최종보스 大虎/백호**)→엔딩. 스토리도 한 마을 비극 → 신산 산신의 진노가 고을·신산으로 번지는 大호환 서사로 확장(주인공=무당 단의 아들, 칼이 아닌 진언으로 산을 잠재움). 메인 퀘스트 2개(main_tiger_lord 5단계 + main_great_tiger 6단계). **월드 그래프 17개 출구 전부 연결 검증(tools/check_connectivity.py), 헤드리스 테스트 16종 그린, 완주 테스트 대호 캠페인 포함 4/4.**
> **이전(3차):** 버그·스토리·이펙트·콘텐츠 (2026-06-12). ① 점프 추락 버그 해결(지면 충돌 폭 정합 + 낙사 안전망). ② 스토리 부자(父子) 인연으로 전면 재설계(주인공=무당 단의 아들, 두령=한이 된 산군). ③ 스킬 이펙트 추가(일섬 참격·회천격 회전·호신부 부적 오라·적중 스파크, SkillFx). ④ 신규 스테이지 '산신당 터'(숲→산신당 터→보스, 구미호 회상·미니보스 팩·보물 궤짝). 전체 동선 타이틀→프롤로그→마을→들판→숲→산신당 터→보스→귀환→엔딩. **헤드리스 테스트 16종 그린.**
> **이전(2차):** 처음부터 끝까지 완주 가능한 게임 (2026-06-12, 2차). 타이틀 → **오프닝 프롤로그(호환 괴담 도입 5문단)** → 마을(어르신 퀘스트 수락) → 들판(약초·서찰 픽업) → 숲(적 5종) → 보스 아레나(두령 일갈→전투) → 마을 귀환(어금니 보고→어르신 고백) → 엔딩(사이드 완료수별 3분기) 까지 한 줄기로 연결. **엔드투엔드 통합 테스트(test_playthrough)로 메인 퀘스트 5단계 완주·부적→호신부 해금·엔딩 분기를 검증.** 이어하기는 저장 지역으로 복귀, 보스 귀환 동선 정합, 픽업은 아이콘+부유 연출. 헤드리스 테스트 15종 그린. 전투 밸런스(평타 ~7초로 보스 처치, 회피·호신부 여유) 수치 확인.
> **이전(1차) 반영분:** **완결 게임 + 1차 사용자 피드백 반영 완료 (2026-06-12).** Godot 4.6.3 / 「호환기담」 / 자체 제작 픽셀아트·사운드 전량. 타이틀→마을→들판→숲→보스→엔딩 한 바퀴 완결에 더해: **주인공 리디자인**(청 전복+홍 전대+금장 환도 — '밋밋함' 피드백 반영), **스킬 3종**(일섬 Lv3 / 회천격 Lv5 / 호신부=부적 퀘스트 해금, HUD 쿨다운 표시), **표준 키세팅**(X공격/Z·Space점프/C회피/1·2·3스킬) + **키 리바인딩 UI**(설정 메뉴, user://input.cfg 저장), **비장한 BGM 전면 재합성**(계면조 하강 선율+북·대금+5도 드론, 타이틀 서곡 신규), **스토리 3막 괴담**(산신당 방화의 업 — 어르신 고백·보스 일갈·상인 복선·**엔딩 3분기**). **헤드리스 테스트 15종 그린** (신규 test_skills 5건 포함). 모든 에셋은 `tools/pixel/`·`tools/audio/` 재현 스크립트 산출물.
> **남은 것(미감·실기기):** ① 손맛/애니 타이밍/전투 밸런스 — PC 실제 플레이 확인 ② **BGM 비장함이 귀에 맞는지** — 합성 구조상 비장하게 설계했으나 청감 판단은 사용자 몫 ③ 폰 미리보기(웹 빌드 호스팅 — itch.io 권장) ④ 픽업 아이템 스프라이트화·말풍선 한지 스킨(폴리시 여지).

## 바로 다음 할 일 (Next Action)
> 1~7. ~~Phase 0~3 + 콘텐츠/2차/3차 + 테스트 그린 + 4.6.3 마이그레이션 + 에셋 전량 + 게임 통합~~ ✅
> 8. ~~**1차 피드백 반영: 주인공 리디자인 / 스킬+키세팅+리바인딩 / 비장 BGM / 스토리(산신당 축)+엔딩 분기**~~ ✅ (2026-06-12)
> 9. **사용자: 실제 플레이 확인** — `플레이.bat` 더블클릭
>    - 새 키: X공격·Z점프·C회피·1/2/3스킬 (설정→키 설정에서 변경 가능)
>    - 확인 포인트: BGM 톤이 비장한지 / 스킬 손맛(레벨 3·5 해금, 호신부는 아낙 부적 퀘스트) / 보스전 입장 일갈 / 엔딩 분기(사이드 완료 수)
> 10. (다음 후보) 웹 빌드 itch.io 업로드 자동화(폰 플레이) / 픽업 스프라이트화 / 말풍선·패널 한지 스킨 마무리 / 전투 밸런스 패스

## 대기 / 막힌 것 (Blocked / Waiting)
> - **미감 최종 판단은 사용자 몫** — 스크린샷으로 정적 화면은 검증했으나 애니메이션 타이밍·손맛·전투 밸런스는 실제 플레이 필요.
> - web export 빌드 + 폰 미리보기 환경(호스팅) 결정.
> - **에셋 재생성 방법:** 모양이 마음에 안 들면 `python tools/pixel/gen_<카테고리>.py` 수정·재실행 → `--import` → 게임 반영. 팔레트는 `tools/pixel/palette.py`(STYLE_BIBLE 25색)에서 잠금.

---

# 🗂️ PART 3. 빠른 참조 & 진행 로그

## 프로젝트 정보
- **레포 주소:** https://github.com/ksjmgrkks/joseon-rpg (private)
- **메인 브랜치:** main
- **상세 규칙:** `CLAUDE.md` 참조 / **상세 로드맵:** `조선시대_도트_RPG_제작_로드맵.md` 참조

## 완료된 작업 로그 (최신이 위로)
> 작업 마칠 때마다 한 줄씩 위에 추가 (날짜 + 한 일).

- **2026-06-12 (6차 — 자율 고도화 전투/UX)** — /goal 자율. 감사(Explore) 후 임팩트순으로: ① **잡몹 근접 공격**(patroller — 예비동작→타격→넉백, 적별 차별, 거리판정으로 아군오사 없음) — 일방적 전투 해소. ② **대화 선택지 키보드 선택**(1~9 숫자/↑↓/Space, 번호 라벨·자동 포커스). ③ **적 처치 드롭**(회복약/엽전 확률, Pickup.spawn 팩토리). ④ **피격 무적시간(i-frame)+피격 피드백**(HealthComponent.invuln_on_hit, 플레이어 0.55s·붉은 깜빡임) — 무리 연타 공정성. ⑤ **메뉴 키보드 포커스**(Main/Pause/GameOver 자동 grab_focus) + 사망→게임오버 흐름 검증. ⑥ **전투 게이트 '남은 적 N' 표시**. ⑦ **저승사자 원거리 영혼 구슬 투사체**(SpiritOrb, 회피 가능) — 전투 다양성. 신규 테스트 6종(enemy_attack/dialogue_keys/drops/iframe/gameover/ranged), 전체 24스위트 그린.

- **2026-06-12 (3차 — 버그/스토리/이펙트/콘텐츠)** — /goal 4건. ① **추락 버그 수정**: 시각 흙바닥(2800px)보다 좁던 충돌 지면(1600px)을 2800 으로 정합 + player.gd 낙사 안전망(안전지점 상시 기록·y>1100 복귀)·종단속도 제한. test_fall_safety 2건. ② **스토리 전면 재설계 — 부자 인연**: 주인공=무당 단의 아들, 두령=사당 방화로 한이 된 산군. 프롤로그 6문단/어르신 고백/대장장이(아버지 환도)/아낙(사당 유물 부적)/상인(목격자)/보스 일갈/엔딩 전부 재집필(노드 ID 보존 → 테스트 유지). ③ **스킬 이펙트**: SkillFx autoload(코드 생성) — 일섬 참격 궤적·회천격 회전베기·호신부 부적 오라·적중 스파크. ④ **신규 스테이지 산신당 터**(숲→산신당 터→보스): 불탄 사당 프롭·구미호 영물 회상(아버지 이야기)·미니보스 팩(호랑이+도깨비2)·보물 궤짝. chest/shrine_ruin 프롭 생성, 저장/메뉴/BGM 통합. 테스트 16종 그린.

- **2026-06-12 (2차 — 처음부터 끝까지 플레이)** — /goal: 완주 가능한 하나의 게임으로 정비. ① **흐름 진단**(Explore 에이전트+전 씬 캡처): 씬 체인·퀘스트 5단계 전이가 엔딩까지 연결됨 확인, 결함은 보스 귀환 entry 불일치·이어하기 마을 고정·픽업 placeholder 정도. ② **오프닝 프롤로그**(Prologue.tscn — 호환 괴담 5문단 타자기, 스킵 가능 → 마을): 새 게임이 '스토리부터' 시작. ③ **이어하기 복귀 지역**(저장 메타 area→씬 역매핑), **보스 귀환 from_boss 정합**. ④ **픽업 스프라이트화**: 부적/약초/엽전/서찰 16px 아이콘(gen_pickups.py) + pickup.gd icon 자동부착·부유, 색박스 7곳 교체. ⑤ **엔드투엔드 통합 테스트**(test_playthrough 3건): 메인 5단계 완주·부적→호신부·엔딩 3분기. ⑥ 전투 밸런스 수치 확인(보스 380HP를 평타 ~21타/약7초, 회피·호신부 여유 — 완주 가능). 테스트 15종 그린.

- **2026-06-12 (스킬·키·음악·스토리)** — 사용자 피드백 4건 일괄 반영. ① **키 표준화**: 공격 J→X, 점프+Z, 회피+C, 스킬 1/2/3 신설 + **키 리바인딩 UI**(설정 메뉴, InputConfig autoload 가 user://input.cfg 저장·충돌 자동 제거·기본값 복원). ② **스킬 3종**(SkillManager autoload + assets/data/skills.json): 발도 일섬(1, 돌진 강타 1.8x, Lv3), 회천격(2, 앞뒤 타격+넉백, Lv5), 호신부(3, 피해 1회 무효, 부적 퀘스트 해금 — charm_blessing). HealthComponent.shield_charges, HUD 스킬 줄(잠김/쿨다운), 모바일 터치에 회피+스킬 버튼. ③ **BGM 비장하게 재합성**: 계면조 하강 선율 + 북(법고)/대금 보이스 + 5도 드론 — village 32s/forest 심장박동/boss 전고 19.2s/title 서곡 24s 신규(MainMenu·Ending 매핑). ④ **스토리 — 산신당 괴담 축**: 어르신 고백 2노드(스무 해 전 산신당 방화 = 두령의 정체), 보스전 입장 시 두령 일갈(AutoDialogue 트리거+boss_intro_seen), 떠돌이 상인 정체 복선 2노드, 부적 반환→가호 해금 연결, **엔딩 3분기**(사이드 0/일부/전부 완료별 문단). SceneManager.transitions_enabled 테스트 시임 추가. 테스트 15종(신규 test_skills 5건 포함).

- **2026-06-11 (자율 대작업 — 실제 돌아가는 비주얼 게임)** — 사용자 지시 "4.6.3 마이그레이션 + 이미지 직접 생성·적용 + 처음부터 끝까지 돌아가는 게임 + 권한 안 묻고 쭉". ① **마이그레이션**: project.godot features 4.6 / CI GODOT_VERSION 4.6.3 / `.gitignore` 사이드카 커밋 전환 / CLAUDE·README·STYLE_BIBLE 버전·컨셉 잠금 / `.claude` 권한 allowlist + `/goal` 커맨드. ② **픽셀아트 파이프라인**: `tools/pixel/`(palette.py=STYLE_BIBLE 25색 강제·검증, core.py=Canvas/strip/contact_sheet, 저장 시 팔레트 검증+8x preview) + `tools/Screenshot.tscn`(윈도우드 임의 씬 PNG 캡처, --scene/--out/--cam/--night)로 시각 자체검증 루프 확립. ③ **에셋 전량 생성**(워크플로 asset-forge + 직접): 주인공 11애님·적 5종(도깨비·구미호·저승사자·호환)·보스 호환두령(telegraph/heal 포함 6애님)·NPC 4종·타일&소품(기와집/초가집/우물/장승/솟대/소나무/등롱)·수묵 산수 배경 3겹·한지 UI 스킨·SFX 10+BGM 4(`tools/audio` 순수 파이썬 신디사이저). 세션 한도로 누락된 도깨비/구미호/보스는 직접 작성(구미호 꼬리 빈약 → 재작업). ④ **통합**: SpriteDb(manifest→SpriteFrames)·CharacterVisual·PlayerVisual·EnemyVisual·BgmDirector autoload, 적/NPC 씬 placeholder→AnimatedSprite2D 배선, 레벨 4종에 ParallaxBackdrop+타일 지면+한옥·소품 드레싱, 타이틀(로고+산수)·엔딩(두루마리 타자기) 완성, 대화 change_scene 액션으로 보스 처치→엔딩 연결. ⑤ Hitbox 게이트(이전 세션 layer 전환)·has_flag 타입분기 유지. 헤드리스 13종 52케이스 그린 유지. 스크린샷으로 타이틀·마을·들판·숲·보스·엔딩 전부 검증. **미감·손맛은 사용자 실플레이 확인 대기.**
- **2026-06-11 (테스트 전면 수리 + 4.6 호환)** — 헤드리스 스위트가 실제로는 절반쯤 좌초돼 있던 것을 발견·복구, **13종 52케이스 전부 통과** (로컬 Godot 4.6.3). ① 좌초 원인: (a) 대화 드레인 `while Dialogue.is_active(): advance()` 가 choices 노드에서 무한 루프(advance 는 choices 노드에서 no-op) — 테스트 4파일 11곳을 `_drain_dialogue()` 헬퍼(첫 선택지 고르기 + 32스텝 상한)로 교체. (b) Godot 4.4+ 파서 강화: 코루틴을 await 없이 호출(test_equipment/pickup_fx/scene)과 `var x := max(...)`/`var ok := dict.v and ...` Variant 추론(time_manager→`maxf`, test_combat→타입 명시)이 파스 에러 → 스크립트 로드 실패 → quit() 없는 빈 씬으로 타임아웃. (c) `has_flag` 의 `v == false or v == 0` Variant 교차 비교가 4.4+ 런타임 에러 — 타입별 분기로 재작성. ② **Hitbox 게이트 교체(전투 핵심 픽스)**: monitoring/monitorable 토글 게이트는 4.4+ 브로드페이즈에서 겹친 채 재활성 시 페어를 안 만들어 *정지 상태 공격이 헛스윙* — `collision_layer` 0↔1 게이트로 변경(hitbox.gd + boss.gd 수동 토글 2곳). 회피 무적 사이클(영구 무적 없음)과 밤 NPC 걸어들어오기 감지는 프로브로 확인. ③ 낡은 단정 2건: test_flags 필터링(샘플 JSON 3번째 선택지가 Phase 3에서 quest 게이트로 변경됨 — village_woman 의 if/unless_flag 로 재작성), test_questline 부적 반납(A2 약초 선택지 추가로 choose(1) 위치 어긋남 — 텍스트 기반 선택). ④ **test_polish 신규 10건** (H 자동저장 슬롯 0/메뉴 제외/토글, I 토스트 시작·완료/단계 침묵, J HP 바 표시·비율·자동 숨김, K NightOnly 초기화·페이즈 토글). ⑤ project.godot `flush_stdout_on_print=true`, .gitignore 에 `*.uid`/`*.import`(버전 확정 전 미커밋 방침).
- **2026-06-10 (3차 폴리시 — 전 세션 커밋 `40c7e41`, HANDOFF 반영 누락분)** — ① **H** 씬 전환 자동 저장: SceneManager._do_change 가 떠나기 전 슬롯 0(autosave) 저장, MainMenu/SettingsMenu 는 NON_GAMEPLAY_SCENES 로 제외. SlotPicker load 모드에 슬롯 0('자동 저장') 노출, MainMenu '이어하기' 활성 조건을 슬롯 0~3 으로 확대. ② **I** QuestToast autoload: quest_changed 를 듣고 시작/완료만 상단 토스트(2.4초 페이드), 단계 전이는 침묵. ③ **J** EnemyHpBar: patroller/dummy/boss 가 attach_to 로 동적 부착, 피격 시 2초 표시 후 숨김(보스는 y 오프셋 상향). ④ **K** NightOnly 노드 + 떠돌이 상인 NPC(Village, 밤 전용 등장, 야시장 open_shop 대화).
- **2026-06-09 (2차 확장)** — A~F 후속 6 트랙. ① **E2** 저장 슬롯 멀티: SaveManager.save 가 area/level/gold 메타 동봉, SlotPicker UI(load/save 양모드, 3 슬롯, 카드별 요약), MainMenu '이어하기'·PauseMenu '저장' 이 picker 호출. ② **D2** 상점: ShopManager autoload + ShopPanel UI(좌 구매·우 판매, 판매가는 정가 50%, 퀘스트 아이템 판매 차단), 대화 액션 `open_shop`, 대장간 어르신이 tiger_lord_resolved 이후 상점 해금. ③ **B2** 전투 폴리시: 회피 구르기(Shift, 무적 + dash + 0.6s 쿨다운), 보스 페이즈 2(HP ≤ 50% 에서 텔레그래프 0.70x · 회복 0.55x · 데미지 1.25x + 핏빛 톤). ④ **A2** 사이드 퀘스트 2종 추가(약초 5포기 수집·들판 서찰), Dialogue 조건 `if_has_item`/`if_inventory_at_least`, 액션 `take_item` 신규. ⑤ **F2** Locale 스캐폴드(ko/en JSON, MainMenu 시범 적용, locale_changed 시그널). ⑥ **C2/G2** 검증: 현 placeholder 박스가 사실상 ColorRect 기반 grid 역할을 수행 — 실제 TileMap 마이그레이션은 타일 텍스처 도착 후 사용자 PC에서. 헤드리스 테스트 +1종(test_shop_slots, 3건).
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
- [x] 폴리시 — 씬 전환 자동저장(슬롯 0) + 퀘스트 토스트 + 적 HP 바 + 밤 전용 NPC/야시장 (2026-06-10).
- [x] 헤드리스 테스트 — 13종 52케이스 그린. 좌초 6종 수리 + Godot 4.4+/4.6 호환 정비 + Hitbox layer 게이트 (2026-06-11).
- [x] 스킬 — 일섬/회천격/호신부 (쿨다운+레벨·퀘스트 해금) + HUD/터치 + 키 리바인딩 UI (2026-06-12).
- [x] 스토리 — 산신당 괴담(어르신 고백·보스 일갈·상인 복선) + 엔딩 3분기 (2026-06-12).
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
