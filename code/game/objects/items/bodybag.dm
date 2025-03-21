//Also contains /obj/structure/closet/body_bag because I doubt anyone would think to look for bodybags in /object/structures

/obj/item/bodybag
	name = "body bag"
	desc = "A folded bag designed for the storage and transportation of cadavers."
	icon = 'icons/obj/medical/bodybag.dmi'
	icon_state = "bodybag_folded"
	w_class = WEIGHT_CLASS_SMALL

	var/bag_type = /obj/structure/closet/body_bag

/obj/item/bodybag/attack_self(mob/user, datum/event_args/actor/actor)
	. = ..()
	if(.)
		return
	add_fingerprint(user)
	create_bag(user.drop_location())
	qdel(src)

/obj/item/bodybag/proc/create_bag(atom/where)
	var/obj/structure/closet/body_bag/bag = new bag_type(where)
	transfer_fingerprints_to(bag)
	return bag

/obj/item/storage/box/bodybags
	name = "body bags"
	desc = "This box contains body bags."
	icon_state = "bodybags"

/obj/item/storage/box/bodybags/New()
	..()
	new /obj/item/bodybag(src)
	new /obj/item/bodybag(src)
	new /obj/item/bodybag(src)
	new /obj/item/bodybag(src)
	new /obj/item/bodybag(src)
	new /obj/item/bodybag(src)
	new /obj/item/bodybag(src)

/obj/structure/closet/body_bag
	name = "body bag"
	desc = "A plastic bag designed for the storage and transportation of cadavers."
	icon = 'icons/obj/medical/bodybag.dmi'
	closet_appearance = null
	open_sound = 'sound/items/zip.ogg'
	close_sound = 'sound/items/zip.ogg'
	icon_opened = "bodybag_open"
	icon_closed = "bodybag_closed"
	icon_state = "bodybag_closed"
	var/item_path = /obj/item/bodybag
	density = 0
	storage_capacity = (MOB_MEDIUM * 2) - 1
	var/contains_body = 0
	use_old_icon_update = TRUE

/obj/structure/closet/body_bag/attackby(obj/item/W, mob/user)
	if (istype(W, /obj/item/pen))
		var/t = input(user, "What would you like the label to be?", name, null) as text
		if (user.get_active_held_item() != W)
			return
		if (!in_range(src, user) && src.loc != user)
			return
		t = sanitizeSafe(t, MAX_NAME_LEN)
		if (t)
			name = "body bag - "
			name += t
			add_overlay(image(src.icon, "bodybag_label"))
		else
			name = "body bag"
	//..() //Doesn't need to run the parent. Since when can fucking bodybags be welded shut? -Agouri
		return
	else if(W.is_wirecutter())
		to_chat(user, "You cut the tag off the bodybag")
		name = "body bag"
		cut_overlays()
		return

/obj/structure/closet/body_bag/store_mobs(var/stored_units)
	contains_body = ..()
	return contains_body

/obj/structure/closet/body_bag/close()
	if(..())
		density = 0
		return 1
	return 0

/obj/structure/closet/body_bag/OnMouseDropLegacy(over_object, src_location, over_location)
	..()
	if((over_object == usr && (in_range(src, usr) || usr.contents.Find(src))))
		if(!ishuman(usr))	return 0
		if(opened)	return 0
		if(contents.len)	return 0
		visible_message("[usr] folds up the [src.name]")
		var/folded = new item_path(get_turf(src))
		spawn(0)
			qdel(src)
		return folded

/obj/structure/closet/body_bag/relaymove(mob/user,direction)
	if(src.loc != get_turf(src))
		src.loc.relaymove(user,direction)
	else
		..()

/obj/structure/closet/body_bag/proc/get_occupants()
	var/list/occupants = list()
	for(var/mob/living/carbon/human/H in contents)
		occupants += H
	return occupants

/obj/structure/closet/body_bag/proc/update(var/broadcast=0)
	if(istype(loc, /obj/structure/morgue))
		var/obj/structure/morgue/M = loc
		M.update(broadcast)

/obj/structure/closet/body_bag/update_icon_state()
	if(opened)
		icon_state = icon_opened
	else
		if(contains_body)
			icon_state = "bodybag_closed1"
		else
			icon_state = icon_closed
	return ..()

