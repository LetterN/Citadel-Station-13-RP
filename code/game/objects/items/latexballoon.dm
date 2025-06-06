/obj/item/latexballon
	name = "latex glove"
	desc = "A latex glove, usually used as a balloon."
	icon_state = "latexballon"
	item_icons = list(
			SLOT_ID_LEFT_HAND = 'icons/mob/items/lefthand_gloves.dmi',
			SLOT_ID_RIGHT_HAND = 'icons/mob/items/righthand_gloves.dmi',
			)
	item_state = "lgloves"
	damage_force = 0
	throw_force = 0
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 1
	throw_range = 15
	var/state
	var/datum/gas_mixture/air_contents = null

/obj/item/latexballon/proc/blow(obj/item/tank/tank)
	if (icon_state == "latexballon_bursted")
		return
	src.air_contents = tank.remove_air_volume(3)
	icon_state = "latexballon_blow"
	item_state = "latexballon"

/obj/item/latexballon/proc/burst()
	if (!air_contents)
		return
	playsound(src, 'sound/weapons/Gunshot_old.ogg', 100, 1)
	icon_state = "latexballon_bursted"
	item_state = "lgloves"
	loc.assume_air(air_contents)

/obj/item/latexballon/inflict_atom_damage(damage, damage_type, damage_tier, damage_flag, damage_mode, hit_zone, attack_type, datum/attack_source)
	. = ..()
	burst()

/obj/item/latexballon/fire_act(datum/gas_mixture/air, temperature, volume)
	if(temperature > T0C+100)
		burst()
	return

/obj/item/latexballon/attackby(obj/item/W as obj, mob/user as mob)
	if (can_puncture(W))
		burst()
