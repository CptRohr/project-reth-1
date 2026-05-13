extends CanvasLayer

@onready var anim = $AnimationPlayer

func fade_out():
	print("START FADE OUT")

	anim.play("fade_out")

	print(anim.current_animation)

	await anim.animation_finished

	print("DONE")