// These are objects that destroy themselves and add themselves to the
// decal list of the floor under them. Use them rather than distinct icon_states
// when mapping in interesting floor designs.
var/list/floor_decals = list()

/obj/effect/floor_decal
	name = "floor decal"
	icon = 'icons/turf/flooring/decals.dmi'

	plane = TURF_PLANE

	#ifdef IN_MAP_EDITOR
	// Display disposal pipes etc. above walls in map editors.
	layer = PLATING_DECAL_LAYER
	alpha = 128 // Set for the benefit of mapping.
	#else
	// Our actual layer ingame.
	layer = FLOOR_DECAL_LAYER
	#endif

	var/supplied_dir

/obj/effect/floor_decal/Initialize(mapload, newdir, newcolour)
	supplied_dir = newdir
	if(newcolour)
		color = newcolour
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/obj/effect/floor_decal/LateInitialize()
	add_to_turf_decals()
	qdel(src)

/obj/effect/floor_decal/proc/make_decal_image()
	var/image/I = image(icon = icon, icon_state = icon_state, dir = dir)
	I.layer = DECAL_LAYER
	I.color = color
	I.alpha = alpha
	return I

/obj/effect/floor_decal/proc/get_cache_key(turf/T)
	return "[alpha]-[color]-[dir]-[icon_state]-[T.layer]"

// This is a separate proc from initialize() to facilitiate its caching and other stuff.  Look into it someday.
/obj/effect/floor_decal/proc/add_to_turf_decals()
	if(supplied_dir)
		setDir(supplied_dir) // TODO - Why can't this line be done in initialize/New()?
	var/turf/T = get_turf(src)
	if(istype(T, /turf/simulated/floor) || istype(T, /turf/unsimulated/floor) || istype(T, /turf/simulated/shuttle/floor))
		var/cache_key = "[alpha]-[color]-[dir]-[icon_state]-[T.layer]"
		var/image/I = floor_decals[cache_key]
		if(!I)
			I = image(icon = icon, icon_state = icon_state, dir = dir)
			I.layer = (T.layer > src.layer ? T.layer : src.layer)
			I.color = color
			I.alpha = alpha
			floor_decals[cache_key] = I
		LAZYADD(T.decals, I) // Add to its decals list (so it remembers to re-apply after it cuts overlays)
		T.add_overlay(I) // Add to its current overlays too.
		return T

/obj/effect/floor_decal/reset
	name = "reset marker"

/obj/effect/floor_decal/reset/LateInitialize()
	var/turf/T = get_turf(src)
	if(T.decals && T.decals.len)
		T.decals.Cut()
		T.update_icon()
	qdel(src)

/obj/effect/floor_decal/corner
	icon_state = "corner_white"

/obj/effect/floor_decal/corner/black
	name = "black corner"
	color = "#333333"

/obj/effect/floor_decal/corner/black/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/black/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/black/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/black/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/black/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/black/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/black/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/black/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/blue
	name = "blue corner"
	color = COLOR_BLUE_GRAY

/obj/effect/floor_decal/corner/blue/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/blue/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/blue/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/blue/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/blue/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/blue/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/blue/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/blue/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/paleblue
	name = "pale blue corner"
	color = COLOR_PALE_BLUE_GRAY

/obj/effect/floor_decal/corner/paleblue/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/paleblue/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/paleblue/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/paleblue/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/paleblue/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/paleblue/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/paleblue/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/paleblue/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/green
	name = "green corner"
	color = COLOR_GREEN_GRAY

/obj/effect/floor_decal/corner/green/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/green/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/green/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/green/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/green/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/green/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/green/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/green/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/lime
	name = "lime corner"
	color = COLOR_PALE_GREEN_GRAY

/obj/effect/floor_decal/corner/lime/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/lime/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/lime/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/lime/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/lime/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/lime/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/lime/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/lime/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/yellow
	name = "yellow corner"
	color = COLOR_BROWN

