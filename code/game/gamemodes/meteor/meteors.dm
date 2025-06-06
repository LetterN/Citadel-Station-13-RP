/var/const/meteor_wave_delay = 425 //minimum wait between waves in tenths of seconds
//set to at least 100 unless you want evarr ruining every round

//Meteors probability of spawning during a given wave
/var/list/meteors_normal = list(/obj/effect/meteor/dust=3, /obj/effect/meteor/medium=8, /obj/effect/meteor/big=3, \
						  /obj/effect/meteor/flaming=1, /obj/effect/meteor/irradiated=3) //for normal meteor event

/var/list/meteors_threatening = list(/obj/effect/meteor/medium=5, /obj/effect/meteor/big=15, \
						  /obj/effect/meteor/flaming=4, /obj/effect/meteor/irradiated=4, /obj/effect/meteor/emp=4) //for threatening meteor event

/var/list/meteors_catastrophic = list(/obj/effect/meteor/medium=5, /obj/effect/meteor/big=50, \
						  /obj/effect/meteor/flaming=10, /obj/effect/meteor/irradiated=10, /obj/effect/meteor/emp=10, /obj/effect/meteor/tunguska = 1) //for catastrophic meteor event

/var/list/meteors_dust = list(/obj/effect/meteor/dust) //for space dust event


///////////////////////////////
//Meteor spawning global procs
///////////////////////////////

/proc/spawn_meteors(var/number = 10, var/list/meteortypes, var/startSide, var/zlevel)
	log_debug(SPAN_DEBUG("Spawning [number] meteors on the [dir2text(startSide)] of [zlevel]"))
	for(var/i = 0; i < number; i++)
		spawn_meteor(meteortypes, startSide, zlevel)

/proc/spawn_meteor(var/list/meteortypes, var/startSide, var/startLevel)
	if(isnull(startSide))
		startSide = pick(GLOB.cardinal)
	if(isnull(startLevel))
		startLevel = pick((LEGACY_MAP_DATUM).station_levels - (LEGACY_MAP_DATUM).sealed_levels)

	var/turf/pickedstart = spaceDebrisStartLoc(startSide, startLevel)
	var/turf/pickedgoal = spaceDebrisFinishLoc(startSide, startLevel)

	var/Me = pickweight(meteortypes)
	var/obj/effect/meteor/M = new Me(pickedstart)
	M.dest = pickedgoal
	spawn(0)
		walk_towards(M, M.dest, 1)
	return

/proc/spaceDebrisStartLoc(startSide, Z)
	var/starty
	var/startx
	switch(startSide)
		if(NORTH)
			starty = world.maxy-(TRANSITIONEDGE+1)
			startx = rand((TRANSITIONEDGE+1), world.maxx-(TRANSITIONEDGE+1))
		if(EAST)
			starty = rand((TRANSITIONEDGE+1),world.maxy-(TRANSITIONEDGE+1))
			startx = world.maxx-(TRANSITIONEDGE+1)
		if(SOUTH)
			starty = (TRANSITIONEDGE+1)
			startx = rand((TRANSITIONEDGE+1), world.maxx-(TRANSITIONEDGE+1))
		if(WEST)
			starty = rand((TRANSITIONEDGE+1), world.maxy-(TRANSITIONEDGE+1))
			startx = (TRANSITIONEDGE+1)
	var/turf/T = locate(startx, starty, Z)
	return T

/proc/spaceDebrisFinishLoc(startSide, Z)
	var/endy
	var/endx
	switch(startSide)
		if(NORTH)
			endy = TRANSITIONEDGE
			endx = rand(TRANSITIONEDGE, world.maxx-TRANSITIONEDGE)
		if(EAST)
			endy = rand(TRANSITIONEDGE, world.maxy-TRANSITIONEDGE)
			endx = TRANSITIONEDGE
		if(SOUTH)
			endy = world.maxy-TRANSITIONEDGE
			endx = rand(TRANSITIONEDGE, world.maxx-TRANSITIONEDGE)
		if(WEST)
			endy = rand(TRANSITIONEDGE,world.maxy-TRANSITIONEDGE)
			endx = world.maxx-TRANSITIONEDGE
	var/turf/T = locate(endx, endy, Z)
	return T

