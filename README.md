# 호환기담 (虎患奇譚) — 조선시대 도트 횡스크롤 RPG

가상의 조선 후기, 호랑이 괴변이 도는 산골 마을에 흘러든 떠돌이 무사의 이야기. 픽셀아트 횡스크롤 액션 RPG. 모바일 우선, 개발 중 미리보기는 웹(HTML5) export로 폰 브라우저에서 확인.

## 스택

- **엔진:** Godot 4.6.3 (**GDScript 전용** — C# 금지: web export 비호환)
- **렌더러:** GL Compatibility (모바일·웹 호환)
- **픽셀 필터:** Nearest (서브픽셀 깨짐 방지)
- **배포:** GitHub 레포 + Web Export(HTML5) → GitHub Pages 등에 미리보기

## 폴더 구조

```
scenes/      Godot 씬(.tscn)
scripts/     GDScript(.gd)
assets/
  sprites/   캐릭터·적·NPC 도트
  tilesets/  타일맵
  fonts/     한글 픽셀 폰트
  audio/     음악·효과음
ui/          HUD·메뉴
docs/        기획 문서·로드맵
```

## 진행 / 다음 작업

자세한 현재 상태·다음 할 일·완료 로그는 **[HANDOFF.md](./HANDOFF.md)** 에 항상 최신 상태로 유지합니다.

## 작업 규율

- 새 세션을 시작하면 **먼저 `HANDOFF.md` 를 읽고** 상황 파악.
- 작업을 마칠 때 HANDOFF.md의 `현재 상태 / 바로 다음 할 일 / 완료된 작업 로그` 를 갱신.
- 갱신 후 `git commit & push`.
- 시각 결과 확인이 필요한 작업은 web export 또는 PC에서 직접 본 뒤에 "완료"로 표시.
