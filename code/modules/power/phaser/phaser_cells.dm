#define FREQ_ROOT 2
#define CRITICAL_ACTIVITY 9000

/obj/item/reactor_rod
	name = "reactor rod"
	desc = "you probably shouldn't be seeing this."
	icon = 'icons/obj/power.dmi'
	icon_state = "reactor-rod-empty"
	var/dampen = 0
	var/resonance = 0
	var/rod_heat = 0
	var/rod_damage = 0
	var/rod_depletes = FALSE
	var/rod_depletion = 100
	var/power_output = 0
	var/power_multiplier = 10
	var/accuracy_exp = 2
	var/flat_dampen = 10 //?
	var/activity_multiplier = 50
	var/heat_multiplier = 1
	var/activity = 0
	var/accuracy = 0
	var/heat_capacity = 500


/obj/item/reactor_rod/proc/frequency_accuracy(freq, res)
	var/res_freq = round(freq / res, 1) * res //finds the closest multple of res to freq
	var/res_diff = abs(res_freq - freq) //finds the difference between the freq and the res_freq
	return 1 - (res_diff / (res * 0.5)) //turns the difference into a number between 1 and 0, with 0 being halfway between and 1 being perfect

/obj/item/reactor_rod/proc/resonate(freq = 0, dampen = 0, exposure = 0)
	if (rod_depletes == TRUE && rod_depletion == 0)
		new /obj/item/reactor_rod/expended(loc)
		qdel(src)
		return
	exposure /= 100 // turns range from 0 - 100 to 0 - 1.00
	accuracy = 0
	if(resonance && freq)
		accuracy = frequency_accuracy(freq, resonance) ** accuracy_exp
	if(rod_depletes == TRUE)
		rod_depletion -= exposure
	activity += round((ROOT(FREQ_ROOT, freq) * accuracy * activity_multiplier * exposure) - (dampen + flat_dampen), 0.01)
	activity = max(activity, 0)
	rod_heat += freq * heat_multiplier * exposure
	power_output = activity * power_multiplier

/obj/item/reactor_rod/process()
	resonate()

/obj/item/reactor_rod/proc/meltdown()
	Destroy(src)

/obj/item/reactor_rod/fuel
	name = "generic fuel rod"
	desc = "you fuel"
	icon_state = "reactor-rod-plasma"
	rod_depletes = TRUE

/obj/item/reactor_rod/expended
	name = "expended fuel rod"
	desc = "all gone. no more"
	//icon_state TODO

/obj/item/reactor_rod/fuel/plasma
	name = "plasma rod"
	desc = "blasma."
	icon_state = "reactor-rod-plasma"
	resonance = 5

/obj/item/reactor_rod/fuel/uranium
	name = "uranium rod"
	desc = "uranium rod has done and got me down."
	icon_state = "reactor-rod-uranium"
	resonance = 11
	accuracy_exp = 3

/obj/item/reactor_rod/control
	name = "control rod"
	desc = "yar."
	icon_state = "reactor-rod-control"

/obj/item/reactor_rod/control/basic
	name = "basic control rod"
	desc = "basic rod."
	dampen = 50
