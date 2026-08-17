# 모바일 출시 전략 — 「해원」 Android / iOS

> 2026-08-17 작성. 결론: **웹뷰 래핑이 아니라 Godot 네이티브 익스포트로 낸다.**
> 웹 빌드(GitHub Pages)는 폰 테스트·데모용으로 계속 유지한다.

---

## 1. 왜 웹뷰 래핑이 아닌가

| 항목 | 웹뷰(WebView) 래핑 | Godot 네이티브 |
|---|---|---|
| App Store 심사 | 가이드라인 4.2(minimum functionality) — 웹사이트를 감싸기만 한 앱은 리젝 사유 | 정상 |
| **진동(햅틱)** | iOS Safari/WKWebView 는 `navigator.vibrate` **미지원** → iOS 진동 불가 | `Input.vibrate_handheld()` 동작 |
| 오디오 | 브라우저 오디오 지연·첫 터치 전 재생 차단 | 엔진 오디오 드라이버 직접 사용 |
| 성능 | WASM + WebGL, iOS 는 JIT 제한 | 네이티브 |
| 최초 실행 | `.pck` 수십 MB 다운로드, 오프라인 불가 | 설치 시 포함, 오프라인 동작 |
| 스토어 기능 | 리더보드·IAP·업적 붙이기 어려움 | 플러그인으로 가능 |

**따라서:** 앱은 네이티브로, 웹은 데모·마케팅 링크로 역할을 나눈다.

---

## 2. 출시 순서 (권장)

### Phase A — Android 먼저 (맥 없이 가능)
1. **필요한 것:** JDK 17, Android SDK(플랫폼 34+ / 빌드툴), Godot 4.6.3 Android 빌드 템플릿, 릴리스 keystore.
2. Godot → `프로젝트 > 설치된 안드로이드 빌드 템플릿`, 에디터 설정에 SDK 경로 지정.
3. keystore 생성(로컬 보관, **git 에 절대 커밋 금지**):
   ```
   keytool -genkey -v -keystore haewon-release.keystore -alias haewon -keyalg RSA -keysize 2048 -validity 10000
   ```
   경로·비밀번호는 Godot **에디터 설정**(프로젝트 파일 아님)에 넣는다.
4. `export_presets.cfg` 의 **Android 프리셋은 이미 추가돼 있다** — 패키지 `com.ksjmgrkks.haewon`, arm64-v8a, min SDK 24, 몰입 모드(immersive), 인터넷 권한 없음.
5. 내부 테스트 배포는 **AAB**(`gradle_build/export_format=1`)로 바꿔 Play Console 업로드. 개발자 등록 **$25(1회)**.
6. ⚠️ **개인 개발자 계정은 클로즈드 테스터 20명 × 12일 연속**을 채워야 프로덕션 승인이 난다 → 일정에 2주 확보.

### Phase B — iOS (맥 필요)
1. **필요한 것:** 맥 + Xcode, Apple Developer Program **$99/년**.
2. Godot 이 Xcode 프로젝트를 생성 → 서명 → 아카이브 → TestFlight → 심사.
3. 맥이 없으면 Android 출시를 먼저 하고, 클라우드 맥 대여로 나중에 붙인다.

### Phase C — 유지
- 웹 빌드(GitHub Pages)는 그대로 두고 데모 링크로 사용.
- 스코어어택이므로 다음 확장은 **리더보드**(Play Games Services / Game Center) — 네이티브 빌드에서만 가능.

---

## 3. 소리·진동 (현재 구현 상태)

- **진동:** `ScreenFx.rumble(ms)` — Android/iOS/Web 에서만 `Input.vibrate_handheld`.
  - 적중 시 콤보 단계별 `10 + 8×단계` ms, 플레이어 피격 시 45ms.
  - 설정 메뉴의 **진동 토글**로 끌 수 있고 `user://settings.cfg` 에 남는다.
  - ⚠️ **iOS 는 지속시간이 무시**되고 시스템 햅틱으로만 울린다. 세기(amplitude) 제어는 네이티브 플러그인이 필요.
    → 강약은 "긴 진동"이 아니라 **짧은 펄스의 개수·간격**으로 표현할 것.
- **오디오:** 모바일 지연이 크면 `audio/driver/output_latency` 를 낮춘다. 짧은 SFX 는 wav 유지.
  앱이 백그라운드로 갈 때 음소거/일시정지 처리는 스토어 리뷰에서 눈에 띄는 항목.

---

## 4. 화면·조작 (이번에 반영한 것)

- `window/stretch/aspect` = **expand** — 19.5:9 등 긴 화면에서 검은 레터박스 없이 꽉 참.
  (뷰포트가 가로로 넓어지므로 `stage.gd` 가 지면을 좌우 500px 덧대 스테이지 밖 빈 칸을 막는다.)
- `window/handheld/orientation` = landscape 고정.
- 터치 컨트롤(`scripts/ui/mobile_controls.gd`)은 코드 배치 —
  안전영역(노치·제스처바) 반영, 왼손 이동 / 오른손 행동 클러스터, 스킬 4종은 아이콘+쿨다운,
  멀티터치(`TouchScreenButton`)로 이동하며 공격 가능, 데스크톱에선 숨었다가 첫 터치에 나타남.

---

## 5. 아직 안 한 것 / 다음

- [ ] Android SDK·keystore 세팅 후 **실제 APK 빌드 및 실기기 설치 확인** (이 저장소에서는 미검증)
- [ ] 런처 아이콘(192×192 / adaptive 432×432) 제작 — 지금은 비어 있음
- [ ] 스토어 등록 정보(스크린샷·설명·개인정보처리방침 URL) 준비
- [ ] 성능 측정: 실기기에서 30/60fps 유지 여부, `.pck` 용량
- [ ] iOS: 맥 확보 후 진행
