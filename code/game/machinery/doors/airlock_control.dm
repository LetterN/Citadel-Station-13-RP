#define AIRLOCK_CONTROL_RANGE 22 // 5 on main

// This code allows for airlocks to be controlled externally by setting an id_tag and comm frequency (disables ID access)
/obj/machinery/door/airlock
	var/id_tag
	var/frequency
	var/datum/radio_frequency/radio_connection
	var/shockedby = list()

/obj/machinery/door/airlock/receive_signal(datum/signal/signal)
	if (!arePowerSystemsOn())
		return //no power

	if(!signal)
		return

	if(id_tag != signal.data["tag"] || !signal.data["command"])
		return

	switch(signal.data["command"])
		if("open")
			open(TRUE)

		if("close")
			close(TRUE)

		if("unlock")
			unlock()

		if("lock")
			lock()

		if("secure_open")
			unlock()

			sleep(2)
			open(TRUE)

			lock()

		if("secure_close")
			unlock()
			close(TRUE)

			lock()
			sleep(2)

	send_status()


/obj/machinery/door/airlock/proc/send_status() //did it do a 200 OK?
	if(radio_connection)
		var/datum/signal/signal = new(list(
			"tag" = id_tag,
			"timestamp" = world.time,
			"door_status" = density ? "closed" : "open",
			"lock_status" = locked ? "locked" : "unlocked"
		))
		radio_connection.post_signal(src, signal, range = AIRLOCK_CONTROL_RANGE, filter = RADIO_AIRLOCK)


/obj/machinery/door/airlock/open(surpress_send)
	. = ..()
	if(!surpress_send)
		send_status()


/obj/machinery/door/airlock/close(surpress_send)
	. = ..()
	if(!surpress_send)
		send_status()

/obj/machinery/door/airlock/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	if(new_frequency)
		frequency = new_frequency
		radio_connection = SSradio.add_object(src, frequency, RADIO_AIRLOCK)

/obj/machinery/door/airlock/Initialize()
	. = ..()
	if(frequency)
		set_frequency(frequency)

	update_icon()

/obj/machinery/door/airlock/Destroy()
	if(frequency)
		SSradio.remove_object(src,frequency)
	return ..()

/obj/machinery/airlock_sensor
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "airlock_sensor_off"
	name = "airlock sensor"
	desc = "Sends atmospheric readings to a nearby controller."

	anchored = 1
	power_channel = ENVIRON

	var/id_tag
	var/master_tag
	var/frequency = FREQ_AIRLOCK_CONTROL

	var/datum/radio_frequency/radio_connection

	var/command = "cycle"

	var/on = TRUE
	var/alert = FALSE
	var/previousPressure

/obj/machinery/airlock_sensor/update_icon()
	if(on)
		if(alert)
			icon_state = "airlock_sensor_alert"
		else
			icon_state = "airlock_sensor_standby"
	else
		icon_state = "airlock_sensor_off"

/obj/machinery/airlock_sensor/attack_hand(mob/user)
	var/datum/signal/signal = new(list(
		"tag" = master_tag,
		"command" = command
	))

	radio_connection.post_signal(src, signal, range = AIRLOCK_CONTROL_RANGE, filter = RADIO_AIRLOCK)
	flick("airlock_sensor_cycle", src)

/obj/machinery/airlock_sensor/process()
	if(on)
		var/datum/gas_mixture/air_sample = return_air()
		var/pressure = round(air_sample.return_pressure(),0.1)

		if(abs(pressure - previousPressure) > 0.001 || previousPressure == null)
			alert = (pressure < ONE_ATMOSPHERE*0.8)
			var/datum/signal/signal = new(list(
				"tag" = id_tag,
				"timestamp" = world.time,
				"pressure" = num2text(pressure)
			))
			radio_connection.post_signal(src, signal, range = AIRLOCK_CONTROL_RANGE, filter = RADIO_AIRLOCK)

			previousPressure = pressure
			update_icon()

/obj/machinery/airlock_sensor/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, RADIO_AIRLOCK)

/obj/machinery/airlock_sensor/Initialize()
	. = ..()
	set_frequency(frequency)

/obj/machinery/airlock_sensor/Destroy()
	SSradio.remove_object(src,frequency)
	return ..()

/obj/machinery/airlock_sensor/airlock_interior
	command = "cycle_interior"

/obj/machinery/airlock_sensor/airlock_exterior
	command = "cycle_exterior"

// Return the air from the turf in "front" of us (Used in shuttles, so it can be in the shuttle area but sense outside it)
/obj/machinery/airlock_sensor/airlock_exterior/shuttle/return_air()
	var/turf/T = get_step(src, dir)
	if(isnull(T))
		return ..()
	return T.return_air()

/obj/machinery/access_button
	icon = 'icons/obj/airlock_machines.dmi'
	icon_state = "access_button_standby"
	name = "access button"

	anchored = 1
	power_channel = ENVIRON

	var/master_tag
	var/frequency = FREQ_AIRLOCK_CONTROL

	var/datum/radio_frequency/radio_connection

	var/command = "cycle"

	var/on = TRUE

/obj/machinery/access_button/update_icon()
	if(on)
		icon_state = "access_button_standby"
	else
		icon_state = "access_button_off"

/obj/machinery/access_button/attackby(obj/item/I, mob/user)
	//Swiping ID on the access button
	if (istype(I, /obj/item/card/id) || istype(I, /obj/item/pda))
		attack_hand(user)
		return
	..()

/obj/machinery/access_button/attack_hand(mob/user)
	add_fingerprint(usr)
	if(!allowed(user))
		to_chat(user, "<span class='warning'>Access Denied</span>")

	else if(radio_connection)
		var/datum/signal/signal = new(list(
			"tag" = master_tag,
			"command" = command
		))

		radio_connection.post_signal(src, signal, range = AIRLOCK_CONTROL_RANGE, filter = RADIO_AIRLOCK)
	flick("access_button_cycle", src)

obj/machinery/access_button/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, RADIO_AIRLOCK)


/obj/machinery/access_button/Initialize()
	. = ..()
	set_frequency(frequency)

/obj/machinery/access_button/Destroy()
	SSradio.remove_object(src,frequency)
	return ..()

/obj/machinery/access_button/airlock_interior
	frequency = 1379
	command = "cycle_interior"

/obj/machinery/access_button/airlock_exterior
	frequency = 1379
	command = "cycle_exterior"
