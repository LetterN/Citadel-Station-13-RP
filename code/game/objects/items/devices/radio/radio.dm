/obj/item/radio
	icon = 'icons/obj/radio_vr.dmi' //VOREStation Edit
	name = "station bounced radio"
	icon_state = "walkietalkie"
	item_state = "radio"
	desc = "A basic handheld radio that communicates with local telecommunication networks."

	slot_flags = SLOT_BELT
	throw_speed = 2
	throw_range = 9
	w_class = WEIGHT_CLASS_SMALL
	// show_messages = 1
	matter = list("glass" = 25,DEFAULT_WALL_MATERIAL = 75)

	var/on = TRUE
	var/frequency = FREQ_COMMON
	var/canhear_range = 3  // The range around the radio in which mobs can hear what it receives.
	var/emped = 0  // Tracks the number of EMPs currently stacked.

	var/broadcasting = FALSE  // Whether the radio will transmit dialogue it hears nearby.
	var/listening = TRUE  // Whether the radio is currently receiving.
	var/prison_radio = FALSE  // If true, the transmit wire starts cut.
	var/unscrewed = FALSE  // Whether wires are accessible. Toggleable by screwdrivering.
	var/freerange = FALSE  // If true, the radio has access to the full spectrum.
	var/subspace_transmission = FALSE  // If true, the radio transmits and receives on subspace exclusively.
	var/subspace_switchable = FALSE  // If true, subspace_transmission can be toggled at will.
	var/freqlock = FALSE  // Frequency lock to stop the user from untuning specialist radios.
	var/use_command = FALSE  // If true, broadcasts will be large and BOLD.
	var/command = FALSE  // If true, use_command can be toggled at will.
	var/commandspan = SPAN_COMMAND //allow us to set what the fuck we want for headsets

	// Encryption key handling
	var/obj/item/encryptionkey/keyslot
	var/translate_binary = FALSE  // If true, can hear the special binary channel.
	var/independent = FALSE  // If true, can say/hear on the special CentCom channel.
	var/syndie = FALSE  // If true, hears all well-known channels automatically, and can say/hear on the Syndicate channel.
	var/list/channels = list()  // Map from name (see communications.dm) to on/off. First entry is current department (:h).
	var/list/secure_radio_connections

	var/traitor_frequency = 0 //tune to frequency to unlock traitor supplies
	var/datum/wires/wires
	var/adhoc_fallback = FALSE //Falls back to 'radio' mode if subspace not available
	var/bluespace_radio = FALSE


	var/const/FREQ_LISTENING = 1
	//FREQ_BROADCASTING = 2
	/// DEPRICATED VARS!! ///
	var/b_stat   // -> unscrewed
	var/centComm // -> independent

/obj/item/radio/proc/set_frequency(new_frequency)
	SEND_SIGNAL(src, COMSIG_RADIO_NEW_FREQUENCY, args)
	remove_radio(src, frequency)
	frequency = add_radio(src, new_frequency)

/obj/item/radio/proc/recalculateChannels()
	channels = list()
	translate_binary = FALSE
	syndie = FALSE
	independent = FALSE

	if(keyslot)
		for(var/ch_name in keyslot.channels)
			if(!(ch_name in channels))
				channels[ch_name] = keyslot.channels[ch_name]

		if(keyslot.translate_binary)
			translate_binary = TRUE
		if(keyslot.syndie)
			syndie = TRUE
		if(keyslot.independent)
			independent = TRUE

	for(var/ch_name in channels)
		secure_radio_connections[ch_name] = add_radio(src, GLOB.radiochannels[ch_name])

/obj/item/radio/proc/make_syndie() // Turns normal radios into Syndicate radios!
	qdel(keyslot)
	keyslot = new /obj/item/encryptionkey/syndicate
	syndie = 1
	recalculateChannels()


