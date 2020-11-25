// Used for translating channels to tokens on examination
GLOBAL_LIST_INIT(channel_tokens, list(
	RADIO_CHANNEL_COMMON = RADIO_KEY_COMMON,
	RADIO_CHANNEL_SCIENCE = RADIO_TOKEN_SCIENCE,
	RADIO_CHANNEL_COMMAND = RADIO_TOKEN_COMMAND,
	RADIO_CHANNEL_MEDICAL = RADIO_TOKEN_MEDICAL,
	RADIO_CHANNEL_ENGINEERING = RADIO_TOKEN_ENGINEERING,
	RADIO_CHANNEL_SECURITY = RADIO_TOKEN_SECURITY,
	RADIO_CHANNEL_CENTCOM = RADIO_TOKEN_CENTCOM,
	//RADIO_CHANNEL_SYNDICATE = RADIO_TOKEN_SYNDICATE,
	RADIO_CHANNEL_SUPPLY = RADIO_TOKEN_SUPPLY,
	RADIO_CHANNEL_SERVICE = RADIO_TOKEN_SERVICE,
	MODE_BINARY = MODE_TOKEN_BINARY,
	RADIO_CHANNEL_AI_PRIVATE = RADIO_TOKEN_AI_PRIVATE
))

/obj/item/radio/headset
	name = "radio headset"
	desc = "An updated, modular intercom that fits over the head. Takes encryption keys"
	icon_state = "headset"
	item_state = null //To remove the radio's state
	matter = list(DEFAULT_WALL_MATERIAL = 75)
	subspace_transmission = TRUE
	canhear_range = 0 // can't hear headsets from very far away

	slot_flags = SLOT_EARS

	sprite_sheets = list(
		SPECIES_TESHARI = 'icons/mob/species/teshari/ears.dmi',
		SPECIES_VOX = 'icons/mob/species/vox/ears.dmi'
		)

	var/obj/item/encryptionkey/keyslot2 = null
	var/bowman = FALSE

	///DEPRICATED///
	var/obj/item/encryptionkey/keyslot1 = null
	var/ks1type = null
	var/ks2type = null
	//var/translate_binary = 0
	//var/translate_hive = 0

/obj/item/radio/headset/Initialize(mapload)
	. = ..()
	recalculateChannels()

/obj/item/radio/headset/Destroy()
	QDEL_NULL(keyslot2)
	return ..()

/obj/item/radio/headset/talk_into(mob/living/M, message, channel, list/spans,datum/language/language)
	if (!listening)
		return ITALICS | REDUCE_RANGE
	return ..()

/obj/item/radio/headset/can_receive(freq, level, AIuser)
	if(ishuman(src.loc))
		var/mob/living/carbon/human/H = src.loc
		if(H.ears == src)
			return ..(freq, level)
	else if(AIuser)
		return ..(freq, level)
	return FALSE

/obj/item/radio/headset/examine(mob/user)
	. = ..()
	if(loc == user)
		// construction of frequency description
		var/list/avail_chans = list("Use [RADIO_KEY_COMMON] for the currently tuned frequency")
		if(translate_binary)
			avail_chans += "use [MODE_TOKEN_BINARY] for [MODE_BINARY]"
		if(length(channels))
			for(var/i in 1 to length(channels))
				if(i == 1)
					avail_chans += "use [MODE_TOKEN_DEPARTMENT] or [GLOB.channel_tokens[channels[i]]] for [lowertext(channels[i])]"
				else
					avail_chans += "use [GLOB.channel_tokens[channels[i]]] for [lowertext(channels[i])]"
		to_chat(user, "<span class='notice'>A small screen on the headset displays the following available frequencies:\n[english_list(avail_chans)].")

		if(command)
			to_chat(user, "<span class='info'>Alt-click to toggle the high-volume mode.</span>")
	else
		to_chat(user, "<span class='notice'>A small screen on the headset flashes, it's too small to read without holding or wearing the headset.</span>")

/obj/item/radio/headset/get_worn_icon_state(var/slot_name)
	var/append = ""
	if(icon_override)
		switch(slot_name)
			if(slot_l_ear_str)
				append = "_l"
			if(slot_r_ear_str)
				append = "_r"

	return "[..()][append]"

/obj/item/radio/headset/syndicate
	origin_tech = list(TECH_ILLEGAL = 3)

/obj/item/radio/headset/syndicate/alt
	icon_state = "syndie_headset"
	item_state = "headset"
	bowman = TRUE

/obj/item/radio/headset/syndicate/Initialize()
	. = ..()
	make_syndie()

/obj/item/radio/headset/raider
	origin_tech = list(TECH_ILLEGAL = 2)
	keyslot = new /obj/item/encryptionkey/raider
	syndie = TRUE

/obj/item/radio/headset/raider/Initialize()
	. = ..()
	set_frequency(FREQ_RAIDER)
	recalculateChannels()

