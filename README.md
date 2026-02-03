# SummonSaver

SummonSaver is a World of Warcraft: The Burning Crusade Classic addon that provides a secure, combat-safe summon menu for Warlocks. It exposes a single macro/button you can place on your action bar, then opens a small menu to choose which demon to summon.

## Features
- Secure summon menu that can open/close in combat.
- Draggable anchor for positioning the menu.
- Reorder summon list per character.
- Keybinding support.
- Optional macro installer command.

## Installation
1. Copy the `summonsaver/` folder into your WoW `Interface/AddOns/` directory.
2. Restart WoW or run `/reload`.

## Usage
- Create a macro with the body:
  ```text
  /click SummonSaver_Toggle
  ```
- Or run: `/summonsaver installmacro` (out of combat) to create it for you.
- Place the macro on your action bar.

### Slash Commands
- `/summonsaver` — Open settings.
- `/summonsaver installmacro` — Create/update the macro (out of combat).
- `/summonsaver anchor` — Show/hide the draggable anchor.
- `/summonsaver reset` — Reset settings to defaults.

### Keybinding
Find **SummonSaver** in the keybindings menu and bind **Toggle Summon Menu**.

## Compatibility
- Target client: TBC Classic / Anniversary 2.5.x
- Interface versions: `20504, 20505`

## Development Notes
- All secure UI work happens out of combat.
- Menu open/close is handled via `SecureHandlerClickTemplate`.
- Reordering during combat queues until combat ends.

## License
MIT
