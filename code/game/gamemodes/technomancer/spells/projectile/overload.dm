/datum/technomancer/spell/overload
	name = "Overload"
	desc = "Fires a bolt of highly unstable energy, that does damaged equal to 0.3% of the technomancer's current reserve of energy.  \
	This energy pierces all known armor.  Energy cost is equal to 10% of maximum core charge."
	enhancement_desc = "Will do damage equal to 0.4% of current energy."
	spell_power_desc = "Increases damage dealt, up to a cap of 80 damage per shot."
	cost = 100
	obj_path = /obj/item/spell/projectile/overload
	ability_icon_state = "tech_overload"
	category = OFFENSIVE_SPELLS

/obj/item/spell/projectile/overload
	name = "overload"
	icon_state = "overload"
	desc = "Hope your Core's full."
	cast_methods = CAST_RANGED
	aspect = ASPECT_UNSTABLE
	spell_projectile = /obj/projectile/overload
	energy_cost_per_shot = 0 // Handled later
	instability_per_shot = 12
	cooldown = 10
	pre_shot_delay = 4
	fire_sound = 'sound/effects/supermatter.ogg'

/obj/projectile/overload
	name = "overloaded bolt"
	icon_state = "bluespace"
	damage_type = DAMAGE_TYPE_BURN
	damage_tier = 7

/obj/item/spell/projectile/overload/make_projectile(obj/projectile/projectile_type, mob/living/user)
	var/obj/projectile/overload/P = new projectile_type(get_turf(user))
	var/energy_before_firing = core.energy
	if(check_for_scepter())
		P.damage_force = round(energy_before_firing * 0.004) // .4% of their current energy pool.
	else
		P.damage_force = round(energy_before_firing * 0.003) // .3% of their current energy pool.
	P.damage_force = min(calculate_spell_power(P.damage_force), 80)
	return P

/obj/item/spell/projectile/overload/on_ranged_cast(atom/hit_atom, mob/living/user)
	energy_cost_per_shot = round(core.max_energy * 0.10)
	..()
/*	var/energy_before_firing = core.energy
	if(set_up(hit_atom, user))
		var/obj/projectile/overload/P = new spell_projectile(get_turf(user))
		P.launch(hit_atom)
		if(check_for_scepter())
			P.damage = round(energy_before_firing * 0.004) // .4% of their current energy pool.
		else
			P.damage = round(energy_before_firing * 0.003) // .3% of their current energy pool.
		adjust_instability(instability_per_shot)
		return 1
*/
