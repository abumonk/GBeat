## Bar - Cache structure for quants within a single bar
class_name Bar
extends RefCounted

var quant_indices: Array[int] = []  ## Indices into pattern's quants array
var quants: Array[Quant] = []       ## Quants in this bar


func clear() -> void:
	quant_indices.clear()
	quants.clear()


func add_quant(index: int, quant: Quant) -> void:
	quant_indices.append(index)
	quants.append(quant)


func get_quant_count() -> int:
	return quants.size()
