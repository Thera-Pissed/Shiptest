#define WATTS_PER_GHZ 100
#define CAPACITOR_CHARGE_PER_CYCLE 1000

#define LOW_HEAT_THRESHOLD 1000
#define CRITICAL_HEAT_THRESHOLD 2000

#define EXTREME_MELTDOWN 5000
#define MEDIUM_MELTDOWN 2500

/obj/machinery/power/reactor_accelerator
	name = "particle blasta"
	desc = "particle yeeaAAAAH!!"
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "end_cap"
	density = TRUE
	use_power = IDLE_POWER_USE
	dir = EAST
	var/checking_parts
	var/list/reactors = list()
	var/obj/machinery/power/reactor_cooler/cooler
	var/on = FALSE
	var/list/all_rods = list()
	var/total_rods = 0
	var/total_dampen = 0
	var/total_rod_heat = 0
	var/frequency = 0
	var/total_power_output = 0
	var/total_activity = 0
	var/capacitor = 0
	var/capacitor_max = 1e6

//decon stuff

/obj/machinery/power/reactor_accelerator/Destroy()
	kill_parts()
	return ..()

/obj/machinery/power/reactor_accelerator/on_deconstruction()
	kill_parts()
	return ..()

//parts procs

/obj/machinery/power/reactor_accelerator/proc/find_parts() //iterates over each turf in the direction it's facing, continuing only if it finds a chamber, and ending otherwise.
	kill_parts()
	var/turf/turf = loc
	checking_parts = TRUE
	while(checking_parts)
		turf = get_step(turf, dir)
		check_for_part(turf)
	if(reactors && cooler)
		return TRUE
	return FALSE

/obj/machinery/power/reactor_accelerator/proc/kill_parts() //removes connected chambers and cooler
	reactors.Cut()
	cooler = null

/obj/machinery/power/reactor_accelerator/proc/check_for_part(turf) //checks for chambers and coolers on turfs sent by find_parts()
	var/obj/machinery/power/reactor_chamber/chamber
	var/chamberpath = /obj/machinery/power/reactor_chamber
	var/coolerpath = /obj/machinery/power/reactor_cooler
	chamber = locate(chamberpath) in turf
	if(chamber && chamber.dir == dir && chamber.anchored && !(chamber.machine_stat &(BROKEN)))
		reactors += chamber
		chamber.accelerator = src
		chamber = null
		return
	cooler = locate(coolerpath) in turf
	if(cooler && cooler.dir == dir && cooler.anchored && !(cooler.machine_stat &(BROKEN)))
		cooler.accelerator = src
	checking_parts = FALSE

//tool stuff

/obj/machinery/power/reactor_accelerator/attackby(obj/item/I, mob/user, params)
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

/obj/machinery/power/reactor_accelerator/AltClick(mob/user)
	frequency = clamp(input(user, "Choose A Frequency!", "Frequency") as num, 0, 9000)
	to_chat(user, "<span class='notice'>[src] is set to [frequency]GHz.</span>")

//examine things

/obj/machinery/power/reactor_accelerator/examine()
	. = ..()
	. += "[src] is [on ? "running!" : "offline."]"
	if(on)
		. += "[src] is running at [frequency]GHz"
/*


REACTOR PROCESS SECTION

Y   Y  EEEEE  SSSSS         GGGGG  EEEEE  CCCCC  !!
Y   Y  E      S             G      E      C      !!
 Y Y   EEEEE  SSSSS         G  GG  EEEEE  C      !!
  Y    E          S         G   G  E      C
  Y    EEEEE  SSSSS         GGGGG  EEEEE  CCCCC  !!

*/


/obj/machinery/power/reactor_accelerator/process()
	//find parts
	if(!find_parts())
		return
	//figure out if we've got power to resonate
	var/power_use = round(frequency * WATTS_PER_GHZ,1)
	if(!avail(power_use))
		if(capacitor < power_use)
			on = FALSE
		else
			capacitor -= power_use
	else
		add_load(power_use)

	//make the rods work
	all_rods.Cut()
	for (var/obj/machinery/power/reactor_chamber/chamber in reactors)
		all_rods.Add(chamber.contents)
	total_rods = all_rods.len
	if(!total_rods)
		return
	total_dampen = 0
	total_rod_heat = 0
	total_power_output = 0
	total_activity = 0

	for (var/obj/item/reactor_rod/control/control_rod in all_rods)
		total_dampen += control_rod.dampen * control_rod.depth
	for (var/obj/item/reactor_rod/rod in all_rods)
		if(!on)
			rod.resonate(0, total_dampen)
		else
			rod.resonate(frequency, total_dampen)
		total_power_output += rod.power_output
		total_rod_heat += rod.rod_heat
		total_activity += rod.activity
	//cooler time
	total_rod_heat = cooler.cool(total_rod_heat)
		for (var/obj/item/reactor_rod/rod in all_rods)
			rod.rod_heat = total_rod_heat / all_rods.len
	//failure states
	if(total_rod_heat > LOW_HEAT_THRESHOLD)
		if(total_rod_heat > CRITICAL_HEAT_THRESHOLD)
			for (var/obj/item/reactor_rod/rod in all_rods)
			meltdown(total_activity, all_rods)

	//make power
	for (var/obj/machinery/power/reactor_chamber/chamber in reactors)
		chamber.add_avail(round(total_power_output / reactors.len,1))


/obj/machinery/power/reactor_accelerator/proc/meltdown(activity, var/list/all_rods = list())
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
/obj/machinery/power/reactor_accelerator/proc/cleanup(var/list/reactors = list(), /obj/machinery/power/reactor_cooler/cooler)
	cooler.meltdown()
	for(var/obj/machinery/power/reactor_chamber/chamber in reactors)
		chamber.meltdown()
	kill_parts()
	Destroy(src)
