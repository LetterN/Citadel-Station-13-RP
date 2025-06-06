/mob
	//* Actionspeed *//
	/// List of action speed modifiers applying to this mob
	/// * Lazy list, see mob_movespeed.dm
	var/list/actionspeed_modifiers
	/// List of action speed modifiers ignored by this mob. List -> List (id) -> List (sources)
	/// * Lazy list, see mob_movespeed.dm
	var/list/actionspeed_modifier_immunities

	//* Impairments *//
	/// active feign_impairment types
	/// * lazy list
	var/list/impairments_feigned

	//* Movespeed *//
	/// List of movement speed modifiers applying to this mob
	/// * This is a lazy list.
	var/list/movespeed_modifiers
	/// List of movement speed modifiers ignored by this mob. List -> List (id) -> List (sources)
	/// * This is a lazy list.
	var/list/movespeed_modifier_immunities
	/// The calculated mob speed slowdown based on the modifiers list
	var/movespeed_hyperbolic

/**
 * Intialize a mob
 *
 * Adds to global lists
 * * GLOB.mob_list
 * * dead_mob_list - if mob is dead
 * * living_mob_list - if the mob is alive
 *
 * Other stuff:
 * * Sets the mob focus to itself
 * * Generates huds
 * * If there are any global alternate apperances apply them to this mob
 * * Intialize the transform of the mob
 */
/mob/Initialize(mapload)
	// mob lists
	mob_list_register(stat)
	// actions
	actions_controlled = new /datum/action_holder/mob_actor(src)
	actions_innate = new /datum/action_holder/mob_actor(src)
	// physiology
	init_physiology()
	// atom HUDs
	prepare_huds()
	set_key_focus(src)
	// signal
	SEND_GLOBAL_SIGNAL(COMSIG_GLOBAL_MOB_NEW, src)
	// abilities
	init_abilities()
	// inventory
	init_inventory()
	// rendering
	init_rendering()
	// resize
	update_transform()
	// offset
	reset_pixel_offsets()
	// update gravity
	update_gravity()
	// movespeed
	update_movespeed_base()
	// actionspeed
	initialize_actionspeed()
	// ssd overlay
	update_ssd_overlay()
	// iff factions
	init_iff()
	return ..()

/mob/Destroy()
	// status effects
	for(var/id in status_effects)
		var/datum/status_effect/effect = status_effects[id]
		qdel(effect)
	status_effects = null
	// mob lists
	mob_list_unregister(stat)
	// todo: remove machine
	unset_machine()
	// hud
	for(var/alert in alerts)
		clear_alert(alert)
	if(client)
		for(var/atom/movable/screen/movable/spell_master/spell_master in spell_masters)
			qdel(spell_master)
		remove_screen_obj_references()
		client.screen = list()
	// mind
	if(!isnull(mind))
		if(mind.current == src)
			// mind is ours, let it disassociate
			// todo: legacy spell
			spellremove(src)
			mind?.disassociate()
		else
			// mind is not ours, null it out
			mind = null
	// signal
	SEND_GLOBAL_SIGNAL(COMSIG_GLOBAL_MOB_DEL, src)
	// abilities
	dispose_abilities()
	// actions
	QDEL_NULL(actions_controlled)
	QDEL_NULL(actions_innate)
	// this kicks out client
	ghostize()
	// get rid of our shit and nullspace everything first..
	..()
	// rendering
	if(hud_used)
		QDEL_NULL(hud_used)
	dispose_rendering()
	// perspective; it might be gone now because self perspective is destroyed in ..()
	using_perspective?.remove_mob(src, TRUE)
	// physiology
	QDEL_NULL(physiology)
	physiology_modifiers = null
	// movespeed
	movespeed_modifiers = null
	// actionspeed
	actionspeed_modifiers = null
	return QDEL_HINT_HARDDEL

//* Mob List Registration *//

/mob/proc/mob_list_register(for_stat)
	GLOB.mob_list += src
	if(for_stat == DEAD)
		dead_mob_list += src
	else
		living_mob_list += src

/mob/proc/mob_list_unregister(for_stat)
	GLOB.mob_list -= src
	if(for_stat == DEAD)
		dead_mob_list -= src
	else
		living_mob_list -= src

/mob/proc/mob_list_update_stat(old_stat, new_stat)
	mob_list_unregister(old_stat)
	mob_list_register(new_stat)

/**
 * Generate the tag for this mob
 *
 * This is simply "mob_"+ a global incrementing counter that goes up for every mob
 */
/mob/generate_tag()
	tag = "mob_[++next_mob_id]"

/**
 * Prepare the huds for this atom
 *
 * Goes through hud_possible list and adds the images to the hud_list variable (if not already
 * cached)
 *
 * todo: this should be atom level but uhh lmao lol
 */
/mob/proc/prepare_huds()
	if(!atom_huds_to_initialize)
		return
	for(var/hud in atom_huds_to_initialize)
		update_atom_hud_provider(src, hud)
	atom_huds_to_initialize = null

/mob/proc/remove_screen_obj_references()
	hands = null
	pullin = null
	purged = null
	internals = null
	oxygen = null
	i_select = null
	m_select = null
	toxin = null
	fire = null
	bodytemp = null
	healths = null
	throw_icon = null
	nutrition_icon = null
	pressure = null
	pain = null
	item_use_icon = null
	gun_move_icon = null
	gun_setting_icon = null
	spell_masters = null
	zone_sel = null

