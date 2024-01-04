shader_type canvas_item;
render_mode unshaded;

uniform float circle_size : hint_range(0.0, 1.05);
uniform vec2 SCREEN_SIZE = vec2(640, 480);

void fragment() {
	float ratio = SCREEN_SIZE.x / SCREEN_SIZE.y;
	float dist = distance(vec2(0.5, 0.5), vec2(mix(0.5, UV.x, ratio), UV.y));
	COLOR.a = step(circle_size, dist);
}