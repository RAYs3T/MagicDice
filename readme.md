# MagicDice
A Sourcemod dice plugin with modular plugin support.

## Intro
This plugin offers:
* Multiple features per dice result.
* Deep configuration of each module. You can configure what speed, gravity, ammo, guns, models etc. a modules uses.
* Modular plugin support. You can super easy develop your own extensions and just load them. The core plugin offers a great API.
* ErrorSafe: If one module encounters an error, the core will detect this and just continue to work. The player will even get a new try.
* Modern API usage and style: We tried to just use the new stuff.
* Full translation support. We some kind of force an developer to create at least one translation.

# Developers
## Modules
Modules (a module is a plugin that includes a dice feature)
Modules are created in the `magicdice` folder.