/obj/item/radio/Initialize(mapload)
	wires = new /datum/wires/radio(src)
	if(prison_radio)
		wires.IsIndexCut(WIRE_TRANSMIT) // OH GOD WHY
	secure_radio_connections = new
	. = ..()
	if(mapload)
		if(b_stat)
			log_mapping("Depricated var 'b_stat' found at \the [src]! [ADMIN_VERBOSEJMP(src)]")
		if(centComm)
			log_mapping("Depricated var 'centComm' found at \the [src]! [ADMIN_VERBOSEJMP(src)]")
	frequency = sanitize_frequency(frequency, freerange)
	set_frequency(frequency)

	for(var/ch_name in channels)
		secure_radio_connections[ch_name] = add_radio(src, GLOB.radiochannels[ch_name])
/obj/item/radio/Destroy()
	remove_radio_all(src) //Just to be sure
	QDEL_NULL(wires)
	QDEL_NULL(keyslot)
	return ..()

// /obj/item/radio/ComponentInitialize()
// 	. = ..()
// 	AddElement(/datum/element/empprotection, EMP_PROTECT_WIRES)

/obj/item/radio/interact(mob/user)
	if(unscrewed && !isAI(user))
		wires.Interact(user)
		add_fingerprint(user)
	else
		..()

/obj/item/radio/attack_self(mob/user as mob)
	user.set_machine(src)
	interact(user)

/obj/item/radio/ui_interact(mob/user, ui_key = "main", datum/nanoui/ui = null, var/force_open = 1)
	var/list/data = list()

	data["mic_status"] = broadcasting
	data["speaker"] = listening
	data["freq"] = format_frequency(frequency)
	data["rawfreq"] = num2text(frequency)

	data["mic_cut"] = (wires.IsIndexCut(WIRE_TRANSMIT) || wires.IsIndexCut(WIRE_SIGNAL))
	data["spk_cut"] = (wires.IsIndexCut(WIRE_RECEIVE) || wires.IsIndexCut(WIRE_SIGNAL))

	var/list/chanlist = list_channels(user)
	if(islist(chanlist) && chanlist.len)
		data["chan_list"] = chanlist
		data["chan_list_len"] = chanlist.len

	if(syndie)
		data["useSyndMode"] = 1

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "radio_basic.tmpl", "[name]", 400, 430)
		ui.set_initial_data(data)
		ui.open()

/obj/item/radio/talk_into(atom/movable/M, message, channel, list/spans, datum/language/language)
	if(!spans)
		spans = list(M.speech_span)
	if(!language)
		language = M.get_selected_language()
	INVOKE_ASYNC(src, .proc/talk_into_impl, M, message, channel, spans.Copy(), language)
	return ITALICS | REDUCE_RANGE

/obj/item/radio/proc/talk_into_impl(atom/movable/M, message, channel, list/spans, datum/language/language)
	if(!on)
		return // the device has to be on
	if(!M || !message)
		return
	if(wires.IsIndexCut(WIRE_TRANSMIT))  // Permacell and otherwise tampered-with radios
		return
	if(!M.IsVocal())
		return

	if(use_command)
		spans |= commandspan

	/*
	Roughly speaking, radios attempt to make a subspace transmission (which
	is received, processed, and rebroadcast by the telecomms satellite) and
	if that fails, they send a mundane radio transmission.

	Headsets cannot send/receive mundane transmissions, only subspace.
	Syndicate radios can hear transmissions on all well-known frequencies.
	CentCom radios can hear the CentCom frequency no matter what.
	*/

	// From the channel, determine the frequency and get a reference to it.
	var/freq
	if(channel && channels && channels.len > 0)
		if(channel == MODE_DEPARTMENT)
			channel = channels[1]
		freq = secure_radio_connections[channel]
		if (!channels[channel]) // if the channel is turned off, don't broadcast
			return
	else
		freq = frequency
		channel = null

	// Nearby active jammers severely gibberish the message

	var/turf/position = get_turf(src)
	for(var/obj/item/radio_jammer/jammer in active_radio_jammers) //GLOB.active_jammers)
		var/turf/jammer_turf = get_turf(jammer)
		if(position.z == jammer_turf.z && (get_dist(position, jammer_turf) < jammer.range))
			message = Gibberish(message,100)
			break

	// Determine the identity information which will be attached to the signal.
	var/atom/movable/virtualspeaker/speaker = new(null, M, src)

	// Construct the signal
	var/datum/signal/subspace/vocal/signal = new(src, freq, speaker, language, message, spans)

	// Independent radios, on the CentCom frequency, reach all independent radios. And bluespace radio gets a pass on this express route
	if (bluespace_radio || independent && (freq == FREQ_CENTCOM || freq == FREQ_CTF_RED || freq == FREQ_CTF_BLUE))
		signal.data["compression"] = 0
		signal.transmission_method = TRANSMISSION_SUPERSPACE
		signal.levels = list(0)  // reaches all Z-levels
		signal.broadcast()
		return

	// All radios make an attempt to use the subspace system first
	signal.send_to_receivers()

	// If the radio is subspace-only, that's all it can do
	if (subspace_transmission)
		return

	// Non-subspace radios will check in a couple of seconds, and if the signal
	// was never received, send a mundane broadcast (no headsets).
	addtimer(CALLBACK(src, .proc/backup_transmission, signal), 20)

