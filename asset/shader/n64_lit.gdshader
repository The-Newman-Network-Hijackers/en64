shader_type spatial;

#define LIT diffuse_lambert, vertex_lighting, cull_back
#define DEPTH depth_draw_always
#define BLEND blend_mix
#define NORMAL_TEX

#include "n64_base.gdshaderinc"
