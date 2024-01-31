/obj/machinery/power/reactor_cooler //temporary
	name = "reactor cooler"
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "power_box"
	density = TRUE
	dir = EAST
	var/accelerator
	var/cooling_power

/obj/machinery/power/reactor_cooler/proc/cool(total_heat)
	if(total_heat)
		return (max(total_heat - cooling_power, 0))
	else
		return(0)

/obj/machinery/power/reactor_cooler/proc/meltdown()
	Destroy(src)
