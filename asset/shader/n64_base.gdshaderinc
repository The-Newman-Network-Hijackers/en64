render_mode LIT, shadows_disabled, specular_disabled, DEPTH, BLEND;

uniform vec4 modulate_color : source_color = vec4(1.0);

#ifdef NO_REPEAT
uniform sampler2D albedoTex : source_color, filter_nearest_mipmap, repeat_disable;
#endif

#ifndef NO_TEXTURE
#ifndef NO_REPEAT
uniform sampler2D albedoTex : source_color, filter_nearest_mipmap, repeat_enable;
#endif
#endif

#ifdef NORMAL_TEX
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_scale : hint_range(-16,16);
#endif

#if !defined(NO_TEXTURE) && !defined(METAL)  // METAL doesn't use UV, so no need for panning properties
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(.0, .0);
uniform vec2 uv_pan_velocity = vec2(0.0);
#endif

#ifdef DECOR_WAVE
	uniform float wind_strength : hint_range(0.01, 2.0, 0.02);
	uniform float wind_speed : hint_range(0.1, 5.0, 0.1);
#endif

#ifdef ALPHA_SCISSOR
uniform bool billboard = false;
uniform bool y_billboard = false;
uniform float alpha_scissor : hint_range(0, 1) = 0.1;
#endif

// https://www.emutalk.net/threads/emulating-nintendo-64-3-sample-bilinear-filtering-using-shaders.54215/
vec4 n64BilinearFilter(vec2 texcoord) {
	ivec2 tex_size = textureSize(albedoTex, 0);
	float Texture_X = float(tex_size.x);
	float Texture_Y = float(tex_size.y);

	vec2 tex_pix_a = vec2(1.0/Texture_X,0.0);
	vec2 tex_pix_b = vec2(0.0,1.0/Texture_Y);
	vec2 tex_pix_c = vec2(tex_pix_a.x,tex_pix_b.y);
	vec2 half_tex = vec2(tex_pix_a.x*0.5,tex_pix_b.y*0.5);
	vec2 UVCentered = texcoord - half_tex;

	vec4 diffuseColor = texture(albedoTex,UVCentered);
	vec4 sample_a = texture(albedoTex,UVCentered+tex_pix_a);
	vec4 sample_b = texture(albedoTex,UVCentered+tex_pix_b);
	vec4 sample_c = texture(albedoTex,UVCentered+tex_pix_c);

	float interp_x = modf(UVCentered.x * Texture_X, Texture_X);
	float interp_y = modf(UVCentered.y * Texture_Y, Texture_Y);

	if (UVCentered.x < 0.0)
	{
		interp_x = 1.0-interp_x*(-1.0);
	}
	if (UVCentered.y < 0.0)
	{
		interp_y = 1.0-interp_y*(-1.0);
	}

	diffuseColor = (diffuseColor + interp_x * (sample_a - diffuseColor) + interp_y * (sample_b - diffuseColor))*(1.0-step(1.0, interp_x + interp_y));
	diffuseColor += (sample_c + (1.0-interp_x) * (sample_b - sample_c) + (1.0-interp_y) * (sample_a - sample_c))*step(1.0, interp_x + interp_y);
	
    return diffuseColor;
}

void vertex()
{
#if !defined(NO_TEXTURE) && !defined(METAL)  // METAL doesn't use UV, so no need to pan UVs
	UV = UV * uv_scale + uv_offset;
	UV += uv_pan_velocity * TIME;
#endif

#ifdef DECOR_WAVE
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * wind_speed + UV.y) * ( 1.0 - UV.y) * wind_strength;
	VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * wind_speed + UV.y) * ( 1.0 - UV.y) * wind_strength;
#endif

#ifdef ALPHA_SCISSOR
	if (y_billboard)
	{
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],MODEL_MATRIX[1],vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz,MODEL_MATRIX[1].xyz)), 0.0),MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(1.0, 0.0, 0.0, 0.0),vec4(0.0, 1.0/length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0),vec4(0.0, 0.0, 0.0 ,1.0));
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),vec4(0.0, 0.0, 0.0, 1.0));
	}
	else if (billboard)
	{
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
#endif
}

void fragment()
{
#ifdef METAL
	vec2 texture_uv = vec2(NORMAL.x / 2.0 + 0.5, (-NORMAL.y) / 2.0 + 0.5);  // Special thanks to Adam McLaughlan
#elif !defined(NO_TEXTURE)
	vec2 texture_uv = UV;
#endif

	vec4 color_base = COLOR * modulate_color;

#ifdef NO_TEXTURE
	ALBEDO = color_base.rgb;
#else
	vec4 texture_color = n64BilinearFilter(texture_uv);
	//texture_color *= COLOR.0
	ALBEDO = (color_base * texture_color).rgb;
#endif

#ifdef NORMAL_TEX
	NORMAL_MAP = texture(texture_normal,texture_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
#endif

#if defined(ALPHA_BLEND) || defined(ALPHA_SCISSOR)
	ALPHA = texture_color.a * color_base.a;
#endif

#ifdef ALPHA_SCISSOR
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
#endif
}
