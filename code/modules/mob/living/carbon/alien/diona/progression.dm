/mob/living/carbon/alien/diona/confirm_evolution()
	if(!Configuration.check_species_whitelist(SPECIES_ID_DIONA, ckey))
		alert(src, "You are currently not whitelisted to play as a full diona.", "Evolution Error")
		return

	if(amount_grown < max_grown)
		to_chat(src, "You are not yet ready for your growth...")
		return

	src.diona_split()

	if(istype(loc,/obj/item/holder/diona))
		var/obj/item/holder/diona/L = loc
		forceMove(L.loc)
		qdel(L)

	src.visible_message("<font color='red'>[src] begins to shift and quiver, and erupts in a shower of shed bark as it splits into a tangle of nearly a dozen new dionaea.</font>","<font color='red'>You begin to shift and quiver, feeling your awareness splinter. All at once, we consume our stored nutrients to surge with growth, splitting into a tangle of at least a dozen new dionaea. We have attained our gestalt form.</font>")
	return SPECIES_DIONA
