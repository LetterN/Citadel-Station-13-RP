#define ONLY_DEPLOY 1
#define ONLY_RETRACT 2
#define SEAL_DELAY 30

/datum/armor/hardsuit
	melee = 0.275
	melee_tier = 3.5
	bullet = 0.05
	bullet_tier = 3
	laser = 0.175
	laser_tier = 3.5
	energy = 0.05
	bomb = 0.35
	bio = 1.0
	rad = 0.2
	fire = 0.5
	acid = 0.7

/*
 * Defines the behavior of hardsuits/rigs/power armour.
 */

/obj/item/hardsuit
	name = "hardsuit control module"
	icon = 'icons/obj/rig_modules.dmi'
	desc = "A back-mounted hardsuit deployment and control mechanism."
	slot_flags = SLOT_BACK
	w_class = WEIGHT_CLASS_HUGE
	rad_flags = NONE
	item_action_name = "Toggle Heatsink"

	// These values are passed on to all component pieces.
	armor_type = /datum/armor/hardsuit
	min_cold_protection_temperature = SPACE_SUIT_MIN_COLD_PROTECTION_TEMPERATURE
	max_heat_protection_temperature = SPACE_SUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	siemens_coefficient = 0.2
	permeability_coefficient = 0.1
	integrity_flags = INTEGRITY_ACIDPROOF
	preserve_item = 1

	weight = ITEM_WEIGHT_BASELINE
	encumbrance = ITEM_ENCUMBRANCE_LEGACY_RIG
	var/online_encumbrance
	var/offline_encumbrance = ITEM_WEIGHT_LEGACY_RIG * 2

	// Activation
	/// activation state
	var/activation_state = RIG_ACTIVATION_OFF
	/// last online, set in process()
	var/last_online = FALSE

	var/maintenance_while_online = FALSE
	var/suit_state //The string used for the suit's icon_state.

	var/interface_path = "hardsuit.tmpl"
	var/ai_interface_path = "hardsuit.tmpl"
	var/interface_title = "Hardsuit Controller"
	var/wearer_move_delay //Used for AI moving.
	var/ai_controlled_move_delay = 10

	// Keeps track of what this hardsuit should spawn with.
	var/suit_type = "hardsuit"
	var/list/initial_modules
	var/chest_type = /obj/item/clothing/suit/space/hardsuit
	var/helm_type =  /obj/item/clothing/head/helmet/space/hardsuit
	var/boot_type =  /obj/item/clothing/shoes/magboots/hardsuit
	var/glove_type = /obj/item/clothing/gloves/gauntlets/hardsuit
	var/cell_type =  /obj/item/cell/high
	var/air_type =   /obj/item/tank/oxygen

	var/unremovable_cell = FALSE

	//Component/device holders.
	var/obj/item/tank/air_supply                       // Air tank, if any.
	var/obj/item/clothing/shoes/boots = null                  // Deployable boots, if any.
	var/obj/item/clothing/suit/space/hardsuit/chest                // Deployable chestpiece, if any.
	var/obj/item/clothing/head/helmet/space/hardsuit/helmet = null // Deployable helmet, if any.
	var/obj/item/clothing/gloves/gauntlets/hardsuit/gloves = null  // Deployable gauntlets, if any.
	var/obj/item/cell/cell                             // Power supply, if any.
	var/obj/item/hardsuit_module/selected_module = null            // Primary system (used with middle-click)
	var/obj/item/hardsuit_module/vision/visor                      // Kinda shitty to have a var for a module, but saves time.
	var/obj/item/hardsuit_module/voice/speech                      // As above.
	var/mob/living/carbon/human/wearer                        // The person currently wearing the hardsuit.
	var/mutable_appearance/mob_icon                                        // Holder for on-mob icon.
	var/list/installed_modules = list()                       // Power consumption/use bookkeeping.

	// Cooling system vars.
	var/cooling_on = 0					//is it turned on?
	var/max_cooling = 15				// in degrees per second - probably don't need to mess with heat capacity here
	var/charge_consumption = 2			// charge per second at max_cooling		//more effective on a hardsuit, because it's all built in already
	var/thermostat = T20C

	// hardsuit status vars.
	var/open = 0                                              // Access panel status.
	var/locked = 1                                            // Lock status.
	var/subverted = 0
	var/interface_locked = 0
	var/control_overridden = 0
	var/ai_override_enabled = 0
	var/security_check_enabled = 1
	var/malfunctioning = 0
	var/malfunction_delay = 0
	var/electrified = 0
	var/locked_down = 0

	var/seal_delay = SEAL_DELAY
	var/vision_restriction
	var/offline_vision_restriction = 1                        // 0 - none, 1 - welder vision, 2 - blind. Maybe move this to helmets.
	var/airtight = 1 //If set, will adjust ALLOWINTERNALS flag and pressure protections on components. Otherwise it should leave them untouched.
	var/rigsuit_max_pressure = 10 * ONE_ATMOSPHERE			  // Max pressure the hardsuit protects against when sealed
	var/rigsuit_min_pressure = 0							  // Min pressure the hardsuit protects against when sealed

	var/emp_protection = 0
	clothing_flags = PHORONGUARD

	// Wiring! How exciting.
	var/datum/wires/hardsuit/wires
	var/datum/effect_system/spark_spread/spark_system
	var/datum/mini_hud/hardsuit/minihud

	//Traps, too.
	var/isTrapped = 0 //Will it lock you in?
	var/trapSprung = 0 //Don't define this one. It's if it's procced.
	var/springtrapped = 0 //Will it cause severe bodily harm?
	var/trapDelay = 300 //in deciseconds
	var/warn = 1 //If the suit will warn you if it can't deploy a part. Will always end back at 1.

	var/sprint_slowdown_modifier = 0					      // Sprinter module modifier.

	//* Storage *//
	var/list/storage_insertion_whitelist
	var/list/storage_insertion_blacklist
	var/list/storage_insertion_allow

	var/storage_max_single_weight_class = WEIGHT_CLASS_NORMAL
	var/storage_max_combined_weight_class
	var/storage_max_combined_volume = WEIGHT_VOLUME_NORMAL * 7
	var/storage_max_items

	var/storage_weight_subtract = 0
	var/storage_weight_multiply = 1

	var/storage_allow_quick_empty = TRUE
	var/storage_allow_quick_empty_via_clickdrag = TRUE
	var/storage_allow_quick_empty_via_attack_self = FALSE

	var/storage_sfx_open = "rustle"
	var/storage_sfx_insert = "rustle"
	var/storage_sfx_remove = "rustle"

	var/storage_ui_numerical_mode = FALSE

	/// storage datum path
	var/storage_datum_path = /datum/object_system/storage
	/// Cleared after Initialize().
	/// List of types associated to amounts.
	var/list/storage_starts_with
	/// set to prevent us from spawning starts_with
	var/storage_empty = FALSE

