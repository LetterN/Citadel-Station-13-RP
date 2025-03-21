/mob/verb/up()
	set name = "Move Upwards"
	set category = VERB_CATEGORY_IC

	if(zMove(UP))
		to_chat(src, SPAN_NOTICE("You move upwards."))

/mob/verb/down()
	set name = "Move Downwards"
	set category = VERB_CATEGORY_IC

	if(zMove(DOWN))
		to_chat(src, SPAN_NOTICE("You move down."))

/mob/proc/zMove(direction)
	if(eyeobj)
		return eyeobj.zMove(direction)

	if(istype(loc,/obj/vehicle/sealed/mecha))
		var/obj/vehicle/sealed/mecha/mech = loc
		return mech.relaymove(src,direction)

	if(!can_ztravel())
		to_chat(src, SPAN_WARNING("You lack means of travel in that direction."))
		return

	var/turf/start = loc
	if(!istype(start))
		to_chat(src, SPAN_NOTICE("You are unable to move from here."))
		return FALSE

	var/turf/destination = get_vertical_step(src, direction)
	if(!destination)
		to_chat(src, SPAN_NOTICE("There is nothing of interest in this direction."))
		return FALSE

	if(is_incorporeal())
		forceMove(destination)
		return TRUE

	var/atom/obstructing = start.z_exit_obstruction(src, direction)
	if(obstructing)
		to_chat(src, SPAN_WARNING("\The [obstructing] is in the way."))
		return FALSE

	if(direction == UP && has_gravity() && !can_overcome_gravity())

		var/obj/structure/lattice/lattice = locate() in destination.contents
		if(lattice)
			var/pull_up_time = max(5 SECONDS + (movement_delay() * 10), 1)
			to_chat(src, SPAN_NOTICE("You grab \the [lattice] and start pulling yourself upward..."))
			destination.audible_message(SPAN_NOTICE("You hear something climbing up \the [lattice]."))
			if(do_after(src, pull_up_time))
				to_chat(src, SPAN_NOTICE("You pull yourself up."))
			else
				to_chat(src, SPAN_WARNING("You gave up on pulling yourself up."))
				return FALSE

		else if(ismob(src)) // Are they a mob, and are they currently flying??
			var/mob/living/H = src
			var/fly_time
			if(H.flying)
				if(H.incapacitated(INCAPACITATION_ALL))
					to_chat(src, SPAN_NOTICE("You can't fly in your current state."))
					H.stop_flying() //Should already be done, but just in case.
					return FALSE
				if(ishuman(src))
					var/mob/living/carbon/human/M = src
					fly_time = 7 SECONDS * M.species.flight_mod	//flight-based species get shorter delay
				else
					fly_time = 7 SECONDS //Non-flight based species / simple mobs get static cooldown
				to_chat(src, SPAN_NOTICE("You begin to fly upwards..."))
				destination.audible_message(SPAN_NOTICE("You hear the of air moving."))
				H.audible_message(SPAN_NOTICE("[H] begins to soar upwards!"))
				if(do_after(H, fly_time) && H.flying)
					to_chat(src, SPAN_NOTICE("You fly upwards."))
				else
					to_chat(src, SPAN_WARNING("You stopped flying upwards."))
					return FALSE
			else
				to_chat(src, SPAN_WARNING("Gravity stops you from moving upward."))
				return FALSE
		else
			to_chat(src, SPAN_WARNING("Gravity stops you from moving upward."))
			return FALSE
	// todo: this should not use Move()
	if(!Move(destination))
		return FALSE
	return TRUE

/mob/proc/can_overcome_gravity()
	return FALSE

/mob/living/can_overcome_gravity()
	return hovering

/mob/living/carbon/human/can_overcome_gravity()
	. = ..()
	if(!.)
		return species && species.can_overcome_gravity(src)

/mob/observer/zMove(direction)
	var/turf/destination = (direction == UP) ? get_vertical_step(src, UP) : get_vertical_step(src, DOWN)
	if(destination)
		forceMove(destination)
	else
		to_chat(src, "<span class='notice'>There is nothing of interest in this direction.</span>")

/mob/observer/eye/zMove(direction)
	var/turf/destination = (direction == UP) ? get_vertical_step(src, UP) : get_vertical_step(src, DOWN)
	if(destination)
		setLoc(destination)
	else
		to_chat(src, "<span class='notice'>There is nothing of interest in this direction.</span>")

