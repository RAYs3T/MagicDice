#Translations
Each module must provide at least english translations. 
We want to provide a great user expirience, so translations are required.

## How module translations are loaded?
The name of the translation depends on the name of the plugin.
For example if you write an extension with the name `md_example` the translation for it must be named `md_example.phrases.txt`.

Then the module is getting loaded, it is automatically loading the translations for it (this way we ensure that you use translations!)

Please have a look at [the Sourcemod docs about translations](https://wiki.alliedmods.net/Translations_(SourceMod_Scripting))
if you want to know how to organize / format them.

## Translations for the core
Well translations for the core are loaded in the `OnPluginStart()` method. Nothing special here.
