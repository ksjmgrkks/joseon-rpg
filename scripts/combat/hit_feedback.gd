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
        "kick": minf((1.25 + 0.45 * weight) * (1.0 + 0.18 * float(stack)), 4.0),
        "duration": minf(0.065 + 0.006 * weight, 0.085),
        "heavy": stack >= 1,
        "stack": stack,
    }


static func player_hit(hit_count: int = 1, power: float = 1.0, pitch_bias: float = 0.0,
        with_camera_bump: bool = true, direction_x: float = 1.0) -> void:
    if hit_count <= 0:
        return
    var feel := profile(hit_count, power, pitch_bias)
    Audio.play_sfx(Sfx.HIT_CONFIRM, float(feel.volume_db), float(feel.pitch))
    if bool(feel.heavy):
        Audio.play_sfx(Sfx.HIT_HEAVY, -1.0 + minf(3.0, float(feel.stack)), 1.0)
    if with_camera_bump:
        ScreenFx.impact_bump(float(feel.kick), float(feel.duration), direction_x)
