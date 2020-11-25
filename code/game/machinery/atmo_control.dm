/obj/machinery/air_sensor
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "gsensor1"
	name = "Gas Sensor"

	anchored = 1
	var/state = 0
	var/on = TRUE

	var/id_tag
	var/frequency = FREQ_ATMOS_STORAGE
	var/datum/radio_frequency/radio_connection

	var/output = 3 //depricated var, do not use.

/obj/machinery/air_sensor/update_icon()
	icon_state = "gsensor[on]"

/obj/machinery/air_sensor/process()
	if(on)
		var/datum/gas_mixture/air_sample = return_air()

		var/datum/signal/signal = new(list(
			"sigtype" = "status",
			"id_tag" = id_tag, //tg packet
			"tag" = id_tag, //compatability packet
			"timestamp" = world.time,
			"pressure" = air_sample.return_pressure(),
			"temperature" = air_sample.temperature,
			"gases" = list()
		))

		var/total_moles = air_sample.total_moles
		signal.data["oxygen"] = round(100*air_sample.gas[/datum/gas/oxygen]/total_moles,0.1)
		signal.data["phoron"] = round(100*air_sample.gas[/datum/gas/phoron]/total_moles,0.1)
		signal.data["nitrogen"] = round(100*air_sample.gas[/datum/gas/nitrogen]/total_moles,0.1)
		signal.data["carbon_dioxide"] = round(100*air_sample.gas[/datum/gas/carbon_dioxide]/total_moles,0.1)

		radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

/obj/machinery/air_sensor/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, RADIO_TO_AIRALARM)

/obj/machinery/air_sensor/Initialize()
	. = ..()
	set_frequency(frequency)

/obj/machinery/air_sensor/Destroy()
	SSradio.remove_object(src, frequency)
	return ..()

/////////////////////////////////////////////////////////////
// GENERAL AIR CONTROL (a.k.a atmos computer)
/////////////////////////////////////////////////////////////
/obj/machinery/computer/general_air_control
	name = "atmospherics monitoring"
	desc = "Used to monitor the station's atmospherics sensors."
	icon_keyboard = "atmos_key"
	icon_screen = "tank"
	circuit = /obj/item/circuitboard/air_management

	var/frequency = FREQ_ATMOS_STORAGE
	var/list/sensors = list()
	var/list/sensor_information = list()
	var/datum/radio_frequency/radio_connection


/obj/machinery/computer/general_air_control/Initialize()
	. = ..()
	set_frequency(frequency)

/obj/machinery/computer/general_air_control/Destroy()
	SSradio.remove_object(src, frequency)
	return ..()

/obj/machinery/computer/general_air_control/attack_hand(mob/user)
	if(..(user))
		return

	ui_interact(user)

/obj/machinery/computer/general_air_control/receive_signal(datum/signal/signal)
	if(!signal)
		return

	var/id_tag = signal.data["tag"] //id_tag in tg.
	if(!id_tag || !sensors.Find(id_tag))
		return

	sensor_information[id_tag] = signal.data

/obj/machinery/computer/general_air_control/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	user.set_machine(src)

	var/list/data = list()
	var/sensors_ui[0]
	if(sensors.len)
		for(var/id_tag in sensors)
			var/long_name = sensors[id_tag]
			var/list/sensor_data = sensor_information[id_tag]
			sensors_ui[++sensors_ui.len] = list("long_name" = long_name, "sensor_data" = sensor_data)
	else
		sensors_ui = null

	data["sensors"] = sensors_ui

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "atmo_control.tmpl", name, 525, 600)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(5)

/obj/machinery/computer/general_air_control/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	radio_connection = SSradio.add_object(src, frequency, RADIO_ATMOSIA)

/////////////////////////////////////////////////////////////
// LARGE TANK CONTROL
/////////////////////////////////////////////////////////////

/obj/machinery/computer/general_air_control/large_tank_control
	var/input_tag
	var/output_tag
	icon = 'icons/obj/computer.dmi'
	frequency = FREQ_ATMOS_STORAGE
	circuit = /obj/item/circuitboard/air_management/tank_control

	var/list/input_info
	var/list/output_info

	var/input_flow_setting = 200
	var/pressure_setting = ONE_ATMOSPHERE * 45

