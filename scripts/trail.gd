class_name Trail3D extends MeshInstance3D

'''
Creates a trail at defined position.
'''

@export_category("Trail3D")

## Determines if the trail is currently being emitted.
@export var emit = true
## The amount of time the trail will extend.
@export var lifespan = 1.0
## The smoothness of the trail.
@export var motionDelta = 0.1

@export_group("Width")
## The width of the trail when first emitted.
@export var fromWidth = 0.5
## The width of the trail at the very end of it's cycle.
@export var toWidth = 0.0
## The speed in which to accelerate the trail's width.
@export_range(0.5, 1.5) var scaleAcceleration:float  = 1.0

@export_group("Visual")
## Whether or not to scale the material's texture associated with the trail.
@export var scaleTexture = true
## The color of the start of the trail.
@export var startColor = Color(1.0, 1.0, 1.0, 1.0)
## The color of the end of the trail.
@export var endColor = Color(1.0, 1.0, 1.0, 0.0)

var points : Array = []
var widths : Array = []
var lifePoints : Array = []

## The old position of the trail
var oldPos : Vector3

func _ready() -> void:
	oldPos = get_global_transform().origin
	mesh = ImmediateMesh.new()

func _physics_process(delta) -> void:

	if (oldPos - get_global_transform().origin).length() > motionDelta and emit:
		appendPoint()
		oldPos = get_global_transform().origin

	var p = 0
	var max_points = points.size()
	while p < max_points:
		lifePoints[p] += delta
		if lifePoints[p] > lifespan:
			removePoint(p)
			p -= 1
			if (p < 0): p = 0

		max_points = points.size()
		p += 1

	mesh.clear_surfaces()

	if points.size() < 2:
		return

	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(points.size()):
		var t = float(i) / (points.size() - 1.0)
		var currColor = startColor.lerp(endColor, 1 - t)
		mesh.surface_set_color(currColor)

		var currWidth = widths[i][0] - pow(1-t, scaleAcceleration) * widths[i][1]

		if scaleTexture:
			var t0 = motionDelta * i
			var t1 = motionDelta * (i + 1)
			mesh.surface_set_uv(Vector2(t0, 0))
			mesh.surface_add_vertex(to_local(points[i] + currWidth))
			mesh.surface_set_uv(Vector2(t1, 1))
			mesh.surface_add_vertex(to_local(points[i] - currWidth))
		else:
			var t0 = i / points.size()
			var t1 = t

			mesh.surface_set_uv(Vector2(t0, 0))
			mesh.surface_add_vertex(to_local(points[i] + currWidth))
			mesh.surface_set_uv(Vector2(t1, 1))
			mesh.surface_add_vertex(to_local(points[i] - currWidth))
	mesh.surface_end()

func appendPoint() -> void:
	points.append(get_global_transform().origin)
	widths.append([
		get_global_transform().basis.x * fromWidth,
		get_global_transform().basis.x * fromWidth - get_global_transform().basis.x * toWidth])
	lifePoints.append(0.0)

func removePoint(i) -> void:
	points.remove_at(i)
	widths.remove_at(i)
	lifePoints.remove_at(i)
