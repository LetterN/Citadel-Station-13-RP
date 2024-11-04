//
// /obj/machinery POWER USAGE CODE HERE! GO GO GADGET STATIC POWER!
// Note: You can find /obj/machinery/power power usage code in power.dm
//
// The following four machinery variables determine the "static" amount of power used every power cycle:
// - use_power, idle_power_usage, active_power_usage, power_channel
//
// Please never change any of these variables! Use the procs that update them instead!
//

// Note that we update the area even if the area is unpowered.
#define REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power)\
	if(old_power != new_power){\
		var/area/A = get_area(src);\
		if(A) A.power_use_change(old_power, new_power, power_channel)}

// Current power consumption right now.
#define POWER_CONSUMPTION (use_power == USE_POWER_IDLE ? idle_power_usage : (use_power >= USE_POWER_ACTIVE ? active_power_usage : 0))

// todo: oh boy audit all of this

// returns true if the area has power on given channel (or doesn't require power).
// defaults to power_channel
/obj/machinery/proc/powered(chan = power_channel, ignore_use_power = FALSE)
	// if(!use_power && !ignore_use_power)
	// 	return TRUE

	var/area/A = get_area(src) // make sure it's in an area
	if(!A)
		return FALSE // if not, then not powered

	return A.powered(chan)			// return power status of the area

/**
 * Called whenever the power settings of the containing area change
 *
 * by default, check equipment channel & set flag, can override if needed
 *
 * Returns TRUE if the NOPOWER flag was toggled
 */
/obj/machinery/proc/power_change()
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)

	if(machine_stat & BROKEN)
		update_appearance()
		return

	var/initial_stat = machine_stat
	if(powered(power_channel))
		machine_stat &= ~NOPOWER
		if(initial_stat & NOPOWER)
			. = TRUE
	else
		machine_stat |= NOPOWER
		if(!(initial_stat & NOPOWER))
			. = TRUE

	if(appearance_power_state != (machine_stat & NOPOWER))
		update_appearance()

// Saves like 300ms of init by not duping calls in the above proc
/obj/machinery/update_appearance(updates)
	. = ..()
	appearance_power_state = machine_stat & NOPOWER

// Get the amount of power this machine will consume each cycle.  Override by experts only!
/obj/machinery/proc/get_power_usage()
	return POWER_CONSUMPTION

// DEPRECATED! - USE use_power_oneoff() instead!
/obj/machinery/proc/use_power(amount, chan = power_channel)
	return src.use_power_oneoff(amount, chan);

/**
 * Draws energy from the APC "once".
 * Args:
 * - amount: The amount of energy to use.
 * - channel: The power channel to use.
 * Returns: The amount of energy used.
 */
/obj/machinery/proc/use_power_oneoff(amount, chan = power_channel)
	if(amount <= 0) //just in case
		return FALSE
	var/area/home = get_area(src)		// make sure it's in an area
	if(isnull(home))
		return FALSE //apparently space isn't an area
	if(!home.requires_power)
		return amount //Shuttles get free power, don't ask why

	// the apc isnt running, we cant pull
	var/obj/machinery/power/apc/local_apc = home.apc
	if(isnull(local_apc) || !local_apc.operating)
		return FALSE

	return home.use_power_oneoff(amount, chan)

// Check if we CAN use a given amount of extra power as a one off. Returns amount we could use without actually using it.
// For backwards compatibilty this returns true if the channel is powered. This is consistant with pre-static-power
// behavior of APC powerd machines, but at some point we might want to make this a bit cooler.
/obj/machinery/proc/can_use_power_oneoff(amount, chan = power_channel)
	if(powered(chan))
		return amount // If channel is powered then you can do it.
	return FALSE

// Do not do power stuff in New/Initialize until after ..()
/obj/machinery/Initialize(mapload)
	. = ..()
	var/power = POWER_CONSUMPTION
	REPORT_POWER_CONSUMPTION_CHANGE(0, power)
	power_init_complete = TRUE

