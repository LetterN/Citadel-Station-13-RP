/obj/item/vehicle_module/weapon/energy/pulse
	equip_cooldown = 30
	name = "eZ-13 mk2 heavy pulse rifle"
	desc = "An experimental Anti-Everything weapon."
	icon_state = "mecha_pulse"
	energy_drain = 120
	origin_tech = list(TECH_MATERIAL = 3, TECH_COMBAT = 6, TECH_POWER = 4)
	projectile = /obj/projectile/beam/pulse/heavy
	fire_sound = 'sound/weapons/gauss_shoot.ogg'

/obj/projectile/beam/pulse/heavy
	name = "heavy pulse laser"
	icon_state = "pulse1_bl"
