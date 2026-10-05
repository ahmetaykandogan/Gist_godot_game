class_name RandomAI
extends EnemyAI
func choose_skill(enemy) -> SkillData:
	return enemy.skills.pick_random() if not enemy.skills.is_empty() else null
