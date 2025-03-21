/obj/item/clothing/mask/breath
	desc = "A close-fitting mask that can be connected to an air supply."
	name = "breath mask"
	icon_state = "breath"
	item_state_slots = list(SLOT_ID_RIGHT_HAND = "breath", SLOT_ID_LEFT_HAND = "breath")
	clothing_flags = ALLOWINTERNALS|FLEXIBLEMATERIAL
	body_cover_flags = FACE
	w_class = WEIGHT_CLASS_SMALL
	gas_transfer_coefficient = 0.10
	permeability_coefficient = 0.50
	var/hanging = 0
	item_action_name = "Adjust Breath Mask"


/obj/item/clothing/mask/breath/proc/adjust_mask(mob/user)
	if(!user.incapacitated() && !user.restrained() && !user.stat)
		hanging = !hanging
		if (hanging)
			gas_transfer_coefficient = 1
			set_body_cover_flags(body_cover_flags & ~FACE)
			clothing_flags = clothing_flags & ~ALLOWINTERNALS
			icon_state = "breathdown"
			to_chat(user, "Your mask is now hanging on your neck.")
		else
			gas_transfer_coefficient = initial(gas_transfer_coefficient)
			set_body_cover_flags(initial(body_cover_flags))
			clothing_flags = initial(clothing_flags)
			icon_state = initial(icon_state)
			to_chat(user, "You pull the mask up to cover your face.")
		update_worn_icon()

/obj/item/clothing/mask/breath/attack_self(mob/user, datum/event_args/actor/actor)
	. = ..()
	if(.)
		return
	adjust_mask(user)

/obj/item/clothing/mask/breath/verb/toggle()
		set category = VERB_CATEGORY_OBJECT
		set name = "Adjust mask"
		set src in usr

		adjust_mask(usr)

/obj/item/clothing/mask/breath/medical
	desc = "A close-fitting sterile mask that can be connected to an air supply."
	name = "medical mask"
	icon_state = "medical"
	item_state_slots = list(SLOT_ID_RIGHT_HAND = "medical", SLOT_ID_LEFT_HAND = "medical")
	permeability_coefficient = 0.01

/obj/item/clothing/mask/breath/emergency
	desc = "A close-fitting  mask that is used by the wallmounted emergency oxygen pump."
	name = "emergency mask"
	icon_state = "breath"
	item_state = "breath"
	permeability_coefficient = 0.50

/obj/item/clothing/mask/breath/anesthetic
	desc = "A close-fitting sterile mask that is used by the anesthetic wallmounted pump."
	name = "anesthetic mask"
	icon_state = "medical"
	item_state = "medical"
	permeability_coefficient = 0.01

/obj/item/clothing/mask/balaclava/breath
	name = "breathaclava"
	clothing_flags = ALLOWINTERNALS
