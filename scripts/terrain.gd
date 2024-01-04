class_name Terrain extends StaticBody3D

'''
Holds terrain information.
'''

enum SurfaceType {
	DEFAULT,
	NO_SLIP,
	SLIPPERY,
	LAVA
}

enum AudioType {
	GRASS,
	SOFT,
	METAL,
	CRUNCHY
}

@export_category("Terrain")
## The surface type of this terrain.
@export var surface_type : SurfaceType
## The surface audio type of this terrain.
@export var audio_type : AudioType
