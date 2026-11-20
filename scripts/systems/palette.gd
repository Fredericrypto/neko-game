class_name Palette
extends RefCounted
## Paleta oficial e-ink do Muchineko (ART_BIBLE). Nenhuma outra cor é permitida.

const INK := Color("#111111")       # Ink Black
const CHARCOAL := Color("#333333")  # Charcoal
const MID := Color("#777777")       # Mid Gray
const WARM := Color("#BEB8AD")      # Warm Gray
const PAPER := Color("#E6E1D7")     # Paper
const IVORY := Color("#F6F4EE")     # Ivory

static func all() -> Array[Color]:
	return [INK, CHARCOAL, MID, WARM, PAPER, IVORY]
