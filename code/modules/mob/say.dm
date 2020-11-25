/mob/verb/say_verb(message as text)
	set name = "say"
	set category = "IC"
	if(!length(message))
		return
	if(say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	set_typing_indicator(FALSE)
	// clear_typing_indicator()		// clear it immediately!
	say(message)

/mob/verb/me_verb(message as message)
	set name = "me"
	set category = "IC"
	if(!length(message))
		return
	if(say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return

	if(muffled)
		return me_verb_subtle(message)
	message = sanitize_or_reflect(message,src) //VOREStation Edit - Reflect too-long messages (within reason)
	// message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))

	// clear_typing_indicator()		// clear it immediately!
	set_typing_indicator(FALSE)

	// usr.emote("me",1,message,TRUE)

	if(use_me)
		usr.emote("me",usr.emote_type,message)
	else
		usr.emote(message)

/mob/say_mod(input, message_mode)
	if(message_mode == MODE_WHISPER_CRIT)
		return ..()
	if((input[1] == "!") && (length_char(input) > 1))
		message_mode = MODE_CUSTOM_SAY
		return copytext_char(input, 2)
	var/customsayverb = findtext(input, "*")
	if(customsayverb)
		message_mode = MODE_CUSTOM_SAY
		return lowertext(copytext_char(input, 1, customsayverb))
	return ..()

/proc/uncostumize_say(input, message_mode)
	. = input
	if(message_mode == MODE_CUSTOM_SAY)
		var/customsayverb = findtext(input, "*")
		return lowertext(copytext_char(input, 1, customsayverb))

/mob/proc/whisper_wrapper()
	var/message = input(src, "", "whisper (text)") as text|null
	if(!length(message))
		return
	return whisper_verb(message)

/mob/verb/whisper_verb(message as text)
	set name = "Whisper"
	set category = "IC"
	if(!length(message))
		return
	if(say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	whisper(message)


/mob/proc/whisper(message, datum/language/language=null)
	say(message, language) //only living mobs actually whisper, everything else just talks

/mob/proc/say_dead(message)
	var/name = real_name
	var/alt_name = ""

	if(say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return

	var/jb = jobban_isbanned(src, "OOC")
	if(QDELETED(src))
		return

	if(jb)
		to_chat(src, "<span class='danger'>You have been banned from deadchat.</span>")
		return



	if (src.client)
		if(src.client.prefs.muted & MUTE_DEADCHAT)
			to_chat(src, "<span class='danger'>You cannot talk in deadchat (muted).</span>")
			return

		if(src.client.handle_spam_prevention(message,MUTE_DEADCHAT))
			return

	var/mob/dead/observer/O = src
	if(isobserver(src) && O.deadchat_name)
		name = "[O.deadchat_name]"
	else
		if(mind && mind.name)
			name = "[mind.name]"
		else
			name = real_name
		if(name != real_name)
			alt_name = " (died as [real_name])"

	var/spanned = say_quote(say_emphasis(message))
	message = emoji_parse(message)
	var/rendered = "<span class='game deadsay'><span class='prefix'>DEAD:</span> <span class='name'>[name]</span>[alt_name] <span class='message'>[emoji_parse(spanned)]</span></span>"
	log_talk(message, LOG_SAY, tag="DEAD")
	deadchat_broadcast(rendered, follow_target = src, speaker_key = key)

/mob/proc/check_emote(message)
	if(message[1] == "*")
		emote(copytext(message, length(message[1]) + 1), intentional = TRUE)
		return TRUE

// /mob/proc/hivecheck()
// 	return 0

// /mob/proc/lingcheck()
// 	return LINGHIVE_NONE

/mob/proc/get_message_mode(message)
	var/key = message[1]
	if(key == "#")
		return MODE_WHISPER
	else if(key == ";")
		return MODE_HEADSET
	else if((length(message) > (length(key) + 1)) && (key in GLOB.department_radio_prefixes))
		var/key_symbol = lowertext(message[length(key) + 1])
		return GLOB.department_radio_keys[key_symbol]

////////////////////////////////////////////////////////////
/mob/proc/subtle_wrapper()
	var/message = input(src, "", "subtle (text)") as message|null
	if(message)
		me_verb_subtle(message)
/*
/mob/proc/say_understands(var/mob/other,var/datum/language/speaking = null)

	if (src.stat == DEAD)
		return 1

	//Universal speak makes everything understandable, for obvious reasons.
	else if(src.universal_speak || src.universal_understand)
		return 1

	//Languages are handled after.
	if (!speaking)
		if(!other)
			return 1
		if(other.universal_speak)
			return 1
		if(isAI(src) && ispAI(other))
			return 1
		if (istype(other, src.type) || istype(src, other.type))
			return 1
		return 0

	if(speaking.flags & INNATE)
		return 1

	//Language check.
	for(var/datum/language/L in src.languages)
		if(speaking.name == L.name)
			return 1

	return 0

/mob/proc/emote(var/act, var/type, var/message)
	if(act == "me")
		return custom_emote(type, message)

/mob/proc/get_ear()
	// returns an atom representing a location on the map from which this
	// mob can hear things

	// should be overloaded for all mobs whose "ear" is separate from their "mob"

	return get_turf(src)

/mob/proc/say_test(var/text)
	var/ending = copytext_char(text, length_char(text))
	if (ending == "?")
		return "1"
	else if (ending == "!")
		return "2"
	return "0"

//parses the message mode code (e.g. :h, :w) from text, such as that supplied to say.
//returns the message mode string or null for no message mode.
//standard mode is the mode returned for the special ';' radio code.
/mob/proc/parse_message_mode(var/message, var/standard_mode="headset")
	if(length_char(message) >= 1 && copytext_char(message,1,2) == ";")
		return standard_mode

	if(length_char(message) >= 2)
		var/channel_prefix = copytext_char(message, 1 ,3)
		return department_radio_keys[channel_prefix]

	return null

//parses the language code (e.g. :j) from text, such as that supplied to say.
//returns the language object only if the code corresponds to a language that src can speak, otherwise null.
/mob/proc/parse_language(var/message)
	var/prefix = copytext_char(message,1,2)
	// This is for audible emotes
	if(length_char(message) >= 1 && prefix == "!")
		return GLOB.all_languages["Noise"]

	if(length_char(message) >= 2 && is_language_prefix(prefix))
		var/language_prefix = lowertext(copytext_char(message, 2 ,3))
		var/datum/language/L = GLOB.language_keys[language_prefix]
		if (can_speak(L))
			return L
		else
			return GLOB.all_languages[LANGUAGE_GIBBERISH]
	return null
*/
