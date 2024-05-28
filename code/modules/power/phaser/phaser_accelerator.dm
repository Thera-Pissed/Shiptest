#define WATTS_PER_GHZ 100
#define CAPACITOR_CHARGE_PER_CYCLE 1000

#define LOW_HEAT_THRESHOLD 1000
#define CRITICAL_HEAT_THRESHOLD 2000

#define EXTREME_MELTDOWN 5000
#define MEDIUM_MELTDOWN 2500

/obj/machinery/power/phaser/phaser_accelerator
	name = "particle blasta"
	desc = "particle yeeaAAAAH!!"
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "end_cap"
	use_power = IDLE_POWER_USE
	dir = EAST
	var/checking_parts
	var/list/phasers = list()
	var/datum/weakref/cooler
	var/on = FALSE
	var/list/all_cells = list()
	var/total_cells = 0
	var/total_dampen = 0
	var/total_system_heat = 0
	var/frequency = 0 // used to determine activity and power consumption
	var/exposure = 0 //0 to 100, used to determine cell depletion and activity
	var/total_power_output = 0
	var/total_activity = 0
	var/capacitor = 0
	var/capacitor_max = 1e5

//decon stuff

/obj/machinery/power/phaser/phaser_accelerator/Destroy()
	kill_parts()
	return ..()

/obj/machinery/power/phaser/phaser_accelerator/on_deconstruction()
	kill_parts()
	return ..()

//parts procs

/obj/machinery/power/phaser/phaser_accelerator/proc/find_parts() //iterates over each turf in the direction it's facing, continuing only if it finds a chamber, and ending otherwise.
	kill_parts()
	var/turf/turf = loc
	checking_parts = TRUE
	while(checking_parts)
		turf = get_step(turf, dir)
		check_for_part(turf)
	if(phasers && cooler)
		return TRUE
	return FALSE

/obj/machinery/power/phaser/phaser_accelerator/proc/kill_parts() //removes connected chambers and cooler
	phasers.Cut()
	cooler = null

/obj/machinery/power/phaser/phaser_accelerator/proc/check_for_part(turf) //checks for chambers and coolers on turfs sent by find_parts()
	var/chamberpath = /obj/machinery/power/phaser/phaser_chamber
	var/coolerpath = /obj/machinery/power/phaser/phaser_cooler
	for(var/obj/machinery/power/phaser/potential in turf)
		if(potential.dir == dir && potential.anchored && !(potential.machine_stat &(BROKEN)))
			if(istype(potential, chamberpath))
				var/obj/machinery/power/phaser/phaser_chamber/chamber = potential
				phasers += chamber
				chamber.accelerator = src
				chamber = null
				return
			if(istype(potential, coolerpath))
				var/obj/machinery/power/phaser/phaser_cooler/potential_cooler = potential
				potential_cooler.accelerator = src
				cooler = WEAKREF(potential_cooler)
				return
	checking_parts = FALSE
//tool stuff

/obj/machinery/power/phaser/phaser_accelerator/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_MULTITOOL)
		if(find_parts())
			playsound(src, 'sound/misc/box_deploy.ogg', 50)
			to_chat(user, "<span class='notice'>[src] connects successfully.</span>")
		else
			to_chat(user, "<span class='warning'>[src] fails to connect!</span>")
	else if(I.tool_behaviour == TOOL_SCREWDRIVER)
		on = !on
		to_chat(user, "<span class='notice'>[src] turns [on ? "on" : "off"].</span>")
	else
		return .. ()

/obj/machinery/power/phaser/phaser_accelerator/AltClick(mob/user)
	frequency = clamp(input(user, "Choose A Frequency!", "Frequency") as num, 0, 9000)
	exposure = clamp(input(user, "Choose A Rate!", "Rate") as num, 0, 100)
	to_chat(user, "<span class='notice'>[src] is set to [frequency]GHz at [exposure]%.</span>")

/obj/machinery/power/phaser/phaser_accelerator/examine()
	. = ..()
	. += "[src] is [on ? "running!" : "offline."]"
	if(on)
		. += "[src] is running at [frequency]GHz at [exposure]%"
/*


phaser PROCESS SECTION

Y   Y  EEEEE  SSSSS         GGGGG  EEEEE  CCCCC  !!
Y   Y  E      S             G      E      C      !!
 Y Y   EEEEE  SSSSS         G  GG  EEEEE  C      !!
  Y    E          S         G   G  E      C
  Y    EEEEE  SSSSS         GGGGG  EEEEE  CCCCC  !!

*/


/obj/machinery/power/phaser/phaser_accelerator/process()
	//find parts
	if(!find_parts())
		return

	//figure out if we've got power to resonate
	var/power_use = round(frequency * WATTS_PER_GHZ,1)
	if(!avail(power_use))
		if(capacitor < power_use)
			on = FALSE
			capacitor = 0
		else
			capacitor -= power_use
	else
		add_load(power_use)

	//make the cells work
	all_cells.Cut()
	for (var/obj/machinery/power/phaser/phaser_chamber/chamber in phasers)
		all_cells.Add(chamber.contents)
	total_cells = all_cells.len
	if(!total_cells)
		return
	total_dampen = 0
	total_system_heat = 0 //measured in Joules of heat. I think
	total_power_output = 0
	total_activity = 0
	var/total_heat_capacity = 0

	for (var/obj/item/phaser_cell/control/control_cell in all_cells)
		total_dampen += control_cell.dampen
	for (var/obj/item/phaser_cell/cell in all_cells)
		if(!on)
			cell.resonate(0, total_dampen)
		else
			cell.resonate(frequency, total_dampen)
		if(!cell)
			continue
		total_power_output += cell.power_output
		total_system_heat += cell.cell_heat
		total_heat_capacity += cell.heat_capacity
		total_activity += cell.activity
	//cooler time
//	total_heat_capacity += cooler.heat_capacity
//	total_system_heat += cooler.stored_heat
//average heats, cool heater, then average and distribute again?
	//failure states
	if(total_system_heat > LOW_HEAT_THRESHOLD)
		if(total_system_heat > CRITICAL_HEAT_THRESHOLD)
			meltdown(total_activity, all_cells)

	//make power
	for (var/obj/machinery/power/phaser/phaser_chamber/chamber in phasers)
		chamber.add_avail(round(total_power_output / phasers.len,1))


/obj/machinery/power/phaser/phaser_accelerator/proc/meltdown(activity, var/list/all_cells = list())
	if(!find_parts())
		explosion(src,4,4,3,3, smoke = TRUE)
		return
	if(activity > EXTREME_MELTDOWN)
		cleanup()
		return
	else if(activity > MEDIUM_MELTDOWN)
		cleanup()
		return
	else
		cleanup()
		return

/obj/machinery/power/phaser/phaser_accelerator/proc/cleanup(var/list/phasers = list(), var/obj/machinery/power/phaser/phaser_cooler/cooler)
	//cooler.meltdown()
	for(var/obj/machinery/power/phaser/phaser_chamber/chamber in phasers)
		chamber.meltdown()
	kill_parts()
	Destroy(src)
