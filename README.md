# Vostok Trainer 1.0.0

[Download the latest VostokTrainer.vmz](https://raw.githubusercontent.com/Leak1337/vostok-trainer/main/VostokTrainer.vmz) · [Deutsche Anleitung](./README.de.md)

An in-game trainer for single-player **Road to Vostok 0.2.3.1** using Metro Mod Loader 3.5.x.

Press **F6** to open the trainer. The game pauses while the menu is open. Press **F6** or **Esc** to close it. ESP and gameplay features start switched off. The trainer saves your display settings, search, and watchlist automatically.

Use the language selector at the top right to switch between **English** and **Deutsch**. Your selection applies to the menu and trainer overlays and is remembered between sessions.

## Install or update

1. Install [Metro Mod Loader 3.5.x](https://github.com/ametrocavich/vostok-mod-loader/releases) if needed. Put `override.cfg` and `modloader.gd` next to `RTV.exe`.
2. [Download `VostokTrainer.vmz`](https://raw.githubusercontent.com/Leak1337/vostok-trainer/main/VostokTrainer.vmz) and put it in the `mods` folder next to `RTV.exe`. Create the folder if needed. When updating, close the game and replace the old VMZ.
3. Start the game, enable **Vostok Trainer** in the mod loader, load a save, and press **F6**.

## Player

- **Unlimited Stamina** keeps sprinting and arm stamina full.
- **Unlimited Ammo** replaces cartridges as you fire. Load the weapon once. Manually operated weapons still need to be cycled.
- **No Weapon Wear** preserves the weapon's current condition when firing.
- **No Weapon Jams** prevents new jams and clears an existing jam when the weapon is ready to use. It works independently of weapon wear.
- **God Mode** blocks regular damage and keeps health and oxygen full.
- **No Fall Damage** prevents fall damage and fractures independently of God Mode.
- **Increased Carry Capacity** multiplies base carry capacity by five and keeps equipment bonuses.
- **Heal Now** restores health and oxygen and treats injuries. It is available on a loaded map while your character is alive.
- **Sprint Speed** increases sprint speed up to twice its normal value. Stamina use still applies.
- **Jump Height** increases normal jump height up to about twice its usual value. Fall protection is a separate setting.
- **Unlimited Oxygen** keeps oxygen full, including underwater, independently of God Mode.
- **Keep Energy and Hydration Full** keeps both meters full.
- **Night Vision** brightens dark areas and adds a green tint.

## Actor ESP and radar

**Show Enemies**, **Show Traders**, and **Show Other NPCs** are independent toggles. Active traders are cyan. Active nomads and the cat are light green. **Show Skeletons** follows the animated bones of enemies and roaming nomads. Lines get thinner with distance. Tracers and distance labels are configurable. The shared actor range is **10–400 m**, with a default of **150 m**.

**Show Radar** displays enemies, traders, and NPCs around and behind you. The radar sits at the bottom left, rotates with your camera, and uses the actor ESP range and colors. It can run by itself.

## Loot ESP and loot filters

- **Show Ground Loot** marks loose items in view, including through walls.
- **Show Containers and Storage** previews the contents of crates, cabinets, and storage before you open them. Locked containers are labeled. **Show Empty Containers** is optional.
- **List Loot in View** collects nearby markers around the center of the screen. Aim at a building to see loot in that direction or at a container to see more of its contents. Loot farther behind a building can also appear if it is in the same direction and within range.
- **Group Nearby Loot Markers** combines nearby markers and counts quest matches. Aim at the group to see up to five individual targets and how many more are in the group.
- **Loot Filters** lets you select weapons, ammunition, attachments, food and drink, medical supplies, gear, electronics, keys, quest items, and other items. Filters apply to both ground loot and container contents. Items required by tasks in your notes are marked **[Quest]** in yellow.
- Item names show their rarity. Common weapons are orange, rare items blue, and legendary items violet. Rare and legendary weapons use their rarity color. Quest items keep their yellow label and show their rarity as text.
- Tracers, distance labels, and a rare/legendary-only filter are independent. The loot range is **10–400 m**, with a default of **150 m**.

ESP refreshes the target list and loot data about ten times per second. Visible marker positions and skeletons are projected each frame.

## Item search and watchlist

Enable ground loot or containers in **Loot ESP**, then open **Item Search**. Search for part of an item name or its internal ID. The watchlist supports up to 24 terms and 512 characters, with entries separated by commas or line breaks.

Matches are labeled **[Search]** or **[Watchlist]**. Containers with matching items are labeled **[Match]**. Matches are shown even if their item categories are filtered out. **Show Only Search and Watchlist Matches** hides other loot while at least one search term is set.

## ESP profiles

The **Profiles** tab includes **Default**, **Quest**, **Weapons**, and **Everything**. Enter a name and click **Save** to store your current ranges, loot filters, display options, and colors. Save under the same name to update the profile.

Your search, watchlist, and last ESP settings are restored when you restart the game. Loading a profile keeps your search and watchlist. ESP and gameplay feature switches are controlled separately.

## World controls

With a map loaded, use the **World** tab to set the time in five-minute increments or freeze the regular clock. Sleeping and traveling can still advance time. **Set Weather** includes Clear, Overcast, Rain, Storm, Fog, Windy, and Aurora. Weather changes appear outdoors, then normal weather simulation resumes. The next regular save can store the changed time and weather.

## Item spawner

With a map loaded, open **Item Spawner**. Search the catalog by name or internal ID, select an item, and add up to ten copies to your inventory per click. Items use the normal inventory grid. When space runs out, the trainer stops and reports how many copies were added. Ammo and consumables use their default quantity per copy. Magazines are added empty.

## Teleport

Open **F6 → Teleport** to see active traders, map exits, and points of interest such as wells, campfires, radios, and nomad camp spots. Each target shows its distance.

- **Go to Target** places you on clear ground near the selected target on the same map.
- **Change Map** uses the selected exit from your current location. The game handles arrival, travel time, and its usual save rules. Locked exits still need to be unlocked in the game.
- **Last Position** appears after a local teleport. It returns you to your previous location on the same map if a landing spot is available.
- **Save Position** creates a personal waypoint on the current map. Give it an optional name. Saving under an existing name updates that waypoint. Your waypoints persist across restarts and can be selected or removed in the target list.

## Hotkeys

Turn on **Enable Trainer Hotkeys** under **Player** to use these shortcuts during gameplay. They start disabled.

| Key | Action |
| --- | --- |
| **F7** | Heal now |
| **F8** | Save your current position as an automatically named waypoint |
| **F9** | Return to the last teleport origin on the same map |

## Build from source

Zip `mod.txt` and the `VostokTrainer` directory together. Keep `mod.txt` at the archive root, use forward slashes in archive paths, and rename the archive to `VostokTrainer.vmz`.
