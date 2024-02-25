/obj/item/organ/internal/ears
	name = "ears-耳朵"
	icon_state = "ears"
	desc = "There are three parts to the ear. Inner, middle and outer. Only one of these parts should be normally visible."
	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_EARS
	visual = FALSE
	gender = PLURAL

	healing_factor = STANDARD_ORGAN_HEALING
	decay_factor = STANDARD_ORGAN_DECAY

	low_threshold_passed = "<span class='info'>你的耳朵有时随着内部的嗡嗡声共鸣起来.</span>"
	now_failing = "<span class='warning'>你听不见任何声音!</span>"
	now_fixed = "<span class='info'>噪音慢慢再次塞满你的耳朵.</span>"
	low_threshold_cleared = "<span class='info'>耳鸣声消失了.</span>"

	// `deaf` measures "ticks" of deafness. While > 0, the person is unable
	// to hear anything.
	var/deaf = 0

	// `damage` in this case measures long term damage to the ears, if too high,
	// the person will not have either `deaf` or `ear_damage` decrease
	// without external aid (earmuffs, drugs)

	//Resistance against loud noises
	var/bang_protect = 0
	// Multiplier for both long term and short term ear damage
	var/damage_multiplier = 1

/obj/item/organ/internal/ears/on_life(seconds_per_tick, times_fired)
	// only inform when things got worse, needs to happen before we heal
	if((damage > low_threshold && prev_damage < low_threshold) || (damage > high_threshold && prev_damage < high_threshold))
		to_chat(owner, span_warning("The ringing in your ears grows louder, blocking out any external noises for a moment."))

	. = ..()
	// if we have non-damage related deafness like mutations, quirks or clothing (earmuffs), don't bother processing here. Ear healing from earmuffs or chems happen elsewhere
	if(HAS_TRAIT_NOT_FROM(owner, TRAIT_DEAF, EAR_DAMAGE))
		return

	if((organ_flags & ORGAN_FAILING))
		deaf = max(deaf, 1) // if we're failing we always have at least 1 deaf stack (and thus deafness)
	else // only clear deaf stacks if we're not failing
		deaf = max(deaf - (0.5 * seconds_per_tick), 0)
		if((damage > low_threshold) && SPT_PROB(damage / 60, seconds_per_tick))
			adjustEarDamage(0, 4)
			SEND_SOUND(owner, sound('sound/weapons/flash_ring.ogg'))

	if(deaf)
		ADD_TRAIT(owner, TRAIT_DEAF, EAR_DAMAGE)
	else
		REMOVE_TRAIT(owner, TRAIT_DEAF, EAR_DAMAGE)

/obj/item/organ/internal/ears/proc/adjustEarDamage(ddmg, ddeaf)
	if(owner.status_flags & GODMODE)
		return
	set_organ_damage(clamp(damage + (ddmg * damage_multiplier), 0, maxHealth))
	deaf = max(deaf + (ddeaf * damage_multiplier), 0)

/obj/item/organ/internal/ears/invincible
	damage_multiplier = 0

/obj/item/organ/internal/ears/cat
	name = "cat ears-猫耳"
	icon = 'icons/obj/clothing/head/costume.dmi'
	worn_icon = 'icons/mob/clothing/head/costume.dmi'
	icon_state = "kitty"
	visual = TRUE
	damage_multiplier = 2

//SKYRAT EDIT REMOVAL BEGIN - CUSTOMIZATION
/*
/obj/item/organ/internal/ears/cat/on_mob_insert(mob/living/carbon/human/ear_owner)
	. = ..()
	if(istype(ear_owner) && ear_owner.dna)
		color = ear_owner.hair_color
		ear_owner.dna.features["ears"] = ear_owner.dna.species.mutant_bodyparts["ears"] = "Cat"
		ear_owner.dna.update_uf_block(DNA_EARS_BLOCK)
		ear_owner.update_body()

/obj/item/organ/internal/ears/cat/on_mob_remove(mob/living/carbon/human/ear_owner)
	. = ..()
	if(istype(ear_owner) && ear_owner.dna)
		color = ear_owner.hair_color
		ear_owner.dna.species.mutant_bodyparts -= "ears"
		ear_owner.update_body()
*/
//SKYRAT EDIT REMOVAL END

/obj/item/organ/internal/ears/penguin
	name = "penguin ears-企鹅耳"
	desc = "企鹅们快乐舞步的源泉."

/obj/item/organ/internal/ears/penguin/on_mob_insert(mob/living/carbon/human/ear_owner)
	. = ..()
	if(istype(ear_owner))
		to_chat(ear_owner, span_notice("You suddenly feel like you've lost your balance."))
		ear_owner.AddElement(/datum/element/waddling)

/obj/item/organ/internal/ears/penguin/on_mob_remove(mob/living/carbon/human/ear_owner)
	. = ..()
	if(istype(ear_owner))
		to_chat(ear_owner, span_notice("Your sense of balance comes back to you."))
		ear_owner.RemoveElement(/datum/element/waddling)

/obj/item/organ/internal/ears/cybernetic
	name = "basic cybernetic ears-初级电子耳"
	icon_state = "ears-c"
	desc = "A basic cybernetic organ designed to mimic the operation of ears."
	damage_multiplier = 0.9
	organ_flags = ORGAN_ROBOTIC
	failing_desc = "似乎坏掉了."

/obj/item/organ/internal/ears/cybernetic/upgraded
	name = "cybernetic ears-电子耳"
	icon_state = "ears-c-u"
	desc =  "An advanced cybernetic ear, surpassing the performance of organic ears."
	damage_multiplier = 0.5

/obj/item/organ/internal/ears/cybernetic/whisper
	name = "whisper-sensitive cybernetic ears-微敏电子耳"
	icon_state = "ears-c-u"
	desc = "使用者可以更轻松地听到人们的低声耳语，但也会更加容易被巨大噪音伤害"
	// Same sensitivity as felinid ears
	damage_multiplier = 2

// The original idea was to use signals to do this not traits. Unfortunately, the star effect used for whispers applies before any relevant signals
// This seems like the least invasive solution
/obj/item/organ/internal/ears/cybernetic/whisper/on_mob_insert(mob/living/carbon/ear_owner)
	. = ..()
	ADD_TRAIT(ear_owner, TRAIT_GOOD_HEARING, ORGAN_TRAIT)

/obj/item/organ/internal/ears/cybernetic/whisper/on_mob_remove(mob/living/carbon/ear_owner)
	. = ..()
	REMOVE_TRAIT(ear_owner, TRAIT_GOOD_HEARING, ORGAN_TRAIT)

// "X-ray ears" that let you hear through walls
/obj/item/organ/internal/ears/cybernetic/xray
	name = "wall-penetrating cybernetic ears-穿墙电子耳"
	icon_state = "ears-c-u"
	desc = "得益于现代工程技术，使用者可以透过墙壁听到人们的讲话声.但也会更加容易被巨大噪音伤害"
	// Same sensitivity as felinid ears
	damage_multiplier = 2

/obj/item/organ/internal/ears/cybernetic/xray/on_mob_insert(mob/living/carbon/ear_owner)
	. = ..()
	ADD_TRAIT(ear_owner, TRAIT_XRAY_HEARING, ORGAN_TRAIT)

/obj/item/organ/internal/ears/cybernetic/xray/on_mob_remove(mob/living/carbon/ear_owner)
	. = ..()
	REMOVE_TRAIT(ear_owner, TRAIT_XRAY_HEARING, ORGAN_TRAIT)

/obj/item/organ/internal/ears/cybernetic/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	apply_organ_damage(20 / severity)