/mob/statpanel_data(client/C)
	. = ..()
	if(C.statpanel_tab("Status"))
		STATPANEL_DATA_ENTRY("Ping", "[round(client.lastping,1)]ms (Avg: [round(client.avgping,1)]ms)")
		STATPANEL_DATA_ENTRY("Map", "[(LEGACY_MAP_DATUM)?.name || "Loading..."]")
		if(!isnull(SSmapping.next_station) && !isnull(SSmapping.loaded_station) && (SSmapping.next_station.name != SSmapping.loaded_station.name))
			STATPANEL_DATA_ENTRY("Next Map", "[SSmapping.next_station.name]")

/// Message, type of message (1 or 2), alternative message, alt message type (1 or 2)
// todo: refactor
/mob/show_message(msg, type, alt, alt_type)
	if(!client && !teleop)
		return

	if(!saycode_type_eligible(type))
		if(alt && saycode_type_eligible(alt_type))
			msg = alt
			type = alt_type
		else
			return

	if(IS_ALIVE_BUT_UNCONSCIOUS(src))
		to_chat(src,"<I>... You can almost hear someone talking ...</I>", type = MESSAGE_TYPE_LOCALCHAT)
	else
		to_chat(src,msg, type = MESSAGE_TYPE_LOCALCHAT)
		if(teleop)
			to_chat(teleop, create_text_tag("body", "BODY:", teleop) + "[msg]", type = MESSAGE_TYPE_LOCALCHAT)

/mob/proc/saycode_type_eligible(type)
	switch(type)
		if(SAYCODE_TYPE_VISIBLE)
			return !is_blind()
		if(SAYCODE_TYPE_AUDIBLE)
			return !is_deaf()
		if(SAYCODE_TYPE_CONSCIOUS)
			return IS_CONSCIOUS(src)
		if(SAYCODE_TYPE_LIVING)
			return !IS_DEAD(src)
		if(SAYCODE_TYPE_ALWAYS)
			return TRUE
	return TRUE

/**
 * Show a message to all mobs in earshot of this one
 *
 * This would be for audible actions by the src mob
 *
 * vars:
 * * message is the message output to anyone who can hear.
 * * self_message (optional) is what the src mob hears.
 * * deaf_message (optional) is what deaf people will see.
 * * hearing_distance (optional) is the range, how many tiles away the message can be heard.
 */
/mob/audible_message(var/message, var/deaf_message, var/hearing_distance, var/self_message)

	var/range = hearing_distance || world.view
	var/list/hear = get_mobs_and_objs_in_view_fast(get_turf(src),range,remote_ghosts = FALSE)

	var/list/hearing_mobs = hear["mobs"]
	var/list/hearing_objs = hear["objs"]

	for(var/obj in hearing_objs)
		var/obj/O = obj
		O.show_message(message, 2, deaf_message, 1)

	for(var/mob in hearing_mobs)
		var/mob/M = mob
		var/msg = message
		if(self_message && M==src)
			msg = self_message
		M.show_message(msg, 2, deaf_message, 1)

/mob/proc/findname(msg)
	for(var/mob/M in GLOB.mob_list)
		if (M.real_name == "[msg]")
			return M
	return 0

#define UNBUCKLED 0
#define PARTIALLY_BUCKLED 1
#define FULLY_BUCKLED 2

/mob/proc/is_buckled()
	// Preliminary work for a future buckle rewrite,
	// where one might be fully restrained (like an elecrical chair), or merely secured (shuttle chair, keeping you safe but not otherwise restrained from acting)
	if(!buckled)
		return UNBUCKLED
	return restrained() ? FULLY_BUCKLED : PARTIALLY_BUCKLED

/mob/proc/is_blind()
	return (has_status_effect(/datum/status_effect/sight/blindness) || incapacitated(INCAPACITATION_KNOCKOUT))

/mob/proc/is_deaf()
	return ((sdisabilities & SDISABILITY_DEAF) || ear_deaf || incapacitated(INCAPACITATION_KNOCKOUT))

/mob/proc/is_physically_disabled()
	return incapacitated(INCAPACITATION_DISABLED)

/mob/proc/incapacitated(var/incapacitation_flags = INCAPACITATION_DEFAULT)
	if ((incapacitation_flags & INCAPACITATION_STUNNED) && !CHECK_MOBILITY(src, MOBILITY_CAN_USE))
		return 1

	if ((incapacitation_flags & INCAPACITATION_FORCELYING) && !CHECK_MOBILITY(src, MOBILITY_IS_STANDING))
		return 1

	if ((incapacitation_flags & INCAPACITATION_KNOCKOUT) && !CHECK_MOBILITY(src, MOBILITY_IS_CONSCIOUS))
		return 1

	if((incapacitation_flags & INCAPACITATION_RESTRAINED) && restrained())
		return 1

	if((incapacitation_flags & (INCAPACITATION_BUCKLED_PARTIALLY|INCAPACITATION_BUCKLED_FULLY)))
		var/buckling = buckled()
		if(buckling >= PARTIALLY_BUCKLED && (incapacitation_flags & INCAPACITATION_BUCKLED_PARTIALLY))
			return 1
		if(buckling == FULLY_BUCKLED && (incapacitation_flags & INCAPACITATION_BUCKLED_FULLY))
			return 1

	return 0

#undef UNBUCKLED
#undef PARTIALLY_BUCKLED
#undef FULLY_BUCKLED

///Is the mob restrained
/mob/proc/restrained()
	return

/**
 * Examine a mob
 *
 * mob verbs are faster than object verbs. See
 * [this byond forum post](https://secure.byond.com/forum/?post=1326139&page=2#comment8198716)
 * for why this isn't atom/verb/examine()
 */
