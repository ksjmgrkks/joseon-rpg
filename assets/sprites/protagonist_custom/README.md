# 주인공 커스텀 스프라이트 (PixelLab MCP 생성 — 2026-06-18)

> **현재 에셋 출처:** PixelLab MCP. 측면(side-view) 조선 마창 무사.
> 캐릭터 ID `f5fd2830-c0f3-48c3-aa17-6171e3559da4` ("Joseon Spearman", 4dir/side/92px).
> **생성 애니(east 1방향, 좌향은 코드 flip_h):** idle(breathing-idle)·walk(walking-6-frames)·
> jump(jumping-1)·hurt(taking-punch)·death(falling-back-death) 템플릿 + attack(v3 창 찌름).
> **파생(무크레딧):** run(=walk 가속)·attack2/attack3(=attack 재사용, 콤보 차별은 SkillFx)·
> charge(=attack 윈드업 홀드)·dodge(=jump 웅크림/착지 발췌).
> **재생성/통합 스크립트:** `tools/pixel/integrate_pixellab.py` (zip→스트립+manifest, foot_offset 산출).
> 프레임 92×92, foot_offset −28(콜리전 바닥 +16 정렬). 트라이얼 크레딧 7/40 소모.

---

# (참고) 외부 이미지 드롭인 자리

외부에서 만든(또는 의뢰한) **진짜 주인공 그림**을 여기에 넣으면, Claude가 게임에
통합(슬라이싱·매니페스트·SpriteDb 배선·애니·스크린샷 검증)합니다.

## 넣는 방법 (둘 중 아무거나)

### A. 가장 쉬움 — 정지 이미지 1장
- `idle.png` 한 장만 넣어도 됩니다. (서 있는 전신, 오른쪽 보기, 배경 투명)
- Claude가 일단 그대로 게임에 적용하고, 나머지 동작은 그 그림 기준으로 입힙니다.

### B. 동작별 PNG (있는 것만)
- `idle.png` `walk.png` `attack.png` … 파일명 = 동작 이름.
- 가로 스트립(프레임을 가로로 이어 붙임) 또는 한 칸 1프레임. 칸 크기만 알려주면 됨.

## 기술 사양 (지키면 깔끔하게 들어감)
- **캐릭터 키:** 화면에서 약 48px (프레임 64×64 권장, 더 커도 됨 — Claude가 맞춤)
- **방향:** 오른쪽 보기 (왼쪽은 코드가 자동 반전)
- **배경:** 완전 투명 (반투명 가장자리 X — 픽셀아트는 이진 알파)
- **발바닥:** 프레임 아래쪽에 닿게
- **컨셉:** 조선 후기 떠돌이 무사 — 도포 + 갓 + **긴 창(spear)**
- **색감(권장):** 수묵·한지 톤 (탁한 크림/먹/청 전복/홍 전대). 달라도 Claude가 보정 가능.

## 필요한 동작 (최소는 idle·walk·attack 하나면 충분)
idle, walk, jump, attack(1타), attack2(2타), attack3(3타), charge, dodge, hurt, death

## 외부 AI 이미지 생성 프롬프트 (복붙용)
> 2D pixel art game sprite, side-scrolling character, a Joseon-dynasty Korean
> wandering warrior wearing a long robe (dopo) and a black wide-brim hat (gat),
> holding a long spear, facing right, full body, idle standing pose,
> muted ink-wash / hanji-paper palette (desaturated cream, charcoal ink,
> muted teal vest, dark-red sash), clean readable silhouette,
> transparent background, crisp pixel art, no anti-aliasing, 64x64

스프라이트 시트로 한 번에 뽑으면 프레임이 들쭉날쭉할 수 있으니, **포즈 1~몇 장**을
따로 뽑는 편이 품질이 안정적입니다.
