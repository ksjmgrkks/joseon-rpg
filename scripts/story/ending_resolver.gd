extends Node
class_name EndingResolver
##
## 엔딩 판정 — 「해원」 v2 멀티 엔딩 3+1 (STORY_BIBLE v2).
##
## **저울은 하나다: 얼마나 자기를 태웠는가.**
## 진혼은 기억을 태워 하는 일이라, 필수가 아닌 넋까지 다 달래줄수록 그녀를 잊는다.
## 여기에 5막의 태도와 7막의 마지막 선택이 얹힌다.
##
##   ③ 소멸  — 마지막 등에 제 한까지 얹어 보냄(7막 선택). 무엇보다 우선.
##   ④ 윤슬  — (숨김) 대가를 아꼈고 + 증조모의 이름을 찾았고 + 물빛 회상을 봄.
##   ① 망각  — 태운 양이 많음. 살아나지만 그녀를 알아보지 못한다(기본·가장 잔혹).
##   ② 해원  — 그 사이. 아프게나마 알아본다.
##
## 판정을 순수 함수로 떼어 둔 이유: 엔딩 화면 없이도 헤드리스로 조합을 전수 검증하기 위함.
##

const SOMYEOL := "somyeol"      # ③ 소멸
const YUNSEUL := "yunseul"      # ④ 숨김 — 윤슬
const MANGGAK := "manggak"      # ① 망각
const HAEWON := "haewon"        # ② 해원

## 필수가 아닌 진혼·발견의 흔적. 많이 쥘수록 많이 태운 것.
const BURN_FLAGS := [
    "haewon_clue_knife",   # 4막 — 무당이 두고 간 부러진 신칼
    "haewon_clue_ring",    # 6막 — 우물 바닥의 은가락지
    "haewon_clue_shoe",    # 6막 — 빈 곳간의 작은 짚신
    "haewon_ring_found",   # 3막 — 문간의 은가락지
]
## 이만큼 이상 태우면 그녀를 알아보지 못한다.
const BURN_HEAVY := 3


## 지금 플래그 상태로 엔딩 하나를 고른다.
static func resolve() -> String:
    var burned := 0
    for f in BURN_FLAGS:
        if Flags.has_flag(f):
            burned += 1
    return resolve_from(
        burned,
        Flags.has_flag("haewon_final_release_self"),
        Flags.has_flag("haewon_name_found"),
        Flags.has_flag("haewon_recall_seen"))


## 순수 판정(테스트용). 위 resolve() 가 플래그를 읽어 이걸 부른다.
static func resolve_from(burned: int, released_self: bool, name_found: bool, recall_seen: bool) -> String:
    if released_self:
        return SOMYEOL
    if name_found and recall_seen and burned <= 1:
        return YUNSEUL
    if burned >= BURN_HEAVY:
        return MANGGAK
    return HAEWON


## 엔딩 화면이 쓸 제목·본문(마지막 3~4줄)·등불 수·빛깔.
static func presentation(id: String) -> Dictionary:
    match id:
        SOMYEOL:
            return {
                "title": "소멸",
                "lines": [
                    "그가 마지막 등을 놓자, 몸이 빛으로 풀어졌다.",
                    "달려온 이가 빈 자리를 안았다.",
                    "그해부터 그 고을에서는, 물에 빛이 들 때 등을 하나 띄우는 풍습이 생겼다.",
                    "\"…거기 어디 계시겠지요.\"",
                ],
                "lanterns": 9,
                "tint": Color(1.0, 0.95, 0.84),
            }
        YUNSEUL:
            return {
                "title": "윤슬",
                "lines": [
                    "마지막 등에 그는 제 이름 대신, 그녀의 아명을 썼다.",
                    "쓰는 순간, 잊었던 이름이 되돌아왔다.",
                    "동틀 녘 강가. 물 위로 첫 빛이 깔린다.",
                    "\"…윤슬. 물에 빛이 듭니다.\"",
                ],
                "lanterns": 7,
                "tint": Color(1.0, 0.92, 0.72),
            }
        MANGGAK:
            return {
                "title": "망각",
                "lines": [
                    "그는 사흘을 앓고 눈을 떴다. 곁에 앉은 이가 그의 손을 쥐고 있었다.",
                    "\"…뉘신지요.\"",
                    "그녀는 웃으려다 실패했고, 이윽고 웃었다.",
                    "\"…물빛을 좋아하는 사람입니다.\"",
                ],
                "lanterns": 4,
                "tint": Color(0.86, 0.88, 0.94),
            }
        _:
            return {
                "title": "해원",
                "lines": [
                    "그는 오래 앓다 깨어났다. 눈을 뜨자마자 그 얼굴을 알아보았다.",
                    "신분은 그대로였고, 집안은 끝내 그를 들이지 않았다.",
                    "둘은 고을을 떠났다. 강을 따라, 등 하나를 들고.",
                    "달랠 넋은 어디에나 있었다.",
                ],
                "lanterns": 6,
                "tint": Color(0.98, 0.94, 0.82),
            }