/mob/verb/examinate(atom/A as mob|obj|turf in view()) //It used to be oview(12), but I can't really say why
	set name = "Examine"
	set category = VERB_CATEGORY_IC

	if(isturf(A) && !(sight & SEE_TURFS) && !(A in view(client ? client.view : world.view, src)))
		// shift-click catcher may issue examinate() calls for out-of-sight turfs
		return

	if(is_blind()) //blind people see things differently (through touch)
		to_chat(src, SPAN_WARNING("Something is there but you can't see it!"))
		return

	face_atom(A)
	if(!isobserver(src) && !isturf(A) && (get_top_level_atom(A) != src) && get_turf(A))
		for(var/mob/M in viewers(4, src))
			if(M == src || M.is_blind())
				continue
			// if(M.client && M.client.get_preference_toggle(/datum/client_preference/examine_look))
			to_chat(M, SPAN_TINYNOTICE("<b>\The [src]</b> looks at \the [A]."))

	do_examinate(A)

/**
 * examines something & sends results
 * no pre-checks for dist/view/whatnot
 */
/mob/proc/do_examinate(atom/A)
	var/list/result
	if(client)
		result = A.examine(src, game_range_to(src, A)) // if a tree is examined but no client is there to see it, did the tree ever really exist?

	to_chat(src, "<blockquote class='info'>[result.Join("\n")]</blockquote>")
	SEND_SIGNAL(src, COMSIG_MOB_EXAMINATE, A)

/**
 * Point at an atom
 *
 * mob verbs are faster than object verbs. See
 * [this byond forum post](https://secure.byond.com/forum/?post=1326139&page=2#comment8198716)
 * for why this isn't atom/verb/pointed()
 *
 * note: ghosts can point, this is intended
 *
 * visible_message will handle invisibility properly
 *
 * overridden here and in /mob/observer/dead for different point span classes and sanity checks
 */
/mob/verb/pointed(atom/A as mob|obj|turf in view())
	set name = "Point To"
	set category = VERB_CATEGORY_OBJECT

	if(!src || !isturf(src.loc) || !(A in view(14, src)))
		return 0

	if(istype(A, /obj/effect/temp_visual/point))
		return 0

	var/tile = get_turf(A)
	if (!tile)
		return 0

	var/obj/P = new /obj/effect/temp_visual/point(tile)
	P.invisibility = invisibility
	P.plane = ABOVE_PLANE
	P.layer = FLY_LAYER
	P.pixel_x = A.pixel_x + world.icon_size * (x - A.x)
	P.pixel_y = A.pixel_y + world.icon_size * (y - A.y)
	animate(P, pixel_x = A.pixel_x, pixel_y = A.pixel_y, time = 0.5 SECONDS, easing = QUAD_EASING)
	face_atom(A)
	log_emote("POINTED --> at [A] ([COORD(A)]).", src)
	return 1

/mob/verb/set_self_relative_layer()
	set name = "Set relative layer"
	set desc = "Set your relative layer to other mobs on the same layer as yourself"
	set src = usr
	set category = VERB_CATEGORY_IC

	var/new_layer = input(src, "What do you want to shift your layer to? (-100 to 100)", "Set Relative Layer", clamp(relative_layer, -100, 100))
	new_layer = clamp(new_layer, -100, 100)
	set_relative_layer(new_layer)

/mob/verb/shift_relative_behind()
	set name = "Move Behind"
	set desc = "Move behind of a mob with the same base layer as yourself"
	set src = usr
	set category = VERB_CATEGORY_IC

	if(!client.throttle_verb())
		return

	var/mob/M = tgui_input_list(src, "What mob to move behind?", "Move Behind", get_relative_shift_targets())

	if(QDELETED(M))
		return

	set_relative_layer(M.relative_layer - 1)

/mob/verb/shift_relative_infront()
	set name = "Move Infront"
	set desc = "Move infront of a mob with the same base layer as yourself"
	set src = usr
	set category = VERB_CATEGORY_IC

	if(!client.throttle_verb())
		return

	var/mob/M = tgui_input_list(src, "What mob to move infront?", "Move Infront", get_relative_shift_targets())

	if(QDELETED(M))
		return

	set_relative_layer(M.relative_layer + 1)

/mob/proc/get_relative_shift_targets()
	. = list()
	var/us = isnull(base_layer)? layer : base_layer
	for(var/mob/M in range(1, src))
		if(M.plane != plane)
			continue
		if(us == (isnull(M.base_layer)? M.layer : M.base_layer))
			. += M
	. -= src

/**
 * Get the notes of this mob
 *
 * This actually gets the mind datums notes
 */
/mob/verb/memory()
	set name = "Notes"
	set category = VERB_CATEGORY_IC
	if(mind)
		mind.show_memory(src)
	else
		to_chat(src, "The game appears to have misplaced your mind datum, so we can't show you your notes.")

/**
 * Add a note to the mind datum
 */
/mob/verb/add_memory(msg as message)
	set name = "Add Note"
	set category = VERB_CATEGORY_IC

	msg = sanitize(msg)

	if(mind)
		mind.store_memory(msg)
	else
		to_chat(src, "The game appears to have misplaced your mind datum, so we can't show you your notes.")

/mob/proc/store_memory(msg as message, popup, sane = 1)
	msg = copytext(msg, 1, MAX_MESSAGE_LEN)

	if (sane)
		msg = sanitize(msg)

	if((length(memory) + length(msg)) > MAX_MESSAGE_LEN)
		return

	if (length(memory) == 0)
		memory += msg
	else
		memory += "<BR>[msg]"

	if (popup)
		memory()

/mob/proc/update_flavor_text()
	set src in usr
	if(usr != src)
		to_chat(usr, "No.")
	var/msg = sanitize(input(usr,"Set the flavor text in your 'examine' verb.","Flavor Text",html_decode(flavor_text)) as message|null, extra = 0)

	if(msg != null)
		flavor_text = msg

