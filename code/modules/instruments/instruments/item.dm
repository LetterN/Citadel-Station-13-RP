//copy pasta of the space piano, don't hurt me -Pete
/obj/item/instrument
	name = "generic instrument"
	damage_force = 10
//	integrity_max = 100
//	resistance_flags = FLAMMABLE
	icon = 'icons/obj/musician.dmi'
	item_icons = list(
		SLOT_ID_LEFT_HAND = 'icons/mob/inhands/equipment/instruments_lefthand.dmi',
		SLOT_ID_RIGHT_HAND = 'icons/mob/inhands/equipment/instruments_righthand.dmi'
		)
	var/datum/song/handheld/song
	var/list/allowed_instrument_ids
//	var/tune_time_left = 0

/obj/item/instrument/Initialize(mapload)
	. = ..()
	song = new(src, allowed_instrument_ids)
	allowed_instrument_ids = null			//We don't need this clogging memory after it's used.

/obj/item/instrument/Destroy()
	QDEL_NULL(song)
/*
	if(tune_time_left)
		STOP_PROCESSING(SSprocessing, src)
*/
	return ..()

/obj/item/instrument/proc/should_stop_playing(mob/user)
	return (loc != user) && (depth_inside_atom(user) < 3)

/*
/obj/item/instrument/process(wait)
	if(is_tuned())
		if (song.playing)
			for (var/mob/living/M in song.hearing_mobs)
				M.dizziness = max(0,M.dizziness-2)
				M.jitteriness = max(0,M.jitteriness-2)
				M.confused = max(M.confused-1)
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "goodmusic", /datum/mood_event/goodmusic)
		tune_time_left -= wait
	else
		tune_time_left = 0
		if (song.playing)
			loc.visible_message("<span class='warning'>[src] starts sounding a little off...</span>")
		STOP_PROCESSING(SSprocessing, src)
*/

/obj/item/instrument/attack_self(mob/user, datum/event_args/actor/actor)
	. = ..()
	if(.)
		return
	if(!user.IsAdvancedToolUser())
		to_chat(user, "<span class='warning'>You don't have the dexterity to do this!</span>")
		return TRUE
	interact(user)

/*
/obj/item/instrument/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/musicaltuner))
		var/mob/living/carbon/human/H = user
		if (HAS_TRAIT(H, TRAIT_MUSICIAN))
			if (!is_tuned())
				H.visible_message("[H] tunes the [src] to perfection!", "<span class='notice'>You tune the [src] to perfection!</span>")
				tune_time_left = 600 SECONDS
				START_PROCESSING(SSprocessing, src)
			else
				to_chat(H, "<span class='notice'>[src] is already well tuned!</span>")
		else
			to_chat(H, "<span class='warning'>You have no idea how to use this.</span>")

/obj/item/instrument/proc/is_tuned()
	return tune_time_left > 0
*/

/obj/item/instrument/interact(mob/user)
	nano_ui_interact(user)

/obj/item/instrument/nano_ui_interact(mob/living/user)
	if(!isliving(user) || user.stat || user.restrained())
		return

	user.set_machine(src)
	song.nano_ui_interact(user)

/obj/item/instrument/violin
	name = "space violin"
	desc = "A wooden musical instrument with four strings and a bow. \"The devil went down to space, he was looking for an assistant to grief.\""
	icon_state = "violin"
	item_state = "violin"
	attack_sound = "swing_hit"
	allowed_instrument_ids = "violin"

/obj/item/instrument/violin/golden
	name = "golden violin"
	desc = "A golden musical instrument with four strings and a bow. \"The devil went down to space, he was looking for an assistant to grief.\""
	icon_state = "golden_violin"
	item_state = "golden_violin"
	integrity_flags = INTEGRITY_ACIDPROOF | INTEGRITY_FIREPROOF | INTEGRITY_LAVAPROOF

/obj/item/instrument/piano_synth
	name = "synthesizer"
	desc = "An advanced electronic synthesizer that can be used as various instruments."
	icon_state = "synth"
	item_state = "synth"
	allowed_instrument_ids = "piano"

/obj/item/instrument/piano_synth/Initialize(mapload)
	. = ..()
	song.allowed_instrument_ids = get_allowed_instrument_ids()

/obj/item/instrument/guitar
	name = "guitar"
	desc = "It's made of wood and has bronze strings."
	icon_state = "guitar"
	item_state = "guitar"
	attack_verb = list("played metal on", "serenaded", "crashed", "smashed")
	attack_sound = 'sound/weapons/stringsmash.ogg'
	allowed_instrument_ids = "guitar"

/obj/item/instrument/eguitar
	name = "electric guitar"
	desc = "Makes all your shredding needs possible."
	icon_state = "eguitar"
	item_state = "eguitar"
	damage_force = 12
	attack_verb = list("played metal on", "shredded", "crashed", "smashed")
	attack_sound = 'sound/weapons/stringsmash.ogg'
	allowed_instrument_ids = "eguitar"

/obj/item/instrument/glockenspiel
	name = "glockenspiel"
	desc = "Smooth metal bars perfect for any marching band."
	icon_state = "glockenspiel"
	item_state = "glockenspiel"
	allowed_instrument_ids = "glockenspiel"

/obj/item/instrument/accordion
	name = "accordion"
	desc = "Pun-Pun not included."
	icon_state = "accordion"
	item_state = "accordion"
	allowed_instrument_ids = "accordion"

/obj/item/instrument/trumpet
	name = "trumpet"
	desc = "To announce the arrival of the king!"
	icon_state = "trumpet"
	item_state = "trombone"
	allowed_instrument_ids = "trombone"

