/datum/gm_action/swarm_boarder
	name = "swarmer shell"
	departments = list(DEPARTMENT_EVERYONE, DEPARTMENT_SECURITY, DEPARTMENT_ENGINEERING)
	chaotic = 30
	observers_used = TRUE
	var/area/target_area	// Chosen target area
	var/area/target_turf	// Chosen target turf in target_area
	var/list/area/excluded = list(
		/area/submap,
		/area/shuttle,
		/area/crew_quarters,
		/area/holodeck,
		/area/engineering/engine_room
	)

	var/list/area/included = list(
		/area/maintenance,
		/area/main_map/maintenance
		)

/datum/gm_action/swarm_boarder/set_up()
	severity = pick_weight(mundande_weight = 30, moderate_weight = 10, major_weight = 1)

	var/list/area/grand_list_of_areas = get_station_areas(excluded)

	for(var/area/Incl in included)
		for(var/area/A in grand_list_of_areas)
			if(!istype(A, Incl))
				grand_list_of_areas -= A

	// Okay, now lets try and pick a target! Lets try 10 times, otherwise give up
	for(var/i in 1 to 10)
		var/area/A = pick(grand_list_of_areas)
		if(is_area_occupied(A))
			log_debug(SPAN_DEBUG("[name] event: Rejected [A] because it is occupied."))
			continue
		// A good area, great! Lets try and pick a turf
		var/list/turfs = list()
		for(var/turf/simulated/floor/F in A)
			if(turf_clear(F))
				turfs += F
		if(turfs.len == 0)
			log_debug(SPAN_DEBUG("[name] event: Rejected [A] because it has no clear turfs."))
			continue
		target_area = A
		target_turf = pick(turfs)

	if(!target_area)
		log_debug(SPAN_DEBUG("[name] event: Giving up after too many failures to pick target area"))
		return

/datum/gm_action/swarm_boarder/start()
	if(!target_turf)
		return
	..()

	var/swarmertype = /obj/structure/ghost_pod/ghost_activated/swarm_drone/event

	if(severity == EVENT_LEVEL_MODERATE)
		swarmertype = /obj/structure/ghost_pod/ghost_activated/swarm_drone/event/melee

	if(severity == EVENT_LEVEL_MAJOR)
		swarmertype = /obj/structure/ghost_pod/ghost_activated/swarm_drone/event/gunner

	new swarmertype(target_turf)

/datum/gm_action/swarm_boarder/get_weight()
	return -60 + (metric.count_people_in_department(DEPARTMENT_SECURITY) * 20 + metric.count_people_in_department(DEPARTMENT_SYNTHETIC) * 5 + metric.count_people_in_department(DEPARTMENT_EVERYONE) * 1)

/datum/gm_action/swarm_boarder/announce()
	spawn(rand(5 MINUTES, 15 MINUTES))
		if(prob(80) && severity >= EVENT_LEVEL_MODERATE && SSlegacy_atc && !SSlegacy_atc.squelched)
			SSlegacy_atc.msg("Attention civilian vessels in [(LEGACY_MAP_DATUM).starsys_name] shipping lanes, caution is advised as [pick("an unidentified vessel", "a known criminal's vessel", "a derelict vessel")] has been detected passing multiple local stations.")
