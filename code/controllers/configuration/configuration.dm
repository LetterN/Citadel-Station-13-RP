/datum/controller/configuration
	name = "Configuration"

	var/directory = "config"

	var/warned_deprecated_configs = FALSE
	var/hiding_entries_by_type = TRUE	//Set for readability, admins can set this to FALSE if they want to debug it
	var/list/entries
	var/list/entries_by_type

	var/motd

	/// If the configuration is loaded
	var/loaded = FALSE

/datum/controller/configuration/proc/admin_reload()
	if(IsAdminAdvancedProcCall())
		return
	log_admin("[key_name_admin(usr)] has forcefully reloaded the configuration from disk.")
	message_admins("[key_name_admin(usr)] has forcefully reloaded the configuration from disk.")
	full_wipe()
	Load(world.params[OVERRIDE_CONFIG_DIRECTORY_PARAMETER])

/datum/controller/configuration/proc/Load(_directory)
	if(IsAdminAdvancedProcCall())		//If admin proccall is detected down the line it will horribly break everything.
		return
	if(_directory)
		directory = _directory
	if(entries)
		CRASH("/datum/controller/configuration/Load() called more than once!")
	InitEntries()
	// LoadModes()
	// storyteller_cache = typecacheof(/datum/dynamic_storyteller, TRUE)
	if(fexists("[directory]/config.txt") && LoadEntries("config.txt") <= 1)
		var/list/legacy_configs = list("legacy/game_options.txt", "legacy/dbconfig.txt")
		for(var/I in legacy_configs)
			if(fexists("[directory]/[I]"))
				log_config("No $include directives found in config.txt! Loading legacy [legacy_configs.Join("/")] files...")
				for(var/J in legacy_configs)
					LoadEntries(J)
				break
	LoadMOTD()

	loaded = TRUE

	if (Master)
		Master.on_config_loaded()

/datum/controller/configuration/proc/full_wipe()
	if(IsAdminAdvancedProcCall())
		return
	entries_by_type.Cut()
	QDEL_LIST_ASSOC_VAL(entries)
	entries = null
	// QDEL_LIST_ASSOC_VAL(maplist)
	// maplist = null
	// QDEL_NULL(defaultmap)

/datum/controller/configuration/Destroy()
	full_wipe()
	config = null

	return ..()

/datum/controller/configuration/proc/InitEntries()
	var/list/_entries = list()
	entries = _entries
	var/list/_entries_by_type = list()
	entries_by_type = _entries_by_type

	for(var/I in typesof(/datum/config_entry))	//typesof is faster in this case
		var/datum/config_entry/E = I
		if(initial(E.abstract_type) == I)
			continue
		E = new I
		var/esname = E.name
		var/datum/config_entry/test = _entries[esname]
		if(test)
			log_config("Error: [test.type] has the same name as [E.type]: [esname]! Not initializing [E.type]!")
			qdel(E)
			continue
		_entries[esname] = E
		_entries_by_type[I] = E

/datum/controller/configuration/proc/RemoveEntry(datum/config_entry/CE)
	entries -= CE.name
	entries_by_type -= CE.type

