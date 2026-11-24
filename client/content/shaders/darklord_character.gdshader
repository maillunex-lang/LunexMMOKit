shader_type spatial;
render_mode unshaded, cull_back;
uniform sampler2D main_tex : source_color, filter_linear_mipmap;
uniform sampler2D spec_tex : hint_default_white, filter_linear_mipmap;
uniform float spec_power = 1.0;
uniform float spec_intensity = 1.0;
uniform float spec_power2 = 1.0;
uniform float spec_intensity2 = 1.0;
uniform vec3 light_direction = vec3(0.4, 0.8, 0.4);
uniform vec3 light_color : source_color = vec3(1.0);
uniform float light_intensity = 0.5;
uniform bool cutout = false;
uniform float cutoff = 0.5;
uniform bool flow_enabled = false;
uniform sampler2D flow_tex : hint_default_black, filter_linear_mipmap;
uniform sampler2D flow_mask : hint_default_white, filter_linear_mipmap;
uniform vec2 flow_speed = vec2(0.0);
uniform vec2 flow_scale = vec2(1.0);
uniform vec2 flow_offset = vec2(0.0);
uniform vec3 flow_color : source_color = vec3(1.0);
uniform float flow_intensity = 1.0;
void fragment() {
	vec4 base = texture(main_tex, UV);
	if (cutout && base.a < cutoff) { discard; }
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	vec3 l = normalize((VIEW_MATRIX * vec4(light_direction, 0.0)).xyz);
	vec3 mask = texture(spec_tex, UV).rgb;
	float nv = dot(n, v);
	vec3 primary = pow(clamp(nv, 0.0, 1.0), spec_power * 128.0) * spec_intensity * mask;
	vec3 secondary = pow(clamp(dot(normalize(l + v), n), 0.0, 1.0), spec_power2 * 32.0) * spec_intensity2 * mask * light_color * light_intensity;
	ALBEDO = base.rgb * (nv * 0.3 + 0.7) + primary + secondary;
	if (flow_enabled) {
		ALBEDO += texture(flow_tex, UV2 * flow_scale + flow_offset + fract(flow_speed * TIME)).r * flow_color * texture(flow_mask, UV).r * flow_intensity;
	}
}
