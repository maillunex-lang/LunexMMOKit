shader_type spatial;
render_mode cull_disabled;
uniform sampler2D control_map : filter_linear, repeat_disable;
uniform sampler2D layer0 : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D layer1 : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D layer2 : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 tiling0=vec2(20.0);
uniform vec2 tiling1=vec2(40.0);
uniform vec2 tiling2=vec2(20.0);
void fragment(){
 vec3 w=texture(control_map,UV).rgb;
 w/=max(dot(w,vec3(1.0)),0.0001);
 ALBEDO=texture(layer0,UV*tiling0).rgb*w.r+texture(layer1,UV*tiling1).rgb*w.g+texture(layer2,UV*tiling2).rgb*w.b;
 ROUGHNESS=1.0;
}
