/obj/item/gun/projectile/magnetic/matfed
	name = "portable phoron bore"
	desc = "A large man-portable tunnel bore, using phorogenic plasma blasts. Point away from user."
	description_fluff = "An aging Grayson Manufactories mining tool used for rapidly digging through rock. Mass production was discontinued when many of the devices were stolen and used to break into a high security facility by Boiling Point drones."
	description_antag = "This device is exceptional at breaking down walls, though it is incredibly loud when doing so."
	description_info = "The projectile of this tool will travel six tiles before dissipating, excavating mineral walls as it does so. It can be reloaded with phoron sheets."


	capacitor = new /obj/item/stock_parts/capacitor
	manipulator = new /obj/item/stock_parts/manipulator

	icon_state = "bore"
	item_state = "bore"
	wielded_item_state = "bore-wielded"
	one_handed_penalty = 5

	projectile_type = /obj/projectile/bullet/magnetic/bore

	gun_unreliable = 0

	power_cost = 750
	load_type = /obj/item/stack/material
	no_pin_required = TRUE
	var/mat_storage = 0			// How much material is stored inside? Input in multiples of 2000 as per auto/protolathe.
	var/max_mat_storage = 8000	// How much material can be stored inside?
	var/mat_cost = 500			// How much material is used per-shot?
	var/ammo_material = MAT_PHORON
	var/loading = FALSE

/obj/item/gun/projectile/magnetic/matfed/examine(mob/user, dist)
	. = ..()
	if(mat_storage)
		. += SPAN_NOTICE("It has [mat_storage] out of [max_mat_storage] units of [ammo_material] loaded.")

/obj/item/gun/projectile/magnetic/matfed/update_overlays()
	. = ..()
	if(removable_components)
		if(obj_cell_slot.cell)
			. += image(icon, "[icon_state]_cell")
		if(capacitor)
			. += image(icon, "[icon_state]_capacitor")
	if(!obj_cell_slot.cell || !capacitor)
		. += image(icon, "[icon_state]_red")
	else if(capacitor.charge < power_cost)
		. += image(icon, "[icon_state]_amber")
	else
		. += image(icon, "[icon_state]_green")
	if(mat_storage)
		. += image(icon, "[icon_state]_loaded")

/obj/item/gun/projectile/magnetic/matfed/check_ammo()
	if(mat_storage - mat_cost >= 0)
		return TRUE
	return FALSE

/obj/item/gun/projectile/magnetic/matfed/use_ammo()
	mat_storage -= mat_cost

/obj/item/gun/projectile/magnetic/matfed/attackby(var/obj/item/thing, var/mob/user)
	if(removable_components)
		if(thing.is_crowbar())
			if(!manipulator)
				to_chat(user, "<span class='warning'>\The [src] has no manipulator installed.</span>")
				return
			user.put_in_hands_or_drop(manipulator)
			user.visible_message("<span class='notice'>\The [user] levers \the [manipulator] from \the [src].</span>")
			playsound(src, 'sound/items/Crowbar.ogg', 50, 1)
			manipulator = null
			update_icon()
			return
		if(thing.is_screwdriver())
			if(!capacitor)
				to_chat(user, "<span class='warning'>\The [src] has no capacitor installed.</span>")
				return
			user.put_in_hands_or_drop(capacitor)
			user.visible_message("<span class='notice'>\The [user] unscrews \the [capacitor] from \the [src].</span>")
			playsound(src, 'sound/items/Screwdriver.ogg', 50, 1)
			capacitor = null
			update_icon()
			return

		if(istype(thing, /obj/item/stock_parts/capacitor))
			if(capacitor)
				to_chat(user, "<span class='warning'>\The [src] already has \a [capacitor] installed.</span>")
				return
			if(!user.attempt_insert_item_for_installation(thing, src))
				return
			capacitor = thing
			playsound(src, 'sound/machines/click.ogg', 10, 1)
			power_per_tick = (power_cost*0.15) * capacitor.rating
			user.visible_message("<span class='notice'>\The [user] slots \the [capacitor] into \the [src].</span>")
			update_icon()
			return

		if(istype(thing, /obj/item/stock_parts/manipulator))
			if(manipulator)
				to_chat(user, "<span class='warning'>\The [src] already has \a [manipulator] installed.</span>")
				return
			if(!user.attempt_insert_item_for_installation(thing, src))
				return
			manipulator = thing
			playsound(src, 'sound/machines/click.ogg', 10,1)
			mat_cost = initial(mat_cost) % (2*manipulator.rating)
			user.visible_message("<span class='notice'>\The [user] slots \the [manipulator] into \the [src].</span>")
			update_icon()
			return


	if(istype(thing, load_type))
		loading = TRUE
		var/obj/item/stack/material/M = thing

		if(!M.material || M.material.name != ammo_material)
			return

		if(mat_storage + 2000 > max_mat_storage)
			to_chat(user, "<span class='warning'>\The [src] cannot hold more [ammo_material].</span>")
			return

		var/can_hold_val = 0
		while(can_hold_val < round(max_mat_storage / 2000))
			if(mat_storage + 2000 <= max_mat_storage && do_after(user,1.5 SECONDS))
				can_hold_val ++
				mat_storage += 2000
				playsound(src, 'sound/effects/phasein.ogg', 15, 1)
			else
				loading = FALSE
				break
		M.use(can_hold_val)

		user.visible_message("<span class='notice'>\The [user] loads \the [src] with \the [M].</span>")
		playsound(src, 'sound/weapons/flipblade.ogg', 50, 1)
		update_icon()
		return
	. = ..()

//phoron bore 2
/obj/item/gun/projectile/magnetic/matfed/advanced
	name = "advanced phoron bore"
	description_fluff = "A revision of an aging Grayson design, the Nanotrasen Man-Portable Phorogenic Tunneler, or NT-MPPT is capable of drilling through longer swathes of rock, at the cost of slightly worse power efficiency than the Grayson design."
	description_antag = "This device is exceptional at breaking down walls, though it is incredibly loud when doing so."
	description_info = "The projectile of this tool will travel twelve tiles before dissipating, excavating mineral walls as it does so. It can be reloaded with phoron sheets, and can hold a maximum of ten sheets."
	projectile_type = /obj/projectile/bullet/magnetic/bore/powerful
	power_cost = 1000
	max_mat_storage = 20000
	manipulator = null
	capacitor = null
