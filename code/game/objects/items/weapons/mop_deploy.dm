/obj/item/mop_deploy
	name = "mop"
	desc = "Deployable mop."
	icon_state = "mop"
	damage_force = 3
	anchored = 1    // Never spawned outside of inventory, should be fine.
	throw_force = 1  //Throwing or dropping the item deletes it.
	throw_speed = 1
	throw_range = 1
	w_class = WEIGHT_CLASS_BULKY//So you can't hide it in your pocket or some such.
	attack_verb = list("mopped", "bashed", "bludgeoned", "whacked")
	var/mob/living/creator
	var/mopping = 0
	var/mopcount = 0


/obj/item/mop_deploy/Initialize(mapload)
	. = ..()
	create_reagents(5)
	START_PROCESSING(SSobj, src)

/turf/proc/clean_deploy(atom/source)
	if(source.reagents.has_reagent("water", 1))
		clean_blood()
		if(istype(src, /turf/simulated))
			var/turf/simulated/T = src
			T.dirt = 0
		for(var/obj/effect/O in src)
			if(istype(O,/obj/effect/rune) || istype(O,/obj/effect/debris/cleanable) || istype(O,/obj/effect/overlay))
				qdel(O)
/*	//Reagent code changed at some point and the below doesn't work.  To be fixed later.
	source.reagents.reaction(src, TOUCH, 10)	//10 is the multiplier for the reaction effect. probably needed to wet the floor properly.
	source.reagents.remove_any(1)				//reaction() doesn't use up the reagents
*/
/obj/item/mop_deploy/afterattack(atom/target, mob/user, clickchain_flags, list/params)
	if(!(clickchain_flags & CLICKCHAIN_HAS_PROXIMITY)) return
	if(istype(target, /turf) || istype(target, /obj/effect/debris/cleanable) || istype(target, /obj/effect/overlay) || istype(target, /obj/effect/rune))
		user.visible_message("<span class='warning'>[user] begins to clean \the [get_turf(target)].</span>")

		if(do_after(user, 40))
			var/turf/T = get_turf(target)
			if(T)
				T.clean_deploy(src)
			to_chat(user, "<span class='notice'>You have finished mopping!</span>")

/obj/effect/attackby(obj/item/I, mob/living/user, list/params, clickchain_flags, damage_multiplier)
	if(istype(I, /obj/item/mop_deploy) || istype(I, /obj/item/soap))
		return
	..()

/obj/item/mop_deploy/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/mop_deploy/attack_self(mob/user, datum/event_args/actor/actor)
	. = ..()
	if(.)
		return
	qdel(src)

/obj/item/mop_deploy/dropped(mob/user, flags, atom/newLoc)
	. = ..()
	qdel(src)

/obj/item/mop_deploy/process(delta_time)
	if(!creator || loc != creator || !creator.is_holding(src))
		// Tidy up a bit.
		if(istype(loc,/mob/living))
			var/mob/living/carbon/human/host = loc
			if(istype(host))
				for(var/obj/item/organ/external/organ in host.organs)
					for(var/obj/item/O in organ.implants)
						if(O == src)
							organ.implants -= src
			host._handle_inventory_hud_remove(src)
		qdel(src)
		spawn(1) if(!QDELETED(src)) qdel(src)