/mob/proc/can_ztravel()
	return 0

/mob/living/zMove(direction)
	//Sort of a lame hack to allow ztravel through zpipes. Should be improved.
	if(is_ventcrawling && istype(loc,/obj/machinery/atmospherics/pipe/zpipe))
		var/obj/machinery/atmospherics/pipe/zpipe/currentpipe = loc
		if(istype(currentpipe.node1,/obj/machinery/atmospherics/pipe/zpipe))
			currentpipe.ventcrawl_to(src, currentpipe.node1, direction)
		else if(istype(currentpipe.node2,/obj/machinery/atmospherics/pipe/zpipe))
			currentpipe.ventcrawl_to(src, currentpipe.node2, direction)
	return ..()

/mob/observer/can_ztravel()
	return TRUE

/mob/living/can_ztravel()
	if(incapacitated())
		return FALSE
	return (hovering || is_incorporeal())

/mob/living/carbon/human/can_ztravel()
	if(incapacitated())
		return FALSE

	if(hovering || is_incorporeal())
		return TRUE

	if(flying) // Allows movement up/down with wings.
		return 1
	if(Process_Spacemove())
		return TRUE

	if(Check_Shoegrip())	//scaling hull with magboots
		for(var/turf/simulated/T in trange(1,src))
			if(T.density)
				return TRUE

/mob/living/silicon/robot/can_ztravel()
	if(incapacitated() || is_dead())
		return FALSE

	if(hovering)
		return TRUE

	if(Process_Spacemove()) //Checks for active jetpack
		return TRUE

	for(var/turf/simulated/T in trange(1,src)) //Robots get "magboots"
		if(T.density)
			return TRUE

// TODO - Leshana Experimental

//Execution by grand piano!
/atom/movable/proc/get_fall_damage()
	return 42

//If atom stands under open space, it can prevent fall, or not
/atom/proc/can_prevent_fall(var/atom/movable/mover, var/turf/coming_from)
	return (!CanPass(mover, coming_from))

////////////////////////////

//FALLING STUFF
// todo: refactor
//! WARNING: Falling code is held together by duct tape, to make the new procs shimmed in.
// Yes, sometimes you need to make things worse temporarily, to make it better
// yell at me if shit breaks ~silicons
//Holds fall checks that should not be overriden by children
/atom/movable/proc/fall()
	if(!isturf(loc))
		return

	var/turf/below = get_vertical_step(src, DOWN)
	if(!below)
		return

	if(istype(below, /turf/space))
		return

	var/turf/T = loc
	if(!T.z_exit_check(src, DOWN))
		return
	if(!T.z_fall_check(src))
		return

	// No gravity in space, apparently.
	if(!has_gravity())
		return

	if(throwing)
		return

	if(ismob(src))
		var/mob/H = src // Flight on mobs.
		if(H.flying) //Some other checks are done in the wings_toggle proc
			if(H.nutrition > 2)
				H.nutrition -= 0.5 //You use up 0.5 nutrition per TILE and tick of flying above open spaces. If people wanna flap their wings in the hallways, shouldn't penalize them for it. Lowered to make winged people less sad.
			if(H.incapacitated(INCAPACITATION_ALL))
				H.stop_flying()
				//Just here to see if the person is KO'd, stunned, etc. If so, it'll move onto can_fall.
			else if (H.nutrition > 1000) //Eat too much while flying? Get fat and fall.
				to_chat(H, "<span class='danger'>You're too heavy! Your wings give out and you plummit to the ground!</span>")
				H.stop_flying() //womp womp.
			else if(H.nutrition < 300 && H.nutrition > 289) //290 would be risky, as metabolism could mess it up. Let's do 289.
				to_chat(H, "<span class='danger'>You are starting to get fatigued... You probably have a good minute left in the air, if that. Even less if you continue to fly around! You should get to the ground soon!</span>") //Ticks are, on average, 3 seconds. So this would most likely be 90 seconds, but lets just say 60.
				H.nutrition -= 0.5 //Fixed the evilness to have 10 nutrition drained per tick and tile below 300 nutrition too
				return
			else if(H.nutrition < 100 && H.nutrition > 89)
				to_chat(H, "<span class='danger'>You're seriously fatigued! You need to get to the ground immediately and eat before you fall!</span>")
				return
			else if(H.nutrition < 10) //Should have listened to the warnings!
				to_chat(H, "<span class='danger'>You lack the strength to keep yourself up in the air...</span>")
				H.stop_flying()
			else
				return
		else if(ishuman(H)) //Needed to prevent 2 people from grabbing eachother in the air.
			var/mob/living/carbon/human/F = H
			if(F.grabbed_by.len) //If you're grabbed (presumably by someone flying) let's not have you fall. This also allows people to grab onto you while you jump over a railing to prevent you from falling!
				var/obj/item/grab/G = F.get_active_held_item()
				var/obj/item/grab/J = F.get_inactive_held_item()
				if(istype(G) || istype(J))
					//fall
				else
					return

	if(can_fall())
		// We spawn here to let the current move operation complete before we start falling. fall() is normally called from
		// Entered() which is part of Move(), by spawn()ing we let that complete.  But we want to preserve if we were in client movement
		// or normal movement so other move behavior can continue.
		// todo: this is stupid
		var/checking = loc
		spawn(0)
			if(loc != checking)	// we moved
				return
			if(!isturf(loc))	 // wtf
				return
			var/turf/cT = loc
			if(!cT.z_exit_check(src, DOWN) || !cT.z_fall_check(src))
				return	// nah
			handle_fall(below)
		// TODO - handle fall on damage!