/obj/effect/floor_decal/corner/yellow/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/yellow/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/yellow/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/yellow/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/yellow/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/yellow/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/yellow/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/yellow/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/yellow/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/beige
	name = "beige corner"
	color = COLOR_BEIGE

/obj/effect/floor_decal/corner/beige/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/beige/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/beige/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/beige/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/beige/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/beige/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/beige/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/beige/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/red
	name = "red corner"
	color = COLOR_RED_GRAY

/obj/effect/floor_decal/corner/red/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/red/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/red/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/red/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/red/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/red/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/red/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/red/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/red/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/pink
	name = "pink corner"
	color = COLOR_PALE_RED_GRAY

/obj/effect/floor_decal/corner/pink/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/pink/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/pink/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/pink/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/pink/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/pink/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/pink/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/pink/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/purple
	name = "purple corner"
	color = COLOR_PURPLE_GRAY

/obj/effect/floor_decal/corner/purple/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/purple/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/purple/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/purple/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/purple/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/purple/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/purple/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/purple/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/mauve
	name = "mauve corner"
	color = COLOR_PALE_PURPLE_GRAY

/obj/effect/floor_decal/corner/mauve/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/mauve/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/mauve/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/mauve/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/mauve/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/mauve/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/mauve/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/mauve/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/orange
	name = "orange corner"
	color = COLOR_DARK_ORANGE

/obj/effect/floor_decal/corner/orange/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/orange/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/orange/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/orange/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/orange/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/orange/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/orange/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/orange/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/brown
	name = "brown corner"
	color = COLOR_DARK_BROWN

/obj/effect/floor_decal/corner/brown/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/brown/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/brown/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/brown/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/brown/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/brown/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/brown/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/brown/bordercee
	icon_state = "bordercolorcee"


/obj/effect/floor_decal/corner/white
	name = "white corner"
	icon_state = "corner_white"

/obj/effect/floor_decal/corner/white/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/white/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/white/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/white/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/white/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/white/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/white/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/white/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/grey
	name = "grey corner"
	color = "#8D8C8C"

/obj/effect/floor_decal/corner/grey/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/grey/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/grey/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/grey/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/grey/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/grey/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/grey/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/grey/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/lightgrey
	name = "lightgrey corner"
	color = "#A8B2B6"

/obj/effect/floor_decal/corner/lightgrey/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/lightgrey/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/lightgrey/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/lightgrey/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/lightgrey/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/lightgrey/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/lightgrey/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/spline/plain
	name = "spline - plain"
	icon_state = "spline_plain"

/obj/effect/floor_decal/spline/plain/corner
	name = "spline - plain"
	icon_state = "spline_plain_corner"

/obj/effect/floor_decal/spline/fancy
	name = "spline - fancy"
	icon_state = "spline_fancy"

/obj/effect/floor_decal/spline/fancy/wood
	name = "spline - wood"
	color = "#CB9E04"

/obj/effect/floor_decal/spline/fancy/wood/corner
	icon_state = "spline_fancy_corner"

/obj/effect/floor_decal/spline/fancy/wood/cee
	icon_state = "spline_fancy_cee"

/obj/effect/floor_decal/spline/fancy/wood/three_quarters
	icon_state = "spline_fancy_full"

/obj/effect/floor_decal/industrial/warning
	name = "hazard stripes"
	icon_state = "warning"

/obj/effect/floor_decal/industrial/warning/corner
	icon_state = "warningcorner"

/obj/effect/floor_decal/industrial/warning/full
	icon_state = "warningfull"

/obj/effect/floor_decal/industrial/warning/cee
	icon_state = "warningcee"

/obj/effect/floor_decal/industrial/danger
	name = "hazard stripes"
	icon_state = "danger"

/obj/effect/floor_decal/industrial/danger/corner
	icon_state = "dangercorner"

/obj/effect/floor_decal/industrial/danger/full
	icon_state = "dangerfull"

/obj/effect/floor_decal/industrial/danger/cee
	icon_state = "dangercee"

