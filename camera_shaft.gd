extends Node3D

var koishi : CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready():
	koishi = get_node("../Koishi")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	global_transform.origin = koishi.global_transform.origin + Vector3(0,1,0)