/datum/controller/configuration/proc/LoadEntries(filename, list/stack = list())
	if(IsAdminAdvancedProcCall())
		return

	var/filename_to_test = world.system_type == MS_WINDOWS ? lowertext(filename) : filename
	if(filename_to_test in stack)
		log_config("Warning: Config recursion detected ([english_list(stack)]), breaking!")
		return
	stack = stack + filename_to_test

	log_config("Loading config file [filename]...")
	var/list/lines = world.file2list("[directory]/[filename]")
	var/list/_entries = entries
	var/list/postload_required = list()
	var/linenumber = 0
	for(var/L in lines)
		linenumber++
		L = trim(L)
		if(!L)
			continue

		var/firstchar = L[1]
		if(firstchar == "#")
			continue

		var/lockthis = firstchar == "@"
		if(lockthis)
			L = copytext(L, length(firstchar) + 1)

		var/pos = findtext(L, " ")
		var/entry = null
		var/value = null

		if(pos)
			entry = lowertext(copytext(L, 1, pos))
			value = copytext(L, pos + length(L[pos]))
		else
			entry = lowertext(L)

		if(!entry)
			continue

		if(entry == "$include")
			if(!value)
				log_config("LINE [linenumber]: Warning: Invalid $include directive: [value]")
			else
				LoadEntries(value, stack)
				++.
			continue

		// Reset directive, used for setting a config value back to defaults. Useful for string list config types
		if (entry == "$reset")
			var/datum/config_entry/resetee = _entries[lowertext(value)]
			if (!value || !resetee)
				log_config("Warning: invalid $reset directive: [value]")
				continue
			resetee.set_default()
			log_config("Reset configured value for [value] to original defaults")
			continue

		var/datum/config_entry/E = _entries[entry]
		if(!E)
			log_config("LINE [linenumber]: Unknown setting in configuration: '[entry]'")
			continue

		if(lockthis)
			E.protection |= CONFIG_ENTRY_LOCKED

		if(E.deprecated_by)
			var/datum/config_entry/new_ver = entries_by_type[E.deprecated_by]
			var/new_value = E.DeprecationUpdate(value)
			var/good_update = istext(new_value)
			log_config("LINE [linenumber]: Entry [entry] is deprecated and will be removed soon. Migrate to [new_ver.name]![good_update ? " Suggested new value is: [new_value]" : ""]")
			if(!warned_deprecated_configs)
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(message_admins), "This server is using deprecated configuration settings. Please check the logs and update accordingly."), 0)
				warned_deprecated_configs = TRUE
			if(good_update)
				value = new_value
				E = new_ver
			else
				warning("[new_ver.type] is deprecated but gave no proper return for DeprecationUpdate()")

		var/validated = E.ValidateAndSet(value, TRUE)
		if(!validated)
			log_config("LINE [linenumber]: Failed to validate setting \"[value]\" for [entry]")
		else
			if(E.modified && !E.dupes_allowed)
				log_config("LINE [linenumber]: Duplicate setting for [entry] ([value], [E.resident_file]) detected! Using latest.")
		if(E.postload_required)
			postload_required[E] = TRUE

		E.resident_file = filename

		if(validated)
			E.modified = TRUE

	for(var/i in postload_required)
		var/datum/config_entry/E = i
		E.OnPostload()

	++.

/datum/controller/configuration/can_vv_get(var_name)
	return (var_name != NAMEOF(src, entries_by_type) || !hiding_entries_by_type) && ..()

/datum/controller/configuration/vv_edit_var(var_name, var_value)
	var/list/banned_edits = list(NAMEOF(src, entries_by_type), NAMEOF(src, entries), NAMEOF(src, directory))
	return !(var_name in banned_edits) && ..()

/datum/controller/configuration/stat_entry()
	return "Edit"

/datum/controller/configuration/proc/Get(entry_type)
	var/datum/config_entry/E = GetEntryDatum(entry_type)
	if(E && (E.protection & CONFIG_ENTRY_HIDDEN) && IsAdminAdvancedProcCall() && GLOB.LastAdminCalledProc == "Get" && GLOB.LastAdminCalledTargetRef == "[REF(src)]")
		log_admin_private("Config access of [entry_type] attempted by [key_name(usr)]")
		return
	return E.config_entry_value

/datum/controller/configuration/proc/GetEntryDatum(entry_type)
	var/datum/config_entry/E = entry_type
	var/entry_is_abstract = initial(E.abstract_type) == entry_type
	if(entry_is_abstract)
		CRASH("Tried to retrieve an abstract config_entry: [entry_type]")
	E = entries_by_type[entry_type]
	if(!E)
		CRASH("Missing config entry for [entry_type]!")
	return E