/obj/item/hardsuit/get_cell(inducer)
	return cell

/obj/item/hardsuit/examine(mob/user, dist)
	. = ..()
	if(wearer)
		for(var/obj/item/piece in list(helmet,gloves,chest,boots))
			if(!piece || piece.loc != wearer)
				continue
			. += "[icon2html(thing = piece, target = user)] \The [piece] [piece.gender == PLURAL ? "are" : "is"] deployed."

	if(src.loc == usr)
		. += "The access panel is [locked? "locked" : "unlocked"]."
		. += "The maintenance panel is [open ? "open" : "closed"]."
		. += "Hardsuit systems are [is_activated() ? "<font color='red'>offline</font>" : "<font color='green'>online</font>"]."
		. += "The cooling stystem is [cooling_on ? "active" : "inactive"]."

		if(open)
			. += "It's equipped with [english_list(installed_modules)]."

/obj/item/hardsuit/Initialize(mapload)
	. = ..()
	initialize_storage()
	spawn_storage_contents()

	suit_state = icon_state
	item_state = icon_state
	wires = new(src)

	if((!req_access || !req_access.len) && (!req_one_access || !req_one_access.len))
		locked = 0

	spark_system = new()
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

	START_PROCESSING(SSobj, src)

	if(initial_modules && initial_modules.len)
		for(var/path in initial_modules)
			var/obj/item/hardsuit_module/module = new path(src)
			installed_modules += module
			module.installed(src)

	// Create and initialize our various segments.
	if(cell_type)
		cell = new cell_type(src)
	if(air_type)
		air_supply = new air_type(src)
	if(glove_type)
		gloves = new glove_type(src)
		add_obj_verb(src, /obj/item/hardsuit/proc/toggle_gauntlets)
	if(helm_type)
		helmet = new helm_type(src)
		add_obj_verb(src, /obj/item/hardsuit/proc/toggle_helmet)
	if(boot_type)
		boots = new boot_type(src)
		add_obj_verb(src, /obj/item/hardsuit/proc/toggle_boots)
	if(chest_type)
		chest = new chest_type(src)
		if(allowed)
			chest.allowed = allowed
		add_obj_verb(src, /obj/item/hardsuit/proc/toggle_chest)

	for(var/obj/item/piece in list(gloves,helmet,boots,chest))
		if(!istype(piece))
			continue
		ADD_TRAIT(piece, TRAIT_ITEM_NODROP, RIG_TRAIT)
		piece.name = "[suit_type] [initial(piece.name)]"
		piece.desc = "It seems to be part of a [src.name]."
		piece.icon_state = "[suit_state]"
		piece.min_cold_protection_temperature = min_cold_protection_temperature
		piece.max_heat_protection_temperature = max_heat_protection_temperature
		if(piece.siemens_coefficient > siemens_coefficient) //So that insulated gloves keep their insulation.
			piece.siemens_coefficient = siemens_coefficient
		piece.permeability_coefficient = permeability_coefficient
		piece.integrity_flags = integrity_flags
		piece.set_armor(fetch_armor())

	update_icon(1)

/obj/item/hardsuit/proc/spawn_storage_contents()
	if(length(storage_starts_with) && !storage_empty)
		// this is way too permissive already
		var/safety = 256
		var/atom/where_real_contents = obj_storage.real_contents_loc()
		for(var/path in storage_starts_with)
			var/amount = storage_starts_with[path] || 1
			for(var/i in 1 to amount)
				if(!--safety)
					CRASH("tried to spawn too many objects")
				new path(where_real_contents)
	storage_starts_with = null

/obj/item/hardsuit/proc/initialize_storage()
	ASSERT(isnull(obj_storage))
	init_storage(indirected = TRUE)

	obj_storage.set_insertion_allow(storage_insertion_allow)
	obj_storage.set_insertion_whitelist(storage_insertion_whitelist)
	obj_storage.set_insertion_blacklist(storage_insertion_blacklist)

	obj_storage.max_single_weight_class = storage_max_single_weight_class
	obj_storage.max_combined_weight_class = storage_max_combined_weight_class
	obj_storage.max_combined_volume = storage_max_combined_volume
	obj_storage.max_items = storage_max_items

	obj_storage.weight_subtract = storage_weight_subtract
	obj_storage.weight_multiply = storage_weight_multiply

	obj_storage.allow_quick_empty = storage_allow_quick_empty
	obj_storage.allow_quick_empty_via_clickdrag = storage_allow_quick_empty_via_clickdrag
	obj_storage.allow_quick_empty_via_attack_self = storage_allow_quick_empty_via_attack_self

	obj_storage.sfx_open = storage_sfx_open
	obj_storage.sfx_insert = storage_sfx_insert
	obj_storage.sfx_remove = storage_sfx_remove

	obj_storage.ui_numerical_mode = storage_ui_numerical_mode

/obj/item/hardsuit/Destroy()
	for(var/obj/item/piece in list(gloves,boots,helmet,chest))
		qdel(piece)
	STOP_PROCESSING(SSobj, src)
	if(minihud)
		QDEL_NULL(minihud)
	qdel(wires)
	wires = null
	qdel(spark_system)
	spark_system = null
	return ..()

