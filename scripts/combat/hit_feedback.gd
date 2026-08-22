extends RefCounted
class_name HitFeedback
##
## 플레이어 공격의 공통 유효 명중 피드백.
## 기본/차지/도혼참(Hitbox), 진혼등(TalismanShot), 귀창 강림(직접 광역)이 모두 이곳을 거친다.
## 빗맞음·무적·보호막처럼 HP가 줄지 않은 접촉에는 호출하지 않는다.


static func profile(hit_count: int = 1, power: float = 1.0, pitch_bias: float = 0.0) -> Dictionary:
    var count := maxi(1, hit_count)
    var stack := count - 1
    var weight := clampf(power, 0.5, 3.0)
    return {
        "volume_db": 1.0 + minf(4.0, float(stack)),
        "pitch": clampf(1.0 + pitch_bias + 0.05 * float(stack), 0.85, 1.35),
        "zoom_ratio": 1.0 + minf(0.03, 0.006 + 0.008 * weight + 0.0025 * float(stack)),
        "zoom_in": minf(0.018 + 0.003 * weight, 0.027),
        "zoom_out": minf(0.065 + 0.008 * weight, 0.09),
        "slow_duration": minf(0.012 + 0.014 * weight, 0.05),
        "slow_scale": clampf(0.9 - 0.2 * weight, 0.5, 0.8),
        "heavy": stack >= 1,
        "stack": stack,
    }


static func player_hit(hit_count: int = 1, power: float = 1.0, pitch_bias: float = 0.0,
        with_focus: bool = true) -> void:
    if hit_count <= 0:
        return
    var feel := profile(hit_count, power, pitch_bias)
    Audio.play_sfx(Sfx.HIT_CONFIRM, float(feel.volume_db), float(feel.pitch))
    if bool(feel.heavy):
        Audio.play_sfx(Sfx.HIT_HEAVY, -1.0 + minf(3.0, float(feel.stack)), 1.0)
    if with_focus:
        ScreenFx.impact_focus(float(feel.zoom_ratio), float(feel.zoom_in), float(feel.zoom_out))
        ScreenFx.slow_motion(float(feel.slow_duration), float(feel.slow_scale))
