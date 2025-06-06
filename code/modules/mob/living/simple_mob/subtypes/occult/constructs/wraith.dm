////////////////////////////
//			Wraith
////////////////////////////

/datum/category_item/catalogue/fauna/construct/wraith
	name = "Constructs - Wraith"
	desc = "Employed during the incursion on the NDV Marksman as a flanker and assasin, \
	the Wraith is an agile construct capble of rapidly outmaneuvering its foes. Worryingly, \
	the Wraith possesses the abilty to phase out of the material world and jaunt through \
	solid barriers. This ability allows it to bypass fortifications with ease, or close the \
	distance to a firing line without exposing itself. Extreme caution must be exhibited when \
	facing Constructs, as the Wraith can often ambush teams that over-extend themselves."
	value = CATALOGUER_REWARD_EASY

/mob/living/simple_mob/construct/wraith
	name = "Wraith"
	real_name = "Wraith"
	construct_type = "wraith"
	desc = "A wicked bladed shell contraption piloted by a bound spirit."
	icon_state = "floating"
	icon_living = "floating"
	maxHealth = 200
	health = 200
	legacy_melee_damage_lower = 25
	legacy_melee_damage_upper = 30
	attack_armor_pen = 15
	attack_sharp = 1
	attack_edge = 1
	attacktext = list("slashed")
	friendly = list("pinches")
	movement_base_speed = 6.66
	attack_sound = 'sound/weapons/rapidslice.ogg'
	construct_spells = list(/spell/targeted/ethereal_jaunt/shift,
							/spell/targeted/ambush_mode
							)

	catalogue_data = list(/datum/category_item/catalogue/fauna/construct/wraith)

	ai_holder_type = /datum/ai_holder/polaris/simple_mob/melee/evasive

	var/jaunt_warning = 0.5 SECONDS	// How long the jaunt telegraphing is.
	var/jaunt_tile_speed = 20		// How long to wait between each tile. Higher numbers result in an easier to dodge tunnel attack.


//	environment_smash = 1	// Whatever this gets renamed to, Wraiths need to break things

/mob/living/simple_mob/construct/wraith/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/horror_aura)

/mob/living/simple_mob/construct/wraith/apply_melee_effects(var/atom/A)
	if(isliving(A))
		var/mob/living/L = A
		L.add_modifier(/datum/modifier/deep_wounds, 30 SECONDS)

// In Theory this Jury Rigged Code form Tunneler Spiders Should Allow Wraiths to Jaunt
	special_attack_min_range = 2
	special_attack_max_range = 6
	special_attack_cooldown = 10 SECONDS


/mob/living/simple_mob/construct/wraith/jaunt_spam
	special_attack_cooldown = 5 SECONDS

/mob/living/simple_mob/construct/wraith/fast_jaunt //Teleports behind you
	jaunt_tile_speed = 2

/mob/living/simple_mob/construct/wraith/do_special_attack(atom/A)
	set waitfor = FALSE
	set_AI_busy(TRUE)

	// Save where we're gonna go soon.
	var/turf/destination = get_turf(A)
	var/turf/starting_turf = get_turf(src)

	// Telegraph to give a small window to dodge if really close.
	flick("phase_shift",A)
	icon_state = "phase_shift"
	sleep(jaunt_warning) // For the telegraphing.

	// Do the dig!
	visible_message(SPAN_DANGER("\The [src] vanishes into thin air \the [A]!"))
	flick("phase_shift",A)
	icon_state = "phase_shift"

	if(handle_jaunt(destination) == FALSE)
		set_AI_busy(FALSE)
		flick("phase_shift2",A)
		icon_state = "phase_shift2"
		return FALSE

	// Did we make it?
	if(!(src in destination))
		set_AI_busy(FALSE)
		icon_state = "phase_shift2"
		flick("phase_shift2",A)
		return FALSE

	var/overshoot = TRUE

	// Test if something is at destination.
	for(var/mob/living/L in destination)
		if(L == src)
			continue

		visible_message(SPAN_DANGER("\The [src] appears in a flurry of slashes \the [L]!"))
		playsound(L, 'sound/weapons/heavysmash.ogg', 75, 1)
		L.afflict_paralyze(20 * 3)
		overshoot = FALSE

	if(!overshoot) // We hit the target, or something, at destination, so we're done.
		set_AI_busy(FALSE)
		icon_state = "phase_shift2"
		flick("phase_shift2",A)
		return TRUE

	// Otherwise we need to keep going.
	to_chat(src, SPAN_WARNING( "You overshoot your target!"))
	playsound(src, 'sound/weapons/punchmiss.ogg', 75, 1)
	var/dir_to_go = get_dir(starting_turf, destination)
	for(var/i = 1 to rand(2, 4))
		destination = get_step(destination, dir_to_go)

	if(handle_jaunt(destination) == FALSE)
		set_AI_busy(FALSE)
		icon_state = "phase_shift2"
		flick("phase_shift2",A)
		return FALSE

	set_AI_busy(FALSE)
	icon_state = "phase_shift2"
	flick("phase_shift2",A)
	return FALSE

// Does the jaunt movement
/mob/living/simple_mob/construct/wraith/proc/handle_jaunt(turf/destination)
	var/turf/T = get_turf(src) // Hold our current tile.

	// Regular tunnel loop.
	for(var/i = 1 to get_dist(src, destination))
		if(stat)
			return FALSE // We died or got knocked out on the way.
		if(loc == destination)
			break // We somehow got there early.

		// Update T.
		T = get_step(src, get_dir(src, destination))
		if(T.check_density(ignore_mobs = TRUE))
			to_chat(src, SPAN_CRITICAL("You hit something really solid!"))
			playsound(src, "punch", 75, 1)
			afflict_paralyze(20 * 5)
			add_modifier(/datum/modifier/tunneler_vulnerable, 10 SECONDS)
			return FALSE // Hit a wall.

		// Get into the tile.
		forceMove(T)


/mob/living/simple_mob/construct/wraith/should_special_attack(atom/A)
	// Make sure its possible for the wraith to reach the target so it doesn't try to go through a window.
	var/turf/destination = get_turf(A)
	var/turf/starting_turf = get_turf(src)
	var/turf/T = starting_turf
	for(var/i = 1 to get_dist(starting_turf, destination))
		if(T == destination)
			break

		T = get_step(T, get_dir(T, destination))
		if(T.check_density(ignore_mobs = TRUE))
			return FALSE
	return T == destination
