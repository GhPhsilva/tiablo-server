/**
 * Canary - A free and open-source MMORPG server emulator
 * Copyright (©) 2019-2024 OpenTibiaBR <opentibiabr@outlook.com>
 * Repository: https://github.com/opentibiabr/canary
 * License: https://github.com/opentibiabr/canary/blob/main/LICENSE
 * Contributors: https://github.com/opentibiabr/canary/graphs/contributors
 * Website: https://docs.opentibiabr.com/
 */

#pragma once

enum ItemAttribute_t : uint64_t {
	NONE = 0,
	ACTIONID = 1,
	UNIQUEID = 2,
	DESCRIPTION = 3,
	TEXT = 4,
	DATE = 5,
	WRITER = 6,
	NAME = 7,
	ARTICLE = 8,
	PLURALNAME = 9,
	WEIGHT = 10,
	ATTACK = 11,
	DEFENSE = 12,
	EXTRADEFENSE = 13,
	ARMOR = 14,
	HITCHANCE = 15,
	SHOOTRANGE = 16,
	OWNER = 17,
	DURATION = 18,
	DECAYSTATE = 19,
	CORPSEOWNER = 20,
	CHARGES = 21,
	FLUIDTYPE = 22,
	DOORID = 23,
	SPECIAL = 24,
	IMBUEMENT_SLOT = 25,
	OPENCONTAINER = 26,
	QUICKLOOTCONTAINER = 27,
	DURATION_TIMESTAMP = 28,
	AMOUNT = 29,
	TIER = 30,
	STORE = 31,
	CUSTOM = 32,
	LOOTMESSAGE_SUFFIX = 33,
	STORE_INBOX_CATEGORY = 34,
	OBTAINCONTAINER = 35,

	// Epic Items System
	EPIC_ITEM_ID          = 36, // uint32_t — references epic_items.id
	EPIC_ITEM_RARITY      = 37, // uint8_t  — references epic_items_rarity.id (0 until identified)
	EPIC_ITEM_IDENTIFIED  = 38, // bool     — false = unidentified
	EPIC_MODIFIER_1_ID    = 39, // uint16_t — attack modifier id
	EPIC_MODIFIER_1_VALUE = 40, // int32_t  — rolled value
	EPIC_MODIFIER_2_ID    = 41, // uint16_t — defense modifier id
	EPIC_MODIFIER_2_VALUE = 42, // int32_t
	EPIC_MODIFIER_3_ID    = 43, // uint16_t — support modifier id
	EPIC_MODIFIER_3_VALUE = 44, // int32_t
};

enum ItemDecayState_t : uint8_t {
	DECAYING_FALSE = 0,
	DECAYING_TRUE,
	DECAYING_PENDING,
	DECAYING_STOPPING,
};

enum ItemAnimation_t : uint8_t {
	ANIMATION_NONE = 0,
	ANIMATION_RANDOM = 1,
	ANIMATION_DESYNC = 2,
};