/mob/proc/warn_flavor_changed()
	if(flavor_text && flavor_text != "") // don't spam people that don't use it!
		to_chat(src, "<h2 class='alert'>OOC Warning:</h2>")
		to_chat(src, "<span class='alert'>Your flavor text is likely out of date! <a href='byond://?src=\ref[src];flavor_change=1'>Change</a></span>")

/mob/proc/print_flavor_text()
	if (flavor_text && flavor_text != "")
		var/msg = replacetext(flavor_text, "\n", " ")
		if(length(msg) <= 40)
			return "<font color=#4F49AF>[msg]</font>"
		else
			return "<font color=#4F49AF>[copytext_preserve_html(msg, 1, 37)]... <a href='byond://?src=\ref[src];flavor_more=1'>More...</font></a>"

/*
/mob/verb/help()
	set name = "Help"
	src << browse('html/help.html', "window=help")
	return
*/

/mob/proc/set_respawn_timer(var/time)
	// Try to figure out what time to use

	// Special cases, can never respawn
	if(SSticker?.mode?.deny_respawn)
		time = -1
	else if(!config_legacy.abandon_allowed)
		time = -1
	else if(!config_legacy.respawn)
		time = -1

	// Special case for observing before game start
	else if(SSticker?.current_state <= GAME_STATE_SETTING_UP)
		time = 1 MINUTE

	// Wasn't given a time, use the config time
	else if(!time)
		time = config_legacy.respawn_time

	var/keytouse = ckey
	// Try harder to find a key to use
	if(!keytouse && key)
		keytouse = ckey(key)
	else if(!keytouse && mind?.ckey)
		keytouse = mind.ckey

	GLOB.respawn_timers[keytouse] = world.time + time

/mob/observer/dead/set_respawn_timer()
	if(config_legacy.antag_hud_restricted && has_enabled_antagHUD)
		..(-1)
	else
		return 	// Don't set it, no need

/**
 * Allows you to respawn, abandoning your current mob
 *
 * This sends you back to the lobby creating a new dead mob
 *
 * Only works if flag/norespawn is allowed in config
 */
/mob/verb/abandon_mob()
	set name = "Respawn"
	set category = VERB_CATEGORY_OOC
	set desc = "Return to the lobby."

	// don't lose out on that sweet observer playtime
	SSplaytime.queue_playtimes(client)

	if(stat != DEAD)
		to_chat(usr, SPAN_BOLDNOTICE("You must be dead to use this!"))
		return

	// Final chance to abort "respawning"
	if(mind && timeofdeath)	// They had spawned before
		var/choice = alert(usr, "Returning to the menu will prevent your character from being revived in-round. Are you sure?", "Confirmation", "No, wait", "Yes, leave")
		if(choice == "No, wait")
			return

	// Beyond this point, you're going to respawn
	to_chat(usr, config_legacy.respawn_message)

	if(!client)
		log_game("[usr.key] AM failed due to disconnect.")
		return
	client.screen.Cut()
	client.mob.reload_rendering()
	if(!client)
		log_game("[usr.key] AM failed due to disconnect.")
		return

	announce_ghost_joinleave(client, 0)

	var/mob/new_player/M = new /mob/new_player()
	if(!client)
		log_game("[usr.key] AM failed due to disconnect.")
		qdel(M)
		return

	transfer_client_to(M)
	if(M.mind)
		M.mind.reset()
	return

/**
 * Allows you to respawn, abandoning your current mob
 *
 * This sends you back to the lobby creating a new dead mob
 *
 * Doesn't require the config to be set.
 */
/mob/verb/return_to_menu()
	set name = "Return to Menu"
	set category = VERB_CATEGORY_OOC
	set desc = "Return to the lobby."
	return abandon_mob()

/mob/verb/observe()
	set name = "Observe"
	set category = VERB_CATEGORY_OOC

	if(stat != DEAD || istype(src, /mob/new_player))
		to_chat(usr, "<font color=#4F49AF>You must be observing to use this!</font>")
		return

	var/list/names = list()
	var/list/namecounts = list()
	var/list/creatures = list()

	/*for(var/obj/O in world)				//EWWWWWWWWWWWWWWWWWWWWWWWW ~needs to be optimised
		if(!O.loc)
			continue
		if(istype(O, /obj/item/disk/nuclear))
			var/name = "Nuclear Disk"
			if (names.Find(name))
				namecounts[name]++
				name = "[name] ([namecounts[name]])"
			else
				names.Add(name)
				namecounts[name] = 1
			creatures[name] = O

		if(istype(O, /obj/singularity))
			var/name = "Singularity"
			if (names.Find(name))
				namecounts[name]++
				name = "[name] ([namecounts[name]])"
			else
				names.Add(name)
				namecounts[name] = 1
			creatures[name] = O
	*/

	for(var/mob/M in sortList(GLOB.mob_list))
		var/name = M.name
		if (names.Find(name))
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1

		creatures[name] = M


	var/eye_name = null

	eye_name = input("Please, select a player!", "Observe", null, null) as null | anything in creatures

	if (!eye_name)
		return

	var/mob/mob_eye = creatures[eye_name]

	reset_perspective(mob_eye.get_perspective())

GLOBAL_VAR_INIT(exploit_warn_spam_prevention, 0)

