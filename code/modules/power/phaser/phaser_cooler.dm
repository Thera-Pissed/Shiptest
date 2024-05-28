/obj/machinery/power/reactor_cooler
	name = "reactor cooler"
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "power_box"
	density = TRUE
	dir = EAST
	var/accelerator
	var/stored_heat = 0
	var/heat_capacity = 300
	var/system_heat = 0

/obj/machinery/power/reactor_cooler/proc/meltdown()
	Destroy(src)

/obj/machinery/power/reactor_cooler/proc/cool()
