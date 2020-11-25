
/*
	Hello, friends, this is Doohl from sexylands. You may be wondering what this
	monstrous code file is. Sit down, boys and girls, while I tell you the tale.


	The telecom machines were designed to be compatible with any radio
	signals, provided they use subspace transmission. Currently they are only used for
	headsets, but they can eventually be outfitted for real COMPUTER networks. This
	is just a skeleton, ladies and gentlemen.

	Look at radio.dm for the prequel to this code.
*/

GLOBAL_LIST_EMPTY(telecomms_list)

/obj/machinery/telecomms
	var/list/links = list() // list of machines this machine is linked to
	var/traffic = 0 // value increases as traffic increases
	var/netspeed = 5 // how much traffic to lose per tick (50 gigabytes/second * netspeed)
	var/list/autolinkers = list() // list of text/number values to link with
	var/id = "NULL" // identification string
	var/network = "NULL" // the network of the machinery

	var/list/freq_listening = list() // list of frequencies to tune into: if none, will listen to all

	var/on = TRUE
	var/toggled = TRUE 	// Is it toggled on
	var/long_range_link = FALSE  // Can you link it across Z levels or on the otherside of the map? (Relay & Hub)
	var/hide = FALSE  // Is it a hidden machine?
	/// heatcode
	var/integrity = 100 // basically HP, loses integrity by heat
	var/produces_heat = 1	//whether the machine will produce heat when on.
	var/delay = 10 // how many process() ticks to delay per heat

/obj/machinery/telecomms/proc/relay_information(datum/signal/subspace/signal, filter, copysig, amount = 20)
	// relay signal to all linked machinery that are of type [filter]. If signal has been sent [amount] times, stop sending

	if(!on)
		return
	var/send_count = 0

	// Loop through all linked machines and send the signal or copy.
	for(var/obj/machinery/telecomms/machine in links)
		if(filter && !istype( machine, filter ))
			continue
		if(!machine.on)
			continue
		if(amount && send_count >= amount)
			break
		if(z != machine.loc.z && !long_range_link && !machine.long_range_link)
			continue

		send_count++
		if(machine.is_freq_listening(signal))
			machine.traffic++

		if(copysig)
			machine.receive_information(signal.copy(), src)
		else
			machine.receive_information(signal, src)

	if(send_count > 0 && is_freq_listening(signal))
		traffic++

	return send_count

/obj/machinery/telecomms/proc/relay_direct_information(datum/signal/signal, obj/machinery/telecomms/machine)
	// send signal directly to a machine
	machine.receive_information(signal, src)

/obj/machinery/telecomms/proc/receive_information(datum/signal/signal, obj/machinery/telecomms/machine_from)
	// receive information from linked machinery

/obj/machinery/telecomms/proc/is_freq_listening(datum/signal/signal)
	// return TRUE if found, FALSE if not found
	return signal && (!freq_listening.len || (signal.frequency in freq_listening))


/obj/machinery/telecomms/Initialize(mapload)
	. = ..()
	GLOB.telecomms_list += src
	if(mapload && autolinkers.len)
		return INITIALIZE_HINT_LATELOAD

/obj/machinery/telecomms/LateInitialize()
	..()
	for(var/obj/machinery/telecomms/T in (long_range_link ? GLOB.telecomms_list : urange(20, src, 1)))
		add_link(T)

/obj/machinery/telecomms/Destroy()
	GLOB.telecomms_list -= src
	for(var/obj/machinery/telecomms/comm in GLOB.telecomms_list)
		comm.links -= src
	links = list()
	return ..()

// Used in auto linking
/obj/machinery/telecomms/proc/add_link(obj/machinery/telecomms/T)
	var/turf/position = get_turf(src)
	var/turf/T_position = get_turf(T)
	if((position.z == T_position.z) || (long_range_link && T.long_range_link))
		if(src != T)
			for(var/x in autolinkers)
				if(x in T.autolinkers)
					links |= T
					T.links |= src

