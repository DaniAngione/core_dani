# Dani's Core Mod
### by Daniel Angione
v2.0 for Stonehearth 1.1+
Compatible with Stonehearth ACE 0.9.6.18+

## DESCRIPTION

This mod was born during the creation of the Glassworks Mod upon the realization that some of the systems and/or materials and effects created for Glassworks could be useful for other mods - especially the "cooling down" service that allows items to be transformed into different items depending on where they are, stored or not.

If these things remained inside Glassworks, it would always become a dependency for other mods even if the player didn't want to use glassworks itself. To allow for greater flexbility for the players and to also provide such systems to other modders that wish to use them, the Core Mod was created.

As of now it only contains the necessary systems, materials and animations for the Glassworks mod, however I plan to expand on it in the future and also create new mods that will utilize the same common basics.

## CONTENTS

### COLOR MAPS
The Core mod contains the following color maps' aliases:

	"core_dani:color_map:glassworks"
		Contains all the glass colors and the obsidian colors from the Glassworks mod. There's 
		also a text file inside the folder with the list of colors.
	
	"core_dani:color_map:heat"
		Contains several heat/glowy related colors.
		
	"core_dani:color_map:fluids"
		Contains colors for fluids with transparency.

### MATERIAL MAP
The Core mod has a single material map that contains the definitions of all the materials in the different color maps. Its alias is:

	"core_dani:material_map"
	
### NEW ANIMATIONS & EFFECTS
The Core mod adds two animation tables for rigged entities and their accompanying effects. They can be found with the following aliases:

	"core_dani:animations:glass_door"
	"core_dani:effects:glass_door"
		Allows for doors to have an additional matrix on their .qb models.
		The additional matrix must be named "glass" but can be anything.
	
	"core_dani:animations:glass_double_door"
	"core_dani:effects:glass_double_door"
		Allows for double doors to have an additional matrix to each side on their .qb models.
		The additional matrix must be named "leftGlass" and "rightGlass" but can be anything.

### STORAGE COMPONENT CHANGES
You can use the "default_filter" key to define the default filter for a storage entity. You can also use the "reposition_items" key (set to either "fill" or "shift" to make your entities be reorganized inside containers when things are taken from them. That allows piles of things to not have floating items, for example.

### NEW BUFF SCRIPTS
Use the "script": "core_dani:buff_scripts:add_thought" to add a thought (key is "thought") to a buff. Any entity inflicted by this buff will present this thought.

### NEW COMPONENT: OPENING CONTAINER
You can use this component to create entities that will open/close (or play any other animation) when approached.

### NEW COMPONENT: ENTITY CUTAWAY
This component can be used for entities to have a different model variant when selected by the player. This allows for them to, for example, display their interior in "cutaway" style, hence its name.
		
### NEW COMPONENT: PASSIVE TRANSFORMER
Created to replace the previous "Cooling" service, which was a frankenstein version of the Food Decay service from the base game, this new component is built from the ground up to be a lot more efficient, less demanding and more powerful than the cooling service ever allowed the passive transformation mechanics to be.
	
## COMPATIBILITY

This mod should always be compatible with most mods as long as they do not override basic functions of the game.

## LOCALIZATION

The Core Mod has no localization at all. All documentation is in english.

## CREDITS, SUPPORT & LICENSE

Mod created by Daniel Angione (DaniAngione#3266 on Discord; daniangi@gmail.com)
Stonehearth created by Radiant Entertainment (https://stonehearth.net)

VERY SPECIAL thanks to the people that helped in the original version of the "cooling service":
Max, BrunoSupremo and Relyss - THANK YOU! <3

This mod and all its contents are under a GNU GPL 3.0 license and may be used, shared, remixed and anything else as long as credit is given, linked and the same license is used! More info: https://www.gnu.org/licenses/gpl-3.0.en.html

## CHANGELOG

### October 31st, 2024 - v2.0
- The "cooling service" is now discontinued, and has been completely reworked into a much more performant, flexible and powerful component called "PASSIVE TRANSFORM".
- Added a new component called ENTITY CUTAWAY that allows certain entities to display different graphics when selected.
- Hearthlings can now get buffs from eating (if ACE is not present; ACE already has this feature)
- The "Faction Unlocks" campaign has been removed since there are now more elegant ways to unlock things per faction.
- (ACE) There are new gameplay settings available if using ACE!

### May 14th, 2024 - v1.3.2
- Updated the Storage Renderer file inherited from ACE to fix broken weapon/armor racks.

### February 6th, 2020 - v1.3.1
- Small fix to a possible nil inventory error.

### September 20th, 2019 - v1.3
- Reorganized the mod structure, adding more flexbility for the future.
- Fixed an error with the cooling service when it tried to increment cooling.
- Fixed an error that prevented things that can cool from suffering other forms of transformation: for example, food decay.
- Added a monkey patch to the storage component allowing for Default filters to be defined.
- Added a third "proper_cooler" option for the Cooling service. It still uses the same "old" structure - a better and improved component is planned but will require all the other mods using it to also be updated... So this might not happen so soon.
- Added a new campaign, "Faction Unlocks" that shall be mixed into by other mods to handle recipe unlocking based on faction.
- Added a new buff script for adding thoughts through buffs.
- Added a storage renderer change for piles and such working nicer

### July 30th, 2018 - v1.2
- Cleaned and fixed for Stonehearth 1.0
- Added a new color_map in preparation for other mods.
- New functionality added: a secondary Proper Cooler for the Cooling Service

### June 12th, 2018 - v1.1
- New functionality added: Proper Coolers for the Cooling Service

### June 12th, 2018 - v1.0
- Initial release