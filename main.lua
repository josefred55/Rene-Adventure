wf = require 'libraries/windfield'
anim8 = require 'libraries/anim8'

local menu = require 'helpers.menuUi'

local especialCollider = require 'helpers.especialCollider'
local camera = require 'helpers.camera'
local Coin = require 'helpers.coin'
local Enemy = require 'helpers.enemy'
local Fireball = require 'helpers.fireball'
local GUI = require 'helpers.GUI'
local Map = require 'helpers.map'  
local Player = require 'helpers.player'
local PowerUps = require 'helpers.PowerUps'
local Spikes = require 'helpers.spikes'
local sounds = require 'helpers.sounds'

GAME_STARTED = false
GAME_PAUSED = false

function love.load()
    --the menu UI
    menu.load()

    GUI:load()

    --to fix the blur when scaling our sprites
    love.graphics.setDefaultFilter('nearest', 'nearest')

    --powerups
    PowerUps.loadAssets()

    --the fireball powerups assets
    Fireball.loadAssets()

    --load the enemy assets before loading the entities in the map
    Enemy.loadAssets()

    Player:loadAssets()

    sounds.load()
end

function love.loadOtherStuff(stuff)
    if GAME_STARTED then
        if stuff == "map" then
            Map:load()
        elseif stuff == "player" then
            Player:load()
        end
    end
end

function love.update(dt)
    Map:checklevelStarting(dt)
    if not GAME_STARTED or Map.levelStarting then return end
    
    Map:update(dt)
    especialCollider.updateAll(dt)
    Coin.updateAll(dt)
    Enemy.updateAll(dt)
    Fireball.updateAll(dt)
    Player:update(dt)
    PowerUps.updateAll(dt)
    Spikes.updateAll(dt)
    camera:setPosition(Player.x, 0)
end

function love.draw()
    if not GAME_STARTED then
        if END_SCREEN.instructions then
            menu.draw("instructions")
        elseif END_SCREEN.victory then
            menu.draw("victory")
        elseif END_SCREEN.gameOver then
            menu.draw("gameOver")
        elseif END_SCREEN.statistics then
            menu.draw("statistics")
        else
            menu.draw("menu")
        end

    elseif GAME_PAUSED then
        menu.draw("pause")
    
    elseif Map.levelStarting then
        menu.drawLoadingScreen(Map.currentLevel, Player.lives)
    else
        Map:draw()

        camera:apply()
        especialCollider.drawAll()
        Coin.drawAll()
        Enemy.drawAll() 
        Fireball.drawAll()
        Player:draw()
        PowerUps.drawAll()
        camera:clear()

        GUI:draw()
    end
end

--a and b will be the coliding objects, the other argument is the information about the collision

function beginContact(a, b, collision)
    -- if a collision between a coin and a player occured, don´t execute the callback function for the player, same for the spikes
     if Coin:beginContact(a, b, collision) then return end
     if Spikes:beginContact(a, b, collision) then return end
     Enemy:beginContact(a, b, collision) 
     Player:beginContact(a, b, collision)
     PowerUps:beginContact(a, b, collision)
     Fireball:beginContact(a, b, collision)
     especialCollider:beginContact(a, b, collision)
end

function endContact(a, b, collision)
    Player:endContact(a, b, collision)
end

function setPresolve(a, b, collision)
    Enemy:setPresolve(a, b, collision)
end