//suppress the .click/dblclick macros so people can't use them to identify the location of items or aimbot
/mob/verb/DisClick(argu = null as anything, sec = "" as text, number1 = 0 as num  , number2 = 0 as num)
	set name = ".click"
	set hidden = TRUE
	set category = null
	if(GLOB.exploit_warn_spam_prevention < world.time)
		var/msg = "[key_name_admin(src)]([ADMIN_KICK(src)]) attempted to use the .click macro!"
		log_admin(msg)
		message_admins(msg)
		log_click("DROPPED: .click macro from [ckey] at [argu], [sec], [number1]. [number2]")
		GLOB.exploit_warn_spam_prevention = world.time + 10

/mob/verb/DisDblClick(argu = null as anything, sec = "" as text, number1 = 0 as num  , number2 = 0 as num)
	set name = ".dblclick"
	set hidden = TRUE
	set category = null
	if(GLOB.exploit_warn_spam_prevention < world.time)
		var/msg = "[key_name_admin(src)]([ADMIN_KICK(src)]) attempted to use the .dblclick macro!"
		log_admin(msg)
		message_admins(msg)
		log_click("DROPPED: .dblclick macro from [ckey] at [argu], [sec], [number1]. [number2]")
		GLOB.exploit_warn_spam_prevention = world.time + 10

/**
 * Topic call back for any mob
 *
 * * Unset machines if "mach_close" sent
 * * refresh the inventory of machines in range if "refresh" sent
 * * handles the strip panel equip and unequip as well if "item" sent
 */
/mob/Topic(href, href_list)
	if(href_list["strip"])
		var/op = href_list["strip"]
		handle_strip_topic(usr, href_list, op)
		return
	if(href_list["mach_close"])
		var/t1 = "window=[href_list["mach_close"]]"
		unset_machine()
		src << browse(null, t1)

	if(href_list["flavor_more"])
		usr << browse("<HTML><HEAD><TITLE>[name]</TITLE></HEAD><BODY><TT>[replacetext(flavor_text, "\n", "<BR>")]</TT></BODY></HTML>", "window=[name];size=500x200")
		onclose(usr, "[name]")
	if(href_list["flavor_change"])
		update_flavor_text()
//	..()
	return


/mob/proc/pull_damage()
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		if(H.health - H.halloss <= H.getSoftCritHealth())
			for(var/name in H.organs_by_name)
				var/obj/item/organ/external/e = H.organs_by_name[name]
				if(e && H.lying)
					if((e.status & ORGAN_BROKEN && (!e.splinted || (e.splinted && (e.splinted in e.contents) && prob(30))) || e.status & ORGAN_BLEEDING) && (H.getBruteLoss() + H.getFireLoss() >= 100))
						return 1
	return 0

/mob/OnMouseDrop(atom/over, mob/user, proximity, params)
	. = ..()
	if(over != user)
		return
	. |= mouse_drop_strip_interaction(user)

/mob/proc/can_use_hands()
	return

/mob/proc/is_active()
	return (0 >= usr.stat)

/mob/proc/is_dead()
	return stat == DEAD

/mob/proc/is_mechanical()
	if(mind && (mind.assigned_role == "Cyborg" || mind.assigned_role == "AI"))
		return 1
	return istype(src, /mob/living/silicon) || get_species_name() == "Machine"

/mob/proc/is_ready()
	return client && !!mind

/mob/proc/get_gender()
	return gender

/mob/proc/get_visible_gender()
	return gender

/mob/proc/see(message)
	if(!is_active())
		return 0
	to_chat(src, message)
	return 1

/mob/proc/show_viewers(message)
	for(var/mob/M in viewers())
		M.see(message)

/// This might need a rename but it should replace the can this mob use things check
/mob/proc/IsAdvancedToolUser()
	return 0

/mob/proc/AdjustLosebreath(amount)
	losebreath = clamp(0, losebreath + amount, 25)

/mob/proc/SetLosebreath(amount)
	losebreath = clamp(0, amount, 25)

/mob/proc/get_species_name()
	return ""

/**
 * DO NOT USE THIS
 *
 * this should be phased out for get_species_id().
 */
/mob/proc/get_true_species_name()
	return ""

// todo: species vs subspecies
// /mob/proc/get_species_id()
// 	return

/mob/proc/flash_weak_pain()
	flick("weak_pain",pain)

/mob/proc/get_visible_implants(var/class = 0)
	var/list/visible_implants = list()
	return visible_implants

// TODO: rework and readd embeds

// /mob/proc/yank_out_object()
// 	set category = VERB_CATEGORY_OBJECT
// 	set name = "Yank out object"
// 	set desc = "Remove an embedded item at the cost of bleeding and pain."
// 	set src in view(1)

// 	if(!isliving(usr) || !usr.canClick())
// 		return
// 	usr.setClickCooldownLegacy(20)

// 	if(usr.stat == 1)
// 		to_chat(usr, "You are unconcious and cannot do that!")
// 		return

// 	if(usr.restrained())
// 		to_chat(usr, "You are restrained and cannot do that!")
// 		return

// 	var/mob/S = src
// 	var/mob/U = usr
// 	var/list/valid_objects = list()
// 	var/self = null

// 	if(S == U)
// 		self = 1 // Removing object from yourself.

// 	valid_objects = get_visible_implants(0)
// 	if(!valid_objects.len)
// 		if(self)
// 			to_chat(src, "You have nothing stuck in your body that is large enough to remove.")
// 		else
// 			to_chat(U, "[src] has nothing stuck in their wounds that is large enough to remove.")
// 		return

// 	var/obj/item/selection = input("What do you want to yank out?", "Embedded objects") in valid_objects

// 	if(self)
// 		to_chat(src, "<span class='warning'>You attempt to get a good grip on [selection] in your body.</span>")
// 	else
// 		to_chat(U, "<span class='warning'>You attempt to get a good grip on [selection] in [S]'s body.</span>")

