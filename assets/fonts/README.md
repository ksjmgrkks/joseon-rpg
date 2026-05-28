# 한글 픽셀 폰트 — 후보 & 사용 가이드

> Phase 0 결정 사항: **본문/대사 = Galmuri11(우선)**, **HUD·작은 텍스트 = Galmuri9**.
> 현재 상태: 레포에 `Galmuri11.ttf` · `Galmuri9.ttf` · `OFL.txt`(영문) · `OFL-ko.md`(한글) **이미 포함됨** (quiple/galmuri 공식 배포본). Godot 임포트 설정만 남음.

---

## 1) Top 3 후보

| 순위 | 이름 | 제작 | 라이선스 | 권장 용도 | 출처 |
|---|---|---|---|---|---|
| ⭐ | **Galmuri (갈무리)** | Quiple | SIL OFL 1.1 | 본문·대사·HUD | https://quiple.dev/galmuri/ · https://github.com/quiple/galmuri |
| 2 | **Neodgm (네오둥근모)** | Dalgona | SIL OFL 1.1 | 본문, 살짝 둥근 톤 | https://github.com/Dalgona/neodgm |
| 3 | **DungGeunMo (둥근모꼴)** | 주상익 | 비영리·재배포 가능 | 원조 픽셀 한글 (오래된 분위기) | 검색 — 배포처 다양, 라이선스 원본 동봉 필요 |

상업 출시 가능성을 생각하면 **OFL** 라이선스인 Galmuri / Neodgm 둘 중 하나로 가는 게 안전합니다. 둥근모꼴은 출처/라이선스를 매번 확인해야 해서 추천 순위에선 뒤로 뒀습니다.

---

## 2) Galmuri 선택 이유 (1순위)

- **픽셀 한글 전용으로 설계** — 한글 조합형 글자가 픽셀 격자에서 깨지지 않게 손수 그린 폰트
- **사이즈별 컷이 따로** — `Galmuri7 / Galmuri9 / Galmuri11 / Galmuri14`. 각 사이즈에 정확히 맞는 디자인 → 우리 캐릭터 48px·타일 32×32 톤과 잘 어울림
- **사극·고전 분위기 호환** — 둥근모꼴 계열 직선·단정한 형태라 한지·먹 톤과 충돌 안 함
- **OFL** — 상업 출시·재배포 자유 (폰트 파일과 라이선스 함께 배포만 하면 됨)

권장 매핑:
- 대사창 본문: **Galmuri11**
- HUD(체력 수치, 미니맵 라벨 등): **Galmuri9**
- 타이틀/큰 라벨: **Galmuri11** 또는 **Galmuri14**

---

## 3) 받아서 넣는 법 (이미 완료)

✅ 다음 파일들이 이 폴더에 이미 들어있습니다 (Phase 0 자동 셋업에서 quiple/galmuri 공식 배포본에서 가져옴):
- `Galmuri11.ttf` (본문·대사용)
- `Galmuri9.ttf` (HUD·작은 텍스트용)
- `OFL.txt` (SIL Open Font License 1.1, 영문 원본)
- `OFL-ko.md` (한글 번역본 — 참고용)

남은 일은 §4 Godot 임포트 설정뿐.

---

## 4) Godot 임포트 설정 (픽셀 폰트 깨짐 방지)

`.ttf` 를 클릭 → 우측 **Import** 패널에서 아래 값으로 잠그고 `Reimport`:

| 항목 | 값 | 이유 |
|---|---|---|
| `Antialiased` | **Off** | 픽셀 폰트는 안티에일리어싱 비활성이 정답 |
| `Hinting` | **None** | 힌팅 켜면 픽셀 격자 어긋남 |
| `Subpixel Positioning` | **Disabled** | 서브픽셀 어긋남 방지 |
| `Multichannel SDF` | **Off** | 픽셀 폰트엔 부적합 |
| `Force Autohinter` | **Off** | 위와 같은 이유 |
| `Fixed Size` | **11** (Galmuri11.ttf), **9** (Galmuri9.ttf) | 폰트가 정밀하게 그려둔 사이즈에 고정 |

> `Fixed Size`를 안 맞추면 11px 폰트를 13~14px로 늘려 그릴 때 픽셀이 깨집니다. **이 값이 핵심.**

---

## 5) Godot에서 사용 (요약)

```gdscript
# 예: 라벨에 폰트 적용
@onready var label: Label = $Label

func _ready() -> void:
    var font: FontFile = load("res://assets/fonts/Galmuri11.ttf")
    label.add_theme_font_override("font", font)
    label.add_theme_font_size_override("font_size", 11)  # Fixed Size와 일치
```

추천: 폰트는 매 라벨마다 지정하지 말고 **`Theme` 리소스** 하나에 묶어 두고(`res://ui/theme.tres`) 전역으로 적용. UI/HUD 작업 시작할 때 같이 정리합니다.

---

## 6) 체크리스트

- [ ] Galmuri11.ttf · Galmuri9.ttf 다운로드 + 이 폴더에 복사
- [ ] 같은 폴더에 OFL.txt(라이선스) 복사
- [ ] Godot Import 설정 위 표대로 잠금
- [ ] (UI 작업 시) Theme 리소스에 등록

---

### 참고 — 다른 후보가 더 적합해질 수 있는 케이스

- **국한문 혼용·한자 사용 시:** Galmuri/Neodgm에 한자 글리프가 모두 있는지 확인. 없으면 한자만 별도 폰트로 폴백.
- **타이틀에 굴림·붓 느낌이 필요할 때:** 픽셀 폰트와 충돌하지 않게, 타이틀 한정으로 비픽셀 한글 폰트를 사용해도 됨(예: 코트라 희망체 시리즈, 본명조 등 — OFL 확인 필수).
