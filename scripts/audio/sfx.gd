class_name Sfx
##
## SFX 경로 상수. 실제 파일이 없어도 Audio.play_sfx 는 no-op이므로 호출부에서 안전.
## 사용자가 assets/audio/sfx/ 에 같은 이름의 .wav/.ogg 를 떨어뜨리면 자동으로 들리기 시작.
##

const ATTACK := "res://assets/audio/sfx/attack.wav"   # 플레이어 공격 swing
const HURT   := "res://assets/audio/sfx/hurt.wav"     # 플레이어 피격
const HIT    := "res://assets/audio/sfx/hit.wav"      # 적 피격
const DIE    := "res://assets/audio/sfx/die.wav"      # 적 사망
const PICKUP := "res://assets/audio/sfx/pickup.wav"   # 아이템 획득
const POTION := "res://assets/audio/sfx/potion.wav"   # 소모품 사용
