//Updates the mob's health from organs and mob damage variables
/mob/living/carbon/human/update_health()
	if(status_flags & STATUS_GODMODE)
		health = getMaxHealth()
		set_stat(CONSCIOUS)
		update_hud_med_all()

	var/total_burn  = 0
	var/total_brute = 0
	for(var/obj/item/organ/external/O in organs)	//hardcoded to streamline things a bit
		if(!O.vital)
			if(O.robotic >= ORGAN_ROBOT)
				continue //*non-vital* robot limbs don't count towards shock and crit
			else
				// todo: pending med rework, we count non vital organic limbs for less damage, but not less for shock!
				total_brute += O.brute_dam * 0.75
				total_burn += O.burn_dam * 0.75
		else
			total_brute += O.brute_dam
			total_burn  += O.burn_dam

	var/old = health
	health = getMaxHealth() - getOxyLoss() - getToxLoss() - getCloneLoss() - total_burn - total_brute

	//TODO: fix husking
	if( ((getMaxHealth() - total_burn) < getMinHealth()) && stat == DEAD)
		ChangeToHusk()

	if(old != health)
		update_hud_med_all()

// todo: sort file and move to damage_procs

/mob/living/carbon/human/afflict_radiation(amt, run_armor, damage_zone)
	if(species)
		amt = amt * species.radiation_mod
	return ..()

/mob/living/carbon/human/adjustBrainLoss(var/amount)

	if(status_flags & STATUS_GODMODE)	return 0	//godmode

	if(should_have_organ("brain"))
		var/obj/item/organ/internal/brain/sponge = internal_organs_by_name["brain"]
		if(sponge)
			if(amount > 0)
				sponge.take_damage(amount)
			else
				sponge.heal_damage_i(-amount, can_revive = TRUE)
			brainloss = sponge.damage
		else
			brainloss = 200
	else
		brainloss = 0

/mob/living/carbon/human/setBrainLoss(var/amount)

	if(status_flags & STATUS_GODMODE)	return 0	//godmode

	if(should_have_organ("brain"))
		var/obj/item/organ/internal/brain/sponge = internal_organs_by_name["brain"]
		if(sponge)
			sponge.damage = clamp(amount, 0, sponge.max_damage)
			sponge.update_health()
			brainloss = sponge.damage
		else
			brainloss = 200
	else
		brainloss = 0

/mob/living/carbon/human/getBrainLoss()

	if(status_flags & STATUS_GODMODE)	return 0	//godmode

	if(should_have_organ("brain"))
		var/obj/item/organ/internal/brain/sponge = internal_organs_by_name["brain"]
		if(sponge)
			brainloss = sponge.damage
		else
			brainloss = 200
	else
		brainloss = 0
	return brainloss

//These procs fetch a cumulative total damage from all organs
/mob/living/carbon/human/getBruteLoss()
	var/amount = 0
	for(var/obj/item/organ/external/O in organs)
		if(O.robotic >= ORGAN_ROBOT && !O.vital)
			continue //*non-vital*robot limbs don't count towards death, or show up when scanned
		amount += O.brute_dam
	return amount

/mob/living/carbon/human/getShockBruteLoss()
	var/amount = 0
	for(var/obj/item/organ/external/O in organs)
		if(O.robotic >= ORGAN_ROBOT)
			continue //robot limbs don't count towards shock and crit
		amount += O.brute_dam
	return amount

/mob/living/carbon/human/getActualBruteLoss()
	var/amount = 0
	for(var/obj/item/organ/external/O in organs) // Unlike the above, robolimbs DO count.
		amount += O.brute_dam
	return amount

/mob/living/carbon/human/getFireLoss()
	var/amount = 0
	for(var/obj/item/organ/external/O in organs)
		if(O.robotic >= ORGAN_ROBOT && !O.vital)
			continue //*non-vital*robot limbs don't count towards death, or show up when scanned
		amount += O.burn_dam
	return amount

/mob/living/carbon/human/getShockFireLoss()
	var/amount = 0
	for(var/obj/item/organ/external/O in organs)
		if(O.robotic >= ORGAN_ROBOT)
			continue //robot limbs don't count towards shock and crit
		amount += O.burn_dam
	return amount

/mob/living/carbon/human/getActualFireLoss()
	var/amount = 0
	for(var/obj/item/organ/external/O in organs) // Unlike the above, robolimbs DO count.
		amount += O.burn_dam
	return amount

//'include_robo' only applies to healing, for legacy purposes, as all damage typically hurts both types of organs
/mob/living/carbon/human/adjustBruteLoss(var/amount,var/include_robo)
	amount = amount*species.brute_mod
	if(amount > 0)
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_damage_percent))
				amount *= M.incoming_damage_percent
			if(!isnull(M.incoming_brute_damage_percent))
				amount *= M.incoming_brute_damage_percent
		if(nif && nif.flag_check(NIF_C_BRUTEARMOR,NIF_FLAGS_COMBAT)){amount *= 0.7} // NIF mod for damage resistance for this type of damage
		take_overall_damage(amount, 0)
	else
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_healing_percent))
				amount *= M.incoming_healing_percent
		heal_overall_damage(-amount, 0, include_robo)
	update_hud_med_all()