// Override for special behavior when getting hit by meteors, and only meteors.  Return one if the meteor hasn't been 'stopped'.
/atom/proc/handle_meteor_impact(var/obj/effect/meteor/meteor)
	return TRUE

///////////////////////
//The meteor effect
//////////////////////

/obj/effect/meteor
	name = "the concept of meteor"
	desc = "You should probably run instead of gawking at this."
	icon = 'icons/obj/meteor.dmi'
	icon_state = "small"
	density = 1
	anchored = 1
	var/hits = 4
	var/hitpwr = 2 //Level of legacy_ex_act to be called on hit.
	var/dest
	pass_flags = ATOM_PASS_TABLE
	var/heavy = 0
	var/z_original

	var/meteordrop = /obj/item/stack/ore/iron
	var/dropamt = 2

	// How much damage it does to walls, using take_damage().
	// Normal walls will die to 150 or more, where as reinforced walls need 800 to penetrate.  Durasteel walls need 1200 damage to go through.
	// Multiply this and the hits var to get a rough idea of how penetrating a meteor is.
	var/wall_power = 100

/obj/effect/meteor/Initialize(mapload)
	. = ..()
	z_original = z
	GLOB.meteor_list += src

/obj/effect/meteor/Move()
	if(z != z_original || loc == dest)
		qdel(src)
		return

	. = ..() //process movement...

	if(.)//.. if did move, ram the turf we get in
		var/turf/T = get_turf(loc)
		ram_turf(T)

		if(prob(10) && !istype(T, /turf/space))//randomly takes a 'hit' from ramming
			get_hit()

	return .

/obj/effect/meteor/Destroy()
	walk(src,0) //this cancels the walk_towards() proc
	GLOB.meteor_list -= src
	return ..()

/obj/effect/meteor/Initialize(mapload)
	. = ..()
	SpinAnimation()

/obj/effect/meteor/Bump(atom/A)
	if(attempt_vr(src,"Bump_vr",list(A))) return // Allows meteors to be deflected by baseball bats
	if(A)
		if(A.handle_meteor_impact(src)) // Used for special behaviour when getting hit specifically by a meteor, like a shield.
			ram_turf(get_turf(A))
			get_hit()
		else
			die(0)

/obj/effect/meteor/CanAllowThrough(atom/movable/mover, turf/target)
	return istype(mover, /obj/effect/meteor) ? 1 : ..()

/obj/effect/meteor/proc/ram_turf(var/turf/T)
	//first bust whatever is in the turf
	for(var/atom/A in T)
		if(A == src) // Don't hit ourselves.
			continue
		if(isturf(A)) // Don't hit floors. We'll deal with walls later.
			continue
		LEGACY_EX_ACT(A, hitpwr, null)

	//then, ram the turf if it still exists
	if(T)
		if(istype(T, /turf/simulated/wall))
			var/turf/simulated/wall/W = T
			W.inflict_atom_damage(wall_power, damage_flag = ARMOR_BOMB) // Stronger walls can halt asteroids.

/obj/effect/meteor/proc/get_shield_damage()
	return max(((max(hits, 2)) * (heavy + 1) * rand(6, 12)) / hitpwr , 0)

//process getting 'hit' by colliding with a dense object
//or randomly when ramming turfs
/obj/effect/meteor/proc/get_hit()
	hits--
	if(hits <= 0)
		die(1)

/obj/effect/meteor/proc/die(var/explode = 1)
	make_debris()
	meteor_effect(explode)
	qdel(src)

/obj/effect/meteor/legacy_ex_act()
	return

/obj/effect/meteor/using_item_on(obj/item/using, datum/event_args/actor/clickchain/clickchain, clickchain_flags)
	. = ..()
	if(istype(using, /obj/item/pickaxe))
		qdel(src)
		return CLICKCHAIN_DO_NOT_PROPAGATE | CLICKCHAIN_DID_SOMETHING

/obj/effect/meteor/proc/make_debris()
	for(var/throws = dropamt, throws > 0, throws--)
		var/obj/item/O = new meteordrop(get_turf(src))
		O.throw_at_old(dest, 5, 10)

