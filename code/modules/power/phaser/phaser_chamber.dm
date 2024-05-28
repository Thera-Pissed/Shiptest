#define MAX_REACTOR_RODS 3

/obj/machinery/power/reactor_chamber //placeholder
	name = "reactor chamber"
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "fuel_chamber"
	density = TRUE
	dir = EAST
	var/accelerator
	var/list/reactor_rods
	var/open = TRUE

/obj/machinery/power/reactor_chamber/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_CROWBAR)
		open = !open
		to_chat(user, "<span class='notice'>You [open ? "open" : "close"] [src].</span>")
		I.play_tool_sound(src)
		return
	if(!open)
		if(user.a_intent != INTENT_HARM)
			to_chat(user, "<span class='warning'>[src]'s cover is shut!</span>")
			return
		return ..()
	if(istype(I, /obj/item/reactor_rod))
		if(length(contents) < MAX_REACTOR_RODS)
			if(!user.transferItemToLoc(I, src))
				return
			STOP_PROCESSING(SSobj,I) //hands processing over to the reactor
			to_chat(user, "<span class='notice'>You place [I] in [src].</span>")
			update_appearance()
		else
			to_chat(user, "<span class='warning'>[src] is full!</span>")
	else if(I.tool_behaviour == TOOL_WRENCH)
		var/list/rod_options = list()
		for(var/obj/item/reactor_rod/rod in contents)
			rod_options += list(rod.name = image(icon = rod.icon, icon_state = rod.icon_state))
		var/picked_option = show_radial_menu(user, src, rod_options, radius = 38, require_near = TRUE)
		if(picked_option)
			to_chat(user, "<span class='notice'>You remove the [picked_option].</span>")
			I.play_tool_sound(src)
			for(var/obj/item/reactor_rod/rod in contents)
				if(rod.name == picked_option)
					START_PROCESSING(SSobj,rod)
					user.put_in_hands(rod)
					break
	else
		return ..()

/obj/machinery/power/reactor_chamber/examine()
	. = ..()
	. += "The cover is [open ? "open" : "closed"]."

/obj/machinery/power/reactor_chamber/Destroy()
	for(var/obj/item/reactor_rod/rod in contents)
		START_PROCESSING(SSobj,rod)
	. = ..()

/obj/machinery/power/reactor_chamber/process()
	if(!accelerator)
		for(var/obj/item/reactor_rod/rod in contents)
			rod.resonate()

/obj/machinery/power/reactor_chamber/proc/meltdown()
	for(var/obj/item/reactor_rod/rod in contents)
		rod.meltdown()
	Destroy(src)

#undef MAX_REACTOR_RODS
