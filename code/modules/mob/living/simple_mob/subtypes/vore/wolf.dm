/datum/category_item/catalogue/fauna/wolf		//TODO: VIRGO_LORE_WRITING_WIP
	name = "Creature - Wolf"
	desc = "Some sort of wolf, a descendent or otherwise of regular Earth canidae. They look almost exactly like their \
	Earth counterparts, except for the fact that their fur is a uniform grey. Some do show signs of unique coloration, and they \
	love to nip and bite at things, as well as sniffing around. They seem to mark their territory by way of scent-marking/urinating on things."
	value = CATALOGUER_REWARD_MEDIUM

/mob/living/simple_mob/animal/wolf
	name = "grey wolf"
	desc = "My, what big jaws it has!"
	tt_desc = "Canis lupus"
	catalogue_data = list(/datum/category_item/catalogue/fauna/wolf)

	icon_dead = "wolf-dead"
	icon_living = "wolf"
	icon_state = "wolf"
	icon = 'icons/mob/vore.dmi'

	randomized = TRUE

	movement_base_speed = 10 / 5

	harm_intent_damage = 5
	legacy_melee_damage_lower = 5
	legacy_melee_damage_upper = 12

	minbodytemp = 200

	ai_holder_type = /datum/ai_holder/polaris/simple_mob/melee/evasive

// Activate Noms!
/mob/living/simple_mob/animal/wolf


// Adds Phoron Wolf
/mob/living/simple_mob/animal/wolf/phoron
	iff_factions = MOB_IFF_FACTION_BIND_TO_LEVEL

	movement_base_speed = 6.66

	harm_intent_damage = 5
	legacy_melee_damage_lower = 5
	legacy_melee_damage_upper = 12

	minbodytemp = 200

// Lazy way of making sure wolves survive outside.
	min_oxy = 0
	max_oxy = 0
	min_tox = 0
	max_tox = 0
	min_co2 = 0
	max_co2 = 0
	min_n2 = 0
	max_n2 = 0