//'include_robo' only applies to healing, for legacy purposes, as all damage typically hurts both types of organs
/mob/living/carbon/human/adjustFireLoss(var/amount,var/include_robo)
	amount = amount*species.burn_mod
	if(amount > 0)
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_damage_percent))
				amount *= M.incoming_damage_percent
			if(!isnull(M.incoming_fire_damage_percent))
				amount *= M.incoming_fire_damage_percent
		if(nif && nif.flag_check(NIF_C_BURNARMOR,NIF_FLAGS_COMBAT)){amount *= 0.7} // NIF mod for damage resistance for this type of damage
		take_overall_damage(0, amount)
	else
		for(var/datum/modifier/M in modifiers)
			if(!isnull(M.incoming_healing_percent))
				amount *= M.incoming_healing_percent
		heal_overall_damage(0, -amount, include_robo)
	update_hud_med_all()

/mob/living/carbon/human/proc/Stasis(amount)
	if((species.species_flags & NO_SCAN) || isSynthetic())
		in_stasis = 0
	else
		in_stasis = amount

/mob/living/carbon/human/proc/getStasis()
	if((species.species_flags & NO_SCAN) || isSynthetic())
		return 0

	return in_stasis

//This determines if, RIGHT NOW, the life() tick is being skipped due to stasis
/mob/living/carbon/human/proc/inStasisNow()
	var/stasisValue = getStasis()
	if(stasisValue && (life_tick % stasisValue))
		return 1

	return 0

/mob/living/carbon/human/getCloneLoss()
	if((species.species_flags & NO_SCAN) || isSynthetic())
		cloneloss = 0
	return ..()

/mob/living/carbon/human/setCloneLoss(var/amount)
	if((species.species_flags & NO_SCAN) || isSynthetic())
		cloneloss = 0
	else
		..()

/mob/living/carbon/human/adjustCloneLoss(var/amount)
	..()

	if((species.species_flags & NO_SCAN) || isSynthetic())
		cloneloss = 0
		return

	var/heal_prob = max(0, 80 - getCloneLoss())
	var/mut_prob = min(80, getCloneLoss()+10)
	if (amount > 0)
		if (prob(mut_prob))
			var/list/obj/item/organ/external/candidates = list()
			for (var/obj/item/organ/external/O in organs)
				if(!(O.status & ORGAN_MUTATED))
					candidates |= O
			if (candidates.len)
				var/obj/item/organ/external/O = pick(candidates)
				O.mutate()
				to_chat(src, "<span class = 'notice'>Something is not right with your [O.name]...</span>")
				return
	else
		if (prob(heal_prob))
			for (var/obj/item/organ/external/O in organs)
				if (O.status & ORGAN_MUTATED)
					O.unmutate()
					to_chat(src, "<span class = 'notice'>Your [O.name] is shaped normally again.</span>")
					return

	if (getCloneLoss() < 1)
		for (var/obj/item/organ/external/O in organs)
			if (O.status & ORGAN_MUTATED)
				O.unmutate()
				to_chat(src, "<span class = 'notice'>Your [O.name] is shaped normally again.</span>")
	update_hud_med_all()

// Defined here solely to take species flags into account without having to recast at mob/living level.
/mob/living/carbon/human/getOxyLoss()
	if(!should_have_organ(O_LUNGS))
		oxyloss = 0
	return ..()

/mob/living/carbon/human/adjustOxyLoss(var/amount)
	if(!should_have_organ(O_LUNGS))
		oxyloss = 0
	else
		amount = amount*species.oxy_mod
		..(amount)

/mob/living/carbon/human/setOxyLoss(var/amount)
	if(!should_have_organ(O_LUNGS))
		oxyloss = 0
	else
		..()

/mob/living/carbon/human/getToxLoss()
	if(species.species_flags & NO_POISON)
		toxloss = 0
	return ..()

/mob/living/carbon/human/adjustToxLoss(var/amount)
	if(species.species_flags & NO_POISON)
		toxloss = 0
	else
		amount = amount*species.toxins_mod
		..(amount)

/mob/living/carbon/human/setToxLoss(var/amount)
	if(species.species_flags & NO_POISON)
		toxloss = 0
	else
		..()

/mob/living/carbon/human/adjustHallucination(amount)
	if(species.species_flags & NO_HALLUCINATION || isSynthetic())
		hallucination = 0
	else
		..(amount)

/mob/living/carbon/human/setHallucination(amount)
	if(species.species_flags & NO_HALLUCINATION || isSynthetic())
		hallucination = 0
	else
		..(amount)

////////////////////////////////////////////

//Returns a list of damaged organs
/mob/living/carbon/human/proc/get_damaged_organs(var/brute, var/burn)
	var/list/obj/item/organ/external/parts = list()
	for(var/obj/item/organ/external/O in organs)
		if((brute && O.brute_dam) || (burn && O.burn_dam))
			parts += O
	return parts

