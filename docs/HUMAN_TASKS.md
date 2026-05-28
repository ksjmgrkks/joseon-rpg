# 사람이 직접 해야 할 일 (HUMAN_TASKS)

> Claude(=AI)는 코드·문서·로직·다운로드 가능한 모든 자동 작업을 책임지고, 아래 항목들은 **시각 확인·외부 GUI 도구·계정/결제·법무·창작 결정** 등 정말 사람이 직접 해야 하는 일들만 둡니다.
> 일이 새로 생길 때마다 위쪽에 추가하고, 끝낸 건 `[x]`로 체크 + 완료 메모.
> 매 단계마다 "이거 진짜 사람이 해야 하나? 내가 할 수 있나?" 검수 후 등록 — 자동 가능한 건 즉시 처리.

---

## 진행 중

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
