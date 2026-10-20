class_name StatusScaledDamageEffect
extends SkillEffect
## Deals (stacks of a status) x damage_per_stack, e.g. 4 x Spike.

enum Holder { USER, TARGET }

@export var status: String = "Spike"
@export var damage_per_stack: int = 4
@export var read_from: Holder = Holder.USER
@export var consume: bool = true

func execute(user, pattern, slots) -> void:
	var user_stacks: int = user.get_stacks(status)      # read once, so every target gets the same value
	for target in pattern.get_targets(user, slots):
		if not is_instance_valid(target) or target.dying:
			continue
		var stacks: int = user_stacks if read_from == Holder.USER else target.get_stacks(status)
		if stacks > 0:
			user.deal_damage(target, stacks * damage_per_stack)
		if consume and read_from == Holder.TARGET:
			target.remove_status(status)
	if consume and read_from == Holder.USER:
		user.remove_status(status)                       # spent once, after every target was hit