//For children to override
/atom/movable/proc/can_fall()
	if(anchored)
		return FALSE
	// if(throwing)
		// return FALSE
	return TRUE

/obj/effect/can_fall()
	return FALSE

/obj/effect/debris/cleanable/can_fall()
	return TRUE

// These didn't fall anyways but better to nip this now just incase.
/atom/movable/lighting_overlay/can_fall()
	return FALSE

// Mechas are anchored, so we need to override.
/obj/vehicle/sealed/mecha/can_fall()
	return TRUE

/mob/can_fall()
	if(buckled)
		return FALSE	// buckled falls instead
	return ..()

/mob/living/can_fall()
	if(is_incorporeal())
		return FALSE
	if(hovering)
		return FALSE
	return ..()

/mob/living/carbon/human/can_fall()
	if(..())
		return species.can_fall(src)

// Actually process the falling movement and impacts.
/atom/movable/proc/handle_fall(turf/landing)
	var/turf/oldloc = loc

	// something is blocking us
	if(oldloc.z_exit_obstruction(src, DOWN))
		return FALSE

	// TODO - Stairs should operate thru a different mechanism, not falling, to allow side-bumping.

	// this is shitcode lmao
	var/obj/structure/stairs/stairs = locate() in landing
	if(!stairs)
		// Now lets move there!
		if(!forceMove(landing))
			return 1

		var/atom/A = find_fall_target(oldloc, landing)
		if(special_fall_handle(A) || !A || !A.check_z_impact(src))
			return
		fall_impact(A)
	else
		locationTransitForceMove(landing)

/atom/movable/proc/special_fall_handle(atom/A)
	return FALSE

/mob/living/carbon/human/special_fall_handle(atom/A)
	if(species)
		return species.fall_impact_special(src, A)
	return FALSE

/atom/movable/proc/find_fall_target(turf/oldloc, turf/landing)
	if(isopenturf(oldloc))
		oldloc.visible_message("\The [src] falls down through \the [oldloc]!", "You hear something falling through the air.")

	// If the turf has density, we give it first dibs
	if (landing.density && landing.CheckFall(src))
		return landing

	// First hit objects in the turf!
	for(var/atom/movable/A in landing)
		if(A.atom_flags & (ATOM_NONWORLD | ATOM_ABSTRACT))
			continue
		if(A != src && A.CheckFall(src))
			return A

	// If none of them stopped us, then hit the turf itself
	if(landing.CheckFall(src))
		return landing

/mob/living/carbon/human/find_fall_target(turf/landing)
	if(species)
		var/atom/A = species.find_fall_target_special(src, landing)
		if(A)
			return A
	return ..()

// CheckFall landing.fall_impact(src)

//! ## THE FALLING PROCS ###
// todo: rework falling :/

/**
 * Called on everything that falling_atom might hit.
 * Return TRUE if you're handling it so find_fall_target() will stop checking.
 */
/atom/proc/CheckFall(atom/movable/falling_atom)
	if(density && !(atom_flags & ATOM_BORDER))
		return TRUE
	return prevent_z_fall(falling_atom, 0, NONE) & (FALL_TERMINATED | FALL_BLOCKED)