/obj/item/radio/proc/backup_transmission(datum/signal/subspace/vocal/signal)
	var/turf/T = get_turf(src)
	if (signal.data["done"] && (T.z in signal.levels))
		return

	// Okay, the signal was never processed, send a mundane broadcast.
	signal.data["compression"] = 0
	signal.transmission_method = TRANSMISSION_RADIO
	signal.levels = list(T.z)
	signal.broadcast()

/obj/item/radio/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	. = ..()
	if(radio_freq || !broadcasting || get_dist(src, speaker) > canhear_range)
		return

	if(message_mode == MODE_WHISPER || message_mode == MODE_WHISPER_CRIT)
		// radios don't pick up whispers very well
		raw_message = stars(raw_message)
	else if(message_mode == MODE_L_HAND || message_mode == MODE_R_HAND)
		// try to avoid being heard double
		if (loc == speaker && ismob(speaker))
			var/mob/M = speaker
			var/idx = M.get_held_index_of_item(src)
			// left hands are odd slots
			if (idx && (idx % 2) == (message_mode == MODE_L_HAND))
				return

	talk_into(speaker, raw_message, , spans, language=message_language)

// Checks if this radio can receive on the given frequency.
/obj/item/radio/proc/can_receive(freq, level)
	// deny checks
	if (!on || !listening || wires.IsIndexCut(WIRE_RECEIVE))
		return FALSE
	if (freq == FREQ_SYNDICATE && !syndie)
		return FALSE
	if (freq == FREQ_CENTCOM)
		return independent  // hard-ignores the z-level check
	if (!(0 in level))
		var/turf/position = get_turf(src)
		if(!position || !(position.z in level))
			return FALSE

	// allow checks: are we listening on that frequency?
	if (freq == frequency)
		return TRUE
	for(var/ch_name in channels)
		if(channels[ch_name] & FREQ_LISTENING)
			//the GLOB.radiochannels list is located in communications.dm
			if(GLOB.radiochannels[ch_name] == text2num(freq) || syndie)
				return TRUE
	return FALSE

/obj/item/radio/examine(mob/user)
	. = ..()
	if (unscrewed)
		. += "<span class='notice'>It can be attached and modified.</span>"
	else
		. += "<span class='notice'>It cannot be modified or attached.</span>"

/obj/item/radio/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)
	if(istype(W, /obj/item/screwdriver) && !istype(src, /obj/item/radio/beacon))
		unscrewed = !unscrewed
		if(unscrewed)
			to_chat(user, "<span class='notice'>The radio can now be attached and modified!</span>")
		else
			to_chat(user, "<span class='notice'>The radio can no longer be modified or attached!</span>")
	else
		return ..()

/obj/item/radio/proc/ToggleBroadcast()
	broadcasting = !broadcasting && !(wires.IsIndexCut(WIRE_TRANSMIT) || wires.IsIndexCut(WIRE_SIGNAL))

