/// Animation delay for non-living objects moving up/down stairs
#define STAIR_MOVE_DELAY 10
/obj/structure/stairs
	name = "Stairs"
	desc = "Stairs leading to another deck.  Not too useful if the gravity goes out."
	icon = 'icons/obj/structures/multiz.dmi'
	icon_state = "stair"
	opacity = 0
	density = 0
	anchored = 1
	layer = STAIRS_LAYER

/obj/structure/stairs/Initialize(mapload)
	. = ..()
	if(check_integrity())
		update_icon()

/obj/structure/stairs/prevent_z_fall(atom/movable/victim, levels = 0, fall_flags)
	return fall_flags | FALL_TERMINATED

// Returns TRUE if the stairs are a complete and connected unit, FALSE if a piece is missing or obstructed
// Will attempt to reconnect broken pieces
// Parameters:
//  - B1: Loc of bottom stair
//  - B2: Loc of middle stair
//  - T1: Openspace over bottom stair
//  - T2: Loc of top stair, over middle stair
/obj/structure/stairs/proc/check_integrity(var/obj/structure/stairs/bottom/B = null,
										   var/obj/structure/stairs/middle/M = null,
										   var/obj/structure/stairs/top/T = null,
										   var/turf/simulated/open/O = null)

	// Base cases: Something is missing!
	// The parent type doesn't know enough about the positional relations to find neighbors, only evaluate if they're connected
	if(!istype(B) || !istype(M) || !istype(T) || !istype(O))
		return FALSE

	// Case 1: In working order
	if(B.top == T && M.bottom == B && T.bottom == B && \
			get_turf(M) == get_step(B, B.dir) && O == get_vertical_step(B, UP) && get_turf(T) == get_vertical_step(M, UP))
		return TRUE

	// Case 2: The top is linked to someone else
	if(istype(T.bottom) && T.bottom != B)
		return FALSE

	// Case 3: The bottom is linked to someone else
	if(istype(B.top) && B.top != T)
		return FALSE

	// Case 4: They're unlinked
	B.dir = get_dir(get_turf(B), get_turf(M))
	B.top = T
	B.middle = M
	T.dir	 = B.dir
	T.middle = M
	T.bottom = B
	M.dir	 = B.dir
	M.top	 = T
	M.bottom = B
	return TRUE

// Used to actually move stuff up/down stairs. Removed from Crossed for special cases
/obj/structure/stairs/proc/use_stairs(var/atom/movable/AM, var/atom/oldloc)
	return

/obj/structure/stairs/proc/use_stairs_instant(var/atom/movable/AM)
	return

// todo: what the fuck are the above and why is one instant rofl

/obj/structure/stairs/proc/get_destination_turf()
	return null

/obj/structure/stairs/proc/common_prechecks(atom/movable/AM, atom/oldLoc)
	if(!isturf(AM.loc))		// maybe don't yank things out that're being picked up huh
		return
	if(oldLoc && ((get_turf(oldLoc) == get_destination_turf()) || (get_turf(oldLoc) == get_vertical_step(src, DOWN))))
		return FALSE
	if(isobserver(AM))
		return FALSE
	if(ismob(AM))
		var/mob/M = AM
		if(LAZYLEN(M.grabbed_by))
			return FALSE
	return TRUE

/obj/structure/stairs/proc/common_redirect(atom/movable/AM)
	if(ismob(AM))
		var/mob/M = AM
		if(M.buckled)
			return M.buckled
	return AM

/obj/structure/stairs/proc/transition_atom(atom/movable/AM, turf/newLoc = get_destination_turf())
	if(!isturf(newLoc))
		return
	AM.locationTransitForceMove(newLoc, 2)

//////////////////////////////////////////////////////////////////////
// Bottom piece that you step ontor //////////////////////////////////
//////////////////////////////////////////////////////////////////////
/obj/structure/stairs/bottom
	icon_state = "stair_l"
	var/obj/structure/stairs/top/top = null
	var/obj/structure/stairs/middle/middle = null

