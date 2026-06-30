extends RefCounted
class_name MemoryGlyph
##
## MemoryGlyph — 「해원」 시그니처 '기억이 지워짐'의 **순수 글자 변환** 헬퍼(상태 없음).
##
## 텍스트 + 소거 비율(0.0~1.0)을 받아, 글자가 흐려지고 지워지는 표현을 만든다.
## MemoryLedger(상태/세이브)와 분리 — 이쪽은 입력→출력이 결정적(deterministic)이라 헤드리스로 검증 가능.
##
## 결정적인 이유: 같은 (글자수·비율·seed)면 항상 같은 결과 → 프레임마다 깜빡이지 않고,
## 비율이 오를수록 지워진 집합이 **단조 증가**(기억은 되돌아오지 않는다)하며, 테스트가 가능하다.
##
## 쓰임:
##   var bb := MemoryGlyph.dissolve(text, MemoryLedger.progress(), hash(node_path))  # RichTextLabel.text (bbcode)
##   var plain := MemoryGlyph.strip(text, ratio, seed)                                # 일반 Label 용(소거=공백)
##

## 흐려진(소거된) 글자에 입힐 색(한지 바탕에 먹빛이 옅게 번져 사라지는 느낌). RichTextLabel BBCode.
const FADED_COLOR := "8a8378"   # 옅은 먹/재빛
const FADED_ALPHA := "33"       # 거의 사라진 정도(0x33/0xFF)


## 공백이 아닌 글자 중, 주어진 비율만큼이 '소거 대상'인지 결정적으로 판정.
## 비율이 오르면 집합은 단조 증가한다(이미 지워진 글자가 되살아나지 않음).
static func is_erased_char(ch: String, index: int, ratio: float, seed: int) -> bool:
    if ratio <= 0.0:
        return false
    if _is_space(ch):
        return false   # 공백은 단어 형태 유지를 위해 보존
    return _threshold(index, seed) < ratio


## RichTextLabel(bbcode_enabled=true)용. 소거된 글자를 옅은 색+저알파로 감싸 '흐려져 사라짐'을 연출.
## 위치는 유지(글자가 빠져나가 줄이 흔들리지 않게) — 기억의 '잔흔'이 자리에 남는 인상.
static func dissolve(text: String, ratio: float, seed: int = 0) -> String:
    if ratio <= 0.0:
        return text
    var out := ""
    for i in text.length():
        var ch := text[i]
        if is_erased_char(ch, i, ratio, seed):
            out += "[color=#%s%s]%s[/color]" % [FADED_COLOR, FADED_ALPHA, ch]
        else:
            out += ch
    return out


## 일반 Label(BBCode 없음)용. 소거된 글자를 공백으로 비운다(완전 소멸 표현).
static func strip(text: String, ratio: float, seed: int = 0) -> String:
    if ratio <= 0.0:
        return text
    var out := ""
    for i in text.length():
        var ch := text[i]
        out += " " if is_erased_char(ch, i, ratio, seed) else ch
    return out


## 소거된 글자 인덱스 목록(테스트·디버그·연출 타이밍용).
static func erased_indices(text: String, ratio: float, seed: int = 0) -> Array[int]:
    var idx: Array[int] = []
    for i in text.length():
        if is_erased_char(text[i], i, ratio, seed):
            idx.append(i)
    return idx


# ─────────────────────────── 내부 ───────────────────────────

## 글자 위치별 결정적 임계값 [0.0, 1.0). seed 로 노드/대사마다 다른 패턴.
## 주의: Godot 의 String hash() 는 "7:0","7:1"… 처럼 비슷한 입력에 비슷한 값을 내,
## abs(h)%1000 이 한곳에 군집했다(= 한 대사의 글자가 임계 0.85 부근에 몰려, 진행도가
## 그 값을 넘기 전엔 하나도 안 흐려지고 넘으면 통째로 흐려짐 → 대사마다 들쭉날쭉).
## PCG(RandomNumberGenerator)로 seed 비트를 아발란치시켜 [0,1) 균등 분포를 얻는다.
## 결정적(같은 입력=같은 결과)·단조(비율↑=소거 단조증가) 성질은 그대로 유지된다.
static func _threshold(index: int, seed: int) -> float:
    var rng := RandomNumberGenerator.new()
    rng.seed = hash("glyph:%d:%d" % [seed, index])
    return rng.randf()


static func _is_space(ch: String) -> bool:
    return ch == " " or ch == "\t" or ch == "\n" or ch == "　"
