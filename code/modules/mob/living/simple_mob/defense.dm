// When someone clicks us with an empty hand
/mob/living/simple_mob/attack_hand(mob/user, datum/event_args/actor/clickchain/e_args)
	. = ..()
	if(.)
		return

	var/mob/living/L = user
	if(!istype(L))
		return
	switch(L.a_intent)
		if(INTENT_HELP)
			if(health > 0)
				L.visible_message("<span class='notice'>\The [L] [response_help] \the [src].</span>")

		if(INTENT_DISARM)
			L.visible_message("<span class='notice'>\The [L] [response_disarm] \the [src].</span>")
			L.do_attack_animation(src)
			//TODO: Push the mob away or something

		if(INTENT_GRAB)
			if (L == src)
				return
			if (!(status_flags & STATUS_CAN_PUSH))
				return
			if(!incapacitated(INCAPACITATION_ALL) && prob(grab_resist))
				L.visible_message("<span class='warning'>\The [L] tries to grab \the [src] but fails!</span>")
				return

			var/obj/item/grab/G = new /obj/item/grab(L, src)

			L.put_in_active_hand(G)

			G.affecting = src
			LAssailant = L

			L.visible_message("<span class='warning'>\The [L] has grabbed [src] passively!</span>")
			L.do_attack_animation(src)

// When somoene clicks us with an item in hand
/mob/living/simple_mob/attackby(var/obj/item/O, var/mob/user)
	if(istype(O, /obj/item/stack/medical))
		if(stat != DEAD)
			// This could be done better.
			var/obj/item/stack/medical/MED = O
			if(health < getMaxHealth())
				if(MED.amount >= 1)
					adjustBruteLoss(-MED.heal_brute)
					MED.amount -= 1
					if(MED.amount <= 0)
						qdel(MED)
					visible_message("<span class='notice'>\The [user] applies the [MED] on [src].</span>")
		else
			var/datum/gender/T = GLOB.gender_datums[src.get_visible_gender()]
			// the gender lookup is somewhat overkill, but it functions identically to the obsolete gender macros and future-proofs this code
			to_chat(user, "<span class='notice'>\The [src] is dead, medical items won't bring [T.him] back to life.</span>")
	if(can_butcher(user, O))	//if the animal can be butchered, do so and return. It's likely to be gibbed.
		harvest(user, O)
		return

	return ..()

// Exploding.
/mob/living/simple_mob/legacy_ex_act(severity)
	if(!has_status_effect(/datum/status_effect/sight/blindness))
		flash_eyes()
	var/armor = run_armor_check(def_zone = null, attack_flag = "bomb")
	var/bombdam = 500
	switch (severity)
		if (1.0)
			bombdam = 500
		if (2.0)
			bombdam = 60
		if (3.0)
			bombdam = 30

	apply_damage(damage = bombdam, damagetype = DAMAGE_TYPE_BRUTE, def_zone = null, blocked = armor, used_weapon = null, sharp = FALSE, edge = FALSE)

	if(bombdam > maxHealth)
		gib()

// Cold stuff.
/mob/living/simple_mob/get_cold_protection()
	. = cold_resist
	. = 1 - . // Invert from 1 = immunity to 0 = immunity.

	// Doing it this way makes multiplicative stacking not get out of hand, so two modifiers that give 0.5 protection will be combined to 0.75 in the end.
	for(var/thing in modifiers)
		var/datum/modifier/M = thing
		if(!isnull(M.cold_protection))
			. *= 1 - M.cold_protection

	// Code that calls this expects 1 = immunity so we need to invert again.
	. = 1 - .
	. = min(., 1.0)


// Fire stuff. Not really exciting at the moment.
/mob/living/simple_mob/handle_fire()
	return
/mob/living/simple_mob/update_fire()
	return
/mob/living/simple_mob/IgniteMob()
	return
/mob/living/simple_mob/ExtinguishMob()
	return

/mob/living/simple_mob/get_heat_protection()
	. = heat_resist
	. = 1 - . // Invert from 1 = immunity to 0 = immunity.

	// Doing it this way makes multiplicative stacking not get out of hand, so two modifiers that give 0.5 protection will be combined to 0.75 in the end.
	for(var/thing in modifiers)
		var/datum/modifier/M = thing
		if(!isnull(M.heat_protection))
			. *= 1 - M.heat_protection

	// Code that calls this expects 1 = immunity so we need to invert again.
	. = 1 - .
	. = min(., 1.0)

// Electromagnetism
/mob/living/simple_mob/emp_act(severity)
	..() // To emp_act() its contents.
	if(!isSynthetic())
		return
	switch(severity)
		if(1)
		//	adjustFireLoss(rand(15, 25))
			adjustFireLoss(min(60, getMaxHealth()*0.5)) // Weak mobs will always take two direct EMP hits to kill. Stronger ones might take more.
		if(2)
			adjustFireLoss(min(30, getMaxHealth()*0.25))
		//	adjustFireLoss(rand(10, 18))
		if(3)
			adjustFireLoss(min(15, getMaxHealth()*0.125))
		//	adjustFireLoss(rand(5, 12))
		if(4)
			adjustFireLoss(min(7, getMaxHealth()*0.0625))
		//	adjustFireLoss(rand(1, 6))

// Water
/mob/living/simple_mob/get_water_protection()
	return water_resist

// "Poison" (aka what reagents would do if we wanted to deal with those).
/mob/living/simple_mob/get_poison_protection()
	return poison_resist

// Armor
/mob/living/simple_mob/legacy_mob_armor(def_zone, type)
	var/armorval = fetch_armor().get_mitigation(type) * 100
	if(!armorval)
		return 0
	else
		return armorval

/mob/living/simple_mob/legacy_mob_soak(def_zone, attack_flag)
	var/armorval = fetch_armor().get_soak(attack_flag) * 100
	if(!armorval)
		return 0
	else
		return armorval

// Lightning
/mob/living/simple_mob/lightning_act()
	..()
	// If a non-player simple_mob was struck, inflict huge damage.
	// If the damage is fatal, it is turned to ash.
	if(!client)
		inflict_shock_damage_legacy(200) // Mobs that are very beefy or resistant to shock may survive getting struck.
		update_health()
		if(health <= 0)
			visible_message(SPAN_CRITICAL("\The [src] disintegrates into ash!"))
			ash()
			return // No point deafening something that wont exist.

// Lava
/mob/living/simple_mob/lava_act()
	..()
	// Similar to lightning, the mob is turned to ash if the lava tick was fatal and it isn't a player.
	// Unlike lightning, we don't add an additional damage spike (since lava already hurts a lot).
	if(!client)
		update_health()
		if(health <= 0)
			visible_message(SPAN_CRITICAL("\The [src] flashes into ash as the lava consumes them!"))
			ash()

//Acid
/mob/living/simple_mob/acid_act()
	..()
	// If a non-player simple_mob was submerged, inflict huge damage.
	// If the damage is fatal, it is turned to gibs.
	if(!client)
		inflict_heat_damage(30)
		inflict_poison_damage(10)
		update_health()
		if(health <= 0)
			visible_message(SPAN_CRITICAL("\The [src] melts into slurry!"))
			gib()
			return // No point deafening something that wont exist.

// Injections.
/mob/living/simple_mob/can_inject(mob/user, error_msg, target_zone, ignore_thickness)
	if(ignore_thickness)
		return TRUE
	return !thick_armor
