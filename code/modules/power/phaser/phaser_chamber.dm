#define MAX_PHASER_CELLS 3

/obj/machinery/power/phaser/phaser_chamber //placeholder
	name = "phaser chamber"
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "fuel_chamber"
	dir = EAST
	var/accelerator
	var/list/phaser_cells
	var/open = TRUE

/obj/machinery/power/phaser/phaser_chamber/attackby(obj/item/I, mob/user, params)
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
	if(istype(I, /obj/item/phaser_cell))
		if(length(contents) < MAX_PHASER_CELLS)
			if(!user.transferItemToLoc(I, src))
				return
			STOP_PROCESSING(SSobj,I) //hands processing over to the phaser
			to_chat(user, "<span class='notice'>You place [I] in [src].</span>")
			update_appearance()
		else
			to_chat(user, "<span class='warning'>[src] is full!</span>")
	else if(I.tool_behaviour == TOOL_WRENCH)
		var/list/cell_options = list()
		for(var/obj/item/phaser_cell/cell in contents)
			cell_options += list(cell.name = image(icon = cell.icon, icon_state = cell.icon_state))
		var/picked_option = show_radial_menu(user, src, cell_options, radius = 38, require_near = TRUE)
		if(picked_option)
			to_chat(user, "<span class='notice'>You remove the [picked_option].</span>")
			I.play_tool_sound(src)
			for(var/obj/item/phaser_cell/cell in contents)
				if(cell.name == picked_option)
					START_PROCESSING(SSobj,cell)
					user.put_in_hands(cell)
					break
	else
		return ..()

/obj/machinery/power/phaser/phaser_chamber/examine()
	. = ..()
	. += "The cover is [open ? "open" : "closed"]."

/obj/machinery/power/phaser/phaser_chamber/Destroy()
	for(var/obj/item/phaser_cell/cell in contents)
		START_PROCESSING(SSobj,cell)
	. = ..()

/obj/machinery/power/phaser/phaser_chamber/process()
	if(!accelerator)
		for(var/obj/item/phaser_cell/cell in contents)
			cell.resonate()

/obj/machinery/power/phaser/phaser_chamber/proc/meltdown()
	for(var/obj/item/phaser_cell/cell in contents)
		cell.meltdown()
	Destroy(src)

#undef MAX_PHASER_CELLS