/obj/item/bodybag/cryobag
	name = "stasis bag"
	desc = "A non-reusable plastic bag designed to slow down bodily functions such as circulation and breathing, \
	especially useful if short on time or in a hostile environment."
	icon = 'icons/obj/medical/cryobag.dmi'
	icon_state = "bodybag_folded"
	item_state = "bodybag_cryo_folded"
	origin_tech = list(TECH_BIO = 4)
	bag_type = /obj/structure/closet/body_bag/cryobag

	var/obj/item/reagent_containers/syringe/syringe

/obj/item/bodybag/cryobag/create_bag(atom/where)
	var/obj/structure/closet/body_bag/cryobag/bag = ..()
	if(!istype(bag))
		return
	if(!isnull(syringe))
		bag.syringe = syringe
		syringe = null
	return bag

/obj/structure/closet/body_bag/cryobag
	name = "stasis bag"
	desc = "A non-reusable plastic bag designed to slow down bodily functions such as circulation and breathing, \
	especially useful if short on time or in a hostile environment."
	icon = 'icons/obj/medical/cryobag.dmi'
	item_path = /obj/item/bodybag/cryobag
	store_misc = 0
	store_items = 0
	var/obj/item/tank/tank = null
	var/tank_type = /obj/item/tank/stasis/oxygen
	var/stasis_level = 3 //Every 'this' life ticks are applied to the mob (when life_ticks%stasis_level == 1)
	var/obj/item/reagent_containers/syringe/syringe

/obj/structure/closet/body_bag/cryobag/Initialize(mapload)
	tank = new tank_type(null) //It's in nullspace to prevent ejection when the bag is opened.
	..()

/obj/structure/closet/body_bag/cryobag/Destroy()
	QDEL_NULL(syringe)
	QDEL_NULL(tank)
	return ..()

/obj/structure/closet/body_bag/cryobag/OnMouseDropLegacy(over_object, src_location, over_location)
	. = ..()
	if(. && syringe)
		var/obj/item/bodybag/cryobag/folded = .
		folded.syringe = syringe
		syringe = null

/obj/structure/closet/body_bag/cryobag/Entered(atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		H.Stasis(stasis_level)
		inject_occupant(H)

	if(istype(AM, /obj/item/organ))
		var/obj/item/organ/O = AM
		O.preserve(STASIS_BAG_TRAIT)
	..()

/obj/structure/closet/body_bag/cryobag/Exited(atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		H.Stasis(0)

	if(istype(AM, /obj/item/organ))
		var/obj/item/organ/O = AM
		O.unpreserve(STASIS_BAG_TRAIT)
	..()

/obj/structure/closet/body_bag/cryobag/return_air() //Used to make stasis bags protect from vacuum.
	if(tank)
		return tank.air_contents
	..()

/obj/structure/closet/body_bag/cryobag/proc/inject_occupant(var/mob/living/carbon/human/H)
	if(!syringe)
		return

	if(H.reagents)
		syringe.reagents.trans_to_mob(H, 30, CHEM_INJECT)

/obj/structure/closet/body_bag/cryobag/examine(mob/user, dist)
	. = ..()
	if(Adjacent(user)) //The bag's rather thick and opaque from a distance.
		. += "<span class='info'>You peer into \the [src].</span>"
		if(syringe)
			. += "<span class='info'>It has a syringe added to it.</span>"
		for(var/mob/living/L in contents)
			user.do_examinate(L)

/obj/structure/closet/body_bag/cryobag/attackby(obj/item/W, mob/user)
	if(opened)
		..()
	else //Allows the bag to respond to a health analyzer by analyzing the mob inside without needing to open it.
		if(istype(W,/obj/item/healthanalyzer))
			var/obj/item/healthanalyzer/analyzer = W
			for(var/mob/living/L in contents)
				analyzer.melee_interaction_chain(L,user)

		else if(istype(W,/obj/item/reagent_containers/syringe))
			if(syringe)
				to_chat(user,"<span class='warning'>\The [src] already has an injector! Remove it first.</span>")
			else
				var/obj/item/reagent_containers/syringe/syringe = W
				if(!user.attempt_insert_item_for_installation(syringe, src))
					return
				to_chat(user,"<span class='info'>You insert \the [syringe] into \the [src], and it locks into place.</span>")
				syringe = syringe
				syringe.loc = null
				for(var/mob/living/carbon/human/H in contents)
					inject_occupant(H)
					break

		else if(W.is_screwdriver())
			if(syringe)
				syringe.forceMove(src.loc)
				to_chat(user,"<span class='info'>You pry \the [syringe] out of \the [src].</span>")
				syringe = null

		else
			..()
