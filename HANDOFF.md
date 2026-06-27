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
> **지금 여기:** **전투 마무리 VFX + 배경 비주얼 개선 (2026-06-27, 15차).** 사용자 요청("추천(VFX 마무리)대로 + 배경/맵 비주얼 개선"). **모두 순수 GDScript(코드)라 PNG/PIL 재생성 불필요 — Godot로 열어 플레이하면 바로 보임.** ① **전투 마무리 VFX**: `skill_fx.gd` 에 4종 신규 — `charge_aura_tick`(차지=기 모으기 오라, 주변 기운이 중심으로 빨려드는 마름모 알갱이+수축 링, 완전차지 시 금빛), `hit_flash`(피격=흰빛 과노출 번쩍→핏빛→원색, 논블로킹 트윈), `death_scatter`(사망=핏빛 대신 창백한 '혼 흩어짐' — 넋 알갱이 위로 흩어짐+솟는 넋 줄기+바닥 먹 번짐 링, 은은한 괴담 톤), `boss_entrance`(보스 첫 교전 시 1회 — 바닥 마기 솟구침+먼지 링+머리 위 마기 무리+화면 흔들림). 배선: `player.gd` 차지 틱마다 오라, `patroller/dummy.gd` 피격 플래시·사망 흩어짐, `boss.gd` 첫 교전 등장 연출·피격 흰빛·사망 흩어짐. `tools/FxPreview.gd` 에 신규 4종 미리보기 추가. ② **배경 개선**: `parallax_backdrop.gd` 전면 업그레이드 — 밋밋한 단색 하늘→**세로 그라데이션**(상단 하늘색 60% 유지→지평선 한지빛), **떠다니는 구름**(코드 드로잉 타원 구름 5송이, 별도 레이어라 산은 안 움직이고 구름만 느리게 흐름), **대기 원근**(먼 산일수록 하늘색으로 흐려 깊이감), **야간 분위기**(하늘 휘도<0.55 인 폐사지·제단·숲 등에 별/반딧불이 깜빡임+떠다님 — 푸른 하늘=별, 녹빛=반딧불). 모두 stage JSON 의 기존 `backdrop.sky/tint` 그대로 활용, 새 export(`aerial/cloud_drift/night_luminance`)로 조절. ③ **배경 아트 자체 풍부화**(추가 작업): `tools/pixel/gen_background.py` 개선 — 최원경 능선 1겹(25% 디더)·구름띠 3겹·먼 하늘 새 떼·근경 납작돌·풀잎 밀도↑·소나무 1그루↑. 기존 팔레트만·주기 W 타일링 유지, `py_compile` 통과. **이 PNG 는 PIL 필요 → PC에서 `python tools/pixel/gen_background.py` 재생성해야 반영**(폰 세션 PIL 없음). **검증: 이 환경엔 Godot·PIL 없음 → 코드 작성·문법/정적 점검만. 실제 렌더/타이밍/미감은 PC 플레이+재생성 후 확인 대기.**
> **이전(14차):** **PixelLab VFX 퀄리티 업 — 3타 모션 재생성 + 페인티드 이펙트 + 몬스터 출혈 (2026-06-27, 14차).** PixelLab **구독 활성(2000 gen 확인, 트라이얼 아님)** → 비싼 오브젝트 VFX도 가능. ① **3타 모션**: 캐릭터 `attack3_spin_v2`(13f, 도약→머리 위→내려찍기 역동 강화)를 v3 재생성. `tools/pixel/integrate_combos.py` 의 attack3 항목을 새 UUID/13f 로 교체 → **PC에서 `python tools/pixel/integrate_combos.py` 실행해야 strip/manifest 반영**(현재 repo는 기존 11f strip 유지, 정합 상태). ② **페인티드 이펙트**: PixelLab 1방향 sidescroller 오브젝트로 VFX 7장 생성→`assets/sprites/fx/`(slash_crescent/swirl/wide, thrust_lance, spark_star/burst, blood_splat/spray). `skill_fx.gd` 에 `_fx_tex`(지연로드·캐시)·`_painted`(스케일업·회전·드리프트·페이드) 헬퍼 추가하고 **콤보1(창격)/2(횡소)/3(소용돌이)·일섬·회천격·적중 임팩트·궁극기(귀창 강림: 바닥 부적 진법 rune_circle + 데몬 폭발 ult_burst)**에 페인티드 '주역' 레이어를 합성(기존 코드 드로잉 디테일은 보조로 유지). **텍스처 미존재 시 자동 폴백**(autoload 안 깨짐). ③ **몬스터 출혈**: `SkillFx.bleed()` 신규(핏방울 스프레이+작은 얼룩, 은은한 괴담 톤 맞춰 절제) → `player.gd` 적중(`_on_hitbox_landed`)·궁극기 루프에 배선. **검증: WSL엔 Godot 없음 → VFX 후보는 PixelLab MCP 프리뷰로 눈 확인(채택만 다운로드), 인게임 합성/타이밍/3타 손맛은 PC 확인 대기. PixelLab ~175 gen 사용(잔여 ~1825).**
> **이전(13차):** **조작 손맛 1차 — 점프/이동 게임필 + 공격 런지 (2026-06-27, 13차).** "푸시 후 조작 손맛 작업" 방향. `scripts/player/player.gd` 에 액션 플랫포머 표준 손맛 7종 추가: ① **코요테 타임**(0.10s — 발판 떠난 직후에도 점프 구제) ② **점프 버퍼**(0.12s — 착지 직전 입력 기억 후 즉시 발동) ③ **가변 점프**(상승 중 점프 떼면 상승속도 0.45배 컷 → 단타/풀점프 구분) ④ **묵직한 낙하**(하강 시 중력 1.45배, 상승 중 점프 뗀 구간 1.9배 → 붕 뜨는 느낌 제거) ⑤ **가속/마찰 이동**(즉시 스냅 폐기 → 지상 2400·공중 1500 가속, 반대방향 전환 시 +마찰로 칼전환, 정점 부근 공중제어 보너스) ⑥ **공격 런지**(콤보 70/3타 130/강타 150 전방 1회성 임펄스 — move_toward 가 자연 감쇠, 누적 버그 회피) ⑦ **착지 흔들림**(낙하속도 360+ 일 때만 가벼운 shake). 되돌리기: 추가한 const/블록만 제거. **검증: 로컬 Godot 헤드리스(`test_player_movement` 신규 2케이스 variable_jump/coyote_jump 포함) + 실제 플레이 손맛은 사용자 확인 대기(이 환경엔 Godot 없음).**
> **이전(12차):** **게임성 우선 — 스토리/대화/NPC 제거, 전투-클리어 전용 모드 (2026-06-18, 12차).** "스토리는 나중, 지금은 몬스터 잡고 클리어만" 방향. ① **`stage.gd`에 `GAMEPLAY_ONLY` 모드 추가**: NPC·자동대사·퀘스트 트리거·스토리 픽업·auto_quest 를 빌드하지 않고, **전투 스테이지 직선 체인**(foothills→forest_deep→ruined_temple(구미호 여왕)→mountain_pass→sacred_altar(대호 보스))을 따라 **전진 차단 결계(적 전멸 시 자동 개방)+전진 출구**만 합성. 마지막 스테이지는 **Clear 화면**으로 연결. (마을/고을 허브 스킵.) **되돌리기: `GAMEPLAY_ONLY=false` 한 줄이면 기존 스토리 데이터 흐름 전부 복구.** ② **MainMenu 간소화**: 제목·로고·컨셉 부제 숨김, '새로 시작'→프롤로그 대신 곧장 첫 전투 스테이지, '이어하기'·설정 유지. ③ **`Clear.tscn`(클리어 화면)** 신규 — 스토리 엔딩 대체, 다시 도전/처음으로. ④ 유지 시스템(사용자 선택): 인벤토리·장비, 세이브/로드, HUD 스킬바·쿨다운 + 전투/스킬/드롭. 제거(코드는 보존, 미사용): 대화·NPC·퀘스트·상점·프롤로그·엔딩·타이틀 컨셉. **검증: 헤드리스 31/31 그린(신규 test_gameplay_chain 포함) + 메뉴·스테이지·클리어 스크린샷.** (전투 손맛·밸런스 polish 는 이제부터 실제 플레이로.)
> **이전(11차):** **주인공 공격 모션 역동화 + 이펙트 강화 (2026-06-18, 11차).** "기본 공격 모션·이펙트가 아쉽다" 피드백 반영. ① **콤보 1·2·3타를 각기 다른 역동적 PixelLab v3 애니로 재생성**: attack(폭발 전진 찌름 9f)·attack2(횡쓸기 9f)·attack3(도약 회전 내려찍기 11f)·charge(기 모으기 7f 루프) — 기존엔 셋이 같은 찌름 재사용이던 것을 분리. ② **이펙트 강화**: `skill_fx.gd` 전면 업그레이드(찌름=창대+보랏빛 마기+속도선+창끝 섬광, 횡쓸기=3겹 초승달+꽃잎 스파크, 회전=2겹 링+12방 마기 가시+지면 먼지, 일섬/회천격/임팩트/궁극기 다층화) + **캐릭터 잔상(afterimage) 트레일** 신규(콤보·차지·일섬·회천격·궁극기·회피에서 현재 프레임 복제 색조 잔상 → 새 아트가 모션에 살아남). ③ **크레딧 현실 메모**: PixelLab '오브젝트(VFX 스프라이트시트)'는 1개당 20~40 generations이라 트라이얼(잔여 26)로 비현실적 → 이펙트는 코드+잔상으로, 모션은 PixelLab(애니 1~2gen)으로. **트라이얼 14/40 소모(26 잔여).** 검증: **헤드리스 30/30 그린 + FX 미리보기·콤보 포즈 스크린샷**. (손맛·타이밍 최종 미감은 실제 플레이 판단.)
> **이전(10차):** **PixelLab MCP 주인공 아트 교체 완료 (2026-06-18, 10차).** 코드생성 미감 한계로 외부 AI 전환 — PixelLab MCP 로 **측면(side-view) 조선 마창 무사**("Joseon Spearman", ID `f5fd2830…`, 4dir/side/92px) 생성. **먼저 캐릭터 1개로 옆모습(east 우향 프로필+창)·크레딧 확인** 후 진행. **생성 6종(east 1방향, 좌향은 코드 flip_h):** idle(breathing-idle)·walk(walking-6-frames)·jump(jumping-1)·hurt(taking-punch)·death(falling-back-death) 템플릿 + attack(v3 창 찌름). **파생(무크레딧) 5종:** run(=walk 가속)·attack2/attack3(=attack 재사용, 콤보 차별은 SkillFx 유지)·charge(=attack 윈드업 홀드)·dodge(=jump 웅크림/착지 발췌). 통합 스크립트 `tools/pixel/integrate_pixellab.py`(zip→92×92 스트립+manifest, foot_offset −28 산출=콜리전 바닥 +16 정렬), `player_visual.gd` foot_offset −21→−28. **트라이얼 크레딧 7/40 소모(33 잔여).** 검증: **헤드리스 30/30 그린 + 인게임 마을 스크린샷(발 접지·우향 확인)**. (최종 미감·로브 색감(거의 흑색, 수묵톤보다 어두움)은 실제 플레이 판단.)
> **이전(9차):** **주인공 외모·창 휘두름 개선 (2026-06-17, 9차).** "못생겼다 / 창이 작아진다" 피드백 반영. ① **창 작아짐 해결**: 프레임 폭 32→48px 확장(창 잘림 방지) + **각도 기반 일정 길이 창**(spear_angle/SPEAR_LEN=24) — 찌르기는 창을 평행이동(물미 후퇴), 횡쓸기·회전은 각도만 회전+sweep 잔상. 모든 공격 프레임에서 창 길이 불변. ② **얼굴 리디자인**: 잘려나간 코·눈썹 덩어리·뺨 청색 얼룩 정리 → 또렷한 almond 눈+얇은 눈썹+매끈한 콧대+좌상 광원 음영, 갓끈은 얼굴 밖 드리움. 갓(黑笠) 모정/챙 음영 정돈, 목 보강. 몸은 CX=24 중앙 정렬(전 부품 CX 상대좌표 → 자동 재배치). **헤드리스 30종 그린, 전 애니 스트립+인게임 스크린샷 확인.** (최종 미감은 실제 플레이 판단.)
> **이전(8차):** **주인공 모션 전면 고도화 (2026-06-17, 8차).** "모션이 조잡하다"는 피드백 반영 — 전 10종 애니메이션을 프레임 증량 + 애니메이션 원칙(예비동작·따라가기·무게이동·2차 모션)으로 재작업. 보행 6→8(정식 사이클: 접지/통과 무게이동, 발끝 들림, 자락·팔·창 카운터 스윙, 진행방향 lean, 갓 1박자 지연), 대기 4→6(들숨/날숨+창 홍술 살랑임), 도약 2→3(상승/정점/하강+velocity 매핑), 찌르기 3→5·횡쓸기 3→5·회전내려찍기 4→6(예비→타격→여운→회수, 런지·풍압·궤적 잔상, 3타 홍 궤적), 차지 2→3·구르기 3→4·피격 2→3. **헤드리스 30종 그린, 스트립·인게임 스크린샷 확인.** (손맛·타이밍 최종 미감은 실제 플레이 판단.)
> **이전(7차):** **「귀창록」(鬼槍錄) 리브랜딩 — 창 마검사 컨셉 (2026-06-17, 7차).** 제목을 호환기담→**귀창록**으로 바꾸고 주인공을 **마창(魔槍)을 든 자**로 재정립. ① **창(spear) 컨셉**: 주인공 스프라이트 무기를 환도→창으로 전면 재생성(자루+강철 창날+홍 술), 기본 콤보 1·2·3타를 **직선 찌름 / 넓은 횡쓸기 / 회전 내려찍기**로 모션·이펙트 차별화(SkillFx.combo), **3타 1.6배 추가 피해+홍 궤적**. ② **궁극기 4번 '귀창 강림'**(쿨 40s, 3.5배 광역, 화면 섬광+충격파 링+12방 영혼창 — SkillFx.ultimate). ③ **NPC 상호작용 제거**: 스토리 진행 따라 대화 자동 재생(auto_dialogue 트리거), **대화 중 적 전원 정지**(state_machine/patroller/boss/spirit_orb 동결). ④ **시간 경과 자연 회복**(HealthComponent.regen, 피격 6s 후 초당 2.5). ⑤ **보스 다양화**: 호랑이에 묶이지 않게 **구미호 여왕(폐사지)·저승 군주(관아)** 중간보스 2종 추가 + 등장 자동 대사. ⑥ **세계관 통합**: 호환(虎患)→**호귀(虎鬼, 한 서린 범의 넋)**, 최종보스 대호→**호귀로 화한 산군(山君)**으로 재해석(에셋 유지). 프롤로그/에필로그/크레딧 마창·귀(鬼) 테마 재작성. **헤드리스 테스트 30종 그린, 전 스테이지 스크린샷 확인.** (전투 손맛·밸런스·미감은 실제 플레이 판단 영역.)
> **이전(6차):** **자율 고도화 — 전투 깊이·공정성·UX·경제·정합 (2026-06-12, 6차).** 잡몹이 실제로 공격(근접/저승사자 원거리 투사체)하고, 피격 무적·드롭·레벨업 회복·저체력 경고로 전투가 양방향이며 공정. 대화 선택지·메뉴 키보드 조작, 전투 게이트 '남은 적' 안내, 보스 돌진 '!' 경고, 산기슭 행상(엽전 사용처), 클리어 구간 재진입 무결성. **헤드리스 테스트 26종 그린, 월드 연결성 OK.** (전투 손맛·밸런스·음악 청감은 실제 플레이 판단 영역.)
> **이전(5차):** 1스테이지 튜토리얼화 + 컨트롤·대화·음악·배경 개선. ① 기본 키 재배치: **공격 Ctrl, 점프 Alt, 상호작용/넘기기 Space**(+보조 X/W/E). ② 대화 교착 버그 해결(숨겨진 선택지로 advance 막히던 문제). ③ **1막을 퀘스트 받기 없는 튜토리얼 가닥으로 재구성**: 프롤로그→마을 어귀(이동·공격 튜토)→산기슭(점프·콤보)→깊은 숲(스킬)→절벽 보스. 각 구간은 **적을 모두 베야 결계(전투 게이트)가 풀려** 다음으로, 보스 처치 시 **곧바로 2막(고을)로 전환**. 퀘스트는 스테이지 진입 시 자동 시작(받으러 안 다님), 쓸데없는 사이드 퀘스트는 1막에서 비노출. ④ **BGM 전곡 재작곡**(드론→가야금 가락+굿거리/세마치/자진모리 장단). ⑤ 배경 한국화(보름달+동양화 구름띠). 전체 흐름 12 스테이지(튜토 3 + 산신당/절벽 + 고을 3 + 신산 3) 3막. 헤드리스 테스트 17종 그린, 월드 연결성 검증 OK.
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
> 10. ~~**6차 자율 고도화: 전투 양방향화·UX·경제·정합 (26종 그린)**~~ ✅ (2026-06-12)
> 11. ~~**7차 「귀창록」 리브랜딩: 창 마검사(1·2·3타 차별+3타 추가피해)·궁극기 4번·자동 대화/적 동결·자연 회복·보스 다양화(구미호 여왕/저승 군주)·호귀/산군 세계관 (30종 그린)**~~ ✅ (2026-06-17)
> 12. **사용자: 실제 플레이 확인** — `플레이.bat` (공격 Ctrl·점프 Alt·상호작용/넘기기 Space·회피 Shift·스킬 1/2/3·**궁극기 4**). 확인 포인트: 창 콤보 1·2·3타 손맛/이펙트, 궁극기 화려함, 자동 대화 흐름, 보스 다양성.
> 13. (다음 후보) 신규 스테이지 추가 / 창 전용 장비 아이템 / 웹 빌드 itch.io 업로드 자동화(폰 플레이) / 말풍선·패널 한지 스킨 / 전투 밸런스 패스
> 14. ~~**주인공 아트 외부 교체 (PixelLab MCP)** — 측면 마창 무사 생성 6종 + 파생 5종, 통합·발정렬, 30/30 그린·인게임 확인 (트라이얼 7/40)~~ ✅ (2026-06-18)
> 15. **사용자: 실제 플레이로 새 주인공 손맛/미감 확인** — `플레이.bat`. 확인 포인트: 보행/찌르기/점프 타이밍, 로브 색(거의 흑색이 톤에 맞는지), 콤보 2·3타가 같은 찌름+SkillFx 로 충분히 구분되는지. 불만 시 후속 후보: ⓐ 콤보 2타(횡쓸기)·3타(회전)를 PixelLab v3 로 별도 생성(잔여 33gen), ⓑ 로브 색 `create_character_state` 로 밝은 수묵톤 변형, ⓒ 4·궁극기 전용 포즈.
> 16. ~~**11차 공격 모션 역동화 + 이펙트/잔상 강화 (PixelLab v3 콤보 4종 + skill_fx 업그레이드)**~~ ✅ (2026-06-18)
> 17. ~~**12차 게임성 우선: 스토리/대화/NPC 제거, 전투-클리어 전용(GAMEPLAY_ONLY) + Clear 화면 (31/31 그린)**~~ ✅ (2026-06-18)
> 18. **[현재 단계] 전투 게임성 polish** — 실제 플레이로 손맛/밸런스 다듬기. 후보: 적 AI·체력·드롭 밸런스, 콤보 타이밍/히트스톱, 스테이지 적 배치·난이도 곡선, 결계/클리어 피드백. 스토리는 그 다음(되살리려면 `stage.gd`의 `GAMEPLAY_ONLY=false`).
>    - ~~13차: 조작 손맛 1차(코요테/점프버퍼/가변점프/묵직낙하/가속이동/공격런지/착지흔들림)~~ ✅ (2026-06-27, **사용자 PC 검증 대기**)
>    - **사용자: `플레이.bat` 로 손맛 확인** — 점프가 단타/풀점프로 갈리는지, 이동에 발구름·관성이 생겼는지(너무 미끄러우면 FRICTION↑/AIR_FRICTION↑), 공격 시 앞으로 치고 나가는 느낌이 과하지/약한지(런지 값 조정), 낙하가 묵직한지. 수치는 `player.gd` 상단 "조작 손맛 튜닝" const 한곳에 모음.
>    - ~~14차: PixelLab VFX 퀄업(3타 모션 v2 + 페인티드 슬래시/창격/스파크 이펙트 + 출혈)~~ ✅ (2026-06-27, **PC 반영·검증 대기**)
>    - **사용자 PC 필수 단계**: ① Godot로 프로젝트 한 번 열어 `assets/sprites/fx/*.png` import(.import 생성) ② `python tools/pixel/integrate_combos.py` 실행 → 3타 strip(attack3.png 13f)+manifest 갱신 ③ `플레이.bat` 로 이펙트/출혈/3타 확인. 마음에 안 들면: 슬래시/출혈 크기·수명은 `skill_fx.gd` `_painted(...)` 호출 인자, 3타 모션은 PixelLab `animate_character` v3 재롤(잔여 gen 충분).
> 19. **[보존] 주인공 아트 외부 교체 기록** — 코드 생성 미감 한계로 외부 AI 아트 선택.
>     현재: Leonardo 생성 idle 1장을 `assets/sprites/protagonist_custom/`에 통합(배경제거·다운스케일·발정렬),
>     단일 이미지 퍼펫 변형으로 11개 동작 임시 생성(`player_visual`이 custom 시트 우선 사용, 코드생성 폴백).
>     사용자가 품질 불만 → **PixelLab MCP**(https://api.pixellab.ai/mcp, `claude mcp list`에 connected) 결제·연결 완료.
>     **다음 세션 할 일:** PixelLab MCP 도구로 조선 마창 무사 **측면(side-view)** 캐릭터 + walk/attack/hurt/death/jump
>     애니 생성(먼저 1개로 옆모습 지원·크레딧 확인) → `protagonist_custom/`에 넣고 슬라이싱·매니페스트·배선·발정렬
>     → 2타·3타·차지·구르기 파생 → 헤드리스 30종 + 인게임 스크린샷 검증 → 커밋.
>     (MCP 도구는 세션 시작 때만 로드되므로 앱 재시작·새 대화 필요.)

## 다음 작업 후보 (2026-06-27 기준, 우선순위 검토용)
> 폰(WSL) 세션 가능 여부 표기: 🟢 폰서 바로 / 🟡 폰서 생성·코드+PC서 반영 / 🔴 PC 플레이 피드백 필요.
> 1. 🟢 **VFX 마무리** — 차지(기 모으기) 오라, 적 피격 플래시·사망(혼 흩어짐) 이펙트, 보스 등장 연출. 출혈과 세트로 전투 화면 완성도↑. *(추천: 전투 화면을 한 번에 마무리)*
> 2. 🟡 **적·보스 아트 외부 교체** — 주인공처럼 PixelLab로 도깨비/구미호/저승사자/호귀/보스 측면 스프라이트 교체(가장 큰 시각 임팩트·일관성, 큰 작업).
> 3. 🟡 **전투 손맛 2차** — 히트스톱 강약·넉백 곡선·적 피격 반응(경직/플래시)·콤보 캔슬 타이밍. 코드 가능, 최종 체감은 PC.
> 4. 🔴 **전투 밸런스/난이도 곡선** — 적 HP·드롭률·스테이지 적 배치. 실제 플레이 피드백("쉽다/어렵다") 받은 뒤 조정.
> 5. 🟡 **웹 빌드 → itch.io 업로드** — 폰에서 바로 플레이·공유 루프(CI 워크플로 존재, 호스팅만 결정).
> 6. 🟢 **UI/HUD 한지·먹 스킨 폴리시** — 스킬바·체력바·클리어 화면 미감.
> 7. 🟢 **새 스테이지/적 콘텐츠** — `stage.gd` 데이터(JSON) 기반 양산.

## 🖥️ PC에서 해야 할 일 (지금 밀린 반영·검증 — 폰/WSL 세션엔 Godot·PIL 없음)
> 최근 폰 세션에서 코드/아트는 다 커밋·푸시했지만, **아래는 Godot 또는 이미지툴이 필요해 PC에서만 가능**. 끝낸 항목은 `[x]` 로 바꿔 주세요.
> - [ ] **새 FX PNG import** — Godot로 프로젝트 한 번 열기 → `assets/sprites/fx/*.png`(슬래시·창격·스파크·출혈·궁극기 버스트·부적 진법) 자동 import(.import 생성). 안 하면 페인티드 이펙트가 폴백(코드 드로잉)으로만 나옴.
> - [ ] **3타 모션 strip 반영** — `python tools/pixel/integrate_combos.py` 실행 → `attack3.png` 13프레임(attack3_spin_v2)+manifest 갱신. 안 하면 이펙트는 나와도 3타 *모션*은 옛 11프레임.
> - [ ] **헤드리스 테스트** — `godot --headless res://tests/test_player_movement.tscn`(신규 variable_jump/coyote_jump 포함) + 전체 스위트 그린 확인. (13차 손맛 로직 변경분 검증.)
> - [ ] **실제 플레이(`플레이.bat`) 손맛·미감 확인**:
>     - 13차 조작 손맛: 점프 단타/풀점프 구분, 이동 발구름·관성(미끄러우면 `player.gd` 상단 FRICTION↑), 공격 런지 강약, 묵직한 낙하.
>     - 14차 VFX: 콤보1/2/3·일섬·회천격·적중 임팩트·**출혈**·**궁극기**(바닥 부적 진법+폭발) 페인티드 이펙트가 제대로 합성되는지, 크기/수명 과하지 않은지(`skill_fx.gd` `_painted(...)` 인자로 조정).
> - [ ] 위 확인 후 불만 지점 피드백 → 폰 세션에서 수치/재생성으로 후속 대응.
> - [ ] **15차 전투 마무리 VFX 확인** — 차지 길게 눌렀을 때 '기 모으기' 오라(완전차지 금빛), 적 피격 흰빛 번쩍, 적/보스 사망 시 '혼 흩어짐'(창백한 넋), 보스 첫 접근 시 등장 연출(마기 솟구침+흔들림). 과하면: `skill_fx.gd` 의 해당 함수 알갱이 수/수명/크기 인자 조정. (PNG 재생성 불필요, 코드만)
> - [ ] **15차 배경 개선 확인** — 그라데이션 하늘, 떠다니는 구름, 먼 산 흐림(대기 원근), 야간 스테이지(폐사지·제단) 별·반딧불. 톤/속도 조절: `parallax_backdrop.gd` export 변수(`aerial`/`cloud_drift`/`night_luminance`) 또는 stage JSON `backdrop.sky/tint`. 하늘 그라데이션 세로 위치가 어긋나면 `_add_sky()` 의 `tr.size/position` 미세조정. (PNG 재생성 불필요)
> - [ ] **15차 배경 아트 재생성(PIL 필요 — PC에서만)** — `gen_background.py` 를 풍부하게 개선해 둠(최원경 능선 1겹 추가·구름띠 3겹·먼 하늘 새 떼·근경 납작돌·풀잎 밀도↑·소나무 1그루↑). **PC에서 `python tools/pixel/gen_background.py` 실행해야 `assets/sprites/bg/bg_*.png` 가 새 그림으로 갱신**됨(안 돌리면 코드는 있어도 옛 PNG 유지). 실행 후 `shots/bg_composite.png`·`shots/bg_seam_check.png`(이음매)·`shots/sheets/background_sheet.png` 로 눈 확인. 팔레트 위반 시 save 가 예외 → 색 조정. 과하면 새 떼/돌 좌표 리스트나 farthest 능선 루프만 빼면 됨.

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

- **2026-06-27 (14차 — PixelLab VFX 퀄업: 3타 모션 + 페인티드 이펙트 + 출혈)** — 사용자 "3타 모션·이펙트 + 스킬 이펙트 + 몬스터 출혈을 PixelLab MCP로 퀄업". PixelLab 구독 활성 확인(2000 gen). ① 캐릭터 `animate_character` v3 로 `attack3_spin_v2`(13f, east) 생성 → `tools/pixel/integrate_combos.py` attack3 = 새 UUID `1552a702…`/13f 로 교체(PC에서 스크립트 실행 시 strip·manifest 반영). ② `create_1_direction_object`(sidescroller, 160px, 4후보) 3건으로 VFX 생성·후보 검토(MCP 프리뷰)·채택 다운로드: slash(crescent/swirl/wide 3장)·thrust_lance·spark(star/burst 2장)·blood(splat/spray 2장) = `assets/sprites/fx/` 7장. ③ `skill_fx.gd`: `_tex_cache`/`_fx_tex`(지연로드, 미존재 시 null 폴백)+`_painted`(Sprite2D 스케일업·회전·드리프트·페이드 트윈) 헬퍼, 콤보 `_spear_thrust`/`_spear_sweep`/`_spear_spin`·스킬 `slash`/`spin`·`impact` 에 페인티드 주역 레이어 합성, `bleed()`(핏방울+얼룩, 절제 톤) 신규. ④ `player.gd` `_on_hitbox_landed`·`_skill_ultimate` 에 `SkillFx.bleed` 배선. ⑤ **궁극기 연출 페인티드화**: VFX 2종 추가(`ult_burst` 데몬 폭발, `rune_circle` 바닥 부적 진법 탑다운) → `ultimate()` 에 바닥 진법(세로 납작·회전·페이드)+중심 폭발 버스트+보조 스파크 합성(기존 섬광/충격파 링/영혼창 코드는 유지). `.gitignore` 에 `.pl_tmp/` 추가. **PixelLab ~125 gen 사용. WSL엔 Godot 없어 인게임 합성은 PC 검증 대기**(후보 미감은 MCP 프리뷰로 확인함).
- **2026-06-27 (13차 — 조작 손맛 1차: 점프/이동 게임필 + 공격 런지)** — 사용자 "푸시 후 조작 손맛 작업". `scripts/player/player.gd` `_physics_process` 재구성: (a) 중력을 상승/하강·점프유지로 분기(FALL_GRAVITY_MULT 1.45 / LOW_JUMP_GRAVITY_MULT 1.9), (b) `_coyote_timer`(COYOTE_TIME 0.10)·`_jump_buffer_timer`(0.12)·`_jumping` 추가 — 점프를 "버퍼 입력 + (지상 or 코요테)"로 발동하고 상승 중 키 떼면 `velocity.y *= JUMP_CUT_MULT(0.45)`(가변 점프), (c) 좌우 이동을 즉시대입 → `move_toward` 가속/마찰(ACCEL 2400/AIR 1500, FRICTION 2800/AIR 700, 반대전환 시 +마찰, 정점 부근 APEX 가속 보너스), (d) `_lunge_vel` 1회성 전방 임펄스를 콤보(70/3타 130)·강타(150)에 부여 — move_and_slide 직전 1회만 더해 누적 버그 회피, (e) 빠른 착지(낙하속도 360+)에 가벼운 shake. 튜닝 const 13개를 파일 상단 한곳에 모음(되돌리기 쉽게). `tests/test_player_movement` 에 **variable_jump**(탭<풀점프 최고높이)·**coyote_jump**(발판 떠난 직후 점프 발동) 2케이스 추가(바닥 StaticBody 생성 헬퍼 포함). **이 환경(WSL)엔 Godot 미설치 → 헤드리스/플레이 검증은 사용자 PC 대기.**
- **2026-06-18 (12차 — 게임성 우선: 스토리/대화/NPC 제거)** — 사용자 방향("스토리 나중, 지금은 몬스터 잡고 클리어만"). ① `scripts/world/stage.gd` 에 `GAMEPLAY_ONLY`(기본 true)·`CHAIN`/`CHAIN_TSCN`/`CLEAR_SCENE` 추가 + `_build_gameplay`/`_clear_flag`/`_next_target`/`_spawn_exit`: 전투 스테이지 직선 체인(foothills→forest_deep→ruined_temple→mountain_pass→sacred_altar)만 빌드(NPC·대사·퀘스트·스토리픽업·auto_quest 스킵), 적 있는 신규 진입엔 전진 결계, 끝은 Clear. 되돌리기는 `GAMEPLAY_ONLY=false`. ② `scenes/ui/Clear.tscn`+`scripts/ui/clear_screen.gd` 신규(엔딩 대체). ③ `main_menu.gd`: START→Foothills, 새 게임 프롤로그 생략, 제목/로고/부제 숨김. ④ `scene_manager.gd` NON_GAMEPLAY_SCENES += Clear. ⑤ `tests/test_gameplay_chain` 신규(체인 5스테이지: 적 스폰·NPC0·자동대사0·전진출구·게이트 검증). 헤드리스 **31/31 그린** + 메뉴/스테이지/클리어 스크린샷.
- **2026-06-18 (11차 — 공격 모션 역동화 + 이펙트 강화)** — 피드백 반영. ① PixelLab v3 콤보 4종 재생성(attack/attack2/attack3/charge — 1·2·3타 모션 차별, 셋이 같은 찌름이던 문제 해결), `tools/pixel/integrate_combos.py`로 공개 프레임 URL→92×92 스트립·manifest 갱신. ② `scripts/combat/skill_fx.gd` 전면 업그레이드: `_line`/`_belly_curve`/`_ground_dust` 헬퍼, 콤보 다층 이펙트, slash/spin/impact/ultimate 화려화, **afterimage/afterimage_burst**(현재 AnimatedSprite2D 프레임 복제 색조 잔상) 추가. ③ `player.gd`: 콤보·차지·일섬·회천격·궁극기·회피에 `SkillFx.afterimage_burst` 트레일 배선. 크레딧 14/40(콤보 v3 8/10프레임은 2gen씩). 검증: 헤드리스 30/30 그린 + FxPreview/ComboPosePreview 스크린샷. (오브젝트형 VFX 스프라이트는 20~40gen/개라 트라이얼서 보류.)
- **2026-06-18 (10차 — PixelLab 주인공 아트 교체)** — PixelLab MCP(트라이얼 40gen)로 외부 AI 주인공 전면 교체. ① `create_character`(side/4dir/92px/heroic/high-detail) 1gen → **east 우향 프로필+창 측면 확인**. ② `animate_character` east 1방향씩(=1gen) 6종: idle/walk/jump/hurt/death 템플릿 + attack v3 창 찌름 → **7/40 소모**. ③ zip 추출(`metadata.json` 폴더명 generic → 프레임 수+몽타주로 idle(4)/walk(6)/jump(9) 식별). ④ `tools/pixel/integrate_pixellab.py` 신규: east 프레임→92×92 대칭 캔버스 가로 스트립+manifest, run/attack2/attack3/charge/dodge 무크레딧 파생, foot_offset 자동 산출(발행 90→−28). ⑤ `player_visual.gd` foot_offset −28. 검증 **헤드리스 30/30 그린 + 마을 인게임 스크린샷**. (콤보 sprite 는 attack 재사용 — 시각 차별은 기존 SkillFx 오버레이가 담당.)
- **2026-06-17 (9차 — 주인공 외모·창 휘두름)** — /goal 자율. ① 프레임 폭 **32→48px**(W/CX=24) — 창이 프레임에 안 잘리게. ② **각도 기반 일정 길이 창** `spear_angle()`/`_tip()`/SPEAR_LEN=24 — 휘둘러도 창 길이 불변(찌르기=평행이동, 쓸기/회전=각도 회전+sweep 잔상). attack/attack2/attack3/charge 재작성. ③ **얼굴 리디자인** head()/hat()/neck() — almond 눈·얇은 눈썹·매끈 콧대·좌상 광원, 갓끈 얼굴 밖, 갓 음영 정돈. 검증: 30/30 그린 + 스트립/인게임 스크린샷.
- **2026-06-17 (8차 — 주인공 모션 고도화)** — /goal 자율. "모션 조잡" 피드백 → `tools/pixel/gen_protagonist.py` 전 10종 애니 재작업: 프레임 증량(walk 8·idle 6·jump 3·attack 5·attack2 5·attack3 6·charge 3·dodge 4·hurt 3) + 애니 원칙 적용(예비동작/follow-through/무게 bob/2차 모션). 헬퍼 추가: 발끝 들림(feet lift), 창 sway/tassel 2차 모션, body lean, _atk_base 공통체. player_visual jump 프레임 velocity 매핑(상승/정점/하강). ANIMS fps 재조정. 검증: 30/30 그린 + 스트립/인게임 스크린샷.
- **2026-06-17 (7차 — 「귀창록」 리브랜딩·창 마검사)** — /goal 자율(토큰 한도까지). ① 주인공 무기 환도→**창(spear)** 전면 재생성(`tools/pixel/gen_protagonist.py` spear/spear_stand 헬퍼, 10종 애니 전부): idle/walk 창 세워 든 실루엣, 콤보 **1 직선찌름·2 횡쓸기·3 회전내려찍기**, charge 창끝 점화, death 창 떨굼. ② **콤보 이펙트 차별화** `SkillFx.combo(step)` — 찌름 랜스/횡 크레센트/회전 링+8방 스파이크, **3타 1.6배+홍 궤적**(player.gd). ③ **궁극기 '귀창 강림'**(skill_4, skills.json guichang, 쿨40·3.5배 광역·SkillFx.ultimate 섬광/충격파/12방 영혼창). ④ **NPC 상호작용 제거**(npc.gd body_entered 자동) + **대화 중 적 동결**(state_machine/patroller/boss/spirit_orb) + 보스 등장 자동 대사(foxqueen_intro/reaperlord_intro). ⑤ **자연 회복**(health_component.gd regen_rate/delay, Player.tscn 2.5/6s). ⑥ **보스 다양화**: FoxQueen(구미호 여왕·폐사지)·ReaperLord(저승 군주·관아) 중간보스 2종. ⑦ **세계관 재해석** 호환→호귀(虎鬼)·산군(山君), 제목/프롤로그/에필로그/크레딧/메인퀘스트 텍스트 귀창록 테마. ⑧ **세번째 다양 보스 도깨비 대장(GoblinKing)** 저잣거리 배치+자동 대사(보스 3종: 구미호 여왕/저승 군주/도깨비 대장 + 최종 산군). ⑨ **무기 창 계열 재명명**(철검→무쇠창/옥장도→옥자루 창/강철 검→강철 장창) + **마창·각성(spear_demon)** 최종보스 보상. ⑩ **타이틀 로고 재생성**(title_logo(_menu).png 호환기담→귀창록 — 메뉴 실제 표시 로고) + 보스 display_name 정리. 신규 테스트 3종(dialogue_freeze/ultimate/regen), 전체 **30 스위트 그린**.
- **2026-06-12 (6차 — 자율 고도화 전투/UX/정합)** — /goal 자율(토큰 한도까지). 감사(Explore) 후 임팩트순 12건: ① **잡몹 근접 공격**(patroller 예비동작→타격→넉백, 적별 차별, 거리판정 아군오사 없음) — 일방적 전투 해소. ② **대화 선택지 키보드 선택**(1~9/↑↓/Space, 번호 라벨·자동 포커스). ③ **적 처치 드롭**(회복약/엽전, Pickup.spawn 팩토리). ④ **피격 무적시간(i-frame)+피드백**(HealthComponent.invuln_on_hit 0.55s·붉은 깜빡임) — 무리 연타 공정성. ⑤ **메뉴 키보드 포커스**(Main/Pause/GameOver) + 사망→게임오버 검증. ⑥ **전투 게이트 '남은 적 N' 표시**. ⑦ **저승사자 원거리 영혼 구슬**(SpiritOrb, 회피 가능). ⑧ **보스 돌진 '!' 경고**(텔레그래프 가독성). ⑨ **산기슭 떠돌이 행상**(엽전 사용처 — 경제 루프 완성). ⑩ **레벨업 회복(40%)+저체력 HP바 경고색**. ⑪ **클리어 구간 재진입 무결성**(적·게이트 재생성 방지). 신규 테스트 9종, 전체 26스위트 그린 + 월드 연결성 OK.

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
