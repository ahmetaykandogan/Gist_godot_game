class_name DamageEffect
extends SkillEffect

@export var amount: int = 1
@export var hit_time: int = 1          # number of hits
@export var hit_delay: float = 0.15    # seconds between hits

func execute(user, pattern, slots) -> void:
	for i in hit_time:
		if not is_instance_valid(user) or user.dying:
			return
		# The targets are asked again for EVERY hit: dead ones are gone,
		# so the next hit goes to the unit behind (or the next lane).
		var targets: Array = pattern.get_targets(user, slots)
		if targets.is_empty():
			return
		for target in targets:
			user.deal_damage(target, amount)
		if i < hit_time - 1:
			await user.get_tree().create_timer(hit_delay).timeout
