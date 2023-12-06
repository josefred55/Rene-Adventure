# Rene's Adventure
#### Video Demo:  <https://www.youtube.com/watch?v=pRQrfzQN00w>
#### Description:

# Hello, my name is Freddy Arévalo, and my CS50 project is called Rene´s adventure, it is a platformer game created with lua, using the love2d framework.

## Before starting the project:

Before just starting to explain everything about the project, I would like to explain my trajectory throughout this process. I looked into one of the course seminars, that was about this topic (creating games withlove2d in lua), then i got really interested and watched a few tutorials about the language and the framework, then I decided my game was going to be a platformer, so I looked for information about some basic stuff, like creating a player, creating objects, a map, implementing a collision system, a camera, and some other things. 

## The project: Main.lua

Now, I don´t think it is necessary to explain in what order I did ALL of the things of the game, I will just go ahead and explain what everything does and why. The main.lua file is the heart of the project, since that´s the file the program looks when loading the game. But of couse, this file depends mostly of the helpers files (which we'll get to later). The game is loaded in our love.load function, it is updated at every frame by love.update, and everything at the screen is drawed in love.draw, there are some another functions like beginContact or endContact or setPresolve, they are relevant for the collision system of the game, something I added for optimization, is a variable called game_started, if the game is not running (if we are seeing the menu or a end screen) the game won´t keep updating or drawing because it checks for this variable, and only the menu or end screens will be drawed.

## Helpers: Player.lua

 This is probably the most important file here, we create a player table, via which we will keep track of EVERY property of the player (which are a lot), some of them being: the player collider object (for the collision system of the game), the player position(x and y), the player lives, the player animations, etcetera. Talking about the player.animations, they work thanks to one of our helper libraries, called anim8, which works by looking into a spritesheet, creating a grid to use just the necessary sprites and then creating an anim8 animation that will look at the grid to know which sprite it needs to draw, this is the way that almost every animation in the game works, except for some objects, that have their sprites separated in different images and in that case we have to iterate trought all of them and loop. The player collider, and every collider in the game, works because of the windfield module, it is based in love2d physics, but it upgrades a lot of things and basically it let us create a world with some specific gravity, inside of which we can create colliders of different shapes, and just play with their properties to make them do what we want to do. Going back to the player, he is loaded every time the game is started, and updated and drawed when the game is running, The player can move and jump (by moving their physical collider) using WASD or arrow keys, he has some other features like if he moves towards a wall or a platform while in the air, he will slide in that wall, and then if he jumps again, will perform a wall jump, also the player has a double jump, and when having a fire powerUp, he can press z to shoot fireballs and kill enemies (we will get to that in one moment). The player has three hearts of health, and everytime he takes damage he will lose one, logically, he will die if he loses all hearts.

## Helpers: Map.lua

This one is also very important, a map is loaded every time the game is started (but the windfield world we already talked about is only created once), and it could be a different map depending of the level, the way they are loaded and drawed is thanks to our last module, called sti or simple tiled implementation, that takes a tiled map file created from tiled (a map editor), and makes it an object that we can manipulate, actually, our colliders are loaded using this too, we can create "objects" in the map editor, and then when loading the map we look at those objects, their attributes, like position, width, and height to create the colliders, the map update functions look for when it is necessary to make a change in the map of the world, like changing the level, reseting the level, checking if the player ran out of lives to display a game over or if the plaer won the game, or checking if a level is starting to draw the loading screen, and finally in the draw function the background and the tiled map are drawed.

## Helpers: enemy.lua

The enemies are created also from the tiled map, if a "enemy" object is found in the map, a new enemy will be created at that same position, it has some properties like the player, like animations, a collider, a position x and y, width, height, the damage it does to the player, and a funny feature, that makes the enemy go into "rage" mode after crashing into a wall three times, the enemy will be a lot faster than normal, and it will go back to normal mode after crashing again, its movement physics works the same as the player ones, except because it is an npc he doesn´t have the same features, it can't jump or accelerate, but it will change its direction after crashing into a wall of touching the border of a platform, and it will "attack" the player if they collide, making damage to the player, removing one heartg from his health, an enemy will die if it gets hit by a fireball object, playing its death animation and deleting it from the world.

## Helpers: PowerUps.lua

PowerUps are special abilities the player can use for his benefit, there are 2 powerUps in the game, fire and heart, both are spawned from the tiled map in the same way the other objects are, the fire powerUp give the player the ability to shoot fireballs pressing the z key, and the heart, fill the player's health with one more heart if he ahs taken damage, maybe now a "PowerUp" like the fire one, but still makes sense to include it here, and both powerUps dissapear when the player touches them. But they have basically the same properties as other objects, like position, size, a collider (to detect when the player touches them of course) and animations.

## Helpers: Fireball.lua

This is the object the player throws when pressing z if having a fire powerUp, maybe it sounds too simple to have its own file, but building it its more complicated than it seems, to create it we have to give him a position, a radius (becuase the firebal is a circle), the movement speed of the fireball, animations, and a property that i didn´t mention earlier but makes sense to have is a direction, if the player is looking at the right, the fireball will be shoot to the right, and viceversa, so we have to prepare some properties for both cases, like reversing the animations, and reversing the speed. But the most important feature of the object, is what happens when it touches something, if it touches a wall, it will just dissapear, but if it touches an enemy, the enemy will die. A fireball maintains always the same height and just move in the x direction (horizontal).

## Helpers: Spikes.lua

The spikes are obstacles generated from the map taht are meant to harm the player if he touches it, this file takes care of mostly creating their colliders with the correct position, width and height and the property of removing one heart of the player health if they collide. The reason they are not in the same file as the other special colliders, is because the spikes are directly drawn from the tiled map, and this file just create their colliders.

## Helpers: especialCollider.lua

There are four especial colliders, trampoline, flagpole, level and collectibles. Now, the special colliders aren´t drawn from the tiled map, they have their separate sprites, some of them have animations too. This file starts initializing the objects properties, and then when the game is running, they are updated and drawed differently from each other. I'll quickly explain what these objects do, the trampoline will give the player an impulse upwards, only if the player stands above it, the flagpole is like the one from the mario games, the player will win and go to the next level if he touches it, a level is a situational object, what it does is, it makes some obstacles dissapear if the player can´t move on because of them, and collectibles are just special objects positionated in some "hard" places to reach that encourage the player to go to those places and collecting them. A specific function that almost every object has (except the player) is that whenever the player dies or wins, or if the map changes for some reason, all of the objects are destroyed, so when the level starts again, they are created again, of if the level changes, they are removed and created again in different places. 

## Helpers: Coin.lua

A coin is also a special collider, just that it has some more features, it can spin, creating the effect by shrinking and growing its width, when a player collects a coin, his coin count will increase and the coin will dissapear, and if his coin count gets to 100, the player will receive a life and the coin count will reset to 0. Now, I know these could be included with the other special colliders, but it's maybe better to not overload that file, and also, coins are more special, what platformer would be completed without coins?

## Helpers: Camera.lua

This file takes care of the "game camera", what the person playing sees, the game is lineal, so the camera will only move to the left or to the right, it is programmed to always follow the player, moving right of left depending of the player, the camera only stops if the player stops of it comes close to the border of the map, in that case, the camera won´t move further because the map ends there.

## Helpers: GUI.lua

This file controls the graphical user interface when the game is running, it shows the player´s health, his lives, his coins, and tells him if he has a powerUp active, it is updated and drawed at every frame just like other entities, to always show the player accurate properties.

## Helpers: MenuUI.lua

This file controls all of the user interface that is shown when the game is not running, like if the player is in the menu, the game over screen or the victory screen, for all of the cases, it displays some buttons to give the player choices, in the main menu of the game, it gives the option to start the game, look the instructions of how to play and the option to close the game. If the player loses all lifes, it will displaya  game over screen, giving the player the option to play again, go to the menu or exit the game, the same options are displayed if the player wins the game, with the aditional option of showing the player his statistics, like how many coins he collected, how many enemies he killed or how many collectibles they found. It is very responsive.

## Helpers: Sounds.lua

This one creates all of the sounds of the game, sounds effect and music, I included several sounds effects like for jumps, grabbing coins, being hurt, grabbing a powerUp, killing enemies and some others, but as I said, it just load the sounds, because the sounds itself are used (played) in different parts of the project, what I mean is that if the player jumps, the sounds will be played right there in the same chunk of code that made the player jump.

## Other files

All of the the libraries (anim8, sti, and windfield), are contained in their specific folder and required in the needed files of the project, but I already explained their utility. The maps folder contains the map levels of the game, they were created with the tiled map editor, there are currently just 2 levels in the game, but they are enough to show the mechanics of the game. The assets folder contains animated or static sprites for the different objects in the game, a cool font to display text, and all of the sounds used in the game. And that's it.

