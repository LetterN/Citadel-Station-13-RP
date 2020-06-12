#define STATE_DEFAULT 1
#define STATE_INJECTOR  2
#define STATE_ENGINE 3


/obj/machinery/computer/am_engine
	name = "Antimatter Engine Console"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "comm_computer"
	req_access = list(ACCESS_ENGINE)

	var/engine_id = 0
	var/authenticated = 0
	var/obj/machinery/power/am_engine/engine/connected_E = null
	var/obj/machinery/power/am_engine/injector/connected_I = null
	var/state = STATE_DEFAULT

/obj/machinery/computer/am_engine/Initialize()
	. = ..()

	scan_engine(machines)

/obj/machinery/computer/am_engine/proc/scan_engine(list/where = orange(8))
	//flush this
	connected_E = null
	connected_I = null
	//then we scan nearby
	for(var/obj/machinery/power/am_engine/engine/E in where)
		if(E.engine_id == src.engine_id)
			src.connected_E = E
	for(var/obj/machinery/power/am_engine/injector/I in where) 
		if(I.engine_id == src.engine_id)
			src.connected_I = I

/obj/machinery/computer/am_engine/Topic(href, href_list)
	if(..())
		return

	usr.set_machine(src)

	if(!href_list["operation"])
		return
	switch(href_list["operation"])
		// main interface
		if("activate")
			connected_E.engine_process()
		if("engine")
			state = STATE_ENGINE
		if("injector")
			state = STATE_INJECTOR
		if("main")
			state = STATE_DEFAULT
		if("deactivate")
			connected_E.stopping = TRUE
		if("login")
			var/mob/living/carbon/human/M = usr
			if(!istype(M))
				return
			var/obj/item/card/id/I = M.get_idcard() //argh, why are you on human level?
			if(!I || !istype(I))
				return
			if(check_access(I))
				authenticated = TRUE
		if("logout")
			authenticated = FALSE

	updateUsrDialog()

/obj/machinery/computer/am_engine/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/computer/am_engine/attack_paw(mob/user)
	return attack_hand(user)

/obj/machinery/computer/am_engine/attack_hand(mob/user)
	if(..())
		return
	user.set_machine(src)

	var/dat += "<br>\[[(state != STATE_DEFAULT) ? "<a href='?src=[REF(src)];operation=main'>Main Menu</a> | " : " "]<a href='?src=[REF(user)];mach_close=am_engine'>Close</a> \]"

	switch(state)
		if(STATE_DEFAULT)
			if(authenticated)
				dat += "<a href='?src=[REF(src)];operation=logout'>Log Out</a><br>"
				dat += "<h3>General Functions:</h3>"
				dat += "<br><a href='?src=[REF(src)];operation=engine'>Engine Menu</a>"
				dat += "<br><a href='?src=[REF(src)];operation=injector'>Injector Menu</a>"
			else
				dat += "<a href='?src=[REF(src)];operation=login'>Log In</a>"
		if(STATE_INJECTOR)
			if(connected_I)
				if(connected_I.injecting)
					dat += "<br>\[ Injecting \]<br>"
				else
					dat += "<br>\[ Injecting not in progress \]<br>"
			else
				dat += "<br>ERROR! NO INJECTOR CONNECTED"
		if(STATE_ENGINE)
			if(connected_E)
				if(connected_E.stopping)
					dat += "<br>\[ <span class='warning'>STOPPING</span> \]"
				else if(connected_E.operating && !connected_E.stopping)
					dat += "<br><a href='?src=[REF(src)];operation=deactivate'>Emergency Shutdown</a>"
				else
					dat += "<br><a href='?src=[REF(src)];operation=activate'>Activate Engine</a>"

				dat += "<br>Contents:<br>[connected_E.H_fuel]kg of Hydrogen<br>[connected_E.antiH_fuel]kg of Anti-Hydrogen<br>"
			else
				dat += "<br>ERROR! NO ENGINE CONNECTED"

	var/datum/browser/popup = new(user, "am_engine", "Engine Computer", 400, 500)
	popup.set_content(dat)
	popup.open()
	return