/obj/effect/meteor/proc/shake_players()
	for(var/mob/M in GLOB.player_list)
		var/turf/T = get_turf(M)
		if(!T || T.z != src.z)
			continue
		var/dist = get_dist(M.loc, src.loc)
		shake_camera(M, dist > 20 ? 3 : 5, dist > 20 ? 1 : 3)

/obj/effect/meteor/proc/meteor_effect(var/explode)
	if(heavy)
		shake_players()


///////////////////////
//Meteor types
///////////////////////

// Dust breaks windows and hurts normal walls, generally more of an annoyance than a danger unless two happen to hit the same spot.
/obj/effect/meteor/dust
	name = "space dust"
	icon_state = "dust"
	pass_flags = ATOM_PASS_TABLE | ATOM_PASS_GRILLE
	hits = 1
	hitpwr = 3
	meteordrop = /obj/item/stack/ore/glass
	wall_power = 50

// Medium-sized meteors aren't very special and can be stopped easily by r-walls.
/obj/effect/meteor/medium
	name = "meteor"
	dropamt = 3
	wall_power = 75
/obj/effect/meteor/medium/meteor_effect(var/explode)
	..()
	if(explode)
		explosion(src.loc, 0, 0, 1, 1, 0)

// Large-sized meteors generally pack the most punch, but are more concentrated towards the epicenter.
/obj/effect/meteor/big
	name = "large meteor"
	icon_state = "large"
	hits = 2
	heavy = 1
	dropamt = 4
	wall_power = 125

/obj/effect/meteor/big/meteor_effect(var/explode)
	..()
	if(explode)
		explosion(src.loc, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 3, flash_range = 12, adminlog = 0)

// 'Flaming' meteors do less overall damage but are spread out more due to a larger but weaker explosion at the end.
/obj/effect/meteor/flaming
	name = "flaming meteor"
	icon_state = "flaming"
	hits = 5
	heavy = 1
	meteordrop = /obj/item/stack/ore/phoron
	wall_power = 100

/obj/effect/meteor/flaming/meteor_effect(var/explode)
	..()
	if(explode)
		explosion(src.loc, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 8, flash_range = 16, adminlog = 0)

// Irradiated meteors do less physical damage but project a ten-tile ranged pulse of radiation upon exploding.
/obj/effect/meteor/irradiated
	name = "glowing meteor"
	icon_state = "glowing"
	heavy = 1
	meteordrop = /obj/item/stack/ore/uranium
	wall_power = 75


/obj/effect/meteor/irradiated/meteor_effect(var/explode)
	..()
	if(explode)
		explosion(src.loc, devastation_range = 0, heavy_impact_range = 0, light_impact_range = 4, flash_range = 6, adminlog = 0)
	new /obj/effect/debris/cleanable/greenglow(get_turf(src))
	radiation_pulse(src, RAD_INTENSITY_RADIOACTIVE_METEOR)

// This meteor fries toasters.
/obj/effect/meteor/emp
	name = "conducting meteor"
	icon_state = "glowing_blue"
	desc = "Hide your floppies!"
	meteordrop = /obj/item/stack/ore/osmium
	dropamt = 3
	wall_power = 80

/obj/effect/meteor/emp/meteor_effect(var/explode)
	..()
	// Best case scenario: Comparable to a low-yield EMP grenade.
	// Worst case scenario: Comparable to a standard yield EMP grenade.
	empulse(src, rand(1, 3), rand(2, 4), rand(3, 7), rand(5, 10))

/obj/effect/meteor/emp/get_shield_damage()
	return ..() * rand(2,4)

//Station buster Tunguska
/obj/effect/meteor/tunguska
	name = "tunguska meteor"
	icon_state = "flaming"
	desc = "Your life briefly passes before your eyes the moment you lay them on this monstrosity"
	hits = 30
	hitpwr = 1
	heavy = 1
	meteordrop = /obj/item/stack/ore/phoron
	wall_power = 150

/obj/effect/meteor/tunguska/meteor_effect(var/explode)
	..()
	if(explode)
		explosion(src.loc, 5, 10, 15, 20, 0)

/obj/effect/meteor/tunguska/Bump()
	..()
	if(prob(20))
		explosion(src.loc,2,4,6,8)