/obj/item/hardsuit/render_mob_appearance(mob/M, slot_id_or_hand_index, bodytype)
	switch(slot_id_or_hand_index)
		if(SLOT_ID_BACK)
			if(mob_icon)
				mob_icon.color = color
				return mob_icon
		if(SLOT_ID_BELT)
			if(mob_icon)
				mob_icon.color = color
				return mob_icon
	return ..()

/obj/item/hardsuit/proc/suit_is_deployed()
	if(!istype(wearer) || src.loc != wearer || (wearer.back != src && wearer.belt != src))
		return 0
	if(helm_type && !(helmet && wearer.head == helmet))
		return 0
	if(glove_type && !(gloves && wearer.gloves == gloves))
		return 0
	if(boot_type && !(boots && wearer.shoes == boots))
		return 0
	if(chest_type && !(chest && wearer.wear_suit == chest))
		return 0
	return 1

// Updates pressure protection
// Seal = 1 sets protection
// Seal = 0 unsets protection
/obj/item/hardsuit/proc/update_airtight(var/obj/item/piece, var/seal = 0)
	if(seal == 1)
		piece.min_pressure_protection = rigsuit_min_pressure
		piece.max_pressure_protection = rigsuit_max_pressure
		piece.clothing_flags |= ALLOWINTERNALS
	else
		piece.min_pressure_protection = null
		piece.max_pressure_protection = null
		piece.clothing_flags &= ~ALLOWINTERNALS
	return


/obj/item/hardsuit/proc/reset()
	set_activation_state(RIG_ACTIVATION_OFF)
	REMOVE_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)
	//Reset the trap and upgrade it. Won't affect standard rigs.
	trapSprung = 0
	springtrapped = 1
	update_component_sealed()
	for(var/obj/item/piece in list(helmet,boots,gloves,chest))
		piece.icon_state = "[suit_state]"
	update_icon(1)

/obj/item/hardsuit/proc/trap(var/mob/living/carbon/human/M)
	warn = 0
	sleep(trapDelay)
	if(!suit_is_deployed())//Check if it's deployed. Interrupts taking it off.
		toggle_piece("helmet", M, ONLY_DEPLOY)
		toggle_piece("gauntlets", M, ONLY_DEPLOY)
		toggle_piece("chest", M, ONLY_DEPLOY)
		toggle_piece("boots", M, ONLY_DEPLOY)
		if(suit_is_deployed())
			playsound(src.loc, 'sound/weapons/empty.ogg', 40, 1)
			to_chat(M, "<span class='warning'>[src] makes a distinct clicking noise.")
			trapSprung = 1
		else
			trap(M)
			warn = 1
	else
		trap(M)
		warn = 1

/obj/item/hardsuit/proc/springtrap(var/mob/living/carbon/human/M)
	warn = 0
	sleep(trapDelay)
	if(!suit_is_deployed())
		toggle_piece("helmet", M, ONLY_DEPLOY)
		toggle_piece("gauntlets", M, ONLY_DEPLOY)
		toggle_piece("chest", M, ONLY_DEPLOY)
		toggle_piece("boots", M, ONLY_DEPLOY)
		if(suit_is_deployed())
			M.take_targeted_damage(
				brute = 70,
				damage_mode = DAMAGE_MODE_SHARP | DAMAGE_MODE_EDGE | DAMAGE_MODE_SHRED,
				body_zone = BP_TORSO,
			)
			for(var/harm = 8; harm > 0; harm--)
				M.adjustBruteLoss(10)
			playsound(src.loc, 'sound/weapons/gunshot_generic_rifle.ogg', 40, 1)
			to_chat(M, "<span class ='userdanger'>[src] clamps down hard, support rods and wires shooting forth, piercing you all over!")
			trapSprung = 1
		else
			springtrap(M)
			warn = 1
	else
		springtrap(M)
		warn = 1

