// Illusion type mobs pretend to be other things visually, and generally cannot be harmed as they're not 'real'.

/mob/living/simple_mob/illusion
	name = "illusion"
	desc = "If you can read me, the game broke. Please report this to a coder."

	heat_resist = 1
	cold_resist = 1
	shock_resist = 1
	poison_resist = 1

	movement_base_speed = 6.66
	mob_bump_flag = 0 // If the illusion can't be swapped it will be obvious.

	response_help   = "pushes a hand through"
	response_disarm = "tried to disarm"
	response_harm   = "tried to punch"

	mob_class = MOB_CLASS_ILLUSION

	ai_holder_type = /datum/ai_holder/polaris/simple_mob/inert/astar // Gets controlled manually by technomancers/admins, with AI pathfinding assistance.

	var/atom/movable/copying = null // The thing we're trying to look like.
	var/realistic = FALSE // If true, things like bullets and weapons will hit it, to be a bit more convincing from a distance.

/mob/living/simple_mob/illusion/update_icon() // We don't want the appearance changing AT ALL unless by copy_appearance().
	return

/mob/living/simple_mob/illusion/proc/copy_appearance(atom/movable/thing_to_copy)
	if(!thing_to_copy)
		return FALSE
	appearance = thing_to_copy.appearance
	copying = thing_to_copy
	density = thing_to_copy.density // So you can't bump into objects that aren't supposed to be dense.
	catalogue_data = thing_to_copy.catalogue_data.Copy()
	catalogue_delay = thing_to_copy.catalogue_delay
	return TRUE

// Because we can't perfectly duplicate some examine() output, we directly examine the AM it is copying.  It's messy but
// this is to prevent easy checks from the opposing force.
/mob/living/simple_mob/illusion/examine(mob/user, dist)
	return copying?.examine(user) || ..() // ugh

/mob/living/simple_mob/illusion/on_bullet_act(obj/projectile/proj, impact_flags, list/bullet_act_args)
	if(realistic)
		return ..()
	return PROJECTILE_IMPACT_PHASE

/mob/living/simple_mob/illusion/attack_hand(mob/user, datum/event_args/actor/clickchain/e_args)
	var/mob/living/M = user
	if(!istype(M))
		return
	if(!realistic)
		playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)
		visible_message(SPAN_WARNING( "\The [M]'s hand goes through \the [src]!"))
		return
	else
		switch(M.a_intent)
			if(INTENT_HELP)
				var/datum/gender/T = GLOB.gender_datums[src.get_visible_gender()]
				M.visible_message(
					SPAN_NOTICE("\The [M] hugs [src] to make [T.him] feel better!"), \
					SPAN_NOTICE("You hug [src] to make [T.him] feel better!")
					) // slightly redundant as at the moment most mobs still use the normal gender var, but it works and future-proofs it
				playsound(src.loc, 'sound/weapons/thudswoosh.ogg', 50, 1, -1)

			if(INTENT_DISARM)
				playsound(loc, 'sound/weapons/punchmiss.ogg', 25, 1, -1)
				visible_message(SPAN_DANGER("\The [M] attempted to disarm [src]!"))
				M.do_attack_animation(src)

			if(INTENT_GRAB)
				..()

			if(INTENT_HARM)
				adjustBruteLoss(harm_intent_damage)
				M.visible_message(SPAN_DANGER("\The [M] [response_harm] \the [src]"))
				M.do_attack_animation(src)

/mob/living/simple_mob/illusion/melee_act(mob/attacker, obj/item/weapon, datum/melee_attack/weapon/style, target_zone, datum/event_args/actor/clickchain/clickchain, clickchain_flags)
	if(realistic)
		return ..()
	// TODO: proper feedback procs
	attacker?.visible_message(
		SPAN_WARNING("[attacker]'s [weapon] passes right through [src]!"),
	)
	return clickchain_flags | CLICKCHAIN_ATTACK_MISSED

/mob/living/simple_mob/illusion/legacy_ex_act()
	return

// Try to have the same tooltip, or else it becomes really obvious which one is fake.
/mob/living/simple_mob/illusion/get_nametag_name(mob/user)
	if(copying)
		return copying.get_nametag_name(user)

/mob/living/simple_mob/illusion/get_nametag_desc(mob/user)
	if(copying)
		return copying.get_nametag_desc(user)

// Cataloguer stuff. I don't think this will actually come up but better safe than sorry.
/mob/living/simple_mob/illusion/get_catalogue_data()
	if(copying)
		return copying.get_catalogue_data()

/mob/living/simple_mob/illusion/can_catalogue()
	if(copying)
		return copying.can_catalogue()

/mob/living/simple_mob/illusion/get_catalogue_delay()
	if(copying)
		return copying.get_catalogue_delay()