/obj/item/radio/proc/ToggleReception()
	listening = !listening && !(wires.IsIndexCut(WIRE_RECEIVE) || wires.IsIndexCut(WIRE_SIGNAL))

/obj/item/radio/CanUseTopic()
	if(!on)
		return STATUS_CLOSE
	return ..()

/obj/item/radio/Topic(href, href_list)
	if(..())
		return TRUE

	usr.set_machine(src)
	if (href_list["track"])
		var/mob/target = locate(href_list["track"])
		var/mob/living/silicon/ai/A = locate(href_list["track2"])
		if(A && target)
			A.ai_actual_track(target)
		. = 1

	else if (href_list["freq"])
		var/new_frequency = (frequency + text2num(href_list["freq"]))
		if ((new_frequency < PUBLIC_LOW_FREQ || new_frequency > PUBLIC_HIGH_FREQ))
			new_frequency = sanitize_frequency(new_frequency)
		set_frequency(new_frequency)
		if(hidden_uplink)
			if(hidden_uplink.check_trigger(usr, frequency, traitor_frequency))
				usr << browse(null, "window=radio")
		. = 1
	else if (href_list["talk"])
		ToggleBroadcast()
		. = 1
	else if (href_list["listen"])
		var/chan_name = href_list["ch_name"]
		if (!chan_name)
			ToggleReception()
		else
			if (channels[chan_name] & FREQ_LISTENING)
				channels[chan_name] &= ~FREQ_LISTENING
			else
				channels[chan_name] |= FREQ_LISTENING
		. = 1
	else if(href_list["spec_freq"])
		var freq = href_list["spec_freq"]
		if(has_channel_access(usr, freq))
			set_frequency(text2num(freq))
		. = 1
	if(href_list["nowindow"]) // here for pAIs, maybe others will want it, idk
		return TRUE

	if(.)
		SSnanoui.update_uis(src)

/obj/item/radio/emp_act(severity)
	. = ..()
	// if (. & EMP_PROTECT_SELF)
	// 	return
	emped++ //There's been an EMP; better count it
	var/curremp = emped //Remember which EMP this was
	if (listening && ismob(loc))	// if the radio is turned on and on someone's person they notice
		to_chat(loc, "<span class='warning'>\The [src] overloads.</span>")
	broadcasting = FALSE
	listening = FALSE
	for (var/ch_name in channels)
		channels[ch_name] = 0
	on = FALSE
	spawn(200)
		if(emped == curremp) //Don't fix it if it's been EMP'd again
			emped = 0
			if (!istype(src, /obj/item/radio/intercom)) // intercoms will turn back on on their own
				on = TRUE

///////////////////////////////
//////////Borg Radios//////////
///////////////////////////////
//Giving borgs their own radio to have some more room to work with -Sieve

/obj/item/radio/borg
	name = "cyborg radio"
	subspace_switchable = TRUE
	subspace_transmission = TRUE
	icon = 'icons/obj/robot_component.dmi' // Cyborgs radio icons should look like the component.
	icon_state = "radio"
	canhear_range = 0
	var/mob/living/silicon/robot/myborg // Cyborg which owns this radio. Used for power checks
	var/shut_up = 1

/obj/item/radio/borg/Initialize(mapload)
	if(mapload && myborg)
		log_mapping("Depricated var 'myborg' found at \the [src]! [ADMIN_VERBOSEJMP(src)]")
	. = ..()

/obj/item/radio/borg/Destroy()
	myborg = null
	return ..()

// /obj/item/radio/borg/syndicate
// 	syndie = TRUE
// 	keyslot = new /obj/item/encryptionkey/syndicate

// /obj/item/radio/borg/syndicate/Initialize()
// 	. = ..()
// 	set_frequency(FREQ_SYNDICATE)

