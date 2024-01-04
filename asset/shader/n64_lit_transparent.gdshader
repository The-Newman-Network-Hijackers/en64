shader_type spatial;

#define LIT diffuse_lambert, vertex_lighting, cull_back
#define DEPTH depth_draw_opaque
#define BLEND blend_mix
#define ALPHA_BLEND

#include "n64_base.gdshaderinc"