/obj/machinery/computer/general_air_control/large_tank_control/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	user.set_machine(src)

	var/list/data = list()
	var/sensors_ui[0]
	if(sensors.len)
		for(var/id_tag in sensors)
			var/long_name = sensors[id_tag]
			var/list/sensor_data = sensor_information[id_tag]
			sensors_ui[++sensors_ui.len] = list("long_name" = long_name, "sensor_data" = sensor_data)
	else
		sensors_ui = null

	data["sensors"] = sensors_ui
	data["tanks"] = 1

	if(input_info)
		data["input_info"] = list("power" = input_info["power"], "volume_rate" = round(input_info["volume_rate"], 0.1))
	else
		data["input_info"] = null

	if(output_info)
		data["output_info"] = list("power" = output_info["power"], "output_pressure" = output_info["internal"])
	else
		data["output_info"] = null

	data["input_flow_setting"] = round(input_flow_setting, 0.1)
	data["pressure_setting"] = pressure_setting

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "atmo_control.tmpl", name, 660, 500)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(5)

/obj/machinery/computer/general_air_control/large_tank_control/receive_signal(datum/signal/signal)
	if(!signal)
		return

	var/id_tag = signal.data["tag"]

	if(input_tag == id_tag)
		input_info = signal.data
	else if(output_tag == id_tag)
		output_info = signal.data
	else
		..(signal)

/obj/machinery/computer/general_air_control/large_tank_control/Topic(href, href_list)
	if(..())
		return TRUE

	if(href_list["adj_pressure"])
		var/change = text2num(href_list["adj_pressure"])
		pressure_setting = between(0, pressure_setting + change, 50*ONE_ATMOSPHERE)
		return TRUE

	if(href_list["adj_input_flow_rate"])
		var/change = text2num(href_list["adj_input_flow_rate"])
		input_flow_setting = between(0, input_flow_setting + change, ATMOS_DEFAULT_VOLUME_PUMP + 500) //default flow rate limit for air injectors
		return TRUE

	if(!radio_connection)
		return
	var/datum/signal/signal = new(list("sigtype" = "command", "user" = usr))
	if(href_list["in_refresh_status"])
		input_info = null
		signal.data += list("tag" = input_tag, "status" = TRUE)
		. = TRUE

	if(href_list["in_toggle_injector"])
		input_info = null
		signal.data += list("tag" = input_tag, "power_toggle" = TRUE)
		. = TRUE

	if(href_list["in_set_flowrate"])
		input_info = null
		signal.data += list("tag" = input_tag, "set_volume_rate" = input_flow_setting)
		. = TRUE

	if(href_list["out_refresh_status"])
		output_info = null
		signal.data += list("tag" = output_tag, "status" = TRUE)
		. = TRUE

	if(href_list["out_toggle_power"])
		output_info = null
		signal.data += list("tag" = output_tag, "power_toggle" = TRUE)
		. = TRUE

	if(href_list["out_set_pressure"])
		output_info = null
		signal.data += list("tag" = output_tag, "set_internal_pressure" = pressure_setting)
		. = TRUE

	radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

/obj/machinery/computer/general_air_control/supermatter_core
	icon = 'icons/obj/computer.dmi'
	frequency = 1438
	var/input_tag
	var/output_tag
	var/list/input_info
	var/list/output_info
	var/input_flow_setting = 700
	var/pressure_setting = 100
	circuit = /obj/item/circuitboard/air_management/supermatter_core

/obj/machinery/computer/general_air_control/supermatter_core/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	user.set_machine(src)

	var/list/data = list()
	var/sensors_ui[0]
	if(sensors.len)
		for(var/id_tag in sensors)
			var/long_name = sensors[id_tag]
			var/list/sensor_data = sensor_information[id_tag]
			sensors_ui[++sensors_ui.len] = list("long_name" = long_name, "sensor_data" = sensor_data)
	else
		sensors_ui = null

	data["sensors"] = sensors_ui
	data["core"] = 1

	if(input_info)
		data["input_info"] = list("power" = input_info["power"], "volume_rate" = round(input_info["volume_rate"], 0.1))
	else
		data["input_info"] = null
	if(output_info)
		data["output_info"] = list("power" = output_info["power"], "pressure_limit" = output_info["external"])
	else
		data["output_info"] = null

	data["input_flow_setting"] = round(input_flow_setting, 0.1)
	data["pressure_setting"] = pressure_setting

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "atmo_control.tmpl", name, 650, 500)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(5)

/obj/machinery/computer/general_air_control/supermatter_core/receive_signal(datum/signal/signal)
	if(!signal)
		return

	var/id_tag = signal.data["tag"]

	if(input_tag == id_tag)
		input_info = signal.data
	else if(output_tag == id_tag)
		output_info = signal.data
	else
		..(signal)