/obj/effect/floor_decal/industrial/warning/dust
	name = "hazard stripes"
	icon_state = "warning_dust"

/obj/effect/floor_decal/industrial/warning/dust/corner
	name = "hazard stripes"
	icon_state = "warningcorner_dust"

/obj/effect/floor_decal/industrial/hatch
	name = "hatched marking"
	icon_state = "delivery"

/obj/effect/floor_decal/industrial/hatch/yellow
	color = "#CFCF55"

/obj/effect/floor_decal/industrial/outline
	name = "white outline"
	icon_state = "outline"

/obj/effect/floor_decal/industrial/outline/blue
	name = "blue outline"
	color = "#00B8B2"

/obj/effect/floor_decal/industrial/outline/yellow
	name = "yellow outline"
	color = "#CFCF55"

/obj/effect/floor_decal/industrial/outline/grey
	name = "grey outline"
	color = "#808080"

/obj/effect/floor_decal/industrial/loading
	name = "loading area"
	icon_state = "loadingarea"

/obj/effect/floor_decal/industrial/halfstair
	name = "half stairs"
	icon = 'icons/turf/structures.dmi' //These weren't used anywhere except for snowflake instances, lets change them into a decal.
	icon_state = "ramptop"

/obj/effect/floor_decal/plaque
	name = "plaque"
	icon_state = "plaque"

/obj/effect/floor_decal/carpet
	name = "carpet"
	icon = 'icons/turf/flooring/carpet.dmi'
	icon_state = "carpet_edges"

/obj/effect/floor_decal/carpet/blue
	name = "carpet"
	icon = 'icons/turf/flooring/carpet.dmi'
	icon_state = "bcarpet_edges"

/obj/effect/floor_decal/carpet/corners
	name = "carpet"
	icon = 'icons/turf/flooring/carpet.dmi'
	icon_state = "carpet_corners"

/obj/effect/floor_decal/asteroid
	name = "random asteroid rubble"
	icon_state = "asteroid0"

/obj/effect/floor_decal/asteroid/Initialize(mapload)
	icon_state = "asteroid[rand(0,9)]"
	return ..()

/obj/effect/floor_decal/chapel
	name = "chapel"
	icon_state = "chapel"

/obj/effect/floor_decal/ss13/l1
	name = "L1"
	icon_state = "L1"

/obj/effect/floor_decal/ss13/l2
	name = "L2"
	icon_state = "L2"

/obj/effect/floor_decal/ss13/l3
	name = "L3"
	icon_state = "L3"

/obj/effect/floor_decal/ss13/l4
	name = "L4"
	icon_state = "L4"

/obj/effect/floor_decal/ss13/l5
	name = "L5"
	icon_state = "L5"

/obj/effect/floor_decal/ss13/l6
	name = "L6"
	icon_state = "L6"

/obj/effect/floor_decal/ss13/l7
	name = "L7"
	icon_state = "L7"

/obj/effect/floor_decal/ss13/l8
	name = "L8"
	icon_state = "L8"

/obj/effect/floor_decal/ss13/l9
	name = "L9"
	icon_state = "L9"

/obj/effect/floor_decal/ss13/l10
	name = "L10"
	icon_state = "L10"

/obj/effect/floor_decal/ss13/l11
	name = "L11"
	icon_state = "L11"

/obj/effect/floor_decal/ss13/l12
	name = "L12"
	icon_state = "L12"

/obj/effect/floor_decal/ss13/l13
	name = "L13"
	icon_state = "L13"

/obj/effect/floor_decal/ss13/l14
	name = "L14"
	icon_state = "L14"

/obj/effect/floor_decal/ss13/l15
	name = "L15"
	icon_state = "L15"

/obj/effect/floor_decal/ss13/l16
	name = "L16"
	icon_state = "L16"

/obj/effect/floor_decal/sign
	name = "floor sign"
	icon_state = "white_1"