/obj/item/radio/borg/attackby(obj/item/W, mob/user, params)

	if(W.is_screwdriver())
		if(keyslot)
			for(var/ch_name in channels)
				SSradio.remove_object(src, GLOB.radiochannels[ch_name])
				secure_radio_connections[ch_name] = null


			if(keyslot)
				var/turf/T = get_turf(user)
				if(T)
					keyslot.forceMove(T)
					keyslot = null

			recalculateChannels()
			to_chat(user, "<span class='notice'>You pop out the encryption key in the radio.</span>")
			playsound(src, W.usesound, 50, 1)

		else
			to_chat(user, "<span class='warning'>This radio doesn't have any encryption keys!</span>")

	else if(istype(W, /obj/item/encryptionkey/))
		if(keyslot)
			to_chat(user, "<span class='warning'>The radio can't hold another key!</span>")
			return

		if(!keyslot)
			// if(!user.transferItemToLoc(W, src))
			// 	return
			user.drop_item()
			W.loc = src
			keyslot = W

		recalculateChannels()

/obj/item/radio/borg/Topic(href, href_list)
	if(..())
		return TRUE
	if (href_list["mode"])
		var/enable_subspace_transmission = text2num(href_list["mode"])
		if(enable_subspace_transmission != subspace_transmission)
			subspace_transmission = !subspace_transmission
			if(subspace_transmission)
				to_chat(usr, "<span class='notice'>Subspace Transmission is enabled</span>")
			else
				to_chat(usr, "<span class='notice'>Subspace Transmission is disabled</span>")

			if(subspace_transmission == 0)//Simple as fuck, clears the channel list to prevent talking/listening over them if subspace transmission is disabled
				channels = list()
			else
				recalculateChannels()
		. = 1
	if (href_list["shutup"]) // Toggle loudspeaker mode, AKA everyone around you hearing your radio.
		var/do_shut_up = text2num(href_list["shutup"])
		if(do_shut_up != shut_up)
			shut_up = !shut_up
			if(shut_up)
				canhear_range = 0
				to_chat(usr, "<span class='notice'>Loadspeaker disabled.</span>")
			else
				canhear_range = 3
				to_chat(usr, "<span class='notice'>Loadspeaker enabled.</span>")
		. = 1

	if(.)
		SSnanoui.update_uis(src)

/obj/item/radio/borg/interact(mob/user as mob)
	if(!on)
		return
	. = ..()

/obj/item/radio/borg/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/list/data = list()

	data["mic_status"] = broadcasting
	data["speaker"] = listening
	data["freq"] = format_frequency(frequency)
	data["rawfreq"] = num2text(frequency)

	var/list/chanlist = list_channels(user)
	if(islist(chanlist) && chanlist.len)
		data["chan_list"] = chanlist
		data["chan_list_len"] = chanlist.len

	if(syndie)
		data["useSyndMode"] = 1

	data["has_loudspeaker"] = 1
	data["loudspeaker"] = !shut_up
	data["has_subspace"] = 1
	data["subspace"] = subspace_transmission

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "radio_basic.tmpl", "[name]", 400, 430)
		ui.set_initial_data(data)
		ui.open()

/obj/item/radio/off	// Station bounced radios, their only difference is spawning with the speakers off, this was made to help the lag.
	listening = 0			// And it's nice to have a subtype too for future features.

/obj/item/radio/phone
	name = "phone"
	icon = 'icons/obj/items.dmi'
	icon_state = "red_phone"
	subspace_switchable = TRUE
	subspace_transmission = TRUE
	broadcasting = FALSE
	listening = TRUE
	canhear_range = 0

/obj/item/radio/phone/medbay
	// frequency = MED_I_FREQ

/obj/item/radio/emergency
	name = "Medbay Emergency Radio Link"
	icon_state = "med_walkietalkie"
	frequency = MED_I_FREQ
	subspace_switchable = TRUE
	subspace_transmission = TRUE
	adhoc_fallback = TRUE

/obj/item/radio/emergency/Initialize(mapload)
	. = ..()
	internal_channels = GLOB.default_medbay_channels.Copy()

