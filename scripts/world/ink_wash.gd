extends CanvasLayer
##
## InkWash — autoload. 「해원」 서사 연출용 '수묵 흑백 오버랩'.
##  · '걷는 회상'(과거 한 장면이 겹쳐올 때) · 보스 직후 정적 · 엔딩 등에서 호출.
##  · 화면(아래 레이어=게임 월드)을 흑백+한지 톤으로 바래게 하되, **게임은 계속 돈다**(조작 유지).
##
## 레이어=5 → 월드(레이어 0) 위, 대화창/HUD(레이어 10+) 아래.
## 즉, 월드만 수묵으로 바래고 대사 글자는 그 위에 또렷이 남는다(읽힘 유지).
##
## 사용:
##   InkWash.enter()        # 수묵으로 바램(기본 0.8s)
##   InkWash.exit()         # 원래 색으로 복귀
##   InkWash.is_active()
##
## 스크린 텍스처 셰이더(탈채도)는 코드에 내장 — 별도 .gdshader import 불필요.
##

const SHADER_CODE := "
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 ink_tone = vec3(0.93, 0.90, 0.82);
void fragment() {
    vec3 c = texture(screen_tex, SCREEN_UV).rgb;
    float g = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 wash = mix(vec3(g), vec3(g) * ink_tone, 0.6);
    COLOR = vec4(mix(c, wash, amount), 1.0);
}
"

var _rect: ColorRect
var _mat: ShaderMaterial
var _tween: Tween


func _ready() -> void:
    layer = 5
    var sh := Shader.new()
    sh.code = SHADER_CODE
    _mat = ShaderMaterial.new()
    _mat.shader = sh
    _mat.set_shader_parameter("amount", 0.0)
    _rect = ColorRect.new()
    _rect.material = _mat
    _rect.color = Color(1, 1, 1, 1)          # 셰이더가 색을 결정 — ColorRect 자체 색은 무의미
    _rect.mouse_filter = Control.MOUSE_FILTER_IGNORE   # 입력 안 막음(조작 유지)
    _rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    _rect.anchor_right = 1.0
    _rect.anchor_bottom = 1.0
    add_child(_rect)


func is_active() -> bool:
    return _mat != null and float(_mat.get_shader_parameter("amount")) > 0.001


## 수묵 흑백으로 바램.
func enter(duration: float = 0.8) -> void:
    _to(1.0, duration)


## 원래 색으로 복귀.
func exit(duration: float = 1.0) -> void:
    _to(0.0, duration)


func _to(target: float, duration: float) -> void:
    if _mat == null:
        return
    if _tween != null and _tween.is_valid():
        _tween.kill()
    _tween = create_tween()
    _tween.tween_property(_mat, "shader_parameter/amount", target, max(0.01, duration)) \
        .set_trans(Tween.TRANS_SINE)