/obj/structure/stairs/bottom/Initialize(mapload)
	. = ..()
	if(!get_vertical_step(src, UP))
		CRASH("Stair created without level above: [audit_loc()].")

/obj/structure/stairs/bottom/Destroy()
	if(top)
		top.bottom = null
	if(middle)
		middle.bottom = null
	..()

// These are necessarily fairly similar, but because the positional relations are different, we have to copy-pasta a fair bit
/obj/structure/stairs/bottom/check_integrity(var/obj/structure/stairs/bottom/B = null,
											 var/obj/structure/stairs/middle/M = null,
											 var/obj/structure/stairs/top/T = null,
											 var/turf/simulated/open/O = null)

	// In the case where we're provided all the pieces, just try connecting them.
	// In order: all exist, they are appropriately adjacent, and they can connect
	if(istype(B) && istype(M) && istype(T) && istype(O) && \
			B.Adjacent(M) && (get_vertical_step(O, DOWN) == get_turf(B)) && T.Adjacent(O) && \
			..())
		return TRUE

	// If we're already configured, just check those
	else if(istype(top) && istype(middle))
		O = locate(/turf/simulated/open) in get_vertical_step(src, UP)
		if(..(src, middle, top, O))
			return TRUE

	var/turf/B2 = get_step(src, src.dir)
	O = get_vertical_step(src, UP)
	var/turf/T2 = get_vertical_step(B2, UP)

	// T1 is the same regardless of B1's dir, so we can enforce it here
	if(!istype(O))
		return FALSE

	T = locate(/obj/structure/stairs/top)    in T2
	M = locate(/obj/structure/stairs/middle) in B2

	// If you set the dir, that's the dir it *wants* to connect in. It only chooses the others if that doesn't work
	// Everything is simply linked in our original direction
	if(istype(M) && istype(T) && ..(src, M, T, O))
		return TRUE

	// Else, we have to look in other directions
	for(var/dir in GLOB.cardinal - src.dir)
		B2 = get_step(src, dir)
		T2 = get_vertical_step(B2, UP)
		if(!istype(B2) || !istype(T2))
			continue

		T = locate(/obj/structure/stairs/top)    in T2
		M = locate(/obj/structure/stairs/middle) in B2
		if(..(src, M, T, O))
			return TRUE

	// Out of the dir check, we have no valid neighbors, and thus are not complete.
	return FALSE

/obj/structure/stairs/bottom/use_stairs(atom/movable/AM, atom/oldloc)
	if(!common_prechecks(AM, oldloc))
		return
	AM = common_redirect(AM)
	if(!check_integrity())
		return
	transition_atom(AM)

/obj/structure/stairs/bottom/use_stairs_instant(var/atom/movable/AM)
	if(!common_prechecks(AM))
		return
	AM = common_redirect(AM)
	transition_atom(AM)

/obj/structure/stairs/bottom/get_destination_turf()
	return get_turf(top)

//////////////////////////////////////////////////////////////////////
// Middle piece that you are animated onto/off of ////////////////////
//////////////////////////////////////////////////////////////////////
/obj/structure/stairs/middle
	icon_state = "stair_u"
	opacity   = TRUE
	density   = TRUE // Too high to simply step up on
	climb_allowed = TRUE

	var/obj/structure/stairs/top/top = null
	var/obj/structure/stairs/bottom/bottom = null

/obj/structure/stairs/middle/Initialize(mapload)
	. = ..()
	if(!get_vertical_step(src, UP))
		CRASH("Stair created without level above: [audit_loc()].")

/obj/structure/stairs/middle/Destroy()
	if(top)
		top.middle = null
	if(bottom)
		bottom.middle = null
	..()