/obj/effect/floor_decal/sign/two
	icon_state = "white_2"

/obj/effect/floor_decal/sign/a
	icon_state = "white_a"

/obj/effect/floor_decal/sign/b
	icon_state = "white_b"

/obj/effect/floor_decal/sign/c
	icon_state = "white_c"

/obj/effect/floor_decal/sign/d
	icon_state = "white_d"

/obj/effect/floor_decal/sign/ex
	icon_state = "white_ex"

/obj/effect/floor_decal/sign/m
	icon_state = "white_m"

/obj/effect/floor_decal/sign/cmo
	icon_state = "white_cmo"

/obj/effect/floor_decal/sign/v
	icon_state = "white_v"

/obj/effect/floor_decal/sign/p
	icon_state = "white_p"

/obj/effect/floor_decal/sign/dock
	icon_state = "white_d"

/obj/effect/floor_decal/sign/dock/one
	icon_state = "white_d1"

/obj/effect/floor_decal/sign/dock/two
	icon_state = "white_d2"

/obj/effect/floor_decal/sign/dock/three
	icon_state = "white_d3"

/obj/effect/floor_decal/rust
	name = "rust"
	icon_state = "rust"

/obj/effect/floor_decal/rust/mono_rusted1
	icon_state = "mono_rusted1"

/obj/effect/floor_decal/rust/mono_rusted2
	icon_state = "mono_rusted2"

/obj/effect/floor_decal/rust/mono_rusted3
	icon_state = "mono_rusted3"

/obj/effect/floor_decal/rust/part_rusted1
	icon_state = "part_rusted1"

/obj/effect/floor_decal/rust/part_rusted2
	icon_state = "part_rusted2"

/obj/effect/floor_decal/rust/part_rusted3
	icon_state = "part_rusted3"

/obj/effect/floor_decal/rust/color_rusted
	icon_state = "color_rusted"

/obj/effect/floor_decal/rust/color_rustedcorner
	icon_state = "color_rustedcorner"

/obj/effect/floor_decal/rust/color_rustedfull
	icon_state = "color_rustedfull"

/obj/effect/floor_decal/rust/color_rustedcee
	icon_state = "color_rustedcee"

/obj/effect/floor_decal/rust/steel_decals_rusted1
	icon_state = "steel_decals_rusted1"

/obj/effect/floor_decal/rust/steel_decals_rusted2
	icon_state = "steel_decals_rusted2"

//Old tile

/obj/effect/floor_decal/corner_oldtile
	name = "corner oldtile"
	icon_state = "corner_oldtile"

/obj/effect/floor_decal/corner_oldtile/white
	name = "corner oldtile"
	icon_state = "corner_oldtile"
	color = "#d9d9d9"

/obj/effect/floor_decal/corner_oldtile/white/diagonal
	name = "corner oldtile diagonal"
	icon_state = "corner_oldtile_diagonal"

/obj/effect/floor_decal/corner_oldtile/white/full
	name = "corner oldtile full"
	icon_state = "corner_oldtile_full"

/obj/effect/floor_decal/corner_oldtile/blue
	name = "corner oldtile"
	icon_state = "corner_oldtile"
	color = "#8ba7ad"

/obj/effect/floor_decal/corner_oldtile/blue/diagonal
	name = "corner oldtile diagonal"
	icon_state = "corner_oldtile_diagonal"

/obj/effect/floor_decal/corner_oldtile/blue/full
	name = "corner oldtile full"
	icon_state = "corner_oldtile_full"

/obj/effect/floor_decal/corner_oldtile/yellow
	name = "corner oldtile"
	icon_state = "corner_oldtile"
	color = "#8c6d46"

/obj/effect/floor_decal/corner_oldtile/yellow/diagonal
	name = "corner oldtile diagonal"
	icon_state = "corner_oldtile_diagonal"

/obj/effect/floor_decal/corner_oldtile/yellow/full
	name = "corner oldtile full"
	icon_state = "corner_oldtile_full"