/obj/item/instrument/trumpet/spectral
	name = "spectral trumpet"
	desc = "Things are about to get spooky!"
	icon_state = "trumpet"
	item_state = "trombone"
	damage_force = 0
	attack_verb = list("played","jazzed","trumpeted","mourned","dooted","spooked")
	attack_sound = 'sound/runtime/instruments/trombone/En4.mid'

/obj/item/instrument/saxophone
	name = "saxophone"
	desc = "This soothing sound will be sure to leave your audience in tears."
	icon_state = "saxophone"
	item_state = "saxophone"
	allowed_instrument_ids = "saxophone"

/obj/item/instrument/saxophone/spectral
	name = "spectral saxophone"
	desc = "This spooky sound will be sure to leave mortals in bones."
	icon_state = "saxophone"
	item_state = "saxophone"
	damage_force = 0
	attack_verb = list("played","jazzed","saxxed","mourned","dooted","spooked")
	attack_sound = 'sound/runtime/instruments/saxophone/En4.mid'

/obj/item/instrument/trombone
	name = "trombone"
	desc = "How can any pool table ever hope to compete?"
	icon_state = "trombone"
	item_state = "trombone"
	allowed_instrument_ids = "trombone"

/obj/item/instrument/trombone/spectral
	name = "spectral trombone"
	desc = "A skeleton's favorite instrument. Apply directly on the mortals."
	icon_state = "trombone"
	item_state = "trombone"
	damage_force = 0
	attack_verb = list("played","jazzed","tromboned","mourned","dooted","spooked")
	attack_sound = 'sound/runtime/instruments/trombone/Cn4.mid'

/obj/item/instrument/recorder
	name = "recorder"
	desc = "Just like in school, playing ability and all."
	damage_force = 5
	icon_state = "recorder"
	item_state = "recorder"
	allowed_instrument_ids = "recorder"

/obj/item/instrument/harmonica
	name = "harmonica"
	desc = "For when you get a bad case of the space blues."
	icon_state = "harmonica"
	item_state = "harmonica"
	allowed_instrument_ids = "harmonica"
//	slot_flags = ITEM_SLOT_MASK
	damage_force = 5
	w_class = WEIGHT_CLASS_SMALL
//	actions_types = list(/datum/action/item_action/instrument)

/*
/obj/item/instrument/harmonica/proc/handle_speech(datum/source, list/speech_args)
	if(song.playing && ismob(loc))
		to_chat(loc, "<span class='warning'>You stop playing the harmonica to talk...</span>")
		song.playing = FALSE

/obj/item/instrument/harmonica/equipped(mob/M, slot)
	. = ..()
	RegisterSignal(M, COMSIG_MOB_SAY, PROC_REF(handle_speech))

/obj/item/instrument/harmonica/dropped(mob/user, flags, atom/newLoc)
	. = ..()
	UnregisterSignal(M, COMSIG_MOB_SAY)
*/

/obj/item/instrument/bikehorn
	name = "gilded bike horn"
	desc = "An exquisitely decorated bike horn, capable of honking in a variety of notes."
	icon_state = "bike_horn"
	item_state = "bike_horn"
	item_icons = list(
		SLOT_ID_LEFT_HAND = 'icons/mob/inhands/equipment/horns_lefthand.dmi',
		SLOT_ID_RIGHT_HAND = 'icons/mob/inhands/equipment/horns_righthand.dmi'
		)
	attack_verb = list("beautifully honked")
	allowed_instrument_ids = list("honk", "bikehorn")
	w_class = WEIGHT_CLASS_TINY
	damage_force = 0
	throw_speed = 3
	throw_range = 15
	attack_sound = 'sound/items/bikehorn.ogg'

/obj/item/instrument/banjo
	name = "banjo"
	desc = "A 'Mura' brand banjo. It's pretty much just a drum with a neck and strings."
	icon_state = "banjo"
	item_state = "banjo"
	attack_verb = list("scruggs-styled", "hum-diggitied", "shin-digged", "clawhammered")
	attack_sound = 'sound/weapons/banjoslap.ogg'
	allowed_instrument_ids = "banjo"

/*
/obj/item/musicaltuner
	name = "musical tuner"
	desc = "A device for tuning musical instruments both manual and electronic alike."
	icon = 'icons/obj/device.dmi'
	icon_state = "musicaltuner"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
*/

/*
/obj/item/choice_beacon/music
	name = "instrument delivery beacon"
	desc = "Summon your tool of art."
	icon_state = "gangtool-red"

/obj/item/choice_beacon/music/generate_display_names()
	var/static/list/instruments
	if(!instruments)
		instruments = list()
		var/list/templist = list(/obj/item/instrument/violin,
							/obj/item/instrument/piano_synth,
							/obj/item/instrument/guitar,
							/obj/item/instrument/eguitar,
							/obj/item/instrument/glockenspiel,
							/obj/item/instrument/accordion,
							/obj/item/instrument/trumpet,
							/obj/item/instrument/saxophone,
							/obj/item/instrument/trombone,
							/obj/item/instrument/recorder,
							/obj/item/instrument/harmonica
							)
		for(var/V in templist)
			var/atom/A = V
			instruments[initial(A.name)] = A
	return instruments
*/

//Event Reward item.
/obj/item/instrument/gameboy
	name = "gameboy"
	desc = "A bright teal Gameboy Color. This one has a copy of LSDJ slotted into the back. /There's also initals scratched crudely into the lower left hand corner spelling TAS./"
	icon_state = "gameboy"
	item_state = "gameboy"
	attack_verb = ("bitcrushed")
	attack_sound = "sound/weapons/gboy.ogg"
	allowed_instrument_ids = "square"
