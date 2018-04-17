/datum/preferences
	var/med_record = ""
	var/sec_record = ""
	var/gen_record = ""
	var/nanotrasen_relation = "Neutral"
	var/memory = ""
	var/chosen_pin = 1000
	//Some faction information.
	var/home_system           //System of birth.
	var/citizenship = "None"            //Current home system.
	var/faction              //Antag faction/general associated faction.
	var/religion = "None"               //Religious association.

/datum/category_item/player_setup_item/general/background
	name = "Background"
	sort_order = 4

/datum/category_item/player_setup_item/general/background/load_character(var/savefile/S)
	from_file(S["med_record"],pref.med_record)
	from_file(S["sec_record"],pref.sec_record)
	from_file(S["gen_record"],pref.gen_record)
	from_file(S["home_system"],pref.home_system)
	from_file(S["citizenship"],pref.citizenship)
	from_file(S["faction"],pref.faction)
	from_file(S["religion"],pref.religion)
	from_file(S["nanotrasen_relation"],pref.nanotrasen_relation)
	from_file(S["memory"],pref.memory)

/datum/category_item/player_setup_item/general/background/save_character(var/savefile/S)
	to_file(S["med_record"],pref.med_record)
	to_file(S["sec_record"],pref.sec_record)
	to_file(S["gen_record"],pref.gen_record)
	to_file(S["home_system"],pref.home_system)
	to_file(S["citizenship"],pref.citizenship)
	to_file(S["faction"],pref.faction)
	to_file(S["religion"],pref.religion)
	to_file(S["nanotrasen_relation"],pref.nanotrasen_relation)
	to_file(S["memory"],pref.memory)

/datum/category_item/player_setup_item/general/background/sanitize_character()
	return 0
/datum/category_item/player_setup_item/general/background/content(var/mob/user)
	. += "<b>Background Information</b><br><br>"
	. += "Early Life: <a href='?src=\ref[src];home_system=1'>[pref.home_system ? pref.home_system : "Unset*"]</a>"
	if(pref.home_system)
		var/datum/species/S = all_species[pref.species ? pref.species : SPECIES_HUMAN]
		var/background = S.backgrounds[pref.home_system]
		if(background)
			. += "<br>[background]<br>"
	. += "<br><br>Starting Employer: <a href='?src=\ref[src];faction=1'>[pref.faction ? pref.faction : "Unset*"]</a>"
	switch(pref.faction)
		if("Nanotrasen")
			. += "<br>You're offered a job as an employee in Nanotrasen, one of the newest and fastest research firms in the Galaxy. Nanotrasen provides you passage to a gateway that teleports you to their outpost deep inside the frontier.<br>"
		if("Refugees")
			. += "<br>You have left your previous home in a desperate search for a better life. You've been offered free passage to a gateway that will teleport you to a free-station deep inside the frontier.<br><br>"
		if("Entrepreneur")
			. += "<br>You have heard about an unexplored frontier rich in rare materials and untapped research opprotunties. Theirs money to be made everywhere, and theirs even free passage to a gateway that will teleport you to a free-station.<br>"
			
	. += "<br><br>Bank Account Pin:<br>"
	. += "<a href='?src=\ref[src];set_pin=1'>[pref.chosen_pin]</a><br>"
/datum/category_item/player_setup_item/general/background/OnTopic(var/href,var/list/href_list, var/mob/user)
	if(href_list["nt_relation"])
		var/new_relation = input(user, "Choose your relation to [GLOB.using_map.company_name]. Note that this represents what others can find out about your character by researching your background, not what your character actually thinks.", "Character Preference", pref.nanotrasen_relation)  as null|anything in COMPANY_ALIGNMENTS
		if(new_relation && CanUseTopic(user))
			pref.nanotrasen_relation = new_relation
			return TOPIC_REFRESH

	else if(href_list["home_system"])
		var/datum/species/S = all_species[pref.species ? pref.species : SPECIES_HUMAN]
		if(S.backgrounds.len)
			var/choice = input(user, "Please choose a background.", "Character Preference", pref.home_system) as null|anything in S.backgrounds
			if(choice)
				pref.home_system = choice
		else
			pref.home_system = "Unknown"
		return TOPIC_REFRESH

	else if(href_list["citizenship"])
		var/choice = input(user, "Please choose your current citizenship.", "Character Preference", pref.citizenship) as null|anything in GLOB.using_map.citizenship_choices + list("None","Other")
		if(!choice || !CanUseTopic(user))
			return TOPIC_NOACTION
		if(choice == "Other")
			var/raw_choice = sanitize(input(user, "Please enter your current citizenship.", "Character Preference") as text|null, MAX_NAME_LEN)
			if(raw_choice && CanUseTopic(user))
				pref.citizenship = raw_choice
		else
			pref.citizenship = choice
		return TOPIC_REFRESH

	else if(href_list["faction"])
		var/list/joinable = list("Nanotrasen", "Refugees", "Entrepreneur")
		var/choice = input(user, "Please choose a reason for coming to the frontier", "Character Preference", pref.faction) as null|anything in joinable
		if(choice)
			pref.faction = choice
		return TOPIC_REFRESH

	else if(href_list["religion"])
		var/choice = input(user, "Please choose a religion.", "Character Preference", pref.religion) as null|anything in GLOB.using_map.religion_choices + list("None","Other")
		if(!choice || !CanUseTopic(user))
			return TOPIC_NOACTION
		if(choice == "Other")
			var/raw_choice = sanitize(input(user, "Please enter a religon.", "Character Preference")  as text|null, MAX_NAME_LEN)
			if(raw_choice)
				pref.religion = sanitize(raw_choice)
		else
			pref.religion = choice
		return TOPIC_REFRESH

	else if(href_list["set_medical_records"])
		var/new_medical = sanitize(input(user,"Enter medical information here.","Character Preference", html_decode(pref.med_record)) as message|null, MAX_PAPER_MESSAGE_LEN, extra = 0)
		if(!isnull(new_medical) && !jobban_isbanned(user, "Records") && CanUseTopic(user))
			pref.med_record = new_medical
		return TOPIC_REFRESH

	else if(href_list["set_general_records"])
		var/new_general = sanitize(input(user,"Enter employment information here.","Character Preference", html_decode(pref.gen_record)) as message|null, MAX_PAPER_MESSAGE_LEN, extra = 0)
		if(!isnull(new_general) && !jobban_isbanned(user, "Records") && CanUseTopic(user))
			pref.gen_record = new_general
		return TOPIC_REFRESH

	else if(href_list["set_security_records"])
		var/sec_medical = sanitize(input(user,"Enter security information here.","Character Preference", html_decode(pref.sec_record)) as message|null, MAX_PAPER_MESSAGE_LEN, extra = 0)
		if(!isnull(sec_medical) && !jobban_isbanned(user, "Records") && CanUseTopic(user))
			pref.sec_record = sec_medical
		return TOPIC_REFRESH

	else if(href_list["set_memory"])
		var/memes = sanitize(input(user,"Enter memorized information here.","Character Preference", html_decode(pref.memory)) as message|null, MAX_PAPER_MESSAGE_LEN, extra = 0)
		if(!isnull(memes) && CanUseTopic(user))
			pref.memory = memes
		return TOPIC_REFRESH
	else if(href_list["set_pin"])
		var/chose = input(user,"Enter starting bank pin (1000-9999)","Character Preference") as num
		if(chose > 9999 || chose < 1000)
			to_chat(user, "Your pin must be between 1000 and 9999")
		else
			pref.chosen_pin = chose
		return TOPIC_REFRESH
	return ..()
