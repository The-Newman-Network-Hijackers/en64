shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled, depth_draw_opaque;

// Water color
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 out_color: source_color = vec4(0.0, 0.2, 1.0, 1.0);

uniform vec2 uv_pan_velocity = vec2(0.0);
uniform float amount: hint_range(0.2, 5.0, 0.1) = 0.8;
uniform float speed: hint_range(0.1, 5.0, 0.1) = 1;
uniform float metallic = 0.6;
uniform float specular = 0.5;
uniform float roughness = 0.2;

float generateOffset(float x, float z, float val1, float val2, float time) {
	float radiansX = ((mod(x + z * x * val1, amount) / amount) + (time * speed) * mod(x * 0.8 + z, 1.5)) * 2.0 * 3.14;
	float radiansZ = ((mod(val2 * (z * x + x * z), amount) / amount) + (time * speed) * 2.0 * mod(x, 2.0)) * 2.0 * 3.14;
	
	return amount * 0.5 * (sin(radiansZ) * cos(radiansX));
}

vec3 applyDistortion(vec3 vertex, float time) {
	float xd = generateOffset(vertex.x, vertex.z, 0.2, 0.1, time);
	float yd = generateOffset(vertex.x, vertex.z, 0.1, 0.3, time);
	float zd = generateOffset(vertex.x, vertex.z, 0.15, 0.2, time);
	
	return vertex + vec3(xd, yd, zd);
}

float hash(vec2 p) {
  return fract(sin(dot(p * 17.17, vec2(14.91, 67.31))) * 4791.9511);
}

float noise(vec2 x) {
  vec2 p = floor(x);
  vec2 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);
  vec2 a = vec2(1.0, 0.0);
  return mix(mix(hash(p + a.yy), hash(p + a.xy), f.x),
         mix(hash(p + a.yx), hash(p + a.xx), f.x), f.y);
}

float fbm(vec2 x, float time) {
  float height = 0.0;
  float amplitude = 0.5;
  float frequency = 0.5;
  for (int i = 0; i < 6; i++){
    height += noise(x * frequency + time * 3.0 * speed) * amplitude;
    amplitude *= 0.5;
    frequency *= 2.0;
  }
  return height;
}

void vertex() {
	VERTEX = applyDistortion(VERTEX, TIME * 0.1);
	COLOR.xyz = vec3(fbm(VERTEX.zx * .25, TIME));
	UV.x += (TIME + sin(TIME * .8f)) * uv_pan_velocity.x;
	UV.y += (TIME - sin(TIME * 1.2f)) * uv_pan_velocity.y;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(albedo_texture, base_uv);
	//NORMAL = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	ALBEDO = out_color.rgb * albedo_tex.rgb / COLOR.rgb;
	ALPHA = out_color.a;
}