// These are necessarily fairly similar, but because the positional relations are different, we have to copy-pasta a fair bit
/obj/structure/stairs/middle/check_integrity(var/obj/structure/stairs/bottom/B = null,
											 var/obj/structure/stairs/middle/M = null,
											 var/obj/structure/stairs/top/T = null,
											 var/turf/simulated/open/O = null)

	// In the  case where we're provided all the pieces, just try connecting them.
	// In order: all exist, they are appropriately adjacent, and they can connect
	if(istype(B) && istype(M) && istype(T) && istype(O) && \
			B.Adjacent(M) && (get_vertical_step(O, DOWN) == B.loc) && T.Adjacent(O) && \
			..())
		return TRUE

	else if(istype(top) && istype(bottom))
		O = locate(/turf/simulated/open) in get_vertical_step(bottom, UP)
		if(..(bottom, src, top, O))
			return TRUE

	var/turf/B1 = get_step(src, turn(src.dir, 180))
	O = get_vertical_step(B1, UP)
	var/turf/T2 = get_vertical_step(src, UP)

	B = locate(/obj/structure/stairs/bottom) in B1
	T = locate(/obj/structure/stairs/top)    in T2

	// Top is static for Middle stair, if it's invalid we can't do much
	if(!istype(T))
		return FALSE

	// If you set the dir, that's the dir it *wants* to connect in. It only chooses the others if that doesn't work
	// Everything is simply linked in our original direction
	if(istype(B1) && istype(T2) && istype(O) && ..(B, src, T, O))
		return TRUE

	// Else, we have to look in other directions
	for(var/dir in GLOB.cardinal - src.dir)
		B1 = get_step(src, turn(dir, 180))
		O = get_vertical_step(B1, UP)
		if(!istype(B1) || !istype(O))
			continue

		B = locate(/obj/structure/stairs/bottom) in B1
		if(..(B, src, T, O))
			return TRUE

	// The middle stair has some further special logic, in that it can be climbed, and so is technically valid if only the top exists
	// T is enforced by a prior if
	T.middle = src
	src.top = T
	src.dir = T.dir
	return TRUE

/obj/structure/stairs/middle/MouseDroppedOnLegacy(mob/target, mob/user)
	. = ..()
	if(check_integrity())
		do_climb_on(user)
		transition_atom(user, get_turf(top)) // You can't really drag things when you have to climb up the gap in the stairs yourself

/obj/structure/stairs/middle/Bumped(mob/user)
	if(check_integrity() && bottom && (bottom in get_turf(user))) // Bottom must be enforced because the middle stairs don't actually need the bottom
		bottom.use_stairs_instant(user)

//////////////////////////////////////////////////////////////////////
// Top piece that you step onto //////////////////////////////////////
//////////////////////////////////////////////////////////////////////
/obj/structure/stairs/top
	icon_state = "stair_l" // Darker, marginally less contrast w/ openspace
	var/obj/structure/stairs/middle/middle = null
	var/obj/structure/stairs/bottom/bottom = null

/obj/structure/stairs/top/Initialize(mapload)
	. = ..()
	if(!get_vertical_step(src, DOWN))
		CRASH("Stair created without level below: [audit_loc()].")

/obj/structure/stairs/top/Destroy()
	if(middle)
		middle.top = null
	if(bottom)
		bottom.top = null
	..()