//Pathfinder's Subspace Radio
/obj/item/subspaceradio
	name = "subspace radio"
	desc = "A powerful new radio recently gifted to Nanotrasen from Ward Takahashi, this communications device has the ability to send and recieve transmissions from anywhere."
	catalogue_data = list()///datum/category_item/catalogue/information/organization/ward_takahashi)
	icon = 'icons/vore/custom_items_vr.dmi'
	icon_override = 'icons/mob/back_vr.dmi'
	icon_state = "radiopack"
	item_state = "radiopack"
	slot_flags = SLOT_BACK
	force = 5
	throwforce = 6
	preserve_item = 1
	w_class = ITEMSIZE_LARGE
	action_button_name = "Remove/Replace Handset"

	var/obj/item/radio/subspacehandset/linked/handset

/obj/item/subspaceradio/Initialize(mapload) //starts without a cell for rnd
	. = ..()
	handset = new(src, src)

/obj/item/subspaceradio/Destroy()
	. = ..()
	QDEL_NULL(handset)

/obj/item/subspaceradio/ui_action_click()
	toggle_handset()

/obj/item/subspaceradio/attack_hand(mob/user)
	if(loc == user)
		toggle_handset()
	else
		..()

/obj/item/subspaceradio/MouseDrop()
	if(ismob(loc))
		if(!CanMouseDrop(src))
			return
		var/mob/M = loc
		if(!M.unEquip(src))
			return
		add_fingerprint(usr)
		M.put_in_any_hand_if_possible(src)

/obj/item/subspaceradio/attackby(obj/item/W, mob/user, params)
	if(W == handset)
		reattach_handset(user)
	else
		return ..()

/obj/item/subspaceradio/verb/toggle_handset()
	set name = "Toggle Handset"
	set category = "Object"

	var/mob/living/carbon/human/user = usr
	if(!handset)
		to_chat(user, "<span class='warning'>The handset is missing!</span>")
		return

	if(handset.loc != src)
		reattach_handset(user) //Remove from their hands and back onto the defib unit
		return

	if(!slot_check())
		to_chat(user, "<span class='warning'>You need to equip [src] before taking out [handset].</span>")
	else
		if(!usr.put_in_hands(handset)) //Detach the handset into the user's hands
			to_chat(user, "<span class='warning'>You need a free hand to hold the handset!</span>")
		update_icon() //success

//checks that the base unit is in the correct slot to be used
/obj/item/subspaceradio/proc/slot_check()
	var/mob/M = loc
	if(!istype(M))
		return 0 //not equipped

	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_back) == src)
		return 1
	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_s_store) == src)
		return 1

	return 0

/obj/item/subspaceradio/dropped(mob/user)
	..()
	reattach_handset(user) //handset attached to a base unit should never exist outside of their base unit or the mob equipping the base unit

/obj/item/subspaceradio/proc/reattach_handset(mob/user)
	if(!handset) return

	if(ismob(handset.loc))
		var/mob/M = handset.loc
		if(M.drop_from_inventory(handset, src))
			to_chat(user, "<span class='notice'>\The [handset] snaps back into the main unit.</span>")
	else
		handset.forceMove(src)

//Subspace Radio Handset
/obj/item/radio/subspacehandset
	name = "subspace radio handset"
	desc = "A large walkie talkie attached to the subspace radio by a retractable cord. It sits comfortably on a slot in the radio when not in use."
	bluespace_radio = TRUE
	icon_state = "signaller"
	slot_flags = null
	w_class = ITEMSIZE_LARGE

/obj/item/radio/subspacehandset/linked
	var/obj/item/subspaceradio/base_unit

/obj/item/radio/subspacehandset/linked/Initialize(newloc, obj/item/subspaceradio/radio)
	. = ..()
	base_unit = radio

/obj/item/radio/subspacehandset/linked/Destroy()
	if(base_unit)
		//ensure the base unit's icon updates
		if(base_unit.handset == src)
			base_unit.handset = null
		base_unit = null
	return ..()

/obj/item/radio/subspacehandset/linked/dropped(mob/user)
	..() //update twohanding
	if(base_unit)
		base_unit.reattach_handset(user) //handset attached to a base unit should never exist outside of their base unit or the mob equipping the base unit
