local _, fPB = ...

local defaultSpells1 = {--Highest prio spells (distinguished via size by default...)

	-- Mage
	45438, --Ice Block
	118, --Polymorph r1
		12824, --Polymorph r2
		12825, --Polymorph r3
		12826, --Polymorph r4
		28271, --Polymorph turtle
		28272, --Polymorph pig
	18469, --Improved Counterspell
	12355, --Impact Stun
    31661, --Dragon's Breath r1
		33041, --Dragon's Breath r2
		33042, --Dragon's Breath r3
		33043, --Dragon's Breath r4
	122, --Frost Nova r1
		865, --Frost Nova r2
		6131, --Frost Nova r3
		10230, --Frost Nova r4
		27088, --Frost Nova r5
	12494, --Frostbite
	33395, --Freeze (Water Elemental)
	6146, --Slow
	
	-- Shaman


	-- Druid
	29166, --Innervate
	33786, --Cyclone
	5211, --Bash r1
		6798, --Bash r2
		8983, --Bash r3
	16922, --Starfire Stun
	16979, --feral charge
	
	-- Paladin
	642, --Divine Shield r1
		1020, --Divine Shield r2
	6940, --Blessing of Sacrifice r1
		20729, --Blessing of Sacrifice r2
		27147, --Blessing of Sacrifice r3
		27148, --Blessing of Sacrifice r4
	853, --Hammer of Justice r1
		5588, --Hammer of Justice r2
		5589, --Hammer of Justice r3
		10308,--Hammer of Justice r4
	9005, --pounce (stun) r1
		9823, --pounce (stun) r2
		9827, --pounce (stun) r3
		27006, --pounce (stun) r4
	
	-- Warrior
	871, --Warrior Shield Wall
	5246, --Intimidating Shout
	20253, --Intercept Stun r1
		20614, --Intercept Stun r2
		20615, --Intercept Stun r3
		25273, --Intercept Stun r4
		25274, --Intercept Stun r5
	12798, --Revenge Stun
	12809, --Concussion Blow
	7922, --Charge Stun
	5530, --Mace Spec Stun (Warrior & Rogue)
	23694, --Improved Hamstring
	34510, -- Stormherald/Deep thunder stun
	3411, --Intervene
	676, --Disarm
	
	-- Rogue
	2094, --Blind
	6770, --Sap r1
		2070, --Sap r2
		11297, --sap r3
	
	-- Hunter
	19386, --Wyvern Sting
	1513, --Scare Beast r1
		14326, --Scare Beast r2
		14327, --Scare Beast r3
	3355, --Freezing Trap
		14308, --Freezing Trap
		14309, --Freezing Trap
	19229, -- Improved Wing Clip
	19184, --Entrapment r1
		19387, --Entrapment r2
		19388, --Entrapment r3
	19410, --Improved Concussive Shot
	
	-- Priest
	605, --Mind Control
	8122, --Psychic Scream r1
		8124, --Psychic Scream r2
		10888, --Psychic Scream r3
		10890, --Psychic Scream r4
	33206, --Pain Suppression
	15269, --Blackout
	44041, --Chastise r1
		44043, --Chastise r2
		44044, --Chastise r3
		44045, --Chastise r4
		44046, --Chastise r5
		44047, --Chastise r6
	-- Warlock
	710, --Banish r1
		18647, --Banish r2
	5782, --Fear r1
		6213, --Fear r2
		6215, --Fear r3
	6789, --Death Coil r1
		17925, --Death Coil r2
		17926, --Death Coil r3
		27223, --Death Coil r4
	5484, --Howl of Terror r1
		17928, --Howl of Terror r2
	6358, --Seduction (Succubus)
	24259, --Spell Lock Silence
	18093, --Pyroclasm
	22703, --Inferno Effect
	31117, -- Unstable Affliction
	1714, --Curse of Tongues r1
		11719, --Curse of Tongues r2
	18223, --Curse of Exhaustion
	
	----
	23333, -- Warsong Flag (horde WSG flag)
	23335, -- Silverwing Flag (alliance WSG flag)
	34976, -- Netherstorm Flag (EotS flag)
	20549, -- War Stomp
	28730, --Arcane Torrent (Mana)
    25046, --Arcane Torrent (Energy)
	1090, --Magic Dust
	13327, --Reckless Charge
	835, --Tidal Charm
    5134, --Flash Bomb
    19769, --Thorium Grenade
    4068, --Iron Grenade
    15753, --Linken's Boomerang Stun
    13237, --Goblin Mortar trinket
    18798, --Freezing Band
	19482, --Doom Guard Stun
	30153, --Felguard Stun
	33702, 33697, 20572, --Blood Fury (Orc Racial)
	26297, 26296, 20554, -- Berserking (Troll Racial)
    20594, --Stoneform (Dwarf Racial)
    7744, --Will of the Forsaken
	20600, --Perception
}