/datum/controller/configuration/proc/Set(entry_type, new_val)
	var/datum/config_entry/E = entry_type
	var/entry_is_abstract = initial(E.abstract_type) == entry_type
	if(entry_is_abstract)
		CRASH("Tried to set an abstract config_entry: [entry_type]")
	E = entries_by_type[entry_type]
	if(!E)
		CRASH("Missing config entry for [entry_type]!")
	if((E.protection & CONFIG_ENTRY_LOCKED) && IsAdminAdvancedProcCall() && GLOB.LastAdminCalledProc == "Set" && GLOB.LastAdminCalledTargetRef == "[REF(src)]")
		log_admin_private("Config rewrite of [entry_type] to [new_val] attempted by [key_name(usr)]")
		return
	return E.ValidateAndSet("[new_val]")

/*
/datum/controller/configuration/proc/LoadModes()
	gamemode_cache = typecacheof(/datum/game_mode, TRUE)
	modes = list()
	mode_names = list()
	mode_reports = list()
	mode_false_report_weight = list()
	votable_modes = list()
	var/list/probabilities = Get(/datum/config_entry/keyed_list/probability)
	for(var/T in gamemode_cache)
		// I wish I didn't have to instance the game modes in order to look up
		// their information, but it is the only way (at least that I know of).
		// for future reference: just use initial() lol
		var/datum/game_mode/M = new T()

		if(M.config_tag)
			if(!(M.config_tag in modes))		// ensure each mode is added only once
				modes += M.config_tag
				mode_names[M.config_tag] = M.name
				mode_reports[M.config_tag] = M.generate_report()
				if(probabilities[M.config_tag]>0)
					mode_false_report_weight[M.config_tag] = M.false_report_weight
				else
					mode_false_report_weight[M.config_tag] = 1
				if(M.votable)
					votable_modes += M.config_tag
		qdel(M)
	votable_modes += "secret"
*/

/datum/controller/configuration/proc/LoadMOTD()
	motd = file2text("[directory]/motd.txt")
	var/tm_info = GLOB.revdata.GetTestMergeInfo()
	if(motd || tm_info)
		motd = motd ? "[motd]<br>[tm_info]" : tm_info

// todo: actual map config.

/*
/datum/controller/configuration/proc/loadmaplist(filename)
	log_config("Loading config file [filename]...")
	filename = "[directory]/[filename]"
	var/list/Lines = world.file2list(filename)

	var/datum/map_config/currentmap = null
	for(var/t in Lines)
		if(!t)
			continue

		t = trim(t)
		if(length(t) == 0)
			continue
		else if(t[1] == "#")
			continue

		var/pos = findtext(t, " ")
		var/command = null
		var/data = null

		if(pos)
			command = lowertext(copytext(t, 1, pos))
			data = copytext(t, pos + length(t[pos]))
		else
			command = lowertext(t)

		if(!command)
			continue

		if (!currentmap && command != "map")
			continue

		switch (command)
			if ("map")
				currentmap = load_map_config("_mapload/[data].json")
				if(currentmap.defaulted)
					log_config("Failed to load map config for [data]!")
					currentmap = null
			if ("minplayers","minplayer")
				currentmap.config_min_users = text2num(data)
			if ("maxplayers","maxplayer")
				currentmap.config_max_users = text2num(data)
			if ("weight","voteweight")
				currentmap.voteweight = text2num(data)
			if ("default","defaultmap")
				defaultmap = currentmap
			if ("endmap")
				LAZYINITLIST(maplist)
				maplist[currentmap.map_name] = currentmap
				currentmap = null
			if ("disabled")
				currentmap = null
			else
				log_config("Unknown command in map vote config: '[command]'")
*/

