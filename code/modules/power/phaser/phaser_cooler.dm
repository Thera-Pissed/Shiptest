/obj/machinery/power/phaser/phaser_cooler
	name = "phaser cooler"
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "power_box"
	dir = EAST
	var/accelerator
	var/stored_heat = 0
	var/heat_capacity = 300
	var/system_heat = 0

/obj/machinery/power/phaser/phaser_cooler/proc/meltdown()
	Destroy(src)

/obj/machinery/power/phaser/phaser_cooler/proc/cool()