local defaultSpells2 = {--semi-important spells, add them with mid size icons.

	-- Mage
	12042, --Arcane Power
	12472, --Icy Veins
	82691, --Ring of frost
	86949, --Cauterize
	543, --Fire Ward r1
		8457, --Fire Ward r2
		8458, --Fire Ward r3
		10223, --Fire Ward r4
		10225, --Fire Ward r5
		27128, --Fire Ward r6
	6143, --Frost ward r1
		8461, --Frost ward r2
		8462, --Frost ward r3
		10177, --Frost ward r4
		28609, --Frost ward r5
		32796, --Frost ward r6
	12043, --Presence of Mind
	31641, --Blazing speed
	66, --Invisibility
	12051, --Evocation
	
	
	-- Shaman
	32182, --Heroism
	2825, --Bloodlust
	16166, --Elemental Mastery - burst
	39796, --Stoneclaw Totem
	16188, --NS(shaman)
	30823, --Shamanistic Rage
	
	-- Druid
	--33891, --Tree of Life
	1850, --Dash
	22812, --Barkskin
	339, --Entangling Roots r1
		19975,
	1062, --Entangling Roots r2
		19974,
	5195, --Entangling Roots r3
		19973,
	5196, --Entangling Roots r4
		19972,
	9852, --Entangling Roots r5
		19971,
	9853, --Entangling Roots r6
		19970,
	26989, --Entangling Roots r7
		27010,
	22570, --Maim
	2637, --Hibernate r1
		18657, --Hibernate r2
		18658, --Hibernate r3
	16689, --Nature's Grasp (Druid)
	17116, --NS(druid)
	16689, --Nature's grasp r1
		16810, --Nature's grasp r2
		16811, --Nature's grasp r3
		16812, --Nature's grasp r4
		16813, --Nature's grasp r5
		17329, --Nature's grasp r6
		27009, --Nature's grasp r7
	740, --Tranquility r1
		8918, --Tranquility r2
		9862, --Tranquility r3
		9863, --Tranquility r4
		26983, --Tranquility r5
		
	-- Paladin
	1022, --Blessing of Protection r1
		5599, --Blessing of Protection r2
		10278, --Blessing of Protection r3
	1044, --Blessing of Freedom
	31884, --Avenging Wrath
	20066, --Repentance
	498, --Divine Protection
	53563, --Beacon of Light
	10326, --Turn Evil (pally)
	20170, --Seal of Justice stun
	2878, --Turn Undead r1
		5627,--Turn Undead r2
		
	-- Warrior
	1719, --Recklessness
	23920, --Spell Reflection
	18499, --Berserker Rage
	12292, --Death Wish
	18498, --Improved Shield Bash
	19306, --Counterattack r1
		20909, --Counterattack r2
		20910, --Counterattack r3
		27067, --Counterattack r4
	12975, --Last Stand
	20230, --Retaliation
		
	-- Rogue
	45182, --Cheating Death
	31230, --Cheat Death (cd)
	31224, --Cloak of Shadows
	2983, --Sprint
	1966, --Feint
	5277, --Evasion
	13750, --Adrenaline Rush
	1833, --Cheap Shot
	1776, --Gouge r1
		1777, --Gouge r2
		8629,  --Gouge r3
		11285, --Gouge r4
		11286, --Gouge r5
		38764, --Gouge r6
	408, --Kidney Shot r1
		8643, --Kidney Shot r2
	18425, --Improved Kick
	1330, --Garrote Silence
	8647, --Expose armor r1
		8649, --Expose armor r2
		8650, --Expose armor r3
		11197, --Expose armor r4
		11198, --Expose armor r5
		26866, --Expose armor r6
	
	-- Hunter
	19503, --Scatter Shot (hunter)
	3355, --Freezing Trap
	1499, --Freezing Trap
	37587, --Bestial Wrath
	19574, --Bestial Wrath
	19577, --Intimidation
	34490, --Silencing Shot (hunter)
	24394, --Intimidation
	34692, -- The Beast Within
	19263, --Deterrence
	
	-- Priest
	10060, --Power Infusion
	9484, --Shackle Undead
	15487, --Silence
	-- 15286, --Vampiric Embrace
	6346, --Fear Ward
	9484, --Shackle Undead r1
		9485, --Shackle Undead r2
		10955, --Shackle Undead r3
	
	-- Warlock
	30283, --Shadowfury r1
		30413, --Shadowfury r2
		30414, --Shadowfury r3
	43523, --Unstable Affliction
	32752, --Summoning Disorientation
	18708, --Fel domination
	7812, --Sacrifice (pet) r1
		19438, --Sacrifice (pet) r2
		19440, --Sacrifice (pet) r3
		19441, --Sacrifice (pet) r4
		19442, --Sacrifice (pet) r5
		19443, --Sacrifice (pet) r6
		27273, --Sacrifice (pet) r7
	6229, --Shadow Ward r1
		11739, --Shadow Ward r2
		11740, --Shadow Ward r3
		28610, --Shadow Ward r4
	34936, --Backlash
	17941, --Nightfall (Shadow Trance)
	30300, --Nether Protection
	
	----
	2335, --Swiftness Potion
	6624, --Free Action Potion
	67867, --Trampled (ToC arena spell when you run over someone)
	3448, --Lesser Invisibility Potion
	11464, --Invisibility Potion
	17634, --Potion of Petrification
	30457, --eng belt backfire debuff
	30458, --eng belt absorb
	30456, --eng belt absorb
	20600, --Living Free Action (potion)
	6615, --Free Action (potion)
	31368, --Heavy Netherweave Net
	
	4067, --Big Bronze Bomb
    4068, --Iron Grenade
    4069, --Big Iron Bomb
    12543, --Hi-Explosive Bomb
    12562, --The Big One
    19769, --Thorium Grenade
    19784, --Dark Iron Bomb
    19821, --Arcane Bomb
    30216, --Fel Iron Bomb
    30217, --Adamantite Grenade
    30461, --The Bigger One
    39965, --Frost Grenades
}
fPB.defaultSpells1 = defaultSpells1
fPB.defaultSpells2 = defaultSpells2
