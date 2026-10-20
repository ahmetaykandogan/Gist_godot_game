class_name StatusVisuals
extends RefCounted
## How each status looks. To show a new status, add ONE line to STYLES.
## Unknown statuses still show up (grey chip with their name).

const BUFF := Color("2e8b57")
const DEBUFF := Color("a33b3b")
const NEUTRAL := Color("55606b")

# status name -> [text shown, chip color]
const STYLES := {
	"Fury": ["Fury", BUFF],
	"Spike": ["Spike", BUFF],
	"Curse": ["Curse", DEBUFF],
}

static func label_of(status: String) -> String:
	return STYLES[status][0] if STYLES.has(status) else status

static func color_of(status: String) -> Color:
	return STYLES[status][1] if STYLES.has(status) else NEUTRAL