/obj/item/radio/headset/binary
	origin_tech = list(TECH_ILLEGAL = 3)
/obj/item/radio/headset/binary/Initialize()
	. = ..()
	qdel(keyslot)
	keyslot = new /obj/item/encryptionkey/binary
	recalculateChannels()

/obj/item/radio/headset/headset_sec
	name = "security radio headset"
	desc = "This is used by your elite security force."
	icon_state = "sec_headset"
	keyslot = new /obj/item/encryptionkey/headset_sec

/obj/item/radio/headset/headset_sec/alt
	name = "security bowman headset"
	desc = "This is used by your elite security force."
	icon_state = "sec_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/headset_eng
	name = "engineering radio headset"
	desc = "When the engineers wish to chat like girls."
	icon_state = "eng_headset"
	keyslot = new /obj/item/encryptionkey/headset_eng

/obj/item/radio/headset/headset_eng/alt
	name = "engineering bowman headset"
	desc = "When the engineers wish to chat like girls."
	icon_state = "eng_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/headset_rob
	name = "robotics radio headset"
	desc = "Made specifically for the roboticists who cannot decide between departments."
	icon_state = "rob_headset"
	keyslot = new /obj/item/encryptionkey/headset_rob

/obj/item/radio/headset/headset_med
	name = "medical radio headset"
	desc = "A headset for the trained staff of the medbay."
	icon_state = "med_headset"
	keyslot = new /obj/item/encryptionkey/headset_med

/obj/item/radio/headset/headset_med/alt
	name = "medical bowman headset"
	desc = "A headset for the trained staff of the medbay."
	icon_state = "med_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/headset_sci
	name = "science radio headset"
	desc = "A sciency headset. Like usual."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/headset_sci

/obj/item/radio/headset/headset_medsci
	name = "medical research radio headset"
	desc = "A headset that is a result of the mating between medical and science."
	icon_state = "med_headset"
	keyslot = new /obj/item/encryptionkey/headset_medsci

/obj/item/radio/headset/headset_com
	name = "command radio headset"
	desc = "A headset with a commanding channel."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/headset_com

/obj/item/radio/headset/headset_adj //Citadel Add: Secretary headset with service and command.
	name = "secretary radio headset"
	desc = "A headset for those who serve command."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/headset_adj

/obj/item/radio/headset/headset_com/alt
	name = "command bowman headset"
	desc = "A headset with a commanding channel."
	icon_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/heads
	command = TRUE

/obj/item/radio/headset/heads/captain
	name = "Facility Director's headset"
	desc = "The headset of the boss."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/captain

/obj/item/radio/headset/heads/captain/alt
	name = "Facility Director's bowman headset"
	desc = "The headset of the boss."
	icon_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/heads/captain/sfr
	name = "SFR headset"
	desc = "A headset belonging to a Sif Free Radio DJ. SFR, best tunes in the wilderness."
	icon_state = "com_headset_alt"

/obj/item/radio/headset/heads/rd
	name = "\proper the research director's headset"
	desc = "Headset of the fellow who keeps society marching towards technological singularity."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/rd

/obj/item/radio/headset/heads/rd/alt
	name = "research director's bowman headset"
	desc = "Headset of the researching God."
	icon_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/heads/hos
	name = "\proper the head of security's headset"
	desc = "The headset of the man in charge of keeping order and protecting the station."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/hos

/obj/item/radio/headset/heads/hos/alt
	name = "\proper the head of security's bowman headset"
	desc = "The headset of the man in charge of keeping order and protecting the station." // Protects ears from flashbangs.
	icon_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/heads/ce
	name = "\proper the chief engineer's headset"
	desc = "The headset of the guy in charge of keeping the station powered and undamaged."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/ce

/obj/item/radio/headset/heads/ce/alt
	name = "\proper the chief engineer's bowman headset"
	desc = "The headset of the guy in charge of keeping the station powered and undamaged."
	icon_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/heads/cmo
	name = "\proper the chief medical officer's headset"
	desc = "The headset of the highly trained medical chief."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/cmo

/obj/item/radio/headset/heads/cmo/alt
	name = "\proper the chief medical officer's bowman headset"
	desc = "The headset of the highly trained medical chief."
	icon_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/heads/hop
	name = "\proper the head of personnel's headset"
	desc = "The headset of the guy who will one day be facility director."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/hop

/obj/item/radio/headset/heads/hop/alt
	name = "\proper the head of personnel's bowman headset"
	desc = "The headset of the guy who will one day be facility director."
	icon_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/headset_cargo
	name = "supply radio headset"
	desc = "A headset used by the QM and his slaves."
	icon_state = "cargo_headset"
	keyslot = new /obj/item/encryptionkey/headset_cargo

