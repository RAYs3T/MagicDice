# MagicDice
A Sourcemod dice plugin with modular plugin support and advanced configuration options.

## Intro
This plugin offers:
* Multiple features per dice result.
* Deep configuration of each module. You can configure what speed, gravity, ammo, guns, models etc. a modules uses.
* Modular plugin support. You can super easy develop your own extensions and just load them. The core plugin offers a great API.
* ErrorSafe: If one module encounters an error, the core will detect this and just continue to work. The player will even get a new turn.
* Modern API usage and style: We tried to just use the new stuff.
* Full translation support. We some kind of force an developer to create at least one translation.

# Getting started
If you want to install MagicDice on your server, [please have a look at our wiki](https://gitlab.com/PushTheLimits/Sourcemod/MagicDice/wikis/home)
# Developers
For developing we recommand to use [SPEdit](https://github.com/JulienKluge/Spedit).

## Contribution
If you want to contribute, please create a [merge request](https://gitlab.com/PushTheLimits/Sourcemod/MagicDice/merge_requests)
(using the button on the [issues](https://gitlab.com/PushTheLimits/Sourcemod/MagicDice/issues) page)

Have a look at our [developer wiki](https://gitlab.com/PushTheLimits/Sourcemod/MagicDice/wikis/development/getting%20started) for further assistance

## Modules
Modules (a module is a plugin that provides a dice feature. Note: a result can have multiple features)
Modules are created in the `magicdice` folder.