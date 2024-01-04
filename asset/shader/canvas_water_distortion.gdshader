shader_type canvas_item;

uniform vec4 tint : source_color;
uniform float wave_speed = 3.0; //wave loop speed
uniform float wave_freq = 10.0; //wave vertical freq
uniform float wave_width = 1; //wave width
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
 
void fragment(){
	vec2 wave_uv_offset;
	wave_uv_offset.x = cos((TIME*wave_speed)+UV.x+UV.y*wave_freq*2.0)*wave_width*0.01;
	COLOR = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + wave_uv_offset.x, SCREEN_UV.y)) * tint;
}