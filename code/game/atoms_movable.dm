/atom/movable
	plane = OBJ_PLANE

	appearance_flags = TILE_BOUND
	glide_size = 8

	var/last_move = null
	var/anchored = 0
	// var/elevation = 2    - not used anywhere
	var/move_speed = 10
	var/l_move_time = 1
	var/m_flag = 1
	var/throwing = 0
	var/thrower
	var/turf/throw_source = null
	var/throw_speed = 2
	var/throw_range = 7
	var/moved_recently = 0
	var/mob/pulledby = null
	var/item_state = null // Used to specify the item state for the on-mob overlays.

/atom/movable/Destroy()
	. = ..()
	for(var/atom/movable/AM in src)
		qdel(AM)

	forceMove(null)
	if (pulledby)
		if (pulledby.pulling == src)
			pulledby.pulling = null
		pulledby = null

/atom/movable/Bump(var/atom/A, yes)
	if(src.throwing)
		src.throw_impact(A)
		src.throwing = 0

	spawn(0)
		if (A && yes)
			A.last_bumped = world.time
			A.Bumped(src)
		return
	..()
	return

/atom/movable/proc/forceMove(atom/destination)
	if(loc == destination)
		return 0
	var/is_origin_turf = isturf(loc)
	var/is_destination_turf = isturf(destination)
	// It is a new area if:
	//  Both the origin and destination are turfs with different areas.
	//  When either origin or destination is a turf and the other is not.
	var/is_new_area = (is_origin_turf ^ is_destination_turf) || (is_origin_turf && is_destination_turf && loc.loc != destination.loc)

	var/atom/origin = loc
	loc = destination

	if(origin)
		origin.Exited(src, destination)
		if(is_origin_turf)
			for(var/atom/movable/AM in origin)
				AM.Uncrossed(src)
			if(is_new_area && is_origin_turf)
				origin.loc.Exited(src, destination)

	if(destination)
		destination.Entered(src, origin)
		if(is_destination_turf) // If we're entering a turf, cross all movable atoms
			for(var/atom/movable/AM in loc)
				if(AM != src)
					AM.Crossed(src)
			if(is_new_area && is_destination_turf)
				destination.loc.Entered(src, origin)
	return 1

//called when src is thrown into hit_atom
/atom/movable/proc/throw_impact(atom/hit_atom, var/speed)
	if(istype(hit_atom,/mob/living))
		var/mob/living/M = hit_atom
		M.hitby(src,speed)

	else if(isobj(hit_atom))
		var/obj/O = hit_atom
		if(!O.anchored)
			step(O, src.last_move)
		O.hitby(src,speed)

	else if(isturf(hit_atom))
		src.throwing = 0
		var/turf/T = hit_atom
		T.hitby(src,speed)

//decided whether a movable atom being thrown can pass through the turf it is in.
/atom/movable/proc/hit_check(var/speed)
	if(src.throwing)
		for(var/atom/A in get_turf(src))
			if(A == src) continue
			if(istype(A,/mob/living))
				if(A:lying) continue
				src.throw_impact(A,speed)
			if(isobj(A))
				if(A.density && !A.throwpass)	// **TODO: Better behaviour for windows which are dense, but shouldn't always stop movement
					src.throw_impact(A,speed)

/atom/movable/proc/throw_at(atom/target, range, speed, thrower)
	if(!target || !src)
		return 0
	if(target.z != src.z)
		return 0
	//use a modified version of Bresenham's algorithm to get from the atom's current position to that of the target
	src.throwing = 1
	src.thrower = thrower
	src.throw_source = get_turf(src)	//store the origin turf
	src.pixel_z = 0
	if(usr)
		if(HULK in usr.mutations)
			src.throwing = 2 // really strong throw!

	var/dist_x = abs(target.x - src.x)
	var/dist_y = abs(target.y - src.y)

	var/dx
	if (target.x > src.x)
		dx = EAST
	else
		dx = WEST

	var/dy
	if (target.y > src.y)
		dy = NORTH
	else
		dy = SOUTH
	var/dist_travelled = 0
	var/dist_since_sleep = 0
	var/area/a = get_area(src.loc)
	if(dist_x > dist_y)
		var/error = dist_x/2 - dist_y



		while(src && target &&((((src.x < target.x && dx == EAST) || (src.x > target.x && dx == WEST)) && dist_travelled < range) || (a && a.has_gravity == 0)  || istype(src.loc, /turf/space)) && src.throwing && istype(src.loc, /turf))
			// only stop when we've gone the whole distance (or max throw range) and are on a non-space tile, or hit something, or hit the end of the map, or someone picks it up
			if(error < 0)
				var/atom/step = get_step(src, dy)
				if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
					break
				src.Move(step)
				hit_check(speed)
				error += dist_x
				dist_travelled++
				dist_since_sleep++
				if(dist_since_sleep >= speed)
					dist_since_sleep = 0
					sleep(1)
			else
				var/atom/step = get_step(src, dx)
				if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
					break
				src.Move(step)
				hit_check(speed)
				error -= dist_y
				dist_travelled++
				dist_since_sleep++
				if(dist_since_sleep >= speed)
					dist_since_sleep = 0
					sleep(1)
			a = get_area(src.loc)
	else
		var/error = dist_y/2 - dist_x
		while(src && target &&((((src.y < target.y && dy == NORTH) || (src.y > target.y && dy == SOUTH)) && dist_travelled < range) || (a && a.has_gravity == 0)  || istype(src.loc, /turf/space)) && src.throwing && istype(src.loc, /turf))
			// only stop when we've gone the whole distance (or max throw range) and are on a non-space tile, or hit something, or hit the end of the map, or someone picks it up
			if(error < 0)
				var/atom/step = get_step(src, dx)
				if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
					break
				src.Move(step)
				hit_check(speed)
				error += dist_y
				dist_travelled++
				dist_since_sleep++
				if(dist_since_sleep >= speed)
					dist_since_sleep = 0
					sleep(1)
			else
				var/atom/step = get_step(src, dy)
				if(!step) // going off the edge of the map makes get_step return null, don't let things go off the edge
					break
				src.Move(step)
				hit_check(speed)
				error -= dist_x
				dist_travelled++
				dist_since_sleep++
				if(dist_since_sleep >= speed)
					dist_since_sleep = 0
					sleep(1)

			a = get_area(src.loc)

	//done throwing, either because it hit something or it finished moving
	if(isobj(src)) src.throw_impact(get_turf(src),speed)
	src.throwing = 0
	src.thrower = null
	src.throw_source = null
	fall()

