/obj/item/radio/intercom
	name = "station intercom (General)"
	desc = "Talk through this."
	icon = 'icons/obj/radio_vr.dmi' //VOREStation Edit - New Icon
	icon_state = "intercom"
	plane = TURF_PLANE
	layer = ABOVE_TURF_LAYER
	anchored = TRUE
	w_class = WEIGHT_CLASS_BULKY
	canhear_range = 2
	flags = NOBLOODY
	var/circuit = /obj/item/circuitboard/intercom
	var/number = 0
	var/last_tick //used to delay the powercheck
	var/unfastened = FALSE
	///depricated
	var/wiresexposed = 0

/obj/item/radio/intercom/Initialize(mapload, ndir, building)
	. = ..()
	if(building)
		setDir(ndir)
	START_PROCESSING(SSobj, src)

/obj/item/radio/intercom/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/radio/intercom/attackby(obj/item/I, mob/living/user, params)
	if(W.is_screwdriver()) // it's immediate here?
		unfastened = !unfastened
		to_chat(user, "The wires have been [wiresexposed ? "exposed" : "unexposed"]")
		playsound(src, W.usesound, 50, 1)
		if(wiresexposed)
			if(!on)
				icon_state = "intercom-p_open"
			else
				icon_state = "intercom_open"
		else
			icon_state = "intercom"
		return
	else if(W.is_wirecutter())
		if(!unfastened)
			to_chat(user, "<span class='warning'>You need to unscrew [src] from the wall first!</span>")
			return
		user.visible_message("<span class='warning'>[user] has cut the wires inside \the [src]!</span>", "You have cut the wires inside \the [src].")
		playsound(src, W.usesound, 50, TRUE)
		new/obj/item/stack/cable_coil(get_turf(src), 5)
		var/obj/structure/frame/A = new /obj/structure/frame(src.loc)
		var/obj/item/circuitboard/M = circuit
		A.frame_type = M.board_type
		A.pixel_x = pixel_x
		A.pixel_y = pixel_y
		A.circuit = M
		A.setDir(dir)
		A.anchored = 1
		A.state = 2
		A.update_icon()
		M.deconstruct(src)
		qdel(src)
	else
		src.attack_hand(user)
	return

/obj/item/radio/intercom/attack_ai(mob/user)
	attack_self(user)

/obj/item/radio/intercom/attack_hand(mob/user)
	attack_self(user)

/obj/item/radio/intercom/can_receive(freq, level)
	if(!on)
		return FALSE
	if(wires.is_cut(WIRE_RX))
		return FALSE
	if(!(0 in level))
		var/turf/position = get_turf(src)
		if(isnull(position) || !(position.z in level))
			return FALSE
	if(!src.listening)
		return FALSE
	if(freq == FREQ_SYNDICATE)
		if(!(src.syndie))
			return FALSE//Prevents broadcast of messages over devices lacking the encryption

	return TRUE


/obj/item/radio/intercom/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	. = ..()
	if (message_mode == MODE_INTERCOM)
		return  // Avoid hearing the same thing twice
	if(!anyai && !(speaker in ai))
		return
	..()


/obj/item/radio/intercom/process()
	if(((world.timeofday - last_tick) > 30) || ((world.timeofday - last_tick) < 0))
		last_tick = world.timeofday

		var/area/A = get_area(src)
		if(!A || emped)
			on = FALSE
		else
			on = A.powered(EQUIP) // set "on" to the power status

		if(!on)
			if(wiresexposed)
				icon_state = "intercom-p_open"
			else
				icon_state = "intercom-p"
		else
			if(wiresexposed)
				icon_state = "intercom_open"
			else
				icon_state = initial(icon_state)


/obj/item/radio/intercom/custom
	name = "station intercom (Custom)"
	broadcasting = FALSE
	listening = FALSE

/obj/item/radio/intercom/interrogation
	name = "station intercom (Interrogation)"
	frequency  = 1449

/obj/item/radio/intercom/private
	name = "station intercom (Private)"
	frequency = AI_FREQ

/obj/item/radio/intercom/specops
	name = "\improper Spec Ops intercom"
	frequency = ERT_FREQ
	subspace_transmission = 1
	centComm = 1

/obj/item/radio/intercom/department
	canhear_range = 5
	broadcasting = 0
	listening = 1

/obj/item/radio/intercom/department/medbay
	name = "station intercom (Medbay)"
	icon_state = "medintercom"
	frequency = MED_I_FREQ

/obj/item/radio/intercom/department/security
	name = "station intercom (Security)"
	icon_state = "secintercom"
	frequency = SEC_I_FREQ

/obj/item/radio/intercom/entertainment
	name = "entertainment intercom"
	frequency = ENT_FREQ

/obj/item/radio/intercom/omni
	name = "global announcer"
/obj/item/radio/intercom/omni/Initialize()
	channels = radiochannels.Copy()
	return ..()

/obj/item/radio/intercom/department/security/Initialize()
	. = ..()
	internal_channels = list(
		num2text(PUB_FREQ) = list(),
		num2text(SEC_I_FREQ) = list(access_security)
	)

/obj/item/radio/intercom/entertainment/Initialize()
	. = ..()
	internal_channels = list(
		num2text(PUB_FREQ) = list(),
		num2text(ENT_FREQ) = list()
	)

/obj/item/radio/intercom/syndicate
	name = "illicit intercom"
	desc = "Talk through this. Evilly"
	frequency = SYND_FREQ
	subspace_transmission = 1
	syndie = 1

/obj/item/radio/intercom/syndicate/Initialize()
	. = ..()
	internal_channels[num2text(SYND_FREQ)] = list(access_syndicate)

/obj/item/radio/intercom/raider
	name = "illicit intercom"
	desc = "Pirate radio, but not in the usual sense of the word."
	frequency = RAID_FREQ
	subspace_transmission = 1
	syndie = 1

/obj/item/radio/intercom/raider/Initialize()
	. = ..()
	internal_channels[num2text(RAID_FREQ)] = list(access_syndicate)


/obj/item/radio/intercom/locked
    var/locked_frequency

/obj/item/radio/intercom/locked/set_frequency(var/frequency)
	if(frequency == locked_frequency)
		..(locked_frequency)

/obj/item/radio/intercom/locked/list_channels()
	return ""

/obj/item/radio/intercom/locked/ai_private
	name = "\improper AI intercom"
	frequency = AI_FREQ
	broadcasting = 1
	listening = 1

/obj/item/radio/intercom/locked/confessional
	name = "confessional intercom"
	frequency = 1480