/obj/item/hardsuit/proc/toggle_seals(var/mob/living/carbon/human/M,var/instant)
	if(is_cycling())
		return

	if(!check_power_cost(M))
		return 0

	if(trapSprung == 1)
		to_chat(M, "<span class='warning'>The [src] doesn't respond to your inputs.")
		return

	deploy(M,instant)

	var/is_sealing = !is_activated()
	var/old_activation = activation_state
	var/failed_to_seal

	var/atom/movable/screen/rig_booting/booting_L = new
	var/atom/movable/screen/rig_booting/booting_R = new

	if(is_sealing)
		booting_L.icon_state = "boot_left"
		booting_R.icon_state = "boot_load"
		animate(booting_L, alpha=230, time=30, easing=SINE_EASING)
		animate(booting_R, alpha=200, time=20, easing=SINE_EASING)
		M.client.screen += booting_L
		M.client.screen += booting_R

	ADD_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)
	set_activation_state(is_sealing? RIG_ACTIVATION_STARTUP : RIG_ACTIVATION_SHUTDOWN)

	if(is_sealing && !suit_is_deployed())
		M.visible_message("<span class='danger'>[M]'s suit flashes an error light.</span>","<span class='danger'>Your suit flashes an error light. It can't function properly without being fully deployed.</span>")
		failed_to_seal = 1

	if(!failed_to_seal)

		if(!instant)
			M.visible_message("<font color=#4F49AF>[M]'s suit emits a quiet hum as it begins to adjust its seals.</font>","<font color=#4F49AF>With a quiet hum, the suit begins running checks and adjusting components.</font>")
			if(seal_delay && !do_after(M,seal_delay))
				if(M)
					to_chat(M, "<span class='warning'>You must remain still while the suit is adjusting the components.</span>")
				failed_to_seal = 1
		if(!M)
			failed_to_seal = 1
		else
			for(var/list/piece_data in list(list(M.shoes,boots,"boots",boot_type),list(M.gloves,gloves,"gloves",glove_type),list(M.head,helmet,"helmet",helm_type),list(M.wear_suit,chest,"chest",chest_type)))

				var/obj/item/piece = piece_data[1]
				var/obj/item/compare_piece = piece_data[2]
				var/msg_type = piece_data[3]
				var/piece_type = piece_data[4]

				if(!piece || !piece_type)
					continue

				if(!istype(M) || !istype(piece) || !istype(compare_piece) || !msg_type)
					if(M)
						to_chat(M, "<span class='warning'>You must remain still while the suit is adjusting the components.</span>")
					failed_to_seal = 1
					break

				if(!failed_to_seal && (M.back == src || M.belt == src) && piece == compare_piece)

					if(seal_delay && !instant && !do_self(M, seal_delay, DO_AFTER_IGNORE_ACTIVE_ITEM | DO_AFTER_IGNORE_MOVEMENT, NONE))
						failed_to_seal = 1

					piece.copy_atom_color(src)
					piece.icon_state = "[suit_state][is_sealing ? "_sealed" : ""]"
					piece.update_worn_icon()
					switch(msg_type)
						if("boots")
							to_chat(M, "<font color=#4F49AF>\The [piece] [is_sealing ? "seal around your feet" : "relax their grip on your legs"].</font>")
						if("gloves")
							to_chat(M, "<font color=#4F49AF>\The [piece] [is_sealing ? "tighten around your fingers and wrists" : "become loose around your fingers"].</font>")
						if("chest")
							to_chat(M, "<font color=#4F49AF>\The [piece] [is_sealing ? "cinches tight again your chest" : "releases your chest"].</font>")
						if("helmet")
							to_chat(M, "<font color=#4F49AF>\The [piece] hisses [is_sealing ? "closed" : "open"].</font>")
							if(helmet)
								helmet.update_light(wearer)

					//sealed pieces become airtight, protecting against diseases
					if (is_sealing)
						piece.set_armor(piece.fetch_armor().boosted(list(ARMOR_BIO = 100)))
					else
						piece.set_armor(piece.fetch_armor().overwritten(list(ARMOR_BIO = fetch_armor().get_mitigation(ARMOR_BIO))))
				else
					failed_to_seal = 1

		if((M && !(istype(M) && (M.back == src || M.belt == src)) && !istype(M,/mob/living/silicon)) || (is_sealing && !suit_is_deployed()))
			failed_to_seal = 1

	if(failed_to_seal)
		set_activation_state(old_activation)
		M.client.screen -= booting_L
		M.client.screen -= booting_R
		qdel(booting_L)
		qdel(booting_R)
		for(var/obj/item/piece in list(helmet,boots,gloves,chest))
			if(!piece)
				continue
			piece.icon_state = "[suit_state][is_activated() ? "_sealed" : ""]"
			piece.copy_atom_color(src)
			piece.update_worn_icon()

		if(is_activated())
			ADD_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)
		else
			REMOVE_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)
		if(airtight)
			update_component_sealed()
		update_icon(1)
		return 0

	// Success!
	if(is_sealing)
		set_activation_state(RIG_ACTIVATION_ON)
		ADD_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)
	else
		set_activation_state(RIG_ACTIVATION_OFF)
		REMOVE_TRAIT(src, TRAIT_ITEM_NODROP, RIG_TRAIT)

	if(M.hud_used)
		if(!is_activated())
			QDEL_NULL(minihud)
		else
			minihud = new (M.hud_used, src)

	to_chat(M, "<font color=#4F49AF><b>Your entire suit [!is_sealing ? "loosens as the components relax" : "tightens around you as the components lock into place"].</b></font>")
	M.client.screen -= booting_L
	qdel(booting_L)
	booting_R.icon_state = "boot_done"
	spawn(40)
		M.client.screen -= booting_R
		qdel(booting_R)

	if(is_sealing)
		if(isTrapped == 1 && springtrapped == 1)
			springtrap(M)
		if(isTrapped == 1 && springtrapped == 0)
			trap(M)

	if(!is_sealing)
		for(var/obj/item/hardsuit_module/module in installed_modules)
			module.deactivate()

	if(airtight)
		update_component_sealed()

	update_icon(1)

/obj/item/hardsuit/proc/update_component_sealed()
	for(var/obj/item/piece in list(helmet,boots,gloves,chest))
		if(!is_activated())
			update_airtight(piece, 0) // Unseal
		else
			update_airtight(piece, 1) // Seal

/obj/item/hardsuit/ui_action_click(datum/action/action, datum/event_args/actor/actor)
	toggle_cooling(usr)

/obj/item/hardsuit/proc/toggle_cooling(var/mob/user)
	if(cooling_on)
		turn_cooling_off(user)
	else
		turn_cooling_on(user)

/obj/item/hardsuit/proc/turn_cooling_on(var/mob/user)
	if(!cell)
		return
	if(cell.charge <= 0)
		to_chat(user, "<span class='notice'>\The [src] has no power!.</span>")
		return
	if(!suit_is_deployed())
		to_chat(user, "<span class='notice'>The hardsuit needs to be deployed first!.</span>")
		return

	cooling_on = 1
	to_chat(usr, "<span class='notice'>You switch \the [src]'s cooling system on.</span>")


/obj/item/hardsuit/proc/turn_cooling_off(var/mob/user, var/failed)
	if(failed)
		visible_message("\The [src]'s cooling system clicks and whines as it powers down.")
	else
		to_chat(usr, "<span class='notice'>You switch \the [src]'s cooling system off.</span>")
	cooling_on = 0

/obj/item/hardsuit/proc/get_environment_temperature()
	if (ishuman(loc))
		var/mob/living/carbon/human/H = loc
		if(istype(H.loc, /obj/vehicle/sealed/mecha))
			var/obj/vehicle/sealed/mecha/M = H.loc
			return M.return_temperature()
		else if(istype(H.loc, /obj/machinery/atmospherics/component/unary/cryo_cell))
			var/obj/machinery/atmospherics/component/unary/cryo_cell/cryo = H.loc
			return cryo.air_contents.temperature

	var/turf/T = get_turf(src)
	if(istype(T, /turf/space))
		return 0	//space has no temperature, this just makes sure the cooling unit works in space

	var/datum/gas_mixture/environment = T.return_air()
	if (!environment)
		return 0

	return environment.temperature

/obj/item/hardsuit/proc/attached_to_user(mob/M)
	if (!ishuman(M))
		return 0

	var/mob/living/carbon/human/H = M

	if (!H.wear_suit || (H.back != src && H.belt != src))
		return 0

	return 1

