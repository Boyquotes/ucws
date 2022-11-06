# Unnamed Godot shooter
An FPS game developed in Godot 3, aiming to include a variety of core weapon types, movement options, and easy use as a template for other fps games.

The [Player](Player.gd) contains movement stuff and holds gun scenes as childs. Weapons have their own logic as to shooting/aiming/etc. by running a loop only if they're visible. This way, guns aren't limited to a base way of functioning and allow for any type of equipment to be created.

Sliding, Decoupled Weapon-Viewmodel animations, Crouching, Mantling, Slide canceling have been implemented. There is no netcode, bots, game modes nor other stuff in it.

# Credits

[Qodot](https://github.com/QodotPlugin/qodot-plugin) is used as means to import maps into the game.

Melee model by [ImageParSeconde](https://sketchfab.com/ImageParSeconde).
Kriss Vector model by [h1ggs](https://sketchfab.com/3d-models/krsv-vector-609166faf8e5416f957c88e0af657e09)

[godot-quake-movement](https://github.com/axel37/godot-quake-movement) was used as a template for this project.

Due to personal reasons, this will not be developed further. [Blog post on that](https://painful.neocities.org/posts/2022-11-06-idk.html)

May contain sugar.