/obj/machinery/computer/general_air_control/supermatter_core/Topic(href, href_list)
	if(..())
		return TRUE

	if(href_list["adj_pressure"])
		var/change = text2num(href_list["adj_pressure"])
		pressure_setting = between(0, pressure_setting + change, 10*ONE_ATMOSPHERE)
		return TRUE

	if(href_list["adj_input_flow_rate"])
		var/change = text2num(href_list["adj_input_flow_rate"])
		input_flow_setting = between(0, input_flow_setting + change, ATMOS_DEFAULT_VOLUME_PUMP + 500) //default flow rate limit for air injectors
		return TRUE

	if(!radio_connection)
		return
	var/datum/signal/signal = new(list("sigtype" = "command", "user" = usr))
	if(href_list["in_refresh_status"])
		input_info = null
		signal.data += list("tag" = input_tag, "status" = TRUE)
		. = TRUE

	if(href_list["in_toggle_injector"])
		input_info = null
		signal.data += list("tag" = input_tag, "power_toggle" = TRUE)
		. = TRUE

	if(href_list["in_set_flowrate"])
		input_info = null
		signal.data += list("tag" = input_tag, "set_volume_rate" = input_flow_setting)
		. = TRUE

	if(href_list["out_refresh_status"])
		output_info = null
		signal.data += list("tag" = input_tag, "status" = TRUE)
		. = TRUE

	if(href_list["out_toggle_power"])
		output_info = null
		signal.data += list("tag" = input_tag, "power_toggle" = TRUE)
		. = TRUE

	if(href_list["out_set_pressure"])
		output_info = null
		signal.data += list("tag" = input_tag, "set_external_pressure" = pressure_setting, "checks" = TRUE)
		. = TRUE

	radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

/obj/machinery/computer/general_air_control/fuel_injection
	icon = 'icons/obj/computer.dmi'
	icon_screen = "alert:0"
	var/device_tag
	var/list/device_info
	var/automation = 0
	var/cutoff_temperature = 2000
	var/on_temperature = 1200
	circuit = /obj/item/circuitboard/air_management/injector_control

/obj/machinery/computer/general_air_control/fuel_injection/process()
	if(automation)
		if(!radio_connection)
			return 0

		var/injecting = 0
		for(var/id_tag in sensor_information)
			var/list/data = sensor_information[id_tag]
			if(data["temperature"])
				if(data["temperature"] >= cutoff_temperature)
					injecting = 0
					break
				if(data["temperature"] <= on_temperature)
					injecting = 1

		var/datum/signal/signal = new(list(
			"tag" = device_tag,
			"power" = injecting,
			"sigtype" = "command"
		))
		radio_connection.post_signal(src, signal, radio_filter = RADIO_ATMOSIA)

	..()

/obj/machinery/computer/general_air_control/fuel_injection/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	user.set_machine(src)

	var/list/data = list()
	var/sensors_ui[0]
	if(sensors.len)
		for(var/id_tag in sensors)
			var/long_name = sensors[id_tag]
			var/list/sensor_data = sensor_information[id_tag]
			sensors_ui[++sensors_ui.len] = list("long_name" = long_name, "sensor_data" = sensor_data)
	else
		sensors_ui = null

	data["sensors"] = sensors_ui
	data["fuel"] = 1
	data["automation"] = automation

	if(device_info)
		data["device_info"] = list("power" = device_info["power"], "volume_rate" = device_info["volume_rate"])
	else
		data["device_info"] = null

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "atmo_control.tmpl", name, 650, 500)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(5)

/obj/machinery/computer/general_air_control/fuel_injection/receive_signal(datum/signal/signal)
	if(!signal)
		return

	var/id_tag = signal.data["tag"]

	if(device_tag == id_tag)
		device_info = signal.data
	else
		..(signal)

/obj/machinery/computer/general_air_control/fuel_injection/Topic(href, href_list)
	if(..())
		return

	if(href_list["refresh_status"])
		device_info = null
		if(!radio_connection)
			return

		var/datum/signal/signal = new(list(
			"sigtype" = "command",
			"user" = usr,
			"tag" = device_tag,
			"status" = TRUE
		))
		radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

	if(href_list["toggle_automation"])
		automation = !automation

	if(href_list["toggle_injector"])
		device_info = null
		if(!radio_connection)
			return

		var/datum/signal/signal = new(list(
			"sigtype" = "command",
			"user" = usr,
			"tag" = device_tag,
			"power_toggle" = TRUE
		))
		radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)

	if(href_list["injection"])
		if(!radio_connection)
			return

		var/datum/signal/signal = new(list(
			"sigtype" = "command",
			"user" = usr,
			"tag" = device_tag,
			"inject" = TRUE
		))
		radio_connection.post_signal(src, signal, filter = RADIO_ATMOSIA)
