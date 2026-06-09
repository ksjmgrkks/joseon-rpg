# 로컬라이제이션 (Localization)

## 현재 상태
- autoload `Locale` (`scripts/locale/locale_manager.gd`) 가 `assets/locale/<locale>.json`
  파일에서 키→문자열 매핑을 로드합니다.
- 기본 locale 은 `ko`. `Locale.set_locale("en")` 로 즉시 전환되고 `locale_changed`
  시그널이 발사됩니다.
- UI 노드들은 시그널을 듣고 `_apply_locale()` 같은 메서드로 문자열을 다시 그립니다.
  (예: `scripts/ui/main_menu.gd`)

## 키 네이밍 규칙
- 점(`.`) 구분 — `area.subsystem.purpose` 형태.
- 예) `menu.new`, `hud.gold`, `shop.no_gold`.
- 숫자 포함 키 권장 안 함. 대신 `Locale.t_format("hud.lv", [3])` 처럼 포맷.

## 새 문자열 추가하기
1. `assets/locale/ko.json` 에 키→번역 추가.
2. `assets/locale/en.json` 에도 같은 키로 영어 번역 추가(미번역이면 키 자체가 반환됨).
3. UI 스크립트에서 `Locale.t("키")` 로 호출.

## 향후 마이그레이션 옵션
대화·아이템·퀘스트 데이터(`assets/dialogue/*.json` 등)도 같은 패턴으로 옮기려면:
- 텍스트 필드를 `{"key": "dlg.elder.intro.text"}` 형태로 두고 런타임에서 `Locale.t(...)` 적용.
- 또는 텍스트 자체를 별도 `assets/locale/dialogue.<locale>.json` 으로 분리.

Godot 내장 `TranslationServer` / `tr()` 로 옮기려면:
- ko/en json 을 CSV 로 옮긴 뒤 Godot 에디터 → 프로젝트 설정 → Localization 으로 import.
- 기존 `Locale.t(key)` 호출을 `tr(key)` 로 일괄 치환.

지금은 키-기반 매핑이 가장 단순해서 이걸로 두었습니다.
