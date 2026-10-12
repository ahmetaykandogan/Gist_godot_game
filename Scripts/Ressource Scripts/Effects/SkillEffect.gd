class_name SkillEffect
extends Resource
## Base type of everything a skill can do (damage, heal, status...).

## Runs this effect for a whole skill. Simple effects only override apply();
## multi-step effects (several hits) override execute().
func execute(user, pattern, slots) -> void:
	for target in pattern.get_targets(user, slots):
		if is_instance_valid(target) and not target.dying:
			apply(target, user)

func apply(_target, _source = null) -> void:
	pass
