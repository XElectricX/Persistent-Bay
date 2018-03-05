/mob/living/carbon/human/proc/create_stack()
	set waitfor=0
	sleep(10)
	internal_organs_by_name[BP_STACK] = new /obj/item/organ/internal/stack(src,1)
	to_chat(src, "<span class='notice'>You feel a faint sense of vertigo as your neural lace boots.</span>")

/obj/item/organ/internal/stack
	name = "neural lace"
	parent_organ = BP_HEAD
	icon_state = "cortical-stack"
	organ_tag = BP_STACK
	robotic = ORGAN_ROBOT
	vital = 1
	origin_tech = list(TECH_BIO = 4, TECH_MATERIAL = 4, TECH_MAGNET = 2, TECH_DATA = 3)
	relative_size = 10

	var/ownerckey
	var/invasive
	var/default_language
	var/list/languages = list()
	var/datum/mind/backup
	action_button_name = "Access Neural Lace UI"
	action_button_is_hands_free = 1
	var/connected_faction = ""
	var/duty_status = 0
	var/datum/world_faction/faction
	
/obj/item/organ/internal/stack/proc/get_owner_name()
	if(!owner) return 0
	return owner.real_name
	
/obj/item/organ/internal/stack/ui_action_click()
	if(!owner) return
	ui_interact(owner)
/obj/item/organ/internal/stack/Topic(href, href_list)
	switch (href_list["action"])
		if("off_duty")
			duty_status = 0
		if("on_duty")
			if(try_duty())
				duty_status = 1
			else
				to_chat(usr, "Your duty signal was rejected.")
		if("disconnect")
			if(faction)
				faction.connected_laces -= src
				faction = null
				connected_faction = ""
		if("connect")
			faction = locate(href_list["selected_ref"])
			if(!faction) return 0
			connected_faction = faction.uid
			try_connect()
		
	GLOB.nanomanager.update_uis(src)
/obj/item/organ/internal/stack/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = GLOB.default_state)
	var/list/data = list()
	try_connect()
	if(faction)
		data["faction_name"] = faction.name
		if(duty_status == 1)
			try_duty()
		data["duty_status"] = duty_status ? "On Duty" : "Off Duty"
		data["duty_status_num"] = duty_status
	else
		var/list/potential = get_potential()
		var/list/formatted[0]
		for(var/datum/world_faction/fact in potential)
			formatted[++formatted.len] = list("name" = fact.name, "ref" = "\ref[fact]")
		message_admins("[formatted.len]")
		data["potential"] = formatted
	ui = GLOB.nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "lace.tmpl", "[name] UI", 550, 450, state = state)
		ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()	
/obj/item/organ/internal/stack/proc/get_potential()
	if(!owner) return list()
	var/list/potential[0]
	for(var/datum/world_faction/fact in GLOB.all_world_factions)
		var/datum/computer_file/crew_record/record = fact.get_record(owner.real_name)
		if(record) 
			potential |= fact
		else
			message_admins("record not found for [fact.name] [owner.real_name]")
	return potential
/obj/item/organ/internal/stack/proc/try_duty()
	if(!owner || !faction)
		duty_status = 0
		return
	var/datum/computer_file/crew_record/record = faction.get_record(owner.real_name)
	if(!record)
		faction = null
		duty_status = 0
		return
	var/assignment_uid = record.try_duty()
	if(assignment_uid)
		var/datum/assignment/assignment = faction.get_assignment(assignment_uid)
		if(assignment && assignment.duty_able)
			return 1
		else
			duty_status = 0
			return
	else
		duty_status = 0
		return
/obj/item/organ/internal/stack/proc/try_connect()
	if(!owner) return 0
	faction = get_faction(connected_faction)
	if(!faction) return 0
	var/datum/computer_file/crew_record/record = faction.get_record(owner.real_name)
	if(!record)
		faction = null
		return 0
	else
		faction.connected_laces |= src
/obj/item/organ/internal/stack/emp_act()
	return

/obj/item/organ/internal/stack/getToxLoss()
	return 0

/obj/item/organ/internal/stack/vox
	name = "cortical stack"
	invasive = 1
	action_button_name = "Access Cortical Stack UI"
/obj/item/organ/internal/stack/proc/do_backup()
	if(owner && owner.stat != DEAD && !is_broken() && owner.mind)
		languages = owner.languages.Copy()
		backup = owner.mind
		default_language = owner.default_language
		if(owner.ckey)
			ownerckey = owner.ckey

/obj/item/organ/internal/stack/New()
	..()
	do_backup()
	robotize()
/obj/item/organ/internal/stack/after_load()
	..()
	try_connect()
/obj/item/organ/internal/stack/proc/backup_inviable()
	return 	(!istype(backup) || backup == owner.mind || (backup.current && backup.current.stat != DEAD))

/obj/item/organ/internal/stack/replaced()
	if(!..()) 
		message_admins("stack replace() failed")
		return 0

	if(owner && !backup_inviable())
		var/current_owner = owner
		var/response = input(find_dead_player(ownerckey, 1), "Your neural backup has been placed into a new body. Do you wish to return to life?", "Resleeving") as anything in list("Yes", "No")
		if(src && response == "Yes" && owner == current_owner)
			overwrite()
	else
		message_admins("stack backup_inviable failed")
	sleep(-1)
	do_backup()

	return 1

/obj/item/organ/internal/stack/removed()
	do_backup()
	..()

/obj/item/organ/internal/stack/vox/removed()
	var/obj/item/organ/external/head = owner.get_organ(parent_organ)
	owner.visible_message("<span class='danger'>\The [src] rips gaping holes in \the [owner]'s [head.name] as it is torn loose!</span>")
	head.take_damage(rand(15,20))
	for(var/obj/item/organ/O in head.contents)
		O.take_damage(rand(30,70))
	..()

/obj/item/organ/internal/stack/proc/overwrite()
	if(owner.mind && owner.ckey) //Someone is already in this body!
		owner.visible_message("<span class='danger'>\The [owner] spasms violently!</span>")
		if(prob(66))
			to_chat(owner, "<span class='danger'>You fight off the invading tendrils of another mind, holding onto your own body!</span>")
			return
		owner.ghostize() // Remove the previous owner to avoid their client getting reset.
	//owner.dna.real_name = backup.name
	//owner.real_name = owner.dna.real_name
	//owner.name = owner.real_name
	//The above three lines were commented out for
	backup.active = 1
	backup.transfer_to(owner)
	if(default_language) owner.default_language = default_language
	owner.languages = languages.Copy()
	to_chat(owner, "<span class='notice'>Consciousness slowly creeps over you as your new body awakens.</span>")