/obj/effect/floor_decal/corner_oldtile/gray
	name = "corner oldtile"
	icon_state = "corner_oldtile"
	color = "#687172"

/obj/effect/floor_decal/corner_oldtile/gray/diagonal
	name = "corner oldtile diagonal"
	icon_state = "corner_oldtile_diagonal"

/obj/effect/floor_decal/corner_oldtile/gray/full
	name = "corner oldtile full"
	icon_state = "corner_oldtile_full"

/obj/effect/floor_decal/corner_oldtile/beige
	name = "corner oldtile"
	icon_state = "corner_oldtile"
	color = "#385e60"

/obj/effect/floor_decal/corner_oldtile/beige/diagonal
	name = "corner oldtile diagonal"
	icon_state = "corner_oldtile_diagonal"

/obj/effect/floor_decal/corner_oldtile/beige/full
	name = "corner oldtile full"
	icon_state = "corner_oldtile_full"

/obj/effect/floor_decal/corner_oldtile/red
	name = "corner oldtile"
	icon_state = "corner_oldtile"
	color = "#964e51"

/obj/effect/floor_decal/corner_oldtile/red/diagonal
	name = "corner oldtile diagonal"
	icon_state = "corner_oldtile_diagonal"

/obj/effect/floor_decal/corner_oldtile/red/full
	name = "corner oldtile full"
	icon_state = "corner_oldtile_full"

/obj/effect/floor_decal/corner_oldtile/purple
	name = "corner oldtile"
	icon_state = "corner_oldtile"
	color = "#906987"

/obj/effect/floor_decal/corner_oldtile/purple/diagonal
	name = "corner oldtile diagonal"
	icon_state = "corner_oldtile_diagonal"

/obj/effect/floor_decal/corner_oldtile/purple/full
	name = "corner oldtile full"
	icon_state = "corner_oldtile_full"

/obj/effect/floor_decal/corner_oldtile/green
	name = "corner oldtile"
	icon_state = "corner_oldtile"
	color = "#46725c"

/obj/effect/floor_decal/corner_oldtile/green/diagonal
	name = "corner oldtile diagonal"
	icon_state = "corner_oldtile_diagonal"

/obj/effect/floor_decal/corner_oldtile/green/full
	name = "corner oldtile full"
	icon_state = "corner_oldtile_full"

//Kafel

/obj/effect/floor_decal/corner_kafel
	name = "corner kafel"
	icon_state = "corner_kafel"

/obj/effect/floor_decal/corner_kafel/white
	name = "corner kafel"
	icon_state = "corner_kafel"
	color = "#d9d9d9"

/obj/effect/floor_decal/corner_kafel/white/diagonal
	name = "corner kafel diagonal"
	icon_state = "corner_kafel_diagonal"

/obj/effect/floor_decal/corner_kafel/white/full
	name = "corner kafel full"
	icon_state = "corner_kafel_full"

/obj/effect/floor_decal/corner_kafel/blue
	name = "corner kafel"
	icon_state = "corner_kafel"
	color = "#8ba7ad"

/obj/effect/floor_decal/corner_kafel/blue/diagonal
	name = "corner kafel diagonal"
	icon_state = "corner_kafel_diagonal"

/obj/effect/floor_decal/corner_kafel/blue/full
	name = "corner kafel full"
	icon_state = "corner_kafel_full"

/obj/effect/floor_decal/corner_kafel/yellow
	name = "corner kafel"
	icon_state = "corner_kafel"
	color = "#8c6d46"

/obj/effect/floor_decal/corner_kafel/yellow/diagonal
	name = "corner kafel diagonal"
	icon_state = "corner_kafel_diagonal"

/obj/effect/floor_decal/corner_kafel/yellow/full
	name = "corner kafel full"
	icon_state = "corner_kafel_full"

/obj/effect/floor_decal/corner_kafel/gray
	name = "corner kafel"
	icon_state = "corner_kafel"
	color = "#687172"