// 	if(!do_after(U, 30))
// 		return
// 	if(!selection || !S || !U)
// 		return

// 	if(self)
// 		visible_message("<span class='warning'><b>[src] rips [selection] out of their body.</b></span>","<span class='warning'><b>You rip [selection] out of your body.</b></span>")
// 	else
// 		visible_message("<span class='warning'><b>[usr] rips [selection] out of [src]'s body.</b></span>","<span class='warning'><b>[usr] rips [selection] out of your body.</b></span>")
// 	valid_objects = get_visible_implants(0)
// 	if(valid_objects.len == 1) //Yanking out last object - removing verb.
// 		remove_verb(src, /mob/proc/yank_out_object)

// 	if(ishuman(src))
// 		var/mob/living/carbon/human/H = src
// 		var/obj/item/organ/external/affected

// 		for(var/obj/item/organ/external/organ in H.organs) //Grab the organ holding the implant.
// 			for(var/obj/item/O in organ.implants)
// 				if(O == selection)
// 					affected = organ

// 		affected.implants -= selection
// 		H.shock_stage+=20
// 		affected.inflict_bodypart_damage(
// 			brute = selection.w_class * 3,
// 			damage_mode = DAMAGE_MODE_EDGE,
// 			weapon_descriptor = "object removal",
// 		)

// 		if(prob(selection.w_class * 5) && (affected.robotic < ORGAN_ROBOT)) //I'M SO ANEMIC I COULD JUST -DIE-.
// 			affected.create_specific_wound(/datum/wound/internal_bleeding, min(selection.w_class * 5, 15))
// 			H.custom_pain("Something tears wetly in your [affected] as [selection] is pulled free!", 50)

// 		if (ishuman(U))
// 			var/mob/living/carbon/human/human_user = U
// 			human_user.bloody_hands(H)

// 	else if(issilicon(src))
// 		var/mob/living/silicon/robot/R = src
// 		R.embedded -= selection
// 		R.adjustBruteLoss(5)
// 		R.adjustFireLoss(10)

// 	selection.forceMove(get_turf(src))
// 	U.put_in_hands(selection)

// 	for(var/obj/item/O in pinned)
// 		if(O == selection)
// 			pinned -= O
// 		if(!pinned.len)
// 			anchored = 0
// 	return 1

/// Check for brain worms in head.
/mob/proc/has_brain_worms()

	for(var/I in contents)
		if(istype(I,/mob/living/simple_mob/animal/borer))
			return I

	return 0

/mob/proc/updateicon()
	return

/mob/verb/face_direction()

	set name = "Face Direction"
	set category = VERB_CATEGORY_IC
	set src = usr

	set_face_dir()

	if(!facing_dir)
		to_chat(usr, "You are now not facing anything.")
	else
		to_chat(usr, "You are now facing [dir2text(facing_dir)].")

/mob/proc/set_face_dir(newdir)
	if(newdir)
		if(newdir == facing_dir)
			facing_dir = null
		else
			facing_dir = newdir
			setDir(newdir)
	else
		if(facing_dir)
			facing_dir = null
		else
			facing_dir = dir

/mob/setDir()
	if(facing_dir)
		if(!canface() || lying || buckled || restrained())
			facing_dir = null
		else if(dir != facing_dir)
			return ..(facing_dir)
	else
		return ..()

/mob/verb/northfaceperm()
	set hidden = 1
	set src = usr
	set_face_dir(client.client_dir(NORTH))

/mob/verb/southfaceperm()
	set hidden = 1
	set src = usr
	set_face_dir(client.client_dir(SOUTH))

/mob/verb/eastfaceperm()
	set hidden = 1
	set src = usr
	set_face_dir(client.client_dir(EAST))

/mob/verb/westfaceperm()
	set hidden = 1
	set src = usr
	set_face_dir(client.client_dir(WEST))

/mob/proc/adjustEarDamage()
	return

/mob/proc/setEarDamage()
	return

/mob/proc/isSynthetic()
	return 0

/mob/proc/is_muzzled()
	return 0

//Exploitable Info Update

/mob/proc/amend_exploitable(var/obj/item/I)
	if(istype(I))
		exploit_addons |= I
		var/exploitmsg = html_decode("\n" + "Has " + I.name + ".")
		exploit_record += exploitmsg

/client/proc/check_has_body_select()
	return mob && mob.hud_used && istype(mob.zone_sel, /atom/movable/screen/zone_sel)

/client/verb/body_toggle_head()
	set name = "body-toggle-head"
	set hidden = 1
	toggle_zone_sel(list(BP_HEAD, O_EYES, O_MOUTH))

/client/verb/body_r_arm()
	set name = "body-r-arm"
	set hidden = 1
	toggle_zone_sel(list(BP_R_ARM,BP_R_HAND))

/client/verb/body_l_arm()
	set name = "body-l-arm"
	set hidden = 1
	toggle_zone_sel(list(BP_L_ARM,BP_L_HAND))

/client/verb/body_chest()
	set name = "body-chest"
	set hidden = 1
	toggle_zone_sel(list(BP_TORSO))

/client/verb/body_groin()
	set name = "body-groin"
	set hidden = 1
	toggle_zone_sel(list(BP_GROIN))

/client/verb/body_r_leg()
	set name = "body-r-leg"
	set hidden = 1
	toggle_zone_sel(list(BP_R_LEG,BP_R_FOOT))

/client/verb/body_l_leg()
	set name = "body-l-leg"
	set hidden = 1
	toggle_zone_sel(list(BP_L_LEG,BP_L_FOOT))

