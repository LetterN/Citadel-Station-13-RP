/*
	Basically just an empty shell for receiving and broadcasting radio messages. Not
	very flexible, but it gets the job done.
*/

/obj/machinery/telecomms/allinone
	name = "Telecommunications Mainframe"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "allinone"
	desc = "A compact machine used for portable subspace telecommuniations processing."
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_OFF
	idle_power_usage = 0
	produces_heat = 0
	var/intercept = 0 // if nonzero, broadcasts all messages to syndicate channel

/obj/machinery/telecomms/allinone/Initialize()
	. = ..()
	if (intercept)
		freq_listening = list(FREQ_SYNDICATE)

/obj/machinery/telecomms/allinone/receive_signal(datum/signal/subspace/signal)
	if(!istype(signal) || signal.transmission_method != TRANSMISSION_SUBSPACE)  // receives on subspace only
		return
	if(!on || !is_freq_listening(signal))  // has to be on to receive messages
		return
	if (!intercept && !(z in signal.levels) && !(0 in signal.levels))  // has to be syndicate or on the right level
		return

	// Decompress the signal and mark it done
	if (intercept)
		signal.levels += 0  // Signal is broadcast to agents anywhere

	signal.data["compression"] = 0
	signal.mark_done()
	signal.broadcast()

/obj/machinery/telecomms/allinone/attackby(obj/item/P, mob/user, params)
	if(istype(P, /obj/item/multitool))
		return attack_hand(user)
