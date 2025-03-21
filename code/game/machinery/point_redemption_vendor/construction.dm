#ifndef T_BOARD
#error T_BOARD macro is not defined but we need it!
#endif

/obj/item/circuitboard/point_redemption_vendor
	abstract_type = /obj/item/circuitboard/point_redemption_vendor

/obj/item/circuitboard/point_redemption_vendor/mining
	name = T_BOARD("Mining Equipment Vendor")
	board_type = new /datum/frame/frame_types/machine
	build_path = /obj/machinery/point_redemption_vendor/mining
	origin_tech = list(TECH_DATA = 1, TECH_ENGINEERING = 3)
	req_components = list(
							/obj/item/stock_parts/console_screen = 1,
							/obj/item/stock_parts/matter_bin = 3)

/obj/item/circuitboard/point_redemption_vendor/survey
	name = T_BOARD("Exploration Equipment Vendor")
	board_type = new /datum/frame/frame_types/machine
	build_path = /obj/machinery/point_redemption_vendor/survey
	origin_tech = list(TECH_DATA = 1, TECH_ENGINEERING = 2)
	req_components = list(
							/obj/item/stock_parts/console_screen = 1,
							/obj/item/stock_parts/matter_bin = 3)