/obj/item/radio/headset/headset_cargo/alt
	name = "supply bowman headset"
	desc = "A bowman headset used by the QM and his slaves."
	icon_state = "cargo_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/headset_mine
	name = "mining radio headset"
	desc = "Headset used by miners. Has inbuilt short-band radio for when comms are down."
	icon_state = "mine_headset"
	adhoc_fallback = TRUE
	keyslot = new /obj/item/encryptionkey/headset_cargo

/obj/item/radio/headset/headset_service
	name = "service radio headset"
	desc = "Headset used by the service staff, tasked with keeping the station full, happy and clean."
	icon_state = "srv_headset"
	keyslot = new /obj/item/encryptionkey/headset_service

/obj/item/radio/headset/ert
	name = "emergency response team radio headset"
	desc = "The headset of the boss's boss."
	icon_state = "com_headset"
	//centComm = 1
	//ks2type = /obj/item/encryptionkey/ert
	//keyslot = new /obj/item/encryptionkey/headset_com
	//keyslot2 = new /obj/item/encryptionkey/headset_cent

/obj/item/radio/headset/ert/alt
	name = "emergency response team bowman headset"
	desc = "The headset of the boss's boss."
	icon_state = "com_headset_alt"
	bowman = TRUE

/obj/item/radio/headset/omni		//Only for the admin intercoms
	keyslot = new /obj/item/encryptionkey/omni

/obj/item/radio/headset/ia
	name = "internal affair's headset"
	desc = "The headset of your worst enemy."
	icon_state = "com_headset"
	keyslot = new /obj/item/encryptionkey/heads/hos

/obj/item/radio/headset/heads/ai_integrated //No need to care about icons, it should be hidden inside the AI anyway.
	name = "\proper Integrated Subspace Transceiver "
	icon = 'icons/obj/robot_component.dmi'
	icon_state = "radio"
	item_state = "headset"
	keyslot2 = new /obj/item/encryptionkey/heads/ai_integrated

	var/myAi = null    // Atlantis: Reference back to the AI which has this radio.
	var/disabledAi = 0 // Atlantis: Used to manually disable AI's integrated radio via intellicard menu.

/obj/item/radio/headset/heads/ai_integrated/can_receive(freq, level)
	return ..(freq, level, TRUE)

/obj/item/radio/headset/mmi_radio
	name = "brain-integrated radio"
	desc = "MMIs and synthetic brains are often equipped with these."
	icon = 'icons/obj/robot_component.dmi'
	icon_state = "radio"
	item_state = "headset"
	var/mmiowner = null
	var/radio_enabled = 1

/obj/item/radio/headset/mmi_radio/can_receive(freq, level)
	return ..(freq, level, TRUE)

/obj/item/radio/headset/attackby(obj/item/W, mob/user, params)
	user.set_machine(src)
	if(!(W.is_screwdriver() || istype(W, /obj/item/encryptionkey)))
		return

	if(W.is_screwdriver())
		if(keyslot || keyslot2)
			for(var/ch_name in channels)
				SSradio.remove_object(src, GLOB.radiochannels[ch_name])
				secure_radio_connections[ch_name] = null

			var/turf/T = user.drop_location() // alt: get_turf(user)
			if(T)
				if(keyslot)
					keyslot.forceMove(T) //	keyslot1.loc = T
					keyslot = null
				if(keyslot2)
					keyslot2.forceMove(T)
					keyslot2 = null

			recalculateChannels()
			to_chat(user, "<span class='notice'>You pop out the encryption keys in the headset.</span>")
			playsound(src, W.usesound, 50, TRUE)

		else
			to_chat(user, "<span class='warning'>This headset doesn't have any unique encryption keys!  How useless...</span>")

	else if(istype(W, /obj/item/encryptionkey))
		if(keyslot && keyslot2)
			to_chat(user, "<span class='warning'>The headset can't hold another key!</span>")
			return

		if(!keyslot1)
			user.drop_item()
			W.loc = src
			keyslot1 = W

		else
			user.drop_item()
			W.loc = src
			keyslot2 = W


		recalculateChannels()
	else
		return ..()

/obj/item/radio/headset/recalculateChannels()
	..()
	if(keyslot2)
		for(var/ch_name in keyslot2.channels)
			if(!(ch_name in src.channels))
				channels[ch_name] = keyslot2.channels[ch_name]

		if(keyslot2.translate_binary)
			translate_binary = TRUE
		if(keyslot2.syndie)
			syndie = TRUE
		if (keyslot2.independent)
			independent = TRUE

	for(var/ch_name in channels)
		secure_radio_connections[ch_name] = add_radio(src, GLOB.radiochannels[ch_name])

/obj/item/radio/headset/AltClick(mob/living/user)
	. = ..()
	if(!istype(user) || !Adjacent(user) || user.incapacitated())
		return
	if (command)
		use_command = !use_command
		to_chat(user, "<span class='notice'>You toggle high-volume mode [use_command ? "on" : "off"].</span>")
		return TRUE
