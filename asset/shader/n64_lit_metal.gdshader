shader_type spatial;

#define LIT diffuse_lambert, vertex_lighting, cull_disabled
#define DEPTH depth_draw_opaque
#define BLEND blend_mix
#define METAL

#include "n64_base.gdshaderinc"
