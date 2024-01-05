shader_type spatial;

#define LIT unshaded, cull_disabled
#define DEPTH depth_draw_always
#define BLEND blend_mix
#define ALPHA_SCISSOR

#include "n64_base.gdshaderinc"
