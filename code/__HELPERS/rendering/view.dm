/proc/getviewsize(view)
	SHOULD_BE_PURE(TRUE)

	if(isnum(view))
		//resetting back to 0- this is the same as just checking !view but we want to be clear the point of the check.
		if(view == 0)
			return list(0, 0)
		var/totalviewrange = 1 + 2 * view
		return list(totalviewrange, totalviewrange)
	else
		var/list/viewrangelist = splittext(view,"x")
		return list(text2num(viewrangelist[1]), text2num(viewrangelist[2]))

/// Takes a string or num view, and converts it to pixel width/height in a list(pixel_width, pixel_height)
/proc/view_to_pixels(view)
	if(!view)
		return list(0, 0)
	var/list/view_info = getviewsize(view)
	view_info[1] *= world.icon_size
	view_info[2] *= world.icon_size
	return view_info

// TODO: optimize
/proc/world_view_max_number()
	if(isnum(world.view))
		return world.view
	var/list/decoded = getviewsize(world.view)
	return max(decoded[1], decoded[2])
