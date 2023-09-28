extends Node

enum LOGICGATE {
	BUFFER,
	NOT,
	AND,
	OR,
	NAND,
	NOR,
	XOR,
	XNOR,
	BATCH_AND,
	BATCH_OR,
	BATCH_NAND,
	BATCH_NOR
}

signal voltage_sent(voltage)

export(Texture) var tile_texture
export(LOGICGATE) var gate_type

var voltage_inputs := [false, false]
var real_voltage = true

func recieve_voltage(voltage: bool, index: int) -> void:
	if index+1 > voltage_inputs.size():
		voltage_inputs.resize(index+1)
	voltage_inputs[index] = voltage
	var new_voltage = false
	match gate_type:
		LOGICGATE.BUFFER:
			new_voltage = voltage_inputs[0]
		LOGICGATE.NOT:
			new_voltage = !voltage_inputs[0]
		LOGICGATE.AND:
			new_voltage = voltage_inputs[0] && voltage_inputs[1]
		LOGICGATE.OR:
			new_voltage = voltage_inputs[0] || voltage_inputs[1]
		LOGICGATE.NAND:
			new_voltage = !(voltage_inputs[0] && voltage_inputs[1])
		LOGICGATE.NOR:
			new_voltage = !(voltage_inputs[0] || voltage_inputs[1])
		LOGICGATE.XOR:
			new_voltage = !(voltage_inputs[0] == voltage_inputs[1])
		LOGICGATE.XNOR:
			new_voltage = voltage_inputs[0] == voltage_inputs[1]
		LOGICGATE.BATCH_AND:
			var idx = 0
			for voltage in voltage_inputs:
				if idx == 0:
					new_voltage = voltage
				else:
					new_voltage = new_voltage && voltage
				idx += 1
		LOGICGATE.BATCH_OR:
			var idx = 0
			for voltage in voltage_inputs:
				if idx == 0:
					new_voltage = voltage
				else:
					new_voltage = new_voltage || voltage
				idx += 1
		LOGICGATE.BATCH_NAND:
			var idx = 0
			for voltage in voltage_inputs:
				if idx == 0:
					new_voltage = voltage
				else:
					new_voltage = new_voltage && voltage
				idx += 1
			new_voltage = !new_voltage
		LOGICGATE.BATCH_NOR:
			var idx = 0
			for voltage in voltage_inputs:
				if idx == 0:
					new_voltage = voltage
				else:
					new_voltage = new_voltage || voltage
				idx += 1
			new_voltage = !new_voltage
	if new_voltage != real_voltage:
		real_voltage = new_voltage
		emit_signal("voltage_sent", real_voltage)
	