/obj/machinery/telecomms/update_icon()
	if(on)
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]_off"

/obj/machinery/telecomms/proc/update_power()
	if(toggled)
		// if powered, on. if not powered, off. if too damaged, off
		if(CHECK_BITFIELD(stat, (BROKEN | NOPOWER | EMPED)))
			on = FALSE
		else
			on = TRUE
	else
		on = FALSE

/obj/machinery/telecomms/process()
	update_power()

	// Check heat and generate some
	checkheat()

	// Update the icon
	update_icon()

	if(traffic > 0)
		traffic -= netspeed

/obj/machinery/telecomms/emp_act(severity)
	if(prob(100/severity))
		if(!CHECK_BITFIELD(stat, EMPED))
			ENABLE_BITFIELD(stat, EMPED)
			var/duration = (300 * 10)/severity
			spawn(rand(duration - 20, duration + 20)) // Takes a long time for the machines to reboot.
				DISABLE_BITFIELD(stat, EMPED)
	..()

/obj/machinery/telecomms/proc/checkheat()
	// Checks heat from the environment and applies any integrity damage
	var/datum/gas_mixture/environment = loc.return_air()
	var/damage_chance = 0                           // Percent based chance of applying 1 integrity damage this tick
	switch(environment.temperature)
		if((T0C + 40) to (T0C + 70))                // 40C-70C, minor overheat, 10% chance of taking damage
			damage_chance = 10
		if((T0C + 70) to (T0C + 130))				// 70C-130C, major overheat, 25% chance of taking damage
			damage_chance = 25
		if((T0C + 130) to (T0C + 200))              // 130C-200C, dangerous overheat, 50% chance of taking damage
			damage_chance = 50
		if((T0C + 200) to INFINITY)					// More than 200C, INFERNO. Takes damage every tick.
			damage_chance = 100
	if (damage_chance && prob(damage_chance))
		integrity = between(0, integrity - 1, 100)


	if(delay > 0)
		delay--
	else if(on)
		produce_heat()
		delay = initial(delay)

/obj/machinery/telecomms/proc/produce_heat()
	if (!produces_heat)
		return

	if (!use_power)
		return

	if(!(stat & (NOPOWER|BROKEN)))
		var/turf/simulated/L = loc
		if(istype(L))
			var/datum/gas_mixture/env = L.return_air()

			var/transfer_moles = 0.25 * env.total_moles

			var/datum/gas_mixture/removed = env.remove(transfer_moles)

			if(removed)

				var/heat_produced = idle_power_usage	//obviously can't produce more heat than the machine draws from it's power source
				if (traffic <= 0)
					heat_produced *= 0.30	//if idle, produce less heat.

				removed.add_thermal_energy(heat_produced)

			env.merge(removed)
/*
	The receiver idles and receives messages from subspace-compatible radio equipment;
	primarily headsets. They then just relay this information to all linked devices,
	which can would probably be network hubs.

	Link to Processor Units in case receiver can't send to bus units.
*/

/obj/machinery/telecomms/receiver
	name = "subspace receiver"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "broadcast receiver"
	desc = "This machine has a dish-like shape and green lights. It is designed to detect and process subspace radio activity."
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	idle_power_usage = 600
	produces_heat = 0
	circuit = /obj/item/circuitboard/telecomms/receiver