/obj/effect/floor_decal/corner_kafel/gray/diagonal
	name = "corner kafel diagonal"
	icon_state = "corner_kafel_diagonal"

/obj/effect/floor_decal/corner_kafel/gray/full
	name = "corner kafel full"
	icon_state = "corner_kafel_full"

/obj/effect/floor_decal/corner_kafel/beige
	name = "corner kafel"
	icon_state = "corner_kafel"
	color = "#385e60"

/obj/effect/floor_decal/corner_kafel/beige/diagonal
	name = "corner kafel diagonal"
	icon_state = "corner_kafel_diagonal"

/obj/effect/floor_decal/corner_kafel/beige/full
	name = "corner kafel full"
	icon_state = "corner_kafel_full"

/obj/effect/floor_decal/corner_kafel/red
	name = "corner kafel"
	icon_state = "corner_kafel"
	color = "#964e51"

/obj/effect/floor_decal/corner_kafel/red/diagonal
	name = "corner kafel diagonal"
	icon_state = "corner_kafel_diagonal"

/obj/effect/floor_decal/corner_kafel/red/full
	name = "corner kafel full"
	icon_state = "corner_kafel_full"

/obj/effect/floor_decal/corner_kafel/purple
	name = "corner kafel"
	icon_state = "corner_kafel"
	color = "#906987"

/obj/effect/floor_decal/corner_kafel/purple/diagonal
	name = "corner kafel diagonal"
	icon_state = "corner_kafel_diagonal"

/obj/effect/floor_decal/corner_kafel/purple/full
	name = "corner kafel full"
	icon_state = "corner_kafel_full"

/obj/effect/floor_decal/corner_kafel/green
	name = "corner kafel"
	icon_state = "corner_kafel"
	color = "#46725c"

/obj/effect/floor_decal/corner_kafel/green/diagonal
	name = "corner kafel diagonal"
	icon_state = "corner_kafel_diagonal"

/obj/effect/floor_decal/corner_kafel/green/full
	name = "corner kafel full"
	icon_state = "corner_kafel_full"

//Techfloor

/obj/effect/floor_decal/corner_techfloor_gray
	name = "corner techfloorgray"
	icon_state = "corner_techfloor_gray"

/obj/effect/floor_decal/corner_techfloor_gray/diagonal
	name = "corner techfloorgray diagonal"
	icon_state = "corner_techfloor_gray_diagonal"

/obj/effect/floor_decal/corner_techfloor_gray/full
	name = "corner techfloorgray full"
	icon_state = "corner_techfloor_gray_full"

/obj/effect/floor_decal/corner_techfloor_grid
	name = "corner techfloorgrid"
	icon_state = "corner_techfloor_grid"

/obj/effect/floor_decal/corner_techfloor_grid/diagonal
	name = "corner techfloorgrid diagonal"
	icon_state = "corner_techfloor_grid_diagonal"

/obj/effect/floor_decal/corner_techfloor_grid/full
	name = "corner techfloorgrid full"
	icon_state = "corner_techfloor_grid_full"

/obj/effect/floor_decal/corner_steel_grid
	name = "corner steel_grid"
	icon_state = "steel_grid"

/obj/effect/floor_decal/corner_steel_grid/diagonal
	name = "corner tsteel_grid diagonal"
	icon_state = "steel_grid_diagonal"

/obj/effect/floor_decal/corner_steel_grid/full
	name = "corner steel_grid full"
	icon_state = "steel_grid_full"

/obj/effect/floor_decal/borderfloor
	name = "border floor"
	icon_state = "borderfloor"

/obj/effect/floor_decal/borderfloor/corner
	icon_state = "borderfloorcorner"

/obj/effect/floor_decal/borderfloor/corner2
	icon_state = "borderfloorcorner2"

/obj/effect/floor_decal/borderfloor/full
	icon_state = "borderfloorfull"

/obj/effect/floor_decal/borderfloor/cee
	icon_state = "borderfloorcee"

