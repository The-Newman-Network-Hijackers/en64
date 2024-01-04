shader_type spatial;

#define LIT diffuse_lambert, vertex_lighting, cull_disabled
#define DEPTH depth_draw_always
#define BLEND blend_mix
#define ALPHA_SCISSOR
#define DECOR_WAVE

#include "n64_base.gdshaderinc"
