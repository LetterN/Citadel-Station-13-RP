/obj/item/radio/beacon
	name = "tracking beacon"
	desc = "A beacon used by a teleporter."
	icon_state = "beacon"
	item_state = "signaler"
	var/code = "electronic"
	origin_tech = list(TECH_BLUESPACE = 1)

GLOBAL_LIST_BOILERPLATE(all_beacons, /obj/item/radio/beacon)

/obj/item/radio/beacon/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	return ..()


/obj/item/radio/beacon/talk_into(atom/movable/M, message, channel, list/spans, datum/language/language)
	return null

/obj/item/radio/beacon/verb/alter_signal(t as text)
	set name = "Alter Beacon's Signal"
	set category = "Object"
	set src in usr

	if ((usr.canmove && !( usr.restrained() )))
		src.code = t
	if (!( src.code ))
		src.code = "beacon"
	src.add_fingerprint(usr)
	return


/obj/item/radio/beacon/bacon/proc/digest_delay()
	QDEL_IN(src, 600)

// SINGULO BEACON SPAWNER

/obj/item/radio/beacon/syndicate
	name = "suspicious beacon"
	desc = "A label on it reads: <i>Activate to have a singularity beacon teleported to your location</i>."
	origin_tech = list(TECH_BLUESPACE = 1, TECH_ILLEGAL = 7)

/obj/item/radio/beacon/syndicate/attack_self(mob/user as mob)
	if(user)
		to_chat(user, "<span class='notice'>Locked In</span>")
		new /obj/machinery/power/singularity_beacon/syndicate( user.loc )
		playsound(src, 'sound/effects/pop.ogg', 100, 1, 1)
		qdel(src)
	return
