/obj/item/storage/box/bloodpacks
	name = "blood packs bags"
	desc = "This box contains blood packs."
	icon_state = "sterile"

/obj/item/storage/box/bloodpacks/Initialize(mapload)
		. = ..()
		new /obj/item/reagent_containers/blood/empty(src)
		new /obj/item/reagent_containers/blood/empty(src)
		new /obj/item/reagent_containers/blood/empty(src)
		new /obj/item/reagent_containers/blood/empty(src)
		new /obj/item/reagent_containers/blood/empty(src)
		new /obj/item/reagent_containers/blood/empty(src)
		new /obj/item/reagent_containers/blood/empty(src)

/obj/item/reagent_containers/blood
	name = "IV pack"
	var/base_name = " "
	desc = "Holds liquids used for transfusion."
	var/base_desc = " "
	icon = 'icons/obj/bloodpack.dmi'
	icon_state = "empty"
	item_state = "bloodpack_empty"
	drop_sound = 'sound/items/drop/food.ogg'
	pickup_sound = 'sound/items/pickup/food.ogg'
	volume = 200
	var/label_text = ""

	var/blood_type = null
	var/bitten_state = FALSE

/obj/item/reagent_containers/blood/Initialize(mapload)
	. = ..()
	base_name = name
	base_desc = desc
	if(blood_type != null)
		label_text = "[blood_type]"
		update_iv_label()
		// todo: standard way of doing this
		var/datum/blood_mixture/mixture = new
		var/datum/blood_fragment/fragment = new
		fragment.legacy_blood_type = blood_type
		mixture.unsafe_set_fragment_list_ref(list(
			(fragment) = 1,
		))
		reagents.add_reagent("blood", 200, mixture)
		update_icon()

/obj/item/reagent_containers/blood/on_reagent_change()
	update_icon()

/obj/item/reagent_containers/blood/update_icon()
	var/percent = round((reagents.total_volume / volume) * 100)
	if(percent >= 0 && percent <= 9)
		icon_state = "empty"
		item_state = "bloodpack_empty"
	else if(percent >= 10 && percent <= 50)
		icon_state = "half"
		item_state = "bloodpack_half"
	else if(percent >= 51 && percent < INFINITY)
		icon_state = "full"
		item_state = "bloodpack_full"

/obj/item/reagent_containers/blood/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/pen) || istype(W, /obj/item/flashlight/pen))
		var/tmp_label = sanitizeSafe(input(user, "Enter a label for [name]", "Label", label_text), MAX_NAME_LEN)
		if(length(tmp_label) > 50)
			to_chat(user, "<span class='notice'>The label can be at most 50 characters long.</span>")
		else if(length(tmp_label) > 10)
			to_chat(user, "<span class='notice'>You set the label.</span>")
			label_text = tmp_label
			update_iv_label()
		else
			to_chat(user, "<span class='notice'>You set the label to \"[tmp_label]\".</span>")
			label_text = tmp_label
			update_iv_label()

/obj/item/reagent_containers/blood/proc/update_iv_label()
	if(label_text == "")
		name = base_name
	else if(length(label_text) > 10)
		var/short_label_text = copytext(label_text, 1, 11)
		name = "[base_name] ([short_label_text]...)"
	else
		name = "[base_name] ([label_text])"
	desc = "[base_desc] It is labeled \"[label_text]\"."

/obj/item/reagent_containers/blood/APlus
	blood_type = "A+"

/obj/item/reagent_containers/blood/AMinus
	blood_type = "A-"

/obj/item/reagent_containers/blood/BPlus
	blood_type = "B+"

/obj/item/reagent_containers/blood/BMinus
	blood_type = "B-"

/obj/item/reagent_containers/blood/ABPlus
	blood_type = "AB+"

/obj/item/reagent_containers/blood/ABMinus
	blood_type = "AB-"

/obj/item/reagent_containers/blood/OPlus
	blood_type = "O+"

/obj/item/reagent_containers/blood/OMinus
	blood_type = "O-"

/obj/item/reagent_containers/blood/empty
	name = "Empty BloodPack"
	desc = "Seems pretty useless... Maybe if there were a way to fill it?"
	icon_state = "empty"
	item_state = "bloodpack_empty"