//Returns a list of damageable organs
/mob/living/carbon/human/proc/get_damageable_organs()
	var/list/obj/item/organ/external/parts = list()
	for(var/obj/item/organ/external/O in organs)
		if(O.is_damageable(TRUE))
			parts += O
	return parts

//Heals ONE external organ, organ gets randomly selected from damaged ones.
//It automatically updates damage overlays if necesary
//It automatically updates health status
/mob/living/carbon/human/heal_organ_damage(var/brute, var/burn)
	var/list/obj/item/organ/external/parts = get_damaged_organs(brute,burn)
	if(!parts.len)	return
	var/obj/item/organ/external/picked = pick(parts)
	if(picked.heal_damage(brute,burn))
		update_damage_overlay()
	update_health()


//Heal MANY external organs, in random order
//'include_robo' only applies to healing, for legacy purposes, as all damage typically hurts both types of organs
/mob/living/carbon/human/heal_overall_damage(var/brute, var/burn, var/include_robo)
	var/list/obj/item/organ/external/parts = get_damaged_organs(brute,burn)

	var/update = 0
	while(parts.len && (brute>0 || burn>0) )
		var/obj/item/organ/external/picked = pick(parts)

		var/brute_was = picked.brute_dam
		var/burn_was = picked.burn_dam

		update |= picked.heal_damage(brute,burn,robo_repair = include_robo)

		brute -= (brute_was-picked.brute_dam)
		burn -= (burn_was-picked.burn_dam)

		parts -= picked
	update_health()
	if(update)
		update_damage_overlay()


////////////////////////////////////////////

/*
This function restores the subjects blood to max.
*/
/mob/living/carbon/human/proc/restore_blood()
	blood_holder.set_host_volume(species.blood_volume)

/*
This function restores all organs.
*/
/mob/living/carbon/human/restore_all_organs(var/ignore_prosthetic_prefs)
	for(var/obj/item/organ/current_organ in organs)
		current_organ.rejuvenate_legacy(ignore_prosthetic_prefs)

/mob/living/carbon/human/apply_damage(var/damage = 0, var/damagetype = DAMAGE_TYPE_BRUTE, var/def_zone = null, var/blocked = 0, var/soaked = 0, var/sharp = 0, var/edge = 0, var/obj/used_weapon = null)
	var/obj/item/organ/external/organ = null
	if(isorgan(def_zone))
		organ = def_zone
	else
		if(!def_zone)	def_zone = ran_zone(def_zone)
		organ = get_organ(check_zone(def_zone))

	//Handle other types of damage
	if((damagetype != DAMAGE_TYPE_BRUTE) && (damagetype != DAMAGE_TYPE_BURN))
		if(damagetype == DAMAGE_TYPE_HALLOSS)
			if((damage > 25 && prob(20)) || (damage > 50 && prob(60)))
				if(organ && organ.organ_can_feel_pain() && !isbelly(loc) && !istype(loc, /obj/item/dogborg/sleeper))
					emote_nosleep("scream")
		..(damage, damagetype, def_zone, blocked, soaked)
		return 1

	//Handle BRUTE and BURN damage
	handle_suit_punctures(damagetype, damage, def_zone)

	if(blocked >= 100)
		return 0

	if(soaked >= damage)
		return 0

	if(!organ)	return 0

	if(blocked)
		blocked = (100-blocked)/100
		damage = (damage * blocked)

	if(soaked)
		damage -= soaked

	if(GLOB.Debug2)
		log_world("## DEBUG: [src] was hit for [damage].")

	switch(damagetype)
		if(DAMAGE_TYPE_BRUTE)
			damageoverlaytemp = 20
			damage = damage*species.brute_mod

			for(var/datum/modifier/M in modifiers)
				if(!isnull(M.incoming_damage_percent))
					damage *= M.incoming_damage_percent
				if(!isnull(M.incoming_brute_damage_percent))
					damage *= M.incoming_brute_damage_percent

			organ.inflict_bodypart_damage(
				brute = damage,
				damage_mode = (edge? DAMAGE_MODE_EDGE : NONE) | (sharp? DAMAGE_MODE_SHARP : NONE),
				weapon_descriptor = used_weapon,
			)
		if(DAMAGE_TYPE_BURN)
			damageoverlaytemp = 20
			damage = damage*species.burn_mod

			for(var/datum/modifier/M in modifiers)
				if(!isnull(M.incoming_damage_percent))
					damage *= M.incoming_damage_percent
				if(!isnull(M.incoming_brute_damage_percent))
					damage *= M.incoming_fire_damage_percent

			organ.inflict_bodypart_damage(
				burn = damage,
				damage_mode = (edge? DAMAGE_MODE_EDGE : NONE) | (sharp? DAMAGE_MODE_SHARP : NONE),
				weapon_descriptor = used_weapon,
			)

	// Will set our damageoverlay icon to the next level, which will then be set back to the normal level the next mob.Life().
	update_health()
	return 1
