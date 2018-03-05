
/datum/computer_file/program/faction_core
	filename = "faction_core"
	filedesc = "Core Logistics Program"
	program_icon_state = "comm"
	program_menu_icon = "flag"
	nanomodule_path = /datum/nano_module/program/faction_core
	extended_desc = "Uses a Logistic Processor to connect to and modify bluespace networks over satalite."
	required_access = access_heads
	requires_ntnet = 0
	size = 65
	usage_flags = PROGRAM_CONSOLE

/datum/nano_module/program/faction_core
	name = "Core Logistics Program"
	available_to_ai = TRUE
	var/datum/world_faction/connected_faction
	var/connected = 0
	var/attempted_password = ""
	var/wrong_password = 0
	var/wrong_connection = 0
	var/menu = 1 // 1 = connect to network 2 = login screen 3 = main directory 4 = central options 5 = network options 6 = main access control 7 = main assignment control 8 = access category view 9 = access view 10 = assignment category view 11 = assignment view
	var/datum/access_category/selected_accesscategory
	var/selected_access = 0
	var/datum/assignment_category/selected_assignmentcategory
	var/datum/assignment/selected_assignment
	var/viewing_ranks = 0
	var/prior_menu = 3
	var/datum/access_category/core_access
/datum/nano_module/program/faction_core/proc/try_connect()

	if(!program.computer.logistic_processor || !program.computer.logistic_processor.check_functionality())
		connected = 0
		connected_faction = null
		menu = 1
		return
	if(connected_faction)
		if(connected_faction.uid != program.computer.logistic_processor.faction_uid || connected_faction.password != program.computer.logistic_processor.faction_password)
			connected = 0
			connected_faction = null
			menu = 1
			return
		else
			connected = 1
			wrong_connection = 0
			return 1
	else
		connected_faction = get_faction(program.computer.logistic_processor.faction_uid)
		if(connected_faction)
			if(connected_faction.password != program.computer.logistic_processor.faction_password)
				connected = 0
				connected_faction = null
				menu = 1
				return
			connected = 1
			wrong_connection = 0
			return 1
		menu = 1
		return

	