/obj/effect/floor_decal/borderfloorblack
	name = "border floor"
	icon_state = "borderfloor_black"

/obj/effect/floor_decal/borderfloorblack/corner
	icon_state = "borderfloorcorner_black"

/obj/effect/floor_decal/borderfloorblack/corner2
	icon_state = "borderfloorcorner2_black"

/obj/effect/floor_decal/borderfloorblack/full
	icon_state = "borderfloorfull_black"

/obj/effect/floor_decal/borderfloorblack/cee
	icon_state = "borderfloorcee_black"

/obj/effect/floor_decal/borderfloorwhite
	name = "border floor"
	icon_state = "borderfloor_white"

/obj/effect/floor_decal/borderfloorwhite/corner
	icon_state = "borderfloorcorner_white"

/obj/effect/floor_decal/borderfloorwhite/corner2
	icon_state = "borderfloorcorner2_white"

/obj/effect/floor_decal/borderfloorwhite/full
	icon_state = "borderfloorfull_white"

/obj/effect/floor_decal/borderfloorwhite/cee
	icon_state = "borderfloorcee_white"

/obj/effect/floor_decal/steeldecal
	name = "steel decal"
	icon_state = "steel_decals1"

/obj/effect/floor_decal/steeldecal/steel_decals1
	icon_state = "steel_decals1"

/obj/effect/floor_decal/steeldecal/steel_decals2
	icon_state = "steel_decals2"

/obj/effect/floor_decal/steeldecal/steel_decals3
	icon_state = "steel_decals3"

/obj/effect/floor_decal/steeldecal/steel_decals4
	icon_state = "steel_decals4"

/obj/effect/floor_decal/steeldecal/steel_decals5
	icon_state = "steel_decals5"

/obj/effect/floor_decal/steeldecal/steel_decals5white
	icon_state = "steel_decals5white"

/obj/effect/floor_decal/steeldecal/steel_decals6
	icon_state = "steel_decals6"

/obj/effect/floor_decal/steeldecal/steel_decals7
	icon_state = "steel_decals7"

/obj/effect/floor_decal/steeldecal/steel_decals8
	icon_state = "steel_decals8"

/obj/effect/floor_decal/steeldecal/steel_decals9
	icon_state = "steel_decals9"

/obj/effect/floor_decal/steeldecal/steel_decals10
	icon_state = "steel_decals10"

/obj/effect/floor_decal/steeldecal/steel_decals_central1
	icon_state = "steel_decals_central1"

/obj/effect/floor_decal/steeldecal/steel_decals_central2
	icon_state = "steel_decals_central2"

/obj/effect/floor_decal/steeldecal/steel_decals_central3
	icon_state = "steel_decals_central3"

/obj/effect/floor_decal/steeldecal/steel_decals_central4
	icon_state = "steel_decals_central4"

/obj/effect/floor_decal/steeldecal/steel_decals_central5
	icon_state = "steel_decals_central5"

/obj/effect/floor_decal/steeldecal/steel_decals_central6
	icon_state = "steel_decals_central6"

/obj/effect/floor_decal/steeldecal/steel_decals_central7
	icon_state = "steel_decals_central7"


/obj/effect/floor_decal/techfloor
	name = "techfloor edges"
	icon_state = "techfloor_edges"

/obj/effect/floor_decal/techfloor/corner
	name = "techfloor corner"
	icon_state = "techfloor_corners"

/obj/effect/floor_decal/techfloor/orange
	name = "techfloor edges"
	icon_state = "techfloororange_edges"

/obj/effect/floor_decal/techfloor/orange/corner
	name = "techfloor corner"
	icon_state = "techfloororange_corners"

/obj/effect/floor_decal/techfloor/hole
	name = "hole left"
	icon_state = "techfloor_hole_left"

/obj/effect/floor_decal/techfloor/hole/right
	name = "hole right"
	icon_state = "techfloor_hole_right"


//Grass for ship garden