/*
/datum/controller/configuration/proc/pick_mode(mode_name)
	// I wish I didn't have to instance the game modes in order to look up
	// their information, but it is the only way (at least that I know of).
	// ^ This guy didn't try hard enough
	for(var/T in gamemode_cache)
		var/datum/game_mode/M = T
		var/ct = initial(M.config_tag)
		if(ct && ct == mode_name)
			return new T
	return new /datum/game_mode/extended()

/datum/controller/configuration/proc/pick_storyteller(storyteller_name)
	for(var/T in storyteller_cache)
		var/datum/dynamic_storyteller/S = T
		var/name = initial(S.name)
		if(name && name == storyteller_name)
			return T
	return /datum/dynamic_storyteller/classic

/datum/controller/configuration/proc/get_runnable_modes()
	var/list/datum/game_mode/runnable_modes = new
	var/list/probabilities = Get(/datum/config_entry/keyed_list/probability)
	var/list/min_pop = Get(/datum/config_entry/keyed_list/min_pop)
	var/list/max_pop = Get(/datum/config_entry/keyed_list/max_pop)
	var/list/repeated_mode_adjust = Get(/datum/config_entry/number_list/repeated_mode_adjust)
	for(var/T in gamemode_cache)
		var/datum/game_mode/M = new T()
		if(!(M.config_tag in modes))
			qdel(M)
			continue
		if(probabilities[M.config_tag]<=0)
			qdel(M)
			continue
		if(CONFIG_GET(flag/modetier_voting) && !(M.config_tag in SSvote.stored_modetier_results))
			qdel(M)
			continue
		if(min_pop[M.config_tag])
			M.required_players = min_pop[M.config_tag]
		if(max_pop[M.config_tag])
			M.maximum_players = max_pop[M.config_tag]
		if(M.can_start())
			var/final_weight = probabilities[M.config_tag]
			if(SSpersistence.saved_modes.len == 3 && repeated_mode_adjust.len == 3)
				var/recent_round = min(SSpersistence.saved_modes.Find(M.config_tag),3)
				var/adjustment = 0
				while(recent_round)
					adjustment += repeated_mode_adjust[recent_round]
					recent_round = SSpersistence.saved_modes.Find(M.config_tag,recent_round+1,0)
				final_weight *= ((100-adjustment)/100)
			runnable_modes[M] = final_weight
	return runnable_modes

/datum/controller/configuration/proc/get_runnable_storytellers()
	var/list/datum/dynamic_storyteller/runnable_storytellers = new
	var/list/probabilities = Get(/datum/config_entry/keyed_list/storyteller_weight)
	var/list/repeated_mode_adjust = Get(/datum/config_entry/number_list/repeated_mode_adjust)
	for(var/T in storyteller_cache)
		var/datum/dynamic_storyteller/S = T
		var/config_tag = initial(S.config_tag)
		var/final_weight = initial(S.weight)
		if(probabilities[config_tag]<=0)
			continue
		final_weight = probabilities[config_tag]
		if(SSpersistence.saved_storytellers.len == 3 && repeated_mode_adjust.len == 3)
			var/name = initial(S.name)
			var/recent_round = min(SSpersistence.saved_storytellers.Find(name),3)
			var/adjustment = 0
			while(recent_round)
				adjustment += repeated_mode_adjust[recent_round]
				recent_round = SSpersistence.saved_modes.Find(name,recent_round+1,0)
			final_weight *= ((100-adjustment)/100)
		runnable_storytellers[S] = final_weight
	return runnable_storytellers

/datum/controller/configuration/proc/get_runnable_midround_modes(crew)
	var/list/datum/game_mode/runnable_modes = new
	var/list/probabilities = Get(/datum/config_entry/keyed_list/probability)
	var/list/min_pop = Get(/datum/config_entry/keyed_list/min_pop)
	var/list/max_pop = Get(/datum/config_entry/keyed_list/max_pop)
	for(var/T in (gamemode_cache - SSticker.mode.type))
		var/datum/game_mode/M = new T()
		if(!(M.config_tag in modes))
			qdel(M)
			continue
		if(probabilities[M.config_tag]<=0)
			qdel(M)
			continue
		if(min_pop[M.config_tag])
			M.required_players = min_pop[M.config_tag]
		if(max_pop[M.config_tag])
			M.maximum_players = max_pop[M.config_tag]
		if(M.required_players <= crew)
			if(M.maximum_players >= 0 && M.maximum_players < crew)
				continue
			runnable_modes[M] = probabilities[M.config_tag]
	return runnable_modes
*/
