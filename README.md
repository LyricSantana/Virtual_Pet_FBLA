# Virtual Pet FBLA (BudgetBuddy)
A Godot 4 virtual pet game built for FBLA Introduction to Programming. Players adopt a cat or dog, manage pet stats, and learn budgeting through care expenses, a shop system, and chores.

## Features
- Pet selection and naming flow (cat or dog)
- Stat-based pet care (hunger, happiness, energy, health, cleanliness)
- Thought bubbles and animation changes based on needs
- Shop and inventory system with item effects and costs
- Budgeting mechanics: total expenses, weekly limit, savings goal
- Chores system that rewards money for care items
- Daily stat decay and in-game day progression
- Autosave and settings (game speed, autosave toggle)

## How To Run
1. Open the project in Godot 4.x.
2. Run the main scene from the editor.

## Project Structure
- Scenes/ : Godot scenes for the main game, UI, start menu, and pet manager
- src/ : GDScript logic and default save data
- assets/ : Pixel art, sprites, backgrounds, and UI textures

## Key Scripts
- src/gameManager.gd: Game clock, stat decay, autosave, day changes
- src/petManager.gd: Pet animation, thought bubble logic, pet walking
- src/ui.gd: HUD, popups, shop, inventory, chores, reports, settings
- src/start.gd: Start menu and pet setup flow
- src/saveLoadManager.gd: JSON save/load, default merge, value clamping
- src/inventoryManager.gd: Inventory CRUD helpers
- src/itemDB.gd: Item definitions and stat effects

## Save Data
- Defaults: src/defaultSave.json
- User save (runtime): user://player_save.json

## Notes
- Built with Godot 4.x and GDScript. Pixel art created in Aseprite.
