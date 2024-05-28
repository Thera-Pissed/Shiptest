#define FREQ_ROOT 2
#define CRITICAL_ACTIVITY 9000

/obj/item/phaser_cell
	name = "phaser cell"
	desc = "you probably shouldn't be seeing this."
	icon = 'icons/obj/power.dmi'
	icon_state = "phaser-cell-empty"
	var/dampen = 0
	var/resonance = 0
	var/cell_heat = 0
	var/cell_damage = 0
	var/cell_depletes = FALSE
	var/cell_depletion = 100
	var/power_output = 0
	var/power_multiplier = 10
	var/accuracy_exp = 2
	var/flat_dampen = 10 //?
	var/activity_multiplier = 50
	var/heat_multiplier = 1
	var/activity = 0
	var/accuracy = 0
	var/heat_capacity = 500


/obj/item/phaser_cell/proc/frequency_accuracy(freq, res)
	var/res_freq = round(freq / res, 1) * res //finds the closest multple of res to freq
	var/res_diff = abs(res_freq - freq) //finds the difference between the freq and the res_freq
	return 1 - (res_diff / (res * 0.5)) //turns the difference into a number between 1 and 0, with 0 being halfway between and 1 being perfect

/obj/item/phaser_cell/proc/resonate(freq = 0, dampen = 0, exposure = 0)
	if (cell_depletes == TRUE && cell_depletion == 0)
		new /obj/item/phaser_cell/expended(loc)
		qdel(src)
		return
	exposure /= 100 // turns range from 0 - 100 to 0 - 1.00
	accuracy = 0
	if(resonance && freq)
		accuracy = frequency_accuracy(freq, resonance) ** accuracy_exp
	if(cell_depletes == TRUE)
		cell_depletion -= exposure
	activity += round((ROOT(FREQ_ROOT, freq) * accuracy * activity_multiplier * exposure) - (dampen + flat_dampen), 0.01)
	activity = max(activity, 0)
	cell_heat += freq * heat_multiplier * exposure
	power_output = activity * power_multiplier

/obj/item/phaser_cell/process()
	resonate()

/obj/item/phaser_cell/proc/meltdown()
	Destroy(src)

/obj/item/phaser_cell/fuel
	name = "generic fuel cell"
	desc = "you fuel"
	icon_state = "phaser-cell-plasma"
	cell_depletes = TRUE

/obj/item/phaser_cell/expended
	name = "expended fuel cell"
	desc = "all gone. no more"
	//icon_state TODO

/obj/item/phaser_cell/fuel/plasma
	name = "plasma cell"
	desc = "blasma."
	icon_state = "phaser-cell-plasma"
	resonance = 5

/obj/item/phaser_cell/fuel/uranium
	name = "uranium cell"
	desc = "uranium cell has done and got me down."
	icon_state = "phaser-cell-uranium"
	resonance = 11
	accuracy_exp = 3

/obj/item/phaser_cell/control
	name = "control cell"
	desc = "yar."
	icon_state = "phaser-cell-control"

/obj/item/phaser_cell/control/basic
	name = "basic control cell"
	desc = "basic cell."
	dampen = 50