/client/proc/toggle_zone_sel(list/zones)
	if(!check_has_body_select())
		return
	var/atom/movable/screen/zone_sel/selector = mob.zone_sel
	selector.set_selected_zone(next_list_item(mob.zone_sel.selecting,zones))

// This handles setting the client's color variable, which makes everything look a specific color.
// This proc is here so it can be called without needing to check if the client exists, or if the client relogs.
// This is for inheritence since /mob/living will serve most cases. If you need ghosts to use this you'll have to implement that yourself.
/mob/proc/update_client_color()
	if(client && client.color)
		animate(client, color = null, time = 10)
	return

/mob/proc/will_show_tooltip()
	if(alpha <= EFFECTIVE_INVIS)
		return FALSE
	return TRUE

/mob/MouseEntered(location, control, params)
	if(usr != src && usr.get_preference_toggle(/datum/game_preference_toggle/game/mob_tooltips) && src.will_show_tooltip())
		openToolTip(user = usr, tip_src = src, params = params, title = get_nametag_name(usr), content = get_nametag_desc(usr))

	..()

/mob/MouseDown()
	closeToolTip(usr) //No reason not to, really

	..()

/mob/MouseExited()
	closeToolTip(usr) //No reason not to, really

	..()

// Manages a global list of mobs with clients attached, indexed by z-level.
/mob/proc/update_client_z(new_z) // +1 to register, null to unregister.
	if(registered_z != new_z)
		if(registered_z)
			GLOB.players_by_zlevel[registered_z] -= src
		if(client)
			if(new_z)
				GLOB.players_by_zlevel[new_z] += src
			registered_z = new_z
		else
			registered_z = null

/mob/on_changed_z_level(old_z, new_z)
	..()
	update_client_z(new_z)

/mob/verb/local_diceroll(n as num)
	set name = "diceroll"
	set category = VERB_CATEGORY_OOC
	set desc = "Roll a random number between 1 and a chosen number."
	set src = usr

	n = round(n)		// why are you putting in floats??
	if(n < 2)
		to_chat(src, "<span class='warning'>[n] must be 2 or above, otherwise why are you rolling?</span>")
		return

	to_chat(src, "<span class='notice'>Diceroll result: <b>[rand(1, n)]</b></span>")

/**
 * Checks for anti magic sources.
 *
 * @params
 * - magic - wizard-type magic
 * - holy - cult-type magic, stuff chaplains/nullrods/similar should be countering
 * - chargecost - charges to remove from antimagic if applicable/not a permanent source
 * - self - check if the antimagic is ourselves
 *
 * @return The datum source of the antimagic
 */
/mob/proc/anti_magic_check(magic = TRUE, holy = FALSE, chargecost = 1, self = FALSE)
	if(!magic && !holy)
		return
	var/list/protection_sources = list()
	if(SEND_SIGNAL(src, COMSIG_MOB_RECEIVE_MAGIC, src, magic, holy, chargecost, self, protection_sources) & COMPONENT_MAGIC_BLOCKED)
		if(protection_sources.len)
			return pick(protection_sources)
		else
			return src
	if((magic && HAS_TRAIT(src, TRAIT_ANTIMAGIC)) || (holy && HAS_TRAIT(src, TRAIT_HOLY)))
		return src

/mob/drop_location()
	if(temporary_form)
		return temporary_form.drop_location()
	return ..()

/**
 * Returns whether or not we should be allowed to examine a target
 */
/mob/proc/allow_examine(atom/A)
	return client && (client.eye == src)

/// Checks for slots that are currently obscured by other garments.
/mob/proc/check_obscured_slots()
	return

/mob/z_pass_in(atom/movable/AM, dir, turf/old_loc)
	return TRUE	// we don't block

/mob/z_pass_out(atom/movable/AM, dir, turf/new_loc)
	return TRUE

//? Pixel Offsets

/mob/proc/get_buckled_pixel_x_offset()
	if(!buckled)
		return 0
	// todo: this doesn't properly take into account all transforms of both us and the buckled object
	. = get_centering_pixel_x_offset(dir)
	if(lying != 0)
		. *= cos(lying)
		. += sin(lying) * get_centering_pixel_y_offset(dir)
	return buckled.pixel_x + . - buckled.get_centering_pixel_x_offset(buckled.dir) + buckled.get_buckled_x_offset(src)

/mob/proc/get_buckled_pixel_y_offset()
	if(!buckled)
		return 0
	// todo: this doesn't properly take into account all transforms of both us and the buckled object
	. = get_centering_pixel_y_offset(dir)
	if(lying != 0)
		. *= cos(lying)
		. += sin(lying) * get_centering_pixel_x_offset(dir)
	return buckled.pixel_y + . - buckled.get_centering_pixel_y_offset(buckled.dir) + buckled.get_buckled_y_offset(src)

/mob/get_managed_pixel_x()
	return ..() + shift_pixel_x + get_buckled_pixel_x_offset()

/mob/get_managed_pixel_y()
	return ..() + shift_pixel_y + get_buckled_pixel_y_offset()

/mob/get_centering_pixel_x_offset(dir)
	. = ..()
	. += shift_pixel_x

/mob/get_centering_pixel_y_offset(dir)
	. = ..()
	. += shift_pixel_y

/mob/proc/reset_pixel_shifting()
	if(!shifted_pixels)
		return
	shifted_pixels = FALSE
	pixel_x -= shift_pixel_x
	pixel_y -= shift_pixel_y
	wallflowering = NONE
	shift_pixel_x = 0
	shift_pixel_y = 0
	SEND_SIGNAL(src, COMSIG_MOVABLE_PIXEL_OFFSET_CHANGED)

