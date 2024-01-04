shader_type spatial;
render_mode cull_disabled;

uniform float speed = 2.0;
uniform vec3 frequency = vec3(2.5, 5.0, 2.5);
uniform vec3 amplitude = vec3(0.05, 0.1, 0.05);
uniform float inclination = -0.04;

uniform sampler2D tex: hint_default_white;

void fragment(){
	vec4 albedo_tex = texture(tex, UV);
	ALBEDO = COLOR.rgb * albedo_tex.rgb;
}

void vertex(){
	VERTEX.y += sin((UV.x - TIME * speed) * frequency.y) * amplitude.y * UV.x;
	VERTEX.x += cos((UV.y - TIME * speed) * frequency.x) * amplitude.x * 0.1 * UV.x;
	VERTEX.z += sin((UV.x - TIME * speed) * frequency.z) * amplitude.z * UV.x;
	VERTEX.x -= (1.0 - UV.y) * inclination;
}