/obj/item/sample
	name = "forensic sample"
	icon = 'icons/obj/forensics.dmi'
	atom_flags = NOPRINT
	w_class = WEIGHT_CLASS_TINY
	var/list/evidence = list()

/obj/item/sample/Initialize(mapload, atom/supplied)
	. = ..()
	if(supplied)
		copy_evidence(supplied)
		name = "[initial(name)] (\the [supplied])"

/obj/item/sample/print/Initialize(mapload, atom/supplied)
	. = ..()
	if(evidence && evidence.len)
		icon_state = "fingerprint1"

/obj/item/sample/proc/copy_evidence(var/atom/supplied)
	if(supplied.suit_fibers && supplied.suit_fibers.len)
		evidence = supplied.suit_fibers.Copy()
		supplied.suit_fibers.Cut()

/obj/item/sample/proc/merge_evidence(var/obj/item/sample/supplied, var/mob/user)
	if(!supplied.evidence || !supplied.evidence.len)
		return 0
	evidence |= supplied.evidence
	name = "[initial(name)] (combined)"
	to_chat(user, "<span class='notice'>You transfer the contents of \the [supplied] into \the [src].</span>")
	return 1

/obj/item/sample/print/merge_evidence(var/obj/item/sample/supplied, var/mob/user)
	if(!supplied.evidence || !supplied.evidence.len)
		return 0
	for(var/print in supplied.evidence)
		if(evidence[print])
			evidence[print] = stringmerge(evidence[print],supplied.evidence[print])
		else
			evidence[print] = supplied.evidence[print]
	name = "[initial(name)] (combined)"
	to_chat(user, "<span class='notice'>You overlay \the [src] and \the [supplied], combining the print records.</span>")
	return 1

/obj/item/sample/attackby(var/obj/O, var/mob/user)
	if(O.type == src.type)
		if(merge_evidence(O, user))
			qdel(O)
		return CLICKCHAIN_DO_NOT_PROPAGATE
	return ..()

/obj/item/sample/fibers
	name = "fiber bag"
	desc = "Used to hold fiber evidence for the detective."
	icon_state = "fiberbag"

/obj/item/sample/print
	name = "fingerprint card"
	desc = "Records a set of fingerprints."
	icon = 'icons/obj/card.dmi'
	icon_state = "fingerprint0"
	item_state = "paper"

/obj/item/sample/print/attack_self(mob/user, datum/event_args/actor/actor)
	. = ..()
	if(.)
		return
	if(evidence && evidence.len)
		return
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/obj/item/wearing_gloves = H.inventory.get_slot_single(/datum/inventory_slot/inventory/gloves::id)
	if(wearing_gloves)
		to_chat(user, "<span class='warning'>Take \the [wearing_gloves] off first.</span>")
		return

	to_chat(user, "<span class='notice'>You firmly press your fingertips onto the card.</span>")
	var/fullprint = H.get_full_print()
	evidence[fullprint] = fullprint
	name = "[initial(name)] (\the [H])"
	icon_state = "fingerprint1"

/obj/item/sample/print/legacy_mob_melee_hook(mob/target, mob/user, clickchain_flags, list/params, mult, target_zone, intent)
	if(!ishuman(target) || user.a_intent == INTENT_HARM)
		return ..()
	. = CLICKCHAIN_DO_NOT_PROPAGATE
	if(evidence && evidence.len)
		user.action_feedback(SPAN_WARNING("[src] is full!"), src)
		return

	var/mob/living/carbon/human/H = target

	if(H.gloves)
		to_chat(user, "<span class='warning'>\The [H] is wearing gloves.</span>")
		return

	if(user != H && H.a_intent != "help" && !H.lying)
		user.visible_message("<span class='danger'>\The [user] tries to take prints from \the [H], but they move away.</span>")
		return

	if(user.zone_sel.selecting == "r_hand" || user.zone_sel.selecting == "l_hand")
		var/has_hand
		var/obj/item/organ/external/O = H.organs_by_name["r_hand"]
		if(istype(O) && !O.is_stump())
			has_hand = 1
		else
			O = H.organs_by_name["l_hand"]
			if(istype(O) && !O.is_stump())
				has_hand = 1
		if(!has_hand)
			to_chat(user, "<span class='warning'>They don't have any hands.</span>")
			return
		user.visible_message("[user] takes a copy of \the [H]'s fingerprints.")
		var/fullprint = H.get_full_print()
		evidence[fullprint] = fullprint
		copy_evidence(src)
		name = "[initial(name)] (\the [H])"
		icon_state = "fingerprint1"

/obj/item/sample/print/copy_evidence(var/atom/supplied)
	if(supplied.fingerprints && supplied.fingerprints.len)
		for(var/print in supplied.fingerprints)
			evidence[print] = supplied.fingerprints[print]
		supplied.fingerprints.Cut()

/obj/item/forensics
	atom_flags = NOPRINT

/obj/item/forensics/sample_kit
	name = "fiber collection kit"
	desc = "A magnifying glass and tweezers. Used to lift suit fibers."
	icon_state = "m_glass"
	w_class = WEIGHT_CLASS_SMALL
	var/evidence_type = "fiber"
	var/evidence_path = /obj/item/sample/fibers

/obj/item/forensics/sample_kit/proc/can_take_sample(var/mob/user, var/atom/supplied)
	return (supplied.suit_fibers && supplied.suit_fibers.len)

/obj/item/forensics/sample_kit/proc/take_sample(var/mob/user, var/atom/supplied)
	var/obj/item/sample/S = new evidence_path(get_turf(user), supplied)
	to_chat(user, "<span class='notice'>You transfer [S.evidence.len] [S.evidence.len > 1 ? "[evidence_type]s" : "[evidence_type]"] to \the [S].</span>")

/obj/item/forensics/sample_kit/afterattack(atom/target, mob/user, clickchain_flags, list/params)
	if(!(clickchain_flags & CLICKCHAIN_HAS_PROXIMITY))
		return
	add_fingerprint(user)
	if(can_take_sample(user, target))
		take_sample(user,target)
		return 1
	else
		to_chat(user, "<span class='warning'>You are unable to locate any [evidence_type]s on \the [target].</span>")
		return ..()

/obj/item/forensics/sample_kit/powder
	name = "fingerprint powder"
	desc = "A jar containing aluminum powder and a specialized brush."
	icon_state = "dust"
	evidence_type = "fingerprint"
	evidence_path = /obj/item/sample/print

/obj/item/forensics/sample_kit/powder/can_take_sample(var/mob/user, var/atom/supplied)
	return (supplied.fingerprints && supplied.fingerprints.len)