/datum/nano_module/program/faction_core/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = GLOB.default_state)
	try_connect()
	var/list/data = host.initial_data()
	var/log_status = 1
	if(!program.computer.logistic_processor || !program.computer.logistic_processor.check_functionality()) log_status = 0
	data["has_log"] = log_status
	if(connected_faction)
		if(attempted_password != connected_faction.password)
			menu = 2
		else if(menu == 1 || menu == 2)
			menu = 3
		data["faction_name"] = connected_faction.name
		data["faction_uid"] = connected_faction.uid
		if(menu == 4)			
			data["faction_abbreviation"] = connected_faction.abbreviation
			var/regex/allregex = regex(".")
			data["faction_purpose"] = connected_faction.purpose
			data["faction_password"] = allregex.Replace(connected_faction.password, "*")
		if(menu == 5)
			data["network_name"] = connected_faction.network.name
			data["network_uid"] = connected_faction.network.net_uid
			data["network_password"] = connected_faction.network.password
			data["network_visible"] = connected_faction.network.invisible ? "No" : "Yes"
		if(menu == 6)
			var/list/access_categories[0]
			for(var/datum/access_category/category in connected_faction.access_categories)
				access_categories[++access_categories.len] = list("name" = category.name, "accesses" = list(), "ref" = "\ref[category]")
				var/ind = 0
				for(var/x in category.accesses)
					ind++
					var/name = category.accesses[x]
					if(!name) continue
					access_categories[access_categories.len]["accesses"] += list(list(
					"name" = sanitize("([x]) [name]"),
					"ind" = ind))
			data["access_categories"] = access_categories
		if(menu == 7)
			var/list/assignment_categories[0]
			for(var/datum/assignment_category/category in connected_faction.assignment_categories)
				assignment_categories[++assignment_categories.len] = list("name" = category.name, "assignments" = list(), "ref" = "\ref[category]")
				for(var/datum/assignment/assignment in category.assignments)
					assignment_categories[assignment_categories.len]["assignments"] += list(list(
					"name" = sanitize(assignment.uid),
					"ref2" = "\ref[assignment]"
					))
			data["assignment_categories"] = assignment_categories
		if(menu == 8)
			var/list/accesses[0]
			var/ind = 0
			for(var/x in selected_accesscategory.accesses)
				ind++
				var/name = selected_accesscategory.accesses[x]
				accesses[++accesses.len] = list("name" = "([x]) [name]", "ind" = ind)
			data["accesses"] = accesses	
		if(menu == 10) // assignment category view
			data["leader_faction"] = selected_assignmentcategory.command_faction
			data["membership_faction"] = selected_assignmentcategory.member_faction
			data["account_status"] = selected_assignmentcategory.account_status
			data["faction_leader"] = selected_assignmentcategory.head_position ? selected_assignmentcategory.head_position.uid : "None"
			
			var/list/assignments[0]
			for(var/datum/assignment/assignment in selected_assignmentcategory.assignments)
				assignments[++assignments.len] = list("name" = "([assignment.uid]) [assignment.name]", "ref" = "\ref[assignment]")
			data["assignments"] = assignments
		if(menu == 11)
			data["pay"] = selected_assignment.payscale
			data["title"] = selected_assignment.name
			var/list/access_categories[0]
			var/datum/access_category/core/core
			if(!core_access)
				core = new()
				core_access = core
			var/list/all_categories = list()
			all_categories |= core_access
			all_categories |= connected_faction.access_categories
			for(var/datum/access_category/category in all_categories)
				access_categories[++access_categories.len] = list("name" = category.name, "accesses" = list(), "ref" = "\ref[category]")
				var/ind = 0
				for(var/x in category.accesses)
					var/existing = 0
					if(selected_assignment.accesses.Find(x))
						existing = 1
					ind++
					var/name = category.accesses[x]
					if(!name) continue
					access_categories[access_categories.len]["accesses"] += list(list(
					"name" = sanitize("([x]) [name]"),
					"ind" = ind,
					"existing" = existing))
			data["access_categories"] = access_categories
			var/list/ranks[0]
			for(var/title in selected_assignment.ranks)
				ranks[++ranks.len] = list("name" = "[title]:[selected_assignment.ranks[title]]")
			data["ranks"] = ranks
			data["view_ranks"] = viewing_ranks
	else
		menu = 1
	if(selected_accesscategory)
		data["selected_accesscategory"] = selected_accesscategory.name
	if(selected_access && selected_accesscategory)
		var/x = selected_accesscategory.accesses[selected_access]
		var/name = selected_accesscategory.accesses[x]
		data["selected_access"] = name
		data["accessnum"] = x
	if(selected_assignmentcategory)
		data["selected_assignmentcategory"] = selected_assignmentcategory.name
	if(selected_assignment)
		data["selected_assignment"] = "([selected_assignment.uid]) [selected_assignment.name]"
	data["prior_menu"] = prior_menu
	data["menu"] = menu
	data["wrong_connection"] = wrong_connection
	data["wrong_password"] = wrong_password
	ui = GLOB.nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "faction_core.tmpl", name, 550, 650, state = state)
		ui.auto_update_layout = 1
		ui.set_initial_data(data)
		ui.open()

