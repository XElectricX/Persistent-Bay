/obj/item/weapon/basketball
	icon = 'icons/misc/basketball.dmi'
	icon_state = "basketball"
	name = "basketball"
	item_state = "basketball"
	density = 0
	anchored = 0
	w_class = ITEM_SIZE_HUGE
	force = 0.0
	throwforce = 0.0
	throw_speed = 1
	throw_range = 20
	flags = CONDUCT

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		user.drop_item()
		src.throw_at(target, throw_range, throw_speed, user)