/obj/item/hardsuit/proc/coolingProcess()
	if (!cooling_on || !cell)
		return

	if (!ismob(loc))
		return

	if (!attached_to_user(loc))		//make sure the hardsuit's not just in their hands
		return

	if (!suit_is_deployed())		//inbuilt systems only work on the suit they're designed to work on
		return

	var/mob/living/carbon/human/H = loc

	var/turf/T = get_turf(src)
	var/datum/gas_mixture/environment = T.return_air()
	var/efficiency = 1 - H.get_pressure_weakness(environment.return_pressure())	// You need to have a good seal for effective cooling
	var/env_temp = get_environment_temperature()						//wont save you from a fire
	var/temp_adj = min(H.bodytemperature - max(thermostat, env_temp), max_cooling)

	if (temp_adj < 0.5)	//only cools, doesn't heat, also we don't need extreme precision
		return

	var/charge_usage = (temp_adj/max_cooling)*charge_consumption

	H.bodytemperature -= temp_adj*efficiency

	cell.use(charge_usage)

	if(cell.charge <= 0)
		turn_cooling_off(H, 1)

/obj/item/hardsuit/process(delta_time)
	// If we've lost any parts, grab them back.
	for(var/obj/item/piece in list(gloves,boots,helmet,chest))
		if(piece.loc != src && !(wearer && piece.loc == wearer))
			piece.forceMove(src)
	// Run through cooling
	coolingProcess()

	if(!is_online())
		if(last_online)
			last_online = FALSE
			for(var/obj/item/hardsuit_module/module in installed_modules)
				module.deactivate()
			set_encumbrance(offline_encumbrance)
			if(istype(wearer))
				if(is_activated())
					to_chat(wearer, "<span class='danger'>Your suit beeps stridently, and suddenly you're wearing a leaden mass of metal and plastic composites instead of a powered suit.</span>")
				if(offline_vision_restriction == 1)
					to_chat(wearer, "<span class='danger'>The suit optics flicker and die, leaving you with restricted vision.</span>")
				else if(offline_vision_restriction == 2)
					to_chat(wearer, "<span class='danger'>The suit optics drop out completely, drowning you in darkness.</span>")
			if(electrified > 0)
				electrified = 0
		return
	else
		if(!last_online)
			last_online = TRUE
		if(istype(wearer) && !wearer.wearing_rig)
			wearer.wearing_rig = src
		set_encumbrance(isnull(online_encumbrance)? initial(encumbrance) : online_encumbrance)
		set_slowdown(initial(slowdown) + sprint_slowdown_modifier)

	if(cell && cell.charge > 0 && electrified > 0)
		electrified--

	if(malfunction_delay > 0)
		malfunction_delay--
	else if(malfunctioning)
		malfunctioning--
		malfunction()

	for(var/obj/item/hardsuit_module/module in installed_modules)
		cell.use(module.process()*10)

/obj/item/hardsuit/proc/check_power_cost(var/mob/living/user, var/cost, var/use_unconcious, var/obj/item/hardsuit_module/mod, var/user_is_ai)

	if(!istype(user))
		return 0

	var/fail_msg

	if(!user_is_ai)
		var/mob/living/carbon/human/H = user
		if(istype(H) && (H.back != src && H.belt != src))
			fail_msg = "<span class='warning'>You must be wearing \the [src] to do this.</span>"
		else if(user.incorporeal_move)
			fail_msg = "<span class='warning'>You must be solid to do this.</span>"
	if(is_cycling())
		fail_msg = "<span class='warning'>The hardsuit is in the process of adjusting seals and cannot be activated.</span>"
	else if(!fail_msg && ((use_unconcious && user.stat > 1) || (!use_unconcious && user.stat)))
		fail_msg = "<span class='warning'>You are in no fit state to do that.</span>"
	else if(!cell)
		fail_msg = "<span class='warning'>There is no cell installed in the suit.</span>"
	else if(cost && cell.charge < cost * 10) //TODO: Cellrate?
		fail_msg = "<span class='warning'>Not enough stored power.</span>"

	if(fail_msg)
		to_chat(user, fail_msg)
		return 0

	// This is largely for cancelling stealth and whatever.
	if(mod && mod.disruptive)
		for(var/obj/item/hardsuit_module/module in (installed_modules - mod))
			if(module.active && module.disruptable)
				module.deactivate()

	cell.use(cost*10)
	return 1