//Overlays
/atom/movable/overlay
	var/atom/master = null
	anchored = 1

/atom/movable/overlay/New()
	src.verbs.Cut()
	..()

/atom/movable/overlay/Destroy()
	master = null
	. = ..()

/atom/movable/overlay/attackby(a, b)
	if (src.master)
		return src.master.attackby(a, b)
	return

/atom/movable/overlay/attack_hand(a, b, c)
	if (src.master)
		return src.master.attack_hand(a, b, c)
	return

/atom/movable/proc/touch_map_edge()
	if(!simulated)
		return

	if(!z || (z in GLOB.using_map.sealed_levels))
		return

	if(!GLOB.universe.OnTouchMapEdge(src))
		return

	if(GLOB.using_map.use_overmap)
		overmap_spacetravel(get_turf(src), src)
		return

	var/list/L = list(	"1" = list("NORTH" = 19, "SOUTH" = 10, "EAST" = 4, "WEST" = 7),
						"2" = list("NORTH" = 20, "SOUTH" = 11, "EAST" = 5, "WEST" = 8),
						"3" = list("NORTH" = 21, "SOUTH" = 12, "EAST" = 6, "WEST" = 9),
						"4" = list("NORTH" = 22, "SOUTH" = 13, "EAST" = 7, "WEST" = 1),
						"5" = list("NORTH" = 23, "SOUTH" = 14, "EAST" = 8, "WEST" = 2),
						"6" = list("NORTH" = 24, "SOUTH" = 15, "EAST" = 9, "WEST" = 3),
						"7" = list("NORTH" = 25, "SOUTH" = 16, "EAST" = 1, "WEST" = 4),
						"8" = list("NORTH" = 26, "SOUTH" = 17, "EAST" = 2, "WEST" = 5),
						"9" = list("NORTH" = 27, "SOUTH" = 18, "EAST" = 3, "WEST" = 6),
						"10" = list("NORTH" = 1, "SOUTH" = 19, "EAST" = 13, "WEST" = 16),
						"11" = list("NORTH" = 2, "SOUTH" = 20, "EAST" = 14, "WEST" = 17),
						"12" = list("NORTH" = 3, "SOUTH" = 21, "EAST" = 15, "WEST" = 18),
						"13" = list("NORTH" = 4, "SOUTH" = 22, "EAST" = 16, "WEST" = 10),
						"14" = list("NORTH" = 5, "SOUTH" = 23, "EAST" = 17, "WEST" = 11),
						"15" = list("NORTH" = 6, "SOUTH" = 24, "EAST" = 18, "WEST" = 12),
						"16" = list("NORTH" = 7, "SOUTH" = 25, "EAST" = 10, "WEST" = 13),
						"17" = list("NORTH" = 8, "SOUTH" = 26, "EAST" = 11, "WEST" = 14),
						"18" = list("NORTH" = 9, "SOUTH" = 27, "EAST" = 12, "WEST" = 15),
						"19" = list("NORTH" = 10, "SOUTH" = 1, "EAST" = 22, "WEST" = 25),
						"20" = list("NORTH" = 11, "SOUTH" = 2, "EAST" = 23, "WEST" = 26),
						"21" = list("NORTH" = 12, "SOUTH" = 3, "EAST" = 24, "WEST" = 27),
						"22" = list("NORTH" = 13, "SOUTH" = 4, "EAST" = 25, "WEST" = 19),
						"23" = list("NORTH" = 14, "SOUTH" = 5, "EAST" = 26, "WEST" = 20),
						"24" = list("NORTH" = 15, "SOUTH" = 6, "EAST" = 27, "WEST" = 21),
						"25" = list("NORTH" = 16, "SOUTH" = 7, "EAST" = 19, "WEST" = 22),
						"26" = list("NORTH" = 17, "SOUTH" = 8, "EAST" = 20, "WEST" = 23),
						"27" = list("NORTH" = 28, "SOUTH" = 9, "EAST" = 21, "WEST" = 24)
					)

	var/new_x = x
	var/new_y = y
	var/new_z = z
	if(new_z)
		if(x <= TRANSITIONEDGE)
			new_x = world.maxx - TRANSITIONEDGE - 1
			new_z = L["[z]"]["WEST"]

		else if (x >= (world.maxx - TRANSITIONEDGE))
			new_x = TRANSITIONEDGE + 1
			new_z = L["[z]"]["EAST"]

		else if (y <= TRANSITIONEDGE)
			new_y = world.maxy - TRANSITIONEDGE - 1
			new_z = L["[z]"]["SOUTH"]

		else if (y >= (world.maxy - TRANSITIONEDGE))
			new_y = TRANSITIONEDGE + 1
			new_z = L["[z]"]["NORTH"]

		var/turf/T = locate(new_x, new_y, new_z)
		if(T)
			forceMove(T)
