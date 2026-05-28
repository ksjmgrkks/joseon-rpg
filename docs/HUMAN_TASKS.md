# 사람이 직접 해야 할 일 (HUMAN_TASKS)

> Claude(=AI)는 코드·문서·로직만 책임지고, 아래 항목들은 시각 확인·외부 도구·계정/법무 등 사람이 직접 해야 하는 일들입니다.
> 일이 새로 생길 때마다 위쪽에 추가하고, 끝낸 건 `[x]`로 체크 + 완료 메모.

---

## 진행 중

### 🅰️ 폰트 파일 직접 배치 (Step 2 결과)
- [ ] https://github.com/quiple/galmuri 또는 https://quiple.dev/galmuri/ 에서 Galmuri 패키지 다운로드
- [ ] 압축 안에서 다음 파일을 `assets/fonts/` 로 복사
  - `Galmuri11.ttf` (본문·대사용)
  - `Galmuri9.ttf` (HUD·작은 텍스트용)
  - `OFL.txt` (라이선스 본문 — 반드시 동봉)
- [ ] Godot 에디터에서 두 .ttf 임포트 설정을 `assets/fonts/README.md` §4 표대로 잠그기 (Antialiased Off / Hinting None / Subpixel Disabled / Fixed Size 11(또는 9))
  → 이건 PC Godot 에디터에서만 가능. 폰 작업 중엔 불가.

---

## 대기 (Phase 0 진행 따라 활성화)

### 🅑 AI 주인공 스프라이트 생성 (Step 4 프롬프트 나온 뒤)
- [ ] 생성 도구 한 개 고르기 — PixelLab(추천: 스켈레톤+애니메이션) / a1.art(스타일 일관성) / Midjourney·SDXL(스타일 톤만)
- [ ] 도구 계정·결제(있으면) 처리
- [ ] Step 4 프롬프트 세트로 후보 N장 생성 (5~10장)
- [ ] 가장 '조선풍' 한 1장 선택

### 🅒 Aseprite 손보정 (Phase 0 핵심)
- [ ] Aseprite 설치 (스팀 또는 itch.io · 1회성 결제)
- [ ] 위에서 선택한 1장을 Aseprite로 옮겨 보정 — 픽셀 정렬·팔레트 일치(`docs/STYLE_BIBLE.md` 팔레트로 클램프)·서브픽셀 깨짐 정리
- [ ] 완성본을 `assets/sprites/protagonist/idle.png` 같은 식으로 레포에 커밋

### 🅓 시대·톤 확정 (Phase 0 끝)
- [ ] 첫 캐릭터 보고 시대 결정 (조선 초/중/말)
- [ ] 톤 결정 (진지 사극 / 코믹 / 괴담)
- [ ] HANDOFF.md, CLAUDE.md 의 "미확정" 표시 제거 → Claude에게 알려주면 갱신

---

## 운영 / 배포 결정 (Phase 1 진입 전후)

### 🅔 정적 호스팅 선택
- [ ] GitHub Pages (레포 Settings → Pages, 무료 · public 권장) / Netlify / Vercel 중 선택
- [ ] private repo + GitHub Pages 하려면 Pro 또는 별도 워크플로우 필요 — 확인
- [ ] 결정되면 알려주시면 빌드 산출물 push 자동화(Action) 잡아드릴게요

### 🅕 라이선스 검수 (출시 직전)
- [ ] 사용한 AI 도구별 상업적 이용 라이선스 확인 (PixelLab/a1.art/Midjourney 등)
- [ ] 폰트 라이선스 파일 빌드에 동봉되는지 확인
- [ ] BGM·효과음 AI 생성 시 라이선스도 같은 절차

---

## 완료
> 작업이 끝난 항목은 `[x]` 체크 후 이쪽으로 옮겨 둠.

- (아직 없음)