/obj/machinery/telecomms/receiver/Initialize()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/stock_parts/subspace/ansible(src)
	component_parts += new /obj/item/stock_parts/subspace/sub_filter(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/micro_laser(src)
	RefreshParts()

/obj/machinery/telecomms/receiver/receive_signal(datum/signal/subspace/signal)
	if(!on || !istype(signal) || !check_receive_level(signal) || signal.transmission_method != TRANSMISSION_SUBSPACE)
		return
	if(!is_freq_listening(signal))
		return

	signal.levels = list()

	// send the signal to the hub if possible, or a bus otherwise
	if(!relay_information(signal, /obj/machinery/telecomms/hub))
		relay_information(signal, /obj/machinery/telecomms/bus)

/obj/machinery/telecomms/receiver/proc/check_receive_level(datum/signal/subspace/signal)
	if (z in signal.levels)
		return TRUE

	for(var/obj/machinery/telecomms/hub/H in links)
		for(var/obj/machinery/telecomms/relay/R in H.links)
			if(R.can_receive(signal) && (R.z in signal.levels))
				return TRUE

	return FALSE


/*
	The HUB idles until it receives information. It then passes on that information
	depending on where it came from.

	This is the heart of the Telecommunications Network, sending information where it
	is needed. It mainly receives information from long-distance Relays and then sends
	that information to be processed. Afterwards it gets the uncompressed information
	from Servers/Buses and sends that back to the relay, to then be broadcasted.
*/

/obj/machinery/telecomms/hub
	name = "telecommunication hub"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "hub"
	desc = "A mighty piece of hardware used to send/receive massive amounts of data."
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	idle_power_usage = 1600
	long_range_link = TRUE
	netspeed = 40
	circuit = /obj/item/circuitboard/telecomms/hub

/obj/machinery/telecomms/hub/Initialize()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/stock_parts/subspace/sub_filter(src)
	component_parts += new /obj/item/stock_parts/subspace/sub_filter(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stack/cable_coil(src, 2)
	RefreshParts()

/obj/machinery/telecomms/hub/receive_information(datum/signal/signal, obj/machinery/telecomms/machine_from)
	if(!is_freq_listening(signal))
		return

	if(istype(machine_from, /obj/machinery/telecomms/receiver))
		// It's probably compressed so send it to the bus.
		relay_information(signal, /obj/machinery/telecomms/bus, TRUE)
	else
		// Send it to each relay so their levels get added...
		relay_information(signal, /obj/machinery/telecomms/relay)
		// Then broadcast that signal to
		relay_information(signal, /obj/machinery/telecomms/broadcaster)


/*
	The relay idles until it receives information. It then passes on that information
	depending on where it came from.

	The relay is needed in order to send information pass Z levels. It must be linked
	with a HUB, the only other machine that can send/receive pass Z levels.
*/

/obj/machinery/telecomms/relay
	name = "telecommunication relay"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "relay"
	desc = "A mighty piece of hardware used to send massive amounts of data far away."
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	idle_power_usage = 600
	produces_heat = 0
	netspeed = 5
	long_range_link = TRUE
	circuit = /obj/item/circuitboard/telecomms/relay
	var/broadcasting = TRUE
	var/receiving = TRUE
	var/listening_level /// so you can have a relay at z1 while it listens to z3. Optional

/obj/machinery/telecomms/relay/Initialize()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/stock_parts/subspace/sub_filter(src)
	component_parts += new /obj/item/stock_parts/subspace/sub_filter(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stack/cable_coil(src, 2)
	RefreshParts()

/obj/machinery/telecomms/relay/forceMove(newloc)
	. = ..(newloc)
	listening_level = z

/obj/machinery/telecomms/relay/receive_information(datum/signal/subspace/signal, obj/machinery/telecomms/machine_from)
	// Add our level and send it back
	var/turf/T = get_turf(src)
	if(can_send(signal) && T)
		signal.levels |= (listening_level ? listening_level : T.z)

// Checks to see if it can send/receive.

/obj/machinery/telecomms/relay/proc/can(datum/signal/signal)
	if(!on)
		return FALSE
	if(!is_freq_listening(signal))
		return FALSE
	return TRUE

/obj/machinery/telecomms/relay/proc/can_send(datum/signal/signal)
	if(!can(signal))
		return FALSE
	return broadcasting

/obj/machinery/telecomms/relay/proc/can_receive(datum/signal/signal)
	if(!can(signal))
		return FALSE
	return receiving

/*
	The bus mainframe idles and waits for hubs to relay them signals. They act
	as junctions for the network.

	They transfer uncompressed subspace packets to processor units, and then take
	the processed packet to a server for logging.

	Link to a subspace hub if it can't send to a server.
*/

/obj/machinery/telecomms/bus
	name = "bus mainframe"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "bus"
	desc = "A mighty piece of hardware used to send massive amounts of data quickly."
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	idle_power_usage = 1000
	netspeed = 40
	circuit = /obj/item/circuitboard/telecomms/bus
	var/change_frequency

/obj/machinery/telecomms/bus/Initialize()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/stock_parts/subspace/sub_filter(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stack/cable_coil(src, 1)
	RefreshParts()

/obj/machinery/telecomms/bus/receive_information(datum/signal/subspace/signal, obj/machinery/telecomms/machine_from)
	if(!istype(signal) || !is_freq_listening(signal))
		return

	if(change_frequency && signal.frequency != FREQ_SYNDICATE)
		signal.frequency = change_frequency

	if(!istype(machine_from, /obj/machinery/telecomms/processor) && machine_from != src) // Signal must be ready (stupid assuming machine), let's send it
		// send to one linked processor unit
		if(relay_information(signal, /obj/machinery/telecomms/processor))
			return

	// Try sending it!
	var/list/try_send = list(signal.server_type, /obj/machinery/telecomms/hub, /obj/machinery/telecomms/broadcaster)

	for(var/send in try_send)
		if(relay_information(signal, send))
			break


/*
	The processor is a very simple machine that decompresses subspace signals and
	transfers them back to the original bus. It is essential in producing audible
	data.

	Link to servers if bus is not present
*/

/obj/machinery/telecomms/processor
	name = "processor unit"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "processor"
	desc = "This machine is used to process large quantities of information."
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	idle_power_usage = 600
	delay = 5
	circuit = /obj/item/circuitboard/telecomms/processor
	var/process_mode = 1 // 1 = Uncompress Signals, 0 = Compress Signals

/obj/machinery/telecomms/processor/Initialize()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/stock_parts/subspace/sub_filter(src)
	component_parts += new /obj/item/stock_parts/subspace/treatment(src)
	component_parts += new /obj/item/stock_parts/subspace/treatment(src)
	component_parts += new /obj/item/stock_parts/subspace/amplifier(src)
	component_parts += new /obj/item/stock_parts/subspace/analyzer(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stack/cable_coil(src, 2)
	RefreshParts()

/obj/machinery/telecomms/processor/receive_information(datum/signal/subspace/signal, obj/machinery/telecomms/machine_from)
	if(!is_freq_listening(signal))
		return

	if (!process_mode)
		signal.data["compression"] = 100 // even more compressed signal
	else if (signal.data["compression"])
		signal.data["compression"] = 0 // uncompress subspace signal

	if(istype(machine_from, /obj/machinery/telecomms/bus))
		relay_direct_information(signal, machine_from) // send the signal back to the machine
	else // no bus detected - send the signal to servers instead
		relay_information(signal, signal.server_type)

/*
	The server logs all traffic and signal data. Once it records the signal, it sends
	it to the subspace broadcaster.

	Store a maximum of 100 logs and then deletes them.
*/

/obj/machinery/telecomms/server
	name = "telecommunication server"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "comm_server"
	desc = "A machine used to store data and network statistics."
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	idle_power_usage = 300
	circuit = /obj/item/circuitboard/telecomms/server
	var/list/log_entries = list()
	var/totaltraffic = 0 // gigabytes (if > 1024, divide by 1024 -> terrabytes)
	/// ntsc is kill. delete this
	var/list/stored_names = list()
	var/list/TrafficActions = list()
	var/logs = 0 // number of logs

	var/list/memory = list()	// stored memory
	var/rawcode = ""	// the code to compile (raw text)
	var/autoruncode = 0		// 1 if the code is set to run every time a signal is picked up

	var/encryption = "null" // encryption key: ie "password"
	var/salt = "null"		// encryption salt: ie "123comsat"
							// would add up to md5("password123comsat")
	var/language = "human"
	var/obj/item/radio/headset/server_radio = null

/obj/machinery/telecomms/server/Initialize()
	. = ..()
	component_parts = list()
	component_parts += new /obj/item/stock_parts/subspace/sub_filter(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stock_parts/manipulator(src)
	component_parts += new /obj/item/stack/cable_coil(src, 1)
	RefreshParts()

/obj/machinery/telecomms/server/receive_information(datum/signal/subspace/vocal/signal, obj/machinery/telecomms/machine_from)
	// can't log non-vocal signals
	if(!istype(signal) || !signal.data["message"] || !is_freq_listening(signal))
		return

	if(traffic > 0)
		totaltraffic += traffic // add current traffic to total traffic

	// Delete particularly old logs
	if(LAZYLEN(log_entries) >= 400) //[list].len is not safe
		log_entries.Cut(1, 2)

	var/datum/comm_log_entry/log = new
	log.parameters["mobtype"] = signal.virt.source.type
	log.parameters["name"] = signal.data["name"]
	log.parameters["job"] = signal.data["job"]
	log.parameters["message"] = signal.data["message"]
	log.parameters["language"] = signal.language

	// If the signal is still compressed, make the log entry gibberish
	var/compression = signal.data["compression"]
	if(compression > 0)
		log.input_type = "Corrupt File"
		log.parameters["name"] = Gibberish(signal.data["name"], compression + 50)
		log.parameters["job"] = Gibberish(signal.data["job"], compression + 50)
		log.parameters["message"] = Gibberish(signal.data["message"], compression + 50)

	// Give the log a name and store it
	var/identifier = num2text( rand(-1000,1000) + world.time )
	log.name = "data packet ([md5(identifier)])"
	log_entries.Add(log)

	var/can_send = relay_information(signal, /obj/machinery/telecomms/hub)
	if(!can_send)
		relay_information(signal, /obj/machinery/telecomms/broadcaster)

/obj/machinery/telecomms/server/proc/setcode(var/t)
	if(t)
		if(istext(t))
			rawcode = t
/*
/obj/machinery/telecomms/server/proc/update_logs()
	// start deleting the very first log entry
	if(logs >= 400)
		for(var/i = 1, i <= logs, i++) // locate the first garbage collectable log entry and remove it
			var/datum/comm_log_entry/L = log_entries[i]
			if(L.garbage_collector)
				log_entries.Remove(L)
				logs--
				break
*/
// Simple log entry datum
/datum/comm_log_entry
	var/input_type = "Speech File"
	var/name = "data packet (#)"
	var/parameters = list()  // copied from signal.data above

//Generic telecomm connectivity test proc
/*
/proc/can_telecomm(var/atom/A, var/atom/B, var/ad_hoc = FALSE)
	if(!A || !B)
		log_debug("can_telecomm(): Undefined endpoints!")
		return FALSE

	//Can't in this case, obviously!
	if(is_jammed(A) || is_jammed(B))
		return FALSE

	//Items don't have a Z when inside an object or mob
	var/turf/src_turf = get_turf(A)
	var/turf/dst_turf = get_turf(B)

	//Nullspace, probably.
	if(!src_turf || !dst_turf)
		return FALSE

	var/src_z = src_turf.z
	var/dst_z = dst_turf.z

	//Mysterious!
	if(!src_z || !dst_z)
		return FALSE

	//We can do the simple check first, if you have ad_hoc radios.
	if(ad_hoc && src_z == dst_z)
		return TRUE

	//Let's look at hubs and see what we got.
	var/can_comm = FALSE
	for(var/obj/machinery/telecomms/hub/H in telecomms_list)
		if((src_z in H.telecomms_map) && (dst_z in H.telecomms_map))
			can_comm = TRUE
			break

	return can_comm
*/