/obj/effect/floor_decal/grass_edge
	name = "grass edge"
	icon_state = "grass_edge"

/obj/effect/floor_decal/grass_edge/corner
	name = "grass edge"
	icon_state = "grass_edge_corner"

// Victory colour decals

/obj/effect/floor_decal/corner/navblue
	name = "navblue corner"
	color = COLOR_NAV_BLUE

/obj/effect/floor_decal/corner/navblue/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/navblue/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/navblue/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/navblue/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/navblue/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/navblue/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/navblue/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/navblue/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/navblue/halfborder
	icon_state = "bordercolorhalf"

/obj/effect/floor_decal/corner/navgold
	name = "navgold corner"
	color = COLOR_NAV_GOLD

/obj/effect/floor_decal/corner/navgold/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/navgold/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/navgold/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/navgold/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/navgold/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/navgold/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/navgold/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/navgold/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/navgold/halfborder
	icon_state = "bordercolorhalf"

//! ## VR FILE MERGE ## !//

/obj/effect/floor_decal/flesh
	name = "flesh"
	icon = 'icons/turf/stomach_vr.dmi'
	icon_state = "flesh_floor_edges"

/obj/effect/floor_decal/flesh/colour
	name = "flesh"
	icon = 'icons/turf/stomach_vr.dmi'
	icon_state = "c_flesh_floor_edges"

/obj/effect/floor_decal/industrial/outline/red
	name = "red outline"
	color = COLOR_RED
/obj/effect/floor_decal/borderfloor/shifted
	icon_state = "borderfloor_shifted"

/obj/effect/floor_decal/borderfloorblack/shifted
	icon_state = "borderfloor_shifted"

/obj/effect/floor_decal/borderfloorwhite/shifted
	icon_state = "borderfloor_shifted"

/obj/effect/floor_decal/corner/beige/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/black/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/blue/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/brown/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/green/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/grey/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/lightgrey/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/lightorange
	name = "orange corner"
	color = "#ed983d"

/obj/effect/floor_decal/corner/lightorange/diagonal
	icon_state = "corner_white_diagonal"

/obj/effect/floor_decal/corner/lightorange/full
	icon_state = "corner_white_full"

/obj/effect/floor_decal/corner/lightorange/three_quarters
	icon_state = "corner_white_three_quarters"

/obj/effect/floor_decal/corner/lightorange/border
	icon_state = "bordercolor"

/obj/effect/floor_decal/corner/lightorange/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/lightorange/bordercorner
	icon_state = "bordercolorcorner"

/obj/effect/floor_decal/corner/lightorange/bordercorner2
	icon_state = "bordercolorcorner2"

/obj/effect/floor_decal/corner/lightorange/borderfull
	icon_state = "bordercolorfull"

/obj/effect/floor_decal/corner/lightorange/bordercee
	icon_state = "bordercolorcee"

/obj/effect/floor_decal/corner/lime/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/mauve/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/orange/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/paleblue/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/pink/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/purple/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/red/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/white/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/corner/yellow/border/shifted
	icon_state = "bordercolor_shifted"

/obj/effect/floor_decal/transit/orange
	icon = 'icons/turf/transit_vr.dmi'
	icon_state = "transit_techfloororange_edges"

/obj/effect/transit/light
	icon = 'icons/turf/transit_128.dmi'
	icon_state = "tube1-2"

/obj/effect/floor_decal/tracks
	icon = 'icons/obj/mining.dmi'
	icon_state = "rail"

/obj/effect/floor_decal/tracks/intersection
	icon_state = "rail_intersection"

/obj/effect/floor_decal/tracks/t_north
	icon_state = "rail_intersection_NEW"

/obj/effect/floor_decal/tracks/t_south
	icon_state = "rail_intersection_SEW"

/obj/effect/floor_decal/tracks/t_west
	icon_state = "rail_intersection_NSW"

/obj/effect/floor_decal/tracks/t_east
	icon_state = "rail_intersection_NSE"