// Or in Destroy at all, but especially after the ..().
/obj/machinery/Destroy()
	if(ismovable(loc))
		UnregisterSignal(loc, COMSIG_MOVABLE_MOVED)
	var/power = POWER_CONSUMPTION
	REPORT_POWER_CONSUMPTION_CHANGE(power, 0)
	return ..()

// Registering moved_event observers for all machines is too expensive.  Instead we do it ourselves.
// 99% of machines are always on a turf anyway, very few need recursive move handling.
/obj/machinery/Moved(atom/old_loc, direction, forced = FALSE)
	. = ..()
	update_power_on_move(src, old_loc, loc)
	if(ismovable(loc)) // Register for recursive movement (if the thing we're inside moves)
		RegisterSignal(loc, COMSIG_MOVABLE_MOVED, PROC_REF(update_power_on_move))
	if(ismovable(old_loc)) // Unregister recursive movement.
		UnregisterSignal(old_loc, COMSIG_MOVABLE_MOVED)

/obj/machinery/proc/update_power_on_move(atom/movable/mover, atom/old_loc, atom/new_loc)
	var/area/old_area = get_area(old_loc)
	var/area/new_area = get_area(new_loc)
	if(old_area != new_area)
		area_changed(old_area, new_area)

/obj/machinery/proc/area_changed(area/old_area, area/new_area)
	if(old_area == new_area || !power_init_complete)
		return
	var/power = POWER_CONSUMPTION
	if(!power)
		return // This is the most likely case anyway.

	if(old_area)
		old_area.power_use_change(power, 0, power_channel) // Remove our usage from old area
	if(new_area)
		new_area.power_use_change(0, power, power_channel) // Add our usage to new area
	power_change() // Force check in case the old area was powered and the new one isn't or vice versa.

//
// Usage Update Procs - These procs are the only allowed way to modify these four variables:
// 	- use_power, idle_power_usage, active_power_usage, power_channel
//

// Sets the use_power var and then forces an area power update
/obj/machinery/proc/update_use_power(var/new_use_power)
	if(use_power == new_use_power)
		return
	if(!power_init_complete)
		use_power = new_use_power
		return TRUE // We'll be retallying anyway.
	var/old_power = POWER_CONSUMPTION
	use_power = new_use_power
	var/new_power = POWER_CONSUMPTION
	REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power)
	return TRUE

// Sets the power_channel var and then forces an area power update.
/obj/machinery/proc/update_power_channel(var/new_channel)
	if(power_channel == new_channel)
		return
	if(!power_init_complete)
		power_channel = new_channel
		return TRUE // We'll be retallying anyway.
	var/power = POWER_CONSUMPTION
	REPORT_POWER_CONSUMPTION_CHANGE(power, 0) // Subtract from old channel
	power_channel = new_channel
	REPORT_POWER_CONSUMPTION_CHANGE(0, power) // Add to new channel
	return TRUE

// Sets the idle_power_usage var and then forces an area power update if use_power was USE_POWER_IDLE
/obj/machinery/proc/update_idle_power_usage(var/new_power_usage)
	if(idle_power_usage == new_power_usage)
		return
	var/old_power = idle_power_usage
	idle_power_usage = new_power_usage
	if(power_init_complete && use_power == USE_POWER_IDLE) // If this is the channel in use
		REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power_usage)

// Sets the active_power_usage var and then forces an area power update if use_power was USE_POWER_ACTIVE
/obj/machinery/proc/update_active_power_usage(var/new_power_usage)
	if(active_power_usage == new_power_usage)
		return
	var/old_power = active_power_usage
	active_power_usage = new_power_usage
	if(power_init_complete && use_power == USE_POWER_ACTIVE) // If this is the channel in use
		REPORT_POWER_CONSUMPTION_CHANGE(old_power, new_power_usage)

	pass() // macro used immediately before being undefined; BYOND bug 2072419

#undef REPORT_POWER_CONSUMPTION_CHANGE
#undef POWER_CONSUMPTION
