@====================================================@=======================================@
|                # Dani's Core Mod #                 | v1.3             for Stonehearth 1.0+ |
@====================================================@=======================================@
|				  by Daniel Angione					    					     https://stonehearth.net/ |                                                                     
@============================================================================================@

## DESCRIPTION

This mod was born during the creation of the Glassworks Mod upon the realization that some
of the systems and/or materials and effects created for Glassworks could be useful for
other mods - especially the "cooling down" service that allows items to be transformed into
different items depending on where they are, stored or not.

If these things remained inside Glassworks, it would always become a dependency for other
mods even if the player didn't want to use glassworks itself. To allow for greater flexbility
for the players and to also provide such systems to other modders that wish to use them, the
Core Mod was created.

As of now it only contains the necessary systems, materials and animations for the Glassworks
mod, however I plan to expand on it in the future and also create new mods that will utilize
the same common basics.

## CONTENTS

# COLOR MAPS
The Core mod contains the following color maps' aliases:

	"core_dani:color_map:glassworks"
		Contains all the glass colors and the obsidian colors from the Glassworks mod. There's 
		also a text file inside the folder with the list of colors.
	
	"core_dani:color_map:heat"
		Contains several heat/glowy related colors.
		
	"core_dani:color_map:fluids"
		Contains colors for fluids with transparency.

# MATERIAL MAP 
The Core mod has a single material map that contains the definitions of all the materials in 
the different color maps. Its alias is:

	"core_dani:material_map"
	
# ANIMATIONS & EFFECTS
The Core mod adds two animation tables for rigged entities and their accompanying effects.
They can be found with the following aliases:

	"core_dani:animations:glass_door"
	"core_dani:effects:glass_door"
		Allows for doors to have an additional matrix on their .qb models.
		The additional matrix must be named "glass" but can be anything.
	
	"core_dani:animations:glass_double_door"
	"core_dani:effects:glass_double_door"
		Allos for double doors to have an additional matrix to each side on their .qb models.
		The additional matrix must be named "leftGlass" and "rightGlass" but can be anything.

# STORAGE COMPONENT
You can use the "default_filter" key to define the default filter for a storage entity.
You can also use the "reposition_items" key (set to either "fill" or "shift" to make your entities be
reorganized inside containers when things are taken from them. That allows piles of things to not 
have floating items, for example.

# BUFF SCRIPTS
Use the "script": "core_dani:buff_scripts:add_thought" to add a thought (key is "thought") to a buff.
Any entity inflicted by this buff will present this thought.

# FACTION UNLOCKS CAMPAIGN
You can mix into this campaign to unlock recipes based on faction. This should be very helpful for creating
custom recipes per faction without conflicting with mods that redefine faction jobs like ACE.
		
# CORE_DANI:COOLING
This service allows you to create items that can be transformed into different items - just
like the Food_Decay service - but the items can be different depending on whether or not the 
original entity is left on the ground or inside storage.

To utilize the Cooling service, you must add the Core_dani:cooling service checker to your
entity. It goes under "entity_data" and should look like this:

		"core_dani:cooling": {
			"initial_cooling": {
				"min": _,
				"max": _
			},
			"cool_entity_alias": "_",
			"proper_cool_entity_alias": "_",
			"proper_cooler_alias": "_",
			"proper_cooler_alias_2": "_",
			"proper_cooler_alias_3": "_",
			"alternative_cool_entity_alias": "_",
			"alternative_cooler_alias": "_"
		}

The "min" value represents the minimum IN-GAME HOURS before the item is transformed;

The "max" value represents the maximum IN-GAME HOURS before the item is transformed;

"cool_entity_alias" is the alias of the entity to be transformed into if the original entity is
left outside/on the ground; It will only transform if defined, if not defined the entity will not
be transformed.

"proper_cool_entity_alias" is the alias of the entity to be transformed into if the original
entity is left inside some sort of storage.

"proper_cooler_alias", "proper_cooler_alias_2" and "proper_cooler_alias_3" are optional and are the aliases of the proper
containers that can properly transform the item. Any other containers will result in the
"cool_entity_alias".

"alternative_cooler_alias" is an optional, alternative cooler entity that will provide different results if used. The
entity transformed will be the "alternative_cool_entity_alias".

To make sure that your item can only be stored inside the desired containers, utilize unique
input tables for the container and material tags for the entity.
	
## COMPATIBILITY

This mod should always be compatible with most mods as long as they do not override basic 
functions of the game.

## LOCALIZATION

The Core Mod has no localization since it adds no entities. All documentation is in english.

## CREDITS, SUPPORT & LICENSE

Mod created by Daniel Angione (DaniAngione#3266 on Discord; daniangi@gmail.com)
Stonehearth created by Radiant Entertainment (https://stonehearth.net)

VERY SPECIAL thanks to the people that helped this system become what it is and actually work!
Max, BrunoSupremo and Relyss - THANK YOU! <3

This mod and all its contents are under a GNU GPL 3.0 license and may
be used, shared, remixed and anything else as long as credit is given, linked and the
same license is used! More info: https://www.gnu.org/licenses/gpl-3.0.en.html

## CHANGELOG

# (September 20th, 2019) v1.3
- Reorganized the mod structure, adding more flexbility for the future.
- Fixed an error with the cooling service when it tried to increment cooling.
- Fixed an error that prevented things that can cool from suffering other forms of transformation: for example, food decay.
- Added a monkey patch to the storage component allowing for Default filters to be defined.
- Added a third "proper_cooler" option for the Cooling service. It still uses the same "old" structure - a better and improved component is planned but will require all the other mods using it to also be updated... So this might not happen so soon.
- Added a new campaign, "Faction Unlocks" that shall be mixed into by other mods to handle recipe unlocking based on faction.
- Added a new buff script for adding thoughts through buffs.
- Added a storage renderer change for piles and such working nicer

# (July 30th, 2018) v1.2
- Cleaned and fixed for Stonehearth 1.0
- Added a new color_map in preparation for other mods.
- New functionality added: a secondary Proper Cooler for the Cooling Service

# (June 12th, 2018) v1.1
- New functionality added: Proper Coolers for the Cooling Service

# (June 12th, 2018) v1.0
- Initial release