/**
 * If you are hit: how is it handled.
 * Return TRUE if the generic fall_impact should be called.
 * Return FALSE if you handled it yourself or if there's no effect from hitting you.
 *
 * todo: this is a legacy proc
 */
/atom/proc/check_z_impact(atom/movable/falling_atom)
	return TRUE

/**
 * Called by CheckFall when we actually hit something. Various Vars will be described below.
 * hit_atom is the thing we fall on.
 * damage_min is the smallest amount of damage a thing (currently only mobs and mechs) will take from falling.
 * damage_max is the largest amount of damage a thing (currently only mobs and mechs) will take from falling.
 * If silent is True, the proc won't play sound or give a message.
 * If planetary is True, it's harder to stop the fall damage.
 *
 *  todo: rework everything lmao
 */
/atom/movable/proc/fall_impact(atom/hit_atom, damage_min = 0, damage_max = 10, silent = FALSE, planetary = FALSE)
	if(!silent)
		visible_message("\The [src] falls from above and slams into \the [hit_atom]!", "You hear something slam into \the [hit_atom].")
	for(var/atom/movable/A in src.contents)
		if(A.atom_flags & (ATOM_NONWORLD | ATOM_ABSTRACT))
			continue
		A.fall_impact(hit_atom, damage_min, damage_max, silent = TRUE)
	for(var/mob/M in buckled_mobs)
		M.fall_impact(hit_atom, damage_min, damage_max, silent, planetary)

/// Take damage from falling and hitting the ground.
/mob/living/fall_impact(atom/hit_atom, damage_min = 0, damage_max = 5, silent = FALSE, planetary = FALSE)
	var/turf/landing = get_turf(hit_atom)
	if(planetary && CanParachute())
		if(!silent)
			visible_message(
				SPAN_WARNING("\The [src] glides in from above and lands on \the [landing]!"),
				SPAN_DANGER("You land on \the [landing]!"),
				SPAN_HEAR("You hear something land \the [landing]."),
			)
		return
	else if(!planetary && softfall) // Falling one floor and falling one atmosphere are very different things
		if(!silent)
			visible_message(
				SPAN_WARNING("\The [src] falls from above and lands on \the [landing]!"),
				SPAN_DANGER("You land on \the [landing]!"),
				SPAN_HEAR("You hear something land \the [landing]."),
			)
		return
	else
		if(!silent)
			if(planetary)
				visible_message(
					SPAN_USERDANGER("\A [src] falls out of the sky and crashes into [landing]!"),
					SPAN_USERDANGER("You fall out of the sky and crash into [landing]!"),
					SPAN_HEAR("You hear something slam into \the [landing]."),
				)
				var/turf/T = get_turf(landing)
				explosion(T, 0, 1, 2)
			else
				visible_message(
					SPAN_WARNING("\The [src] falls from above and slams into [landing]!"),
					SPAN_DANGER("You fall off and hit \the [landing]!"),
					SPAN_HEAR("You hear something slam into \the [landing]."),
				)
			playsound(loc, "punch", 25, TRUE, -1)

		// Because wounds heal rather quickly, 10 (the default for this proc) should be enough to discourage jumping off but not be enough to ruin you, at least for the first time.
		// Hits 10 times, because apparently targeting individual limbs lets certain species survive the fall from atmosphere
		for(var/i = 1 to 10)
			adjustBruteLoss(rand(damage_min, damage_max))
		afflict_paralyze(8 SECONDS)
		update_health()

/mob/living/carbon/human/fall_impact(atom/hit_atom, damage_min, damage_max, silent, planetary)
	if(!species?.handle_falling(src, hit_atom, damage_min, damage_max, silent, planetary))
		..()

//Using /atom/movable instead of /obj/item because I'm not sure what all humans can pick up or wear
/atom/movable
	/// Is this thing a parachute itself?
	var/parachute = FALSE
	/**
	 * Is the thing floating or flying in some way? If so, don't fall normally.
	 *! Not implemented yet, idea is to let mobs/mechs ignore terrain slowdown and falling down floors.
	 */
	var/hovering = FALSE
	/// Is the thing able to lessen their impact upon falling?
	var/softfall = FALSE
	/// Is the thing able to jump out of planes and survive? Don't check this directly outside of CanParachute().
	var/parachuting = FALSE