/mob/proc/set_pixel_shift_x(val)
	if(!val)
		return
	shifted_pixels = TRUE
	pixel_x += (val - shift_pixel_x)
	shift_pixel_x = val
	switch(val)
		if(-INFINITY to -WALLFLOWERING_PIXEL_SHIFT)
			wallflowering = (wallflowering & ~(EAST)) | WEST
		if(-WALLFLOWERING_PIXEL_SHIFT + 1 to WALLFLOWERING_PIXEL_SHIFT - 1)
			wallflowering &= ~(EAST|WEST)
		if(WALLFLOWERING_PIXEL_SHIFT to INFINITY)
			wallflowering = (wallflowering & ~(WEST)) | EAST
	SEND_SIGNAL(src, COMSIG_MOVABLE_PIXEL_OFFSET_CHANGED)

/mob/proc/set_pixel_shift_y(val)
	if(!val)
		return
	shifted_pixels = TRUE
	pixel_y += (val - shift_pixel_y)
	shift_pixel_y = val
	switch(val)
		if(-INFINITY to -WALLFLOWERING_PIXEL_SHIFT)
			wallflowering = (wallflowering & ~(NORTH)) | SOUTH
		if(-WALLFLOWERING_PIXEL_SHIFT + 1 to WALLFLOWERING_PIXEL_SHIFT - 1)
			wallflowering &= ~(NORTH|SOUTH)
		if(WALLFLOWERING_PIXEL_SHIFT to INFINITY)
			wallflowering = (wallflowering & ~(SOUTH)) | NORTH
	SEND_SIGNAL(src, COMSIG_MOVABLE_PIXEL_OFFSET_CHANGED)

/mob/proc/adjust_pixel_shift_x(val)
	if(!val)
		return
	shifted_pixels = TRUE
	shift_pixel_x += val
	pixel_x += val
	switch(shift_pixel_x)
		if(-INFINITY to -WALLFLOWERING_PIXEL_SHIFT)
			wallflowering = (wallflowering & ~(EAST)) | WEST
		if(-WALLFLOWERING_PIXEL_SHIFT + 1 to WALLFLOWERING_PIXEL_SHIFT - 1)
			wallflowering &= ~(EAST|WEST)
		if(WALLFLOWERING_PIXEL_SHIFT to INFINITY)
			wallflowering = (wallflowering & ~(WEST)) | EAST
	SEND_SIGNAL(src, COMSIG_MOVABLE_PIXEL_OFFSET_CHANGED)

/mob/proc/adjust_pixel_shift_y(val)
	if(!val)
		return
	shifted_pixels = TRUE
	shift_pixel_y += val
	pixel_y += val
	switch(shift_pixel_y)
		if(-INFINITY to -WALLFLOWERING_PIXEL_SHIFT)
			wallflowering = (wallflowering & ~(NORTH)) | SOUTH
		if(-WALLFLOWERING_PIXEL_SHIFT + 1 to WALLFLOWERING_PIXEL_SHIFT - 1)
			wallflowering &= ~(NORTH|SOUTH)
		if(WALLFLOWERING_PIXEL_SHIFT to INFINITY)
			wallflowering = (wallflowering & ~(SOUTH)) | NORTH
	SEND_SIGNAL(src, COMSIG_MOVABLE_PIXEL_OFFSET_CHANGED)

//? Reachability

/mob/CanReachOut(atom/movable/mover, atom/target, obj/item/tool, list/cache)
	return FALSE

/mob/CanReachIn(atom/movable/mover, atom/target, obj/item/tool, list/cache)
	return FALSE

//? Radioactivity

/mob/clean_radiation(str, mul, cheap)
	. = ..()
	if(cheap)
		return
	for(var/obj/item/I as anything in get_equipped_items(TRUE, TRUE))
		I.clean_radiation(str, mul, cheap)

//? Abilities

/mob/proc/init_abilities()
	var/list/built = list()
	var/list/registering = list()
	for(var/datum/ability/ability_path as anything in abilities)
		if(istype(ability_path))
			built += ability_path // don't re-associate existing ones.
		else if(ispath(ability_path, /datum/ability))
			registering += new ability_path
	abilities = built
	for(var/datum/ability/ability as anything in registering)
		ability.associate(src)

/mob/proc/dispose_abilities()
	for(var/datum/ability/ability in abilities)
		ability.disassociate(src)
	abilities = null

/**
 * mob side registration of abilities. must be called from /datum/ability/proc/associate!
 */
/mob/proc/register_ability(datum/ability/ability)
	LAZYINITLIST(abilities)
	abilities += ability

/**
 * mob side unregistration of abilities. must be called from /datum/ability/proc/disassociate!
 */
/mob/proc/unregister_ability(datum/ability/ability)
	LAZYREMOVE(abilities, ability)

//! Misc
/**
 * Whether the mob can use Topic to interact with machines
 *
 * Args:
 * be_close - Whether you need to be next to/on top of M
 * no_dexterity - Whether you need to be an ADVANCEDTOOLUSER
 * no_tk - If be_close is TRUE, this will block Telekinesis from bypassing the requirement
 * need_hands - Whether you need hands to use this
 * floor_okay - Whether mobility flags should be checked for MOBILITY_CAN_UI to use.
 */
/mob/proc/canUseTopic(atom/movable/M, be_close=FALSE, no_dexterity=FALSE, no_tk=FALSE)
	return

/**
 * Checks if we can avoid things like landmine, lava, etc, whether beneficial or harmful.
 */
/mob/is_avoiding_ground()
	return ..() || hovering || flying || (buckled?.buckle_flags & BUCKLING_GROUND_HOIST) || buckled?.is_avoiding_ground()
