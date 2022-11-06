# Unnamed Godot shooter
An FPS game developed in Godot 3, aiming to include a variety of core weapon types, movement options, and easy use as a template for other fps games.

The [Player](Player.gd) contains movement stuff and holds gun scenes as childs. Weapons have their own logic as to shooting/aiming/etc. by running a loop only if they're visible. This way, guns aren't limited to a base way of functioning and allow for any type of equipment to be created.

# Credits

[Qodot](https://github.com/QodotPlugin/qodot-plugin) is used as means to import maps into the game.

First person animations and models by [ImageParSeconde](https://sketchfab.com/ImageParSeconde).

[godot-quake-movement](https://github.com/axel37/godot-quake-movement) was used as a template for this project.

May contain sugar.