/atom/movable/proc/isParachute()
	return parachute


/**
 * This is what makes the parachute items know they've been used.
 * I made it /atom/movable so it can be retooled for other things (mobs, mechs, etc), though it's only currently called in human/CanParachute().
 */
/atom/movable/proc/handleParachute()
	return

/// Checks if the thing is allowed to survive a fall from space.
/atom/movable/proc/CanParachute()
	return parachuting

/// For humans, this needs to be a wee bit more complicated.
/mob/living/carbon/human/CanParachute()
	// Certain slots don't really need to be checked for parachute ability, i.e. pockets, ears, etc. If this changes, just add them to the loop, I guess?
	// This is done in Priority Order, so items lower down the list don't call handleParachute() unless they're actually used.
	if(back && back.isParachute())
		back.handleParachute()
		return TRUE
	if(s_store && s_store.isParachute())
		s_store.handleParachute()
		return TRUE
	if(belt && belt.isParachute())
		belt.handleParachute()
		return TRUE
	if(wear_suit && wear_suit.isParachute())
		wear_suit.handleParachute()
		return TRUE
	if(w_uniform && w_uniform.isParachute())
		w_uniform.handleParachute()
		return TRUE
	else
		return parachuting

// Mech Code
/obj/vehicle/sealed/mecha/handle_fall(turf/landing)
	// First things first, break any lattice
	var/obj/structure/lattice/lattice = locate(/obj/structure/lattice, loc)
	if(lattice)
		// Lattices seem a bit too flimsy to hold up a massive exosuit.
		lattice.visible_message(SPAN_DANGER("\The [lattice] collapses under the weight of \the [src]!"))
		qdel(lattice)

	// Then call parent to have us actually fall
	return ..()

/obj/vehicle/sealed/mecha/fall_impact(var/atom/hit_atom, var/damage_min = 15, var/damage_max = 30, var/silent = FALSE, var/planetary = FALSE)
	// Anything on the same tile as the landing tile is gonna have a bad day.
	for(var/mob/living/L in hit_atom.contents)
		L.visible_message(SPAN_DANGER("\The [src] crushes \the [L] as it lands on them!"))
		L.adjustBruteLoss(rand(70, 100))
		L.afflict_paralyze(20 * 8)

	var/turf/landing = get_turf(hit_atom)

	if(planetary && src.CanParachute())
		if(!silent)
			visible_message(
				SPAN_WARNING("\The [src] glides in from above and lands on \the [landing]!"),
				SPAN_DANGER("You land on \the [landing]!"),
				SPAN_HEAR("You hear something land \the [landing]."),
			)
		return
	else if(!planetary && src.softfall) // Falling one floor and falling one atmosphere are very different things
		if(!silent)
			visible_message(
				SPAN_WARNING("\The [src] falls from above and lands on \the [landing]!"),
				SPAN_DANGER("You land on \the [landing]!"),
				SPAN_HEAR("You hear something land \the [landing]."),
			)
		return
	else
		if(!silent)
			if(planetary)
				visible_message(
					SPAN_USERDANGER("\A [src] falls out of the sky and crashes into \the [landing]!"),
					SPAN_USERDANGER("You fall out of the skiy and crash into \the [landing]!"),
					SPAN_HEAR("You hear something slam into \the [landing]."),
				)
				var/turf/T = get_turf(landing)
				explosion(T, 0, 1, 2)
			else
				visible_message(
					SPAN_WARNING("\The [src] falls from above and slams into \the [landing]!"),
					SPAN_DANGER("You fall off and hit \the [landing]!"),
					SPAN_HEAR("You hear something slam into \the [landing]."),
				)
			playsound(loc, "punch", 25, TRUE, -1)

	// And now to hurt the mech.
	if(!planetary)
		take_damage_legacy(rand(damage_min, damage_max))
	else
		for(var/atom/movable/A in src.contents)
			A.fall_impact(hit_atom, damage_min, damage_max, silent = TRUE)
		qdel(src)

	// And hurt the floor.
	if(istype(hit_atom, /turf/simulated/floor))
		var/turf/simulated/floor/ground = hit_atom
		ground.break_tile()

// todo: rewrite this entire file
/mob/CheckFall(atom/movable/falling_atom)
	return falling_atom.fall_impact(src)

/mob/observer/CheckFall(atom/movable/falling_atom)
	return FALSE