// These are necessarily fairly similar, but because the positional relations are different, we have to copy-pasta a fair bit
/obj/structure/stairs/top/check_integrity(var/obj/structure/stairs/bottom/B = null,
										  var/obj/structure/stairs/middle/M = null,
										  var/obj/structure/stairs/top/T = null,
										  var/turf/simulated/open/O = null)

	// In the  case where we're provided all the pieces, just try connecting them.
	// In order: all exist, they are appropriately adjacent, and they can connect
	if(istype(B) && istype(M) && istype(T) && istype(O) && \
			B.Adjacent(M) && (get_vertical_step(O, DOWN) == B.loc) && T.Adjacent(O) && \
			(. = ..()))
		return

	else if(istype(middle) && istype(bottom))
		O = locate(/turf/simulated/open) in get_vertical_step(bottom, UP)
		if(..(bottom, middle, src, O))
			return TRUE


	O = get_step(src, turn(src.dir, 180))
	var/turf/B1 = get_vertical_step(O, DOWN)
	var/turf/B2 = get_vertical_step(src, DOWN)

	B = locate(/obj/structure/stairs/bottom) in B1
	M = locate(/obj/structure/stairs/middle) in B2

	// Middle stair is static for Top stair, so if it's invalid we can't do much
	if(!istype(M))
		return FALSE

	// If you set the dir, that's the dir it *wants* to connect in. It only chooses the others if that doesn't work
	// Everything is simply linked in our original direction
	if(istype(B) && istype(O) && (. = ..(B, M, src, O)))
		return

	// Else, we have to look in other directions
	for(var/dir in GLOB.cardinal - src.dir)
		O = get_step(src, turn(dir, 180))
		B1 = get_vertical_step(O, DOWN)
		if(!istype(B1) || !istype(O))
			continue

		B = locate(/obj/structure/stairs/bottom) in B1
		if((. = ..(B, M, src, O)))
			return

	// Out of the dir check, we have no valid neighbors, and thus are not complete. `.` was set by ..()
	return

/obj/structure/stairs/top/get_destination_turf()
	return get_turf(bottom)

/obj/structure/stairs/top/use_stairs(var/atom/movable/AM, var/atom/oldloc)
	if(!common_prechecks(AM, oldloc))
		return
	AM = common_redirect(AM)
	// If the stairs aren't broken, go up.
	if(!check_integrity())
		return
	transition_atom(AM)
	AM.setDir(turn(dir, 180))

/obj/structure/stairs/top/use_stairs_instant(atom/movable/AM)
	if(!common_prechecks(AM))
		return
	AM = common_redirect(AM)
	transition_atom(AM, get_turf(bottom))
	AM.setDir(turn(dir, 180))

// Mapping pieces, placed at the bottommost part of the stairs
/obj/structure/stairs/spawner
	name = "Stairs spawner"
	icon = 'icons/obj/structures/stairs_64x64.dmi'
	icon_state = ""

/obj/structure/stairs/spawner/Initialize(mapload)
	..()
	var/turf/B1 = get_step(get_turf(src), turn(dir, 180))
	var/turf/B2 = get_turf(src)
	var/turf/T1 = get_vertical_step(B1, UP)
	var/turf/T2 = get_vertical_step(B2, UP)

	if(!istype(B1) || !istype(B2))
		CRASH("Stair created at invalid loc: [audit_loc()].")
	if(!istype(T1) || !istype(T2))
		CRASH("Stair created without level above: [audit_loc()].")

	// Spawn the stairs
	// Railings sold separately
	var/turf/simulated/open/O = T1
	var/obj/structure/stairs/top/T 	  = new(T2)
	var/obj/structure/stairs/middle/M = new(B2)
	var/obj/structure/stairs/bottom/B = new(B1)
	if(!isopenturf(O))
		O = new(O)

	B.dir = dir
	M.dir = dir
	T.dir = dir
	B.check_integrity(B, M, T, O)

	return INITIALIZE_HINT_QDEL

/obj/structure/stairs/spawner/preloading_dir(datum/dmm_context/context)
	dir = turn(dir, context.loaded_orientation_turn_angle)
	return FALSE

// For ease of spawning. While you *can* spawn the base type and set its dir, this is useful for adminbus and a little bit quicker to map in
/obj/structure/stairs/spawner/north
	dir = NORTH
	bound_height = 64
	bound_y = -32
	pixel_y = -32

/obj/structure/stairs/spawner/south
	dir = SOUTH
	bound_height = 64

/obj/structure/stairs/spawner/east
	dir = EAST
	bound_width = 64
	bound_x = -32
	pixel_x = -32

/obj/structure/stairs/spawner/west
	dir = WEST
	bound_width = 64