/datum/nano_module/program/faction_core/Topic(href, href_list)
	if(..())
		return 1
	if(!program.computer.logistic_processor || !program.computer.logistic_processor.check_functionality()) return 1
	if(!program.can_run(usr)) return 1
	switch (href_list["action"])
		if("connect")
			var/curr_faction_uid = program.computer.logistic_processor.faction_uid
			var/curr_faction_password = program.computer.logistic_processor.faction_password
			var/select_faction_uid = input(usr, "Enter Lognet UID")
			var/select_faction_password = input(usr, "Enter Lognet Password")
			if(curr_faction_password == program.computer.logistic_processor.faction_password && curr_faction_uid == program.computer.logistic_processor.faction_uid)
				program.computer.logistic_processor.faction_uid = select_faction_uid
				program.computer.logistic_processor.faction_password = select_faction_password
				if(!try_connect())
					wrong_connection = 1
			else
				to_chat(usr, "Your inputs expired because someone used the terminal first.")
		if("log_in")
			var/curr_attempted_password = attempted_password
			var/select_attempted_password = input(usr, "Enter Lognet Password")
			if(curr_attempted_password == attempted_password)
				attempted_password = select_attempted_password
				if(attempted_password != connected_faction.password)
					wrong_password = 1
			else
				to_chat(usr, "Your inputs expired because someone used the terminal first.")
		if("disconnect")
			var/curr_attempted_password = attempted_password
			var/select_attempted_password = input(usr, "Enter Lognet Password")
			if(curr_attempted_password == attempted_password)
				if(select_attempted_password != connected_faction.password)
					to_chat(usr, "Error wrong password. Contact system administrator to disconnect network.")
				else
					program.computer.logistic_processor.faction_uid = ""
					program.computer.logistic_processor.faction_password = ""
					attempted_password = ""
			else
				to_chat(usr, "Your inputs expired because someone used the terminal first.")
		if("log_out")
			attempted_password = ""
		if("change_menu")
			var/select_menu = text2num(href_list["menu_target"])
			menu = select_menu
			prior_menu = 3
		if("change_name")
			var/curr_name = connected_faction.name
			var/select_name = sanitizeName(input(usr,"Enter the name of your orginization","Lognet Display Name", connected_faction.name) as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				if(curr_name != connected_faction.name)
					to_chat(usr, "Your inputs expired because someone used the terminal first.")
				else
					for(var/datum/world_faction/existing_faction in GLOB.all_world_factions)
						if(existing_faction.name == select_name)
							to_chat(usr, "Error! A Lognet with that display name already exists!")
							return 1
					connected_faction.name = select_name
					to_chat(usr, "Lognet display name successfully changed.")
		if("change_abbreviation")
			var/curr_name = connected_faction.abbreviation
			var/select_name = sanitizeName(input(usr,"Enter the abbreviation of your orginization","Lognet Abbreviation", connected_faction.abbreviation) as null|text, 20, 1, 0)
			if(select_name)
				if(curr_name != connected_faction.abbreviation)
					to_chat(usr, "Your inputs expired because someone used the terminal first.")
				else
					for(var/datum/world_faction/existing_faction in GLOB.all_world_factions)
						if(existing_faction.abbreviation == select_name)
							to_chat(usr, "Error! A Lognet with that abbreviation already exists!")
							return 1
					connected_faction.abbreviation = select_name
					to_chat(usr, "Lognet abbreviation successfully changed.")
		if("change_purpose")
			var/curr_name = connected_faction.purpose
			var/select_name = sanitize(input(usr,"Enter a description or purpose for your orginization.","Lognet Desc.", connected_faction.purpose) as null|text, 126)
			if(select_name)
				if(curr_name != connected_faction.purpose)
					to_chat(usr, "Your inputs expired because someone used the terminal first.")
				else
					connected_faction.purpose = select_name
					to_chat(usr, "Lognet description successfully changed.")
		if("change_password")
			if(input(usr,"Enter current password","Lognet Password") != connected_faction.password) return 1
			var/curr_name = connected_faction.password
			var/select_name = sanitize(input(usr,"Enter new password. This will log this terminal out.","Lognet Password") as null|text, 20)
			if(select_name)
				var/confirm_password = input(usr,"Reenter password to confirm","Lognet Password") as null|text
				if(confirm_password != select_name)
					to_chat(usr, "Unable to confirm password")
				else
					if(curr_name != connected_faction.password)
						to_chat(usr, "Your inputs expired because someone used the terminal first.")
					else
						connected_faction.password = select_name
						to_chat(usr, "Lognet password successfully changed.")
		if("change_networkname")
			var/curr_name = connected_faction.network.name
			var/select_name = sanitizeName(input(usr,"Enter the wireless network display name","Wireless Network Display Name", curr_name) as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				if(curr_name != connected_faction.network.name)
					to_chat(usr, "Your inputs expired because someone used the terminal first.")
				else
					connected_faction.network.name = select_name
					to_chat(usr, "Wireless network display name successfully changed.")
		if("change_networkuid")
			var/curr_name = connected_faction.network.net_uid
			var/select_name = sanitizeName(input(usr,"Enter the wireless network uid. Spaces are not allowed,","Wireless Network UID", curr_name) as null|text, MAX_NAME_LEN, 1, 0,1)
			if(select_name)
				if(curr_name != connected_faction.network.net_uid)
					to_chat(usr, "Your inputs expired because someone used the terminal first.")
				else
					for(var/datum/world_faction/existing_faction in GLOB.all_world_factions)
						if(existing_faction.network.net_uid == select_name)
							to_chat(usr, "Error! A network with that UID already exists!")
							return 1
					connected_faction.network.net_uid = select_name
					to_chat(usr, "Wireless network UID successfully changed.")
		if("change_networkpassword")
			var/curr_name = connected_faction.network.password
			var/select_name = sanitize(input(usr,"Enter new password. All connected terminals will need to update their password. Leave blank to have unsecured network.","Wireless Network Password") as null|text, 20)
			if(select_name)
				if(curr_name != connected_faction.password)
					to_chat(usr, "Your inputs expired because someone used the terminal first.")
				else
					connected_faction.network.password = select_name
					to_chat(usr, "Wireless network password successfully changed.")
			else
				connected_faction.network.secured = 0
				connected_faction.network.password = null
		if("change_networkvisible")
			connected_faction.network.invisible = !connected_faction.network.invisible
		if("menu_back")
			menu = 3
		if("create_accesscategory")
			var/select_name = sanitizeName(input(usr,"Enter new access category name.","Create Access Category", "") as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				for(var/datum/access_category/category in connected_faction.access_categories)
					if(category.name == select_name)
						to_chat(usr, "Error! That access category already exists!")
						return 1
				var/datum/access_category/category = new()
				category.name = select_name
				connected_faction.access_categories |= category
				to_chat(usr, "Access category successfully created.")
		if("select_accesscategory")
			selected_accesscategory = locate(href_list["selected_ref"])
			if(!selected_accesscategory) return 1
			menu = 8
			prior_menu = 6
		if("edit_accesscategory")
			var/curr_name = selected_accesscategory.name
			var/select_name = sanitizeName(input(usr,"Enter new name.","Change Access Category Name", curr_name) as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				if(select_name == curr_name) return
				for(var/datum/access_category/category in connected_faction.access_categories)
					if(category.name == select_name)
						to_chat(usr, "Error! That access category already exists!")
						return 1
				selected_accesscategory.name = select_name
				to_chat(usr, "Access category successfully edited.")
		if("delete_accesscategory")
			if(selected_accesscategory.accesses.len)
				to_chat(usr, "You must delete the accesses first. You can only delete empty access categories.")
				return 1
			connected_faction.access_categories -= selected_accesscategory
			qdel(selected_accesscategory)
			selected_accesscategory = null
			menu = 6
		if("select_access")
			selected_accesscategory = locate(href_list["selected_ref"])
			if(!selected_accesscategory) return 1
			selected_access = text2num(href_list["selected_ind"])
			menu = 9
			prior_menu = 6
		if("create_access")
			var/selected_uid = input(usr,"Enter unique access number (11 - 99)", "Enter Access Number") as null|num
			if(!selected_uid || selected_uid < 11 || selected_uid > 99)
				to_chat(usr, "Invalid number.")
				return 1
			var/text_uid = num2text(selected_uid)
			connected_faction.rebuild_all_access()
			if(connected_faction.all_access.Find(text_uid))
				to_chat(usr, "This access number is already in use.")
				return 1
			var/select_name = sanitizeName(input(usr,"Enter access label. This can be changed afterwards.","Create new access", "") as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				selected_accesscategory.accesses[text_uid] = select_name
				to_chat(usr, "Access successfully created.")
		if("create_access_two")
			var/datum/access_category/selected_accesscategory2 = locate(href_list["selected_ref"])
			var/selected_uid = input(usr,"Enter unique access number (11 - 99)", "Enter Access Number") as null|num
			if(!selected_uid || selected_uid < 11 || selected_uid > 99)
				to_chat(usr, "Invalid number.")
				return 1
			var/text_uid = num2text(selected_uid)
			connected_faction.rebuild_all_access()
			if(connected_faction.all_access.Find(text_uid))
				to_chat(usr, "This access number is already in use.")
				return 1
			var/select_name = sanitizeName(input(usr,"Enter access label. This can be changed afterwards.","Create new access", "") as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				selected_accesscategory2.accesses[text_uid] = select_name
				to_chat(usr, "Access successfully created.")
		if("edit_access")
			var/x = selected_accesscategory.accesses[selected_access]
			var/curr_name = selected_accesscategory.accesses[x]
			var/select_name = sanitizeName(input(usr,"Change access label.","Edit access label", curr_name) as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				if(curr_name == select_name) return 1
				selected_accesscategory.accesses[x] = select_name
				to_chat(usr, "Access successfully edited.")
		if("delete_access")
			var/x = selected_accesscategory.accesses[selected_access]
			selected_accesscategory.accesses -= x
			connected_faction.rebuild_all_access()
			to_chat(usr, "Access successfully deleted.")
			menu = 8
		if("select_access_noref")
			if(!selected_accesscategory) return 1
			selected_access = text2num(href_list["selected_ind"])
			menu = 9
			prior_menu = 8
		if("create_assignmentcategory")
			var/select_name = sanitizeName(input(usr,"Enter new assignment category name.","Create Assignment Category", "") as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				for(var/datum/assignment_category/category in connected_faction.assignment_categories)
					if(category.name == select_name)
						to_chat(usr, "Error! That assignment category already exists!")
						return 1
				var/datum/assignment_category/category = new()
				category.name = select_name
				category.parent = connected_faction
				connected_faction.assignment_categories |= category
				to_chat(usr, "Assignment category successfully created.")
		if("select_assignmentcategory")
			selected_assignmentcategory = locate(href_list["selected_ref"])
			if(!selected_assignmentcategory) return 1
			menu = 10
			prior_menu = 7
		if("select_assignment")
			selected_assignmentcategory = locate(href_list["category_ref"])
			if(!selected_assignmentcategory) return 1
			selected_assignment = locate(href_list["selected_ref"])
			if(!selected_assignment) return 1
			menu = 11
			prior_menu = 7
		if("select_assignment_two")
			selected_assignment = locate(href_list["selected_ref"])
			if(!selected_assignment) return 1
			menu = 11
			prior_menu = 10
		if("assignmentcategory_leadership_yes")
			selected_assignmentcategory.command_faction = 1
		if("assignmentcategory_leadership_no")
			selected_assignmentcategory.command_faction = 0
		if("assignmentcategory_membership_yes")
			selected_assignmentcategory.member_faction = 1
		if("assignmentcategory_membership_no")
			selected_assignmentcategory.member_faction = 0	
		if("assignmentcategory_account_on")
			selected_assignmentcategory.account_status = 1
		if("assignmentcategory_account_off")
			selected_assignmentcategory.account_status = 0
		if("assignmentcategory_changeleader")
			var/curr = selected_assignmentcategory.head_position
			var/datum/assignment/selected = input(usr,"Choose which assignment","Enter Parameter",null) as null|anything in (selected_assignmentcategory.assignments + "None")
			if(selected_assignmentcategory.head_position != curr)
				to_chat(usr, "Your inputs expired because someone used the terminal first.")
				GLOB.nanomanager.update_uis(src)
				return 1
			if(!selected || selected == "None")
				selected_assignmentcategory.head_position = null
			else
				selected_assignmentcategory.head_position = selected
		if("create_assignment")
			var/x = selected_assignmentcategory
			var/select_name = sanitizeName(input(usr,"Enter the new assignments uid. This cannot be changed. Spaces are not allowed.","New Assignment UID", "") as null|text, MAX_NAME_LEN, 1, 0,1)
			if(select_name)
				connected_faction.rebuild_all_assignments()
				for(var/datum/assignment/assignment in connected_faction.all_assignments)
					if(assignment.uid == select_name)
						to_chat(usr, "Error! An assignment with that UID already exists")
						return 1
				var/select_title = sanitizeName(input(usr,"Enter Assignment Rank 1 Title.","Create Starting Title", "") as null|text, MAX_NAME_LEN, 1, 0)
				if(select_title)
					if(x != selected_assignmentcategory)
						to_chat(usr, "Your inputs expired because someone used the terminal first.")
						GLOB.nanomanager.update_uis(src)
						return 1
					var/datum/assignment/new_assignment = new()
					new_assignment.parent = selected_assignmentcategory
					new_assignment.name = select_title
					new_assignment.uid = select_name
					selected_assignmentcategory.assignments |= new_assignment
					to_chat(usr, "Assignment successfully created.")
		if("create_assignment_two")
			var/datum/assignment_category/selected_assignmentcategory2 = locate(href_list["selected_ref"])
			var/x = selected_assignmentcategory2
			var/select_name = sanitizeName(input(usr,"Enter the new assignments uid. This cannot be changed. Spaces are not allowed.","New Assignment UID", "") as null|text, MAX_NAME_LEN, 1, 0,1)
			if(select_name)
				connected_faction.rebuild_all_assignments()
				for(var/datum/assignment/assignment in connected_faction.all_assignments)
					if(assignment.uid == select_name)
						to_chat(usr, "Error! An assignment with that UID already exists")
						return 1
				var/select_title = sanitizeName(input(usr,"Enter Assignment Rank 1 Title.","Create Starting Title", "") as null|text, MAX_NAME_LEN, 1, 0)
				if(select_title)
					if(x != selected_assignmentcategory2)
						to_chat(usr, "Your inputs expired because someone used the terminal first.")
						GLOB.nanomanager.update_uis(src)
						return 1
					var/datum/assignment/new_assignment = new()
					new_assignment.parent = selected_assignmentcategory2
					new_assignment.name = select_title
					new_assignment.uid = select_name
					selected_assignmentcategory2.assignments |= new_assignment
					to_chat(usr, "Assignment successfully created.")
		if("edit_assignment")
			var/curr_name = selected_assignment.name
			var/select_name = sanitizeName(input(usr,"Enter new rank 1 title.","Rank 1 Title", "") as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				if(curr_name != selected_assignment.name)
					to_chat(usr, "Your inputs expired because someone used the terminal first.")
					GLOB.nanomanager.update_uis(src)
					return 1
				selected_assignment.name = select_name
		if("edit_assignment_pay")
			var/new_pay = input("Enter new payscale. Payscale is the number that the standard pay gets multiplied by, 0.5 is half the standard and 2 is twice the standard pay.","Rank 1 Payscale") as null|num
			if(!new_pay && new_pay != 0) return 1
			var/maximum = 10
			if(selected_assignment.ranks.len)
				var/x = selected_assignment
				maximum = selected_assignment.ranks[x]
			if(new_pay > maximum)
				to_chat(usr, "Payscale cannot be higher than 10 or the pay of the higher ranks.")
			selected_assignment.payscale = new_pay
		if("delete_assignment")
			var/choice = input(usr,"Are you sure you want to delete this assignment? All ranking data will be lost.") in list("Confirm", "Cancel")
			if(choice == "Confirm")
				selected_assignmentcategory.assignments -= selected_assignment
				qdel(selected_assignment)
				connected_faction.rebuild_all_assignments()
				to_chat(usr, "Assignment successfully deleted.")
			menu = 8
		if("view_access")
			viewing_ranks = 0
		if("view_ranks")
			viewing_ranks = 1
		if("create_rank")
			var/select_name = sanitizeName(input(usr,"Enter new rank title.","New rank title", "") as null|text, MAX_NAME_LEN, 1, 0)
			if(select_name)
				if(select_name == selected_assignment.name || selected_assignment.ranks.Find(select_name))
					to_chat(usr, "A rank with this title already exists.")
					return 1
				var/max = 10
				var/min = 0
				var/ind = 0
				if(selected_assignment.ranks.len)
					var/list/choices = list()
					for(var/x in 2 to selected_assignment.ranks.len+2)
						choices += "[x]"
					ind = text2num(input(usr,"Choose where to place this rank on the structure.","Choose rank position",null) as null|anything in choices)-1
					if(!ind) return 1
					if(ind > selected_assignment.ranks.len)
						ind = 0
						min = selected_assignment.payscale
						if(selected_assignment.ranks.len)
							min = selected_assignment.ranks[selected_assignment.ranks[selected_assignment.ranks.len]]
					if(ind)
						if(ind == 1)
							min = selected_assignment.payscale
							max = text2num(selected_assignment.ranks[selected_assignment.ranks[ind]])
						else
							max = text2num(selected_assignment.ranks[selected_assignment.ranks[ind]])
							min = text2num(selected_assignment.ranks[selected_assignment.ranks[ind-1]])
				var/new_pay = input("Enter new rank payscale. Payscale cannot be less than the prior rank ([min]) amd cannot be higher than 10 or the higher ranks pay ([max])","Rank Payscale") as null|num
				if(!new_pay && new_pay != 0) return 1
				if(new_pay > max)
					to_chat(usr, "Pay exceeded maximum. Rank creation failed.")
					return 1
				if(new_pay < min)
					to_chat(usr, "Pay under minimum. Rank creaton failed.")
					return 1
						
				selected_assignment.ranks.Insert(ind, select_name)
				selected_assignment.ranks[select_name] = new_pay
				to_chat(usr, "Rank successfully created.")
		if("delete_rank")
			var/choice2 = input(usr, "Are you sure you want to delete a rank? All higher ranks will be moved down by one, giving existing lower ranks an instant promotion.") in list("Confirm", "Cancel")
			if(choice2 == "Cancel") return 1
			if(!selected_assignment.ranks.len) return 1
			var/list/choices = list()
			var/ind = 1
			for(var/x in selected_assignment.ranks)
				ind++
				choices += "[ind] [x]"
			var/choice = input(usr,"Choose which rank to delete.","Delete rank",null) as null|anything in choices
			var/list/items = splittext(choice," ")
			ind = text2num(items[1])-1
			selected_assignment.ranks.Cut(ind, ind+1)
			to_chat(usr, "Rank successfully deleted.")
		if("pick_access")
			var/datum/access_category/category = locate(href_list["selected_ref"])
			var/ind = text2num(href_list["selected_ind"])
			var/x = category.accesses[ind]
			if(selected_assignment.accesses.Find(x))
				selected_assignment.accesses -= x
			else
				selected_assignment.accesses |= x
				
				
	GLOB.nanomanager.update_uis(src)