/obj/item/hardsuit/nano_ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/nano_state = inventory_state)
	if(!user)
		return

	var/list/data = list()

	if(selected_module)
		data["primarysystem"] = "[selected_module.interface_name]"

	if(src.loc != user)
		data["ai"] = 1

	data["seals"] =     is_activated()
	data["sealing"] =   is_cycling()
	data["helmet"] =    (helmet ? "[helmet.name]" : "None.")
	data["gauntlets"] = (gloves ? "[gloves.name]" : "None.")
	data["boots"] =     (boots ?  "[boots.name]" :  "None.")
	data["chest"] =     (chest ?  "[chest.name]" :  "None.")

	data["charge"] =       cell ? round(cell.charge,1) : 0
	data["maxcharge"] =    cell ? cell.maxcharge : 0
	data["chargestatus"] = cell ? FLOOR((cell.charge/cell.maxcharge)*50, 1) : 0

	data["emagged"] =       subverted
	data["coverlock"] =     locked
	data["interfacelock"] = interface_locked
	data["aicontrol"] =     control_overridden
	data["aioverride"] =    ai_override_enabled
	data["securitycheck"] = security_check_enabled
	data["malf"] =          malfunction_delay


	var/list/module_list = list()
	var/i = 1
	for(var/obj/item/hardsuit_module/module in installed_modules)
		var/list/module_data = list(
			"index" =             i,
			"name" =              "[module.interface_name]",
			"desc" =              "[module.interface_desc]",
			"can_use" =           "[module.usable]",
			"can_select" =        "[module.selectable]",
			"can_toggle" =        "[module.toggleable]",
			"is_active" =         "[module.active]",
			"engagecost" =        module.use_power_cost*10,
			"activecost" =        module.active_power_cost*10,
			"passivecost" =       module.passive_power_cost*10,
			"engagestring" =      module.engage_string,
			"activatestring" =    module.activate_string,
			"deactivatestring" =  module.deactivate_string,
			"damage" =            module.damage
			)

		if(module.charges && module.charges.len)

			module_data["charges"] = list()
			var/datum/rig_charge/selected = module.charges[module.charge_selected]
			module_data["chargetype"] = selected ? "[selected.display_name]" : "none"

			for(var/chargetype in module.charges)
				var/datum/rig_charge/charge = module.charges[chargetype]
				module_data["charges"] += list(list("caption" = "[chargetype] ([charge.charges])", "index" = "[chargetype]"))

		module_list += list(module_data)
		i++

	if(module_list.len)
		data["modules"] = module_list

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, ((src.loc != user) ? ai_interface_path : interface_path), interface_title, 480, 550, state = nano_state)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/item/hardsuit/update_icon(update_mob_icon)

	//TODO: Maybe consider a cache for this (use mob_icon as blank canvas, use suit icon overlay).
	cut_overlays()
	if(!mob_icon || update_mob_icon)
		var/species_icon = 'icons/mob/clothing/rig_back.dmi'
		// Since setting mob_icon will override the species checks in
		// update_inv_wear_suit(), handle species checks here.
		if(wearer && sprite_sheets && sprite_sheets[wearer.species.get_worn_legacy_bodytype(wearer)])
			species_icon =  sprite_sheets[wearer.species.get_worn_legacy_bodytype(wearer)]
		mob_icon = mutable_appearance(icon = species_icon, icon_state = "[icon_state]")
		mob_icon.color = color

	if(installed_modules.len)
		for(var/obj/item/hardsuit_module/module in installed_modules)
			if(module.suit_overlay)
				chest.add_overlay(image("icon" = 'icons/mob/clothing/rig_modules.dmi', "icon_state" = "[module.suit_overlay]", "dir" = SOUTH))

	if(wearer)
		wearer.update_inv_shoes()
		wearer.update_inv_gloves()
		wearer.update_inv_head()
		wearer.update_inv_wear_suit()
		wearer.update_inv_back()
	return

/obj/item/hardsuit/proc/check_suit_access(var/mob/living/carbon/human/user)

	if(!security_check_enabled)
		return 1

	if(istype(user))
		if(!is_activated())
			return 1
		if(malfunction_check(user))
			return 0
		if(user.back != src && user.belt != src)
			return 0
		else if(!src.allowed(user))
			to_chat(user, "<span class='danger'>Unauthorized user. Access denied.</span>")
			return 0

	else if(!ai_override_enabled)
		to_chat(user, "<span class='danger'>Synthetic access disabled. Please consult hardware provider.</span>")
		return 0

	return 1

//TODO: Fix Topic vulnerabilities for malfunction and AI override.
/obj/item/hardsuit/Topic(href,href_list)
	if(!check_suit_access(usr))
		return 0

	if(href_list["toggle_piece"])
		if(ishuman(wearer) && !CHECK_MOBILITY(usr, MOBILITY_CAN_STORAGE))
			return 0
		toggle_piece(href_list["toggle_piece"], wearer)
	else if(href_list["toggle_seals"])
		toggle_seals(wearer)
	else if(href_list["interact_module"])

		var/module_index = text2num(href_list["interact_module"])

		if(module_index > 0 && module_index <= installed_modules.len)
			var/obj/item/hardsuit_module/module = installed_modules[module_index]
			switch(href_list["module_mode"])
				if("activate")
					module.activate()
				if("deactivate")
					module.deactivate()
				if("engage")
					module.engage()
				if("select")
					selected_module = module
				if("select_charge_type")
					module.charge_selected = href_list["charge_type"]
	else if(href_list["toggle_ai_control"])
		ai_override_enabled = !ai_override_enabled
		notify_ai("Synthetic suit control has been [ai_override_enabled ? "enabled" : "disabled"].")
	else if(href_list["toggle_suit_lock"])
		locked = !locked

	usr.set_machine(src)
	src.add_fingerprint(usr)
	return 0

/obj/item/hardsuit/proc/notify_ai(var/message)
	for(var/obj/item/hardsuit_module/ai_container/module in installed_modules)
		if(module.integrated_ai && module.integrated_ai.client && !module.integrated_ai.stat)
			to_chat(module.integrated_ai, "[message]")
			. = 1

/obj/item/hardsuit/equipped(mob/living/carbon/human/M)
	..()

	if(istype(M.back, /obj/item/hardsuit) && istype(M.belt, /obj/item/hardsuit))
		to_chat(M, "<span class='notice'>You try to put on the [src], but it won't fit.</span>")
		forceMove(get_turf(src))
		return

	if(seal_delay > 0 && istype(M) && (M.back == src || M.belt == src))
		M.visible_message("<font color=#4F49AF>[M] starts putting on \the [src]...</font>", "<font color=#4F49AF>You start putting on \the [src]...</font>")
		if(!do_after(M,seal_delay))
			forceMove(get_turf(src))
			return

	if(istype(M) && (M.back == src || M.belt == src))
		M.visible_message("<font color=#4F49AF><b>[M] struggles into \the [src].</b></font>", "<font color=#4F49AF><b>You struggle into \the [src].</b></font>")
		wearer = M
		wearer.wearing_rig = src
		update_icon()

/obj/item/hardsuit/proc/toggle_piece(var/piece, var/mob/living/carbon/human/H, var/deploy_mode)

	if(is_cycling() || !cell || !cell.charge)
		return

	if(!istype(wearer) || (!wearer.back == src && !wearer.belt == src))
		return

	if(usr == wearer && !CHECK_MOBILITY(H, MOBILITY_CAN_MOVE)) // If the usr isn't wearing the suit it's probably an AI.
		return

	if(trapSprung == 1)
		to_chat(H, "<span class='warning'>The [src] doesn't respond to your inputs.")
		return

	var/obj/item/check_slot
	var/equip_to
	var/obj/item/use_obj

	if(!H)
		return

	switch(piece)
		if("helmet")
			equip_to = SLOT_ID_HEAD
			use_obj = helmet
			check_slot = H.head
		if("gauntlets")
			equip_to = SLOT_ID_GLOVES
			use_obj = gloves
			check_slot = H.gloves
		if("boots")
			equip_to = SLOT_ID_SHOES
			use_obj = boots
			check_slot = H.shoes
		if("chest")
			equip_to = SLOT_ID_SUIT
			use_obj = chest
			check_slot = H.wear_suit

	if(use_obj)
		if(check_slot == use_obj && deploy_mode != ONLY_DEPLOY)

			var/mob/living/carbon/human/holder

			if(use_obj)
				holder = use_obj.loc
				if(istype(holder))
					if(use_obj && check_slot == use_obj)
						to_chat(H, "<font color=#4F49AF><b>Your [use_obj.name] [use_obj.gender == PLURAL ? "retract" : "retracts"] swiftly.</b></font>")
						if(!holder.transfer_item_to_loc(use_obj, src, INV_OP_FORCE))
							use_obj.forceMove(src)

		else if (deploy_mode != ONLY_RETRACT)
			if(check_slot && check_slot == use_obj)
				return
			use_obj.copy_atom_color(src)
			if(!H.equip_to_slot_if_possible(use_obj, equip_to, INV_OP_FORCE))
				if(check_slot && warn == 1)
					to_chat(H, "<span class='danger'>You are unable to deploy \the [piece] as \the [check_slot] [check_slot.gender == PLURAL ? "are" : "is"] in the way.</span>")
					return
			else
				to_chat(H, "<span class='notice'>Your [use_obj.name] [use_obj.gender == PLURAL ? "deploy" : "deploys"] swiftly.</span>")

	if(piece == "helmet" && helmet)
		helmet.update_light(H)

/obj/item/hardsuit/proc/deploy(mob/M,var/sealed)

	var/mob/living/carbon/human/H = M

	if(!H || !istype(H)) return

	if(H.back != src && H.belt != src)
		return

	if(sealed)
		if(H.head)
			H.drop_item_to_ground(H.head, flags = INV_OP_FORCE)

		if(H.gloves)
			H.drop_item_to_ground(H.gloves, flags = INV_OP_FORCE)

		if(H.shoes)
			H.drop_item_to_ground(H.shoes, flags = INV_OP_FORCE)

		if(H.wear_suit)
			H.drop_item_to_ground(H.wear_suit, flags = INV_OP_FORCE)

	for(var/piece in list("helmet","gauntlets","chest","boots"))
		toggle_piece(piece, H, ONLY_DEPLOY)

/obj/item/hardsuit/unequipped(mob/user, slot, flags)
	. = ..()
	for(var/piece in list("helmet","gauntlets","chest","boots"))
		toggle_piece(piece, user, ONLY_RETRACT)
	if(wearer && wearer.wearing_rig == src)
		wearer.wearing_rig = null
	wearer = null

//Todo
/obj/item/hardsuit/proc/malfunction()
	return 0

/obj/item/hardsuit/emp_act(severity_class)
	//set malfunctioning
	if(emp_protection < 30) //for ninjas, really.
		malfunctioning += 10
		if(malfunction_delay <= 0)
			malfunction_delay = max(malfunction_delay, round(30/severity_class))

	//drain some charge
	if(cell) cell.emp_act(severity_class + 15)

	//possibly damage some modules
	take_hit((100/severity_class), "electrical pulse", 1)

/obj/item/hardsuit/proc/shock(mob/user)
	if (electrocute_mob(user, cell, src)) //electrocute_mob() handles removing charge from the cell, no need to do that here.
		spark_system.start()
		if(!CHECK_MOBILITY(user, MOBILITY_CAN_USE))
			return 1
	return 0

/obj/item/hardsuit/proc/take_hit(damage, source, is_emp=0)

	if(!installed_modules.len)
		return

	var/chance
	if(!is_emp)
		chance = 2*max(0, damage - (chest? chest.breach_threshold : 0))
	else
		//Want this to be roughly independant of the number of modules, meaning that X emp hits will disable Y% of the suit's modules on average.
		//that way people designing hardsuits don't have to worry (as much) about how adding that extra module will affect emp resiliance by 'soaking' hits for other modules
		chance = 2*max(0, damage - emp_protection)*min(installed_modules.len/15, 1)

	if(!prob(chance))
		return

	//deal addition damage to already damaged module first.
	//This way the chances of a module being disabled aren't so remote.
	var/list/valid_modules = list()
	var/list/damaged_modules = list()
	for(var/obj/item/hardsuit_module/module in installed_modules)
		if(module.damage < 2)
			valid_modules |= module
			if(module.damage > 0)
				damaged_modules |= module

	var/obj/item/hardsuit_module/dam_module = null
	if(damaged_modules.len)
		dam_module = pick(damaged_modules)
	else if(valid_modules.len)
		dam_module = pick(valid_modules)

	if(!dam_module) return

	dam_module.damage++

	if(!source)
		source = "hit"

	if(wearer)
		if(dam_module.damage >= 2)
			to_chat(wearer, "<span class='danger'>The [source] has disabled your [dam_module.interface_name]!</span>")
		else
			to_chat(wearer, "<span class='warning'>The [source] has damaged your [dam_module.interface_name]!</span>")
	dam_module.deactivate()

/obj/item/hardsuit/proc/malfunction_check(var/mob/living/carbon/human/user)
	if(malfunction_delay)
		if(!is_online())
			to_chat(user, "<span class='danger'>The suit is completely unresponsive.</span>")
		else
			to_chat(user, "<span class='danger'>ERROR: Hardware fault. Rebooting interface...</span>")
		return 1
	return 0

/obj/item/hardsuit/proc/ai_can_move_suit(var/mob/user, var/check_user_module = 0, var/check_for_ai = 0)

	if(check_for_ai)
		if(!(locate(/obj/item/hardsuit_module/ai_container) in contents))
			return 0
		var/found_ai
		for(var/obj/item/hardsuit_module/ai_container/module in contents)
			if(module.damage >= 2)
				continue
			if(module.integrated_ai && module.integrated_ai.client && !module.integrated_ai.stat)
				found_ai = 1
				break
		if(!found_ai)
			return 0

	if(check_user_module)
		if(!user || !user.loc || !user.loc.loc)
			return 0
		var/obj/item/hardsuit_module/ai_container/module = user.loc.loc
		if(!istype(module) || module.damage >= 2)
			to_chat(user, "<span class='warning'>Your host module is unable to interface with the suit.</span>")
			return 0

	if(!is_online() || locked_down)
		if(user)
			to_chat(user, "<span class='warning'>Your host hardsuit is unpowered and unresponsive.</span>")
		return 0
	if(!wearer || (wearer.back != src && wearer.belt != src))
		if(user) to_chat(user, "<span class='warning'>Your host hardsuit is not being worn.</span>")
		return 0
	if(!wearer.stat && !control_overridden && !ai_override_enabled)
		if(user) to_chat(user, "<span class='warning'>You are locked out of the suit servo controller.</span>")
		return 0
	return 1

/obj/item/hardsuit/proc/force_rest(var/mob/user)
	if(!ai_can_move_suit(user, check_user_module = 1))
		return
	wearer.lay_down()
	to_chat(user, "<span class='notice'>\The [wearer] is now [wearer.resting ? "resting" : "getting up"].</span>")

/obj/item/hardsuit/proc/forced_move(var/direction, var/mob/user, var/ai_moving = TRUE, protean_shitcode_moment)
	// Why is all this shit in client/Move()? Who knows?
	if(world.time < wearer_move_delay)
		return

	if(!wearer || !wearer.loc)
		return

	if(ai_moving)
		if(!ai_can_move_suit(user, check_user_module = 1))
			return

	//This is sota the goto stop mobs from moving var
	if(!CHECK_MOBILITY(user, MOBILITY_CAN_MOVE))
		return

	if(!wearer.lastarea)
		wearer.lastarea = get_area(wearer.loc)

	if((istype(wearer.loc, /turf/space)) || (wearer.lastarea.has_gravity == 0))
		if(!wearer.Process_Spacemove(0))
			return 0

	if(malfunctioning)
		direction = pick(GLOB.cardinal)

	// Inside an object, tell it we moved.
	if(isobj(wearer.loc) || ismob(wearer.loc))
		var/atom/O = wearer.loc
		return O.relaymove(wearer, direction)

	if(isturf(wearer.loc))
		if(wearer.restrained())//Why being pulled while cuffed prevents you from moving
			for(var/mob/M in range(wearer, 1))
				if(M.pulling == wearer)
					if(CHECK_MOBILITY(M, MOBILITY_CAN_MOVE) && wearer.Adjacent(M))
						to_chat(user, "<span class='notice'>Your host is restrained! They can't move!</span>")
						return 0
					else
						M.stop_pulling()

	// if(wearer.pinned.len)
	// 	to_chat(src, "<span class='notice'>Your host is pinned to a wall by [wearer.pinned[1]]</span>!")
	// 	return 0

	// AIs are a bit slower than regular and ignore move intent.
	wearer_move_delay = world.time + ai_controlled_move_delay

	if(istype(wearer.buckled, /obj/vehicle_old))
		//manually set move_delay for vehicles so we don't inherit any mob movement penalties
		//specific vehicle move delays are set in code\modules\vehicles\vehicle.dm
		wearer_move_delay = world.time
		return wearer.buckled.relaymove(wearer, direction)

	if(istype(wearer.machine, /obj/machinery))
		if(wearer.machine.relaymove(wearer, direction))
			return

	if(wearer.pulledby || wearer.buckled) // Wheelchair driving!
		if(istype(wearer.loc, /turf/space))
			return // No wheelchair driving in space
		if(istype(wearer.pulledby, /obj/structure/bed/chair/wheelchair))
			return wearer.pulledby.relaymove(wearer, direction)
		else if(istype(wearer.buckled, /obj/structure/bed/chair/wheelchair))
			if(ishuman(wearer.buckled))
				var/obj/item/organ/external/l_hand = wearer.get_organ("l_hand")
				var/obj/item/organ/external/r_hand = wearer.get_organ("r_hand")
				if((!l_hand || (l_hand.status & ORGAN_DESTROYED)) && (!r_hand || (r_hand.status & ORGAN_DESTROYED)))
					return // No hands to drive your chair? Tough luck!
			wearer_move_delay += 2
			return wearer.buckled.relaymove(wearer,direction)

	var/power_cost = 200
	if(!ai_moving)
		power_cost = 20
	if(!protean_shitcode_moment)	// fuck this kill me
		cell.use(power_cost) //Arbitrary, TODO
	wearer.Move(get_step(get_turf(wearer),direction),direction)

// This returns the hardsuit if you are contained inside one, but not if you are wearing it
/atom/proc/get_hardsuit()
	if(loc)
		return loc.get_hardsuit()
	return null

/obj/item/hardsuit/get_hardsuit()
	return src

/mob/living/carbon/human/get_hardsuit(requires_activated)
	if(!requires_activated)
		if(istype(back, /obj/item/hardsuit))
			return back
		else if(istype(belt, /obj/item/hardsuit))
			return belt
	else
		var/obj/item/hardsuit/R
		if(istype(belt, /obj/item/hardsuit))
			R = belt
			if(R.is_activated())
				return R
		else if(istype(back, /obj/item/hardsuit))
			R = back
			if(R.is_activated())
				return R

//Boot animation screen objects
/atom/movable/screen/rig_booting
	screen_loc = "CENTER-7,CENTER-7"
	icon = 'icons/obj/rig_boot.dmi'
	icon_state = ""
	layer = HUD_LAYER_UNDER
	plane = FULLSCREEN_PLANE
	mouse_opacity = 0
	alpha = 20 //Animated up when loading

//Shows cell charge on screen, ideally.

var/atom/movable/screen/cells = null

#undef ONLY_DEPLOY
#undef ONLY_RETRACT
#undef SEAL_DELAY
