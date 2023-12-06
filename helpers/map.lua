local Map = {}
local sti = require 'libraries/sti'

local especialCollider = require 'helpers.especialCollider'
local camera = require 'helpers.camera'
local coin = require 'helpers.coin'
local enemy = require 'helpers.enemy'
local fireball = require 'helpers.fireball'
local player = require 'helpers.player'
local powerUp = require 'helpers.PowerUps'
local spikes = require 'helpers.spikes'
local sounds = require 'helpers.sounds'

local world_created = false
local loading_timer = {current = 0, max = 2}

function Map:load()
    self.levels = 2
    self.currentLevel = 1

    --the world (Where our physical colliders, which we will not see, exist)
    --it will only be created once when the game is booted, and when we move to the next levels only the colliders inside of it will be replaced

    if not world_created then
        World = wf.newWorld(0, 512, true)
        World:addCollisionClass('Wall')
        World:setCallbacks(beginContact, endContact, setPresolve)

        world_created = true
    end

    self.levelStarting = true
end

function Map:init()
    --the map
    self.level = sti("maps/map"..self.currentLevel..".lua")

    self.levelChangeTimer = {current = 0, max = 1}

    REMOVE_FAKE_WALLS = false
    self.fake_walls_removed = false

    --get the map width
    MapWidth = self.level.width * self.level.tilewidth * 2

    self.clouds = nil

    --i know this is like the worst way of loading the backgrounds, but since i will just be using 2 different backgrounds for now i did it this way
    if self.currentLevel == 1 then
        self.background = love.graphics.newImage("Assets/background/Background_2.png")
        self.clouds = love.graphics.newImage("Assets/background/Background_1.png")
        --we have to change the scale of the background to fit the screen size
        self.bgScaleX = 2.7
        self.bgScaleY = 2.7
        MAP_MUSIC = sounds.overworldMusic
   elseif self.currentLevel == 2 then
       self.background = love.graphics.newImage("Assets/background/cave.png")
       self.bgScaleX = 1
       self.bgScaleY = 1
       MAP_MUSIC = sounds.undergroundMusic
   end

    MAP_MUSIC:play()
    self:loadColliders()
end

function Map:checklevelStarting(dt)
    if not self.levelStarting then return end
    
    loading_timer.current = loading_timer.current + dt
    if loading_timer.current > loading_timer.max then
        loading_timer.current = 0
        self.levelStarting = false
        self:init()
        --if this is the first time loading the game, the player will not exist
        if not player.loaded then
            love.loadOtherStuff("player")
        end

        player:respawn()
    end
end

function Map:changeLevel(action)
    self:clear()

    --save the collectibles the player found without dying later
    player.statistics.collectibles_found = player.statistics.collectibles_momentarily_found

    if action == "next_level" then
        if self.currentLevel + 1 <= self.levels then
            self.levelStarting = true
            self.currentLevel = self.currentLevel + 1
        else --if there are no more levels, send the player to the menu
            self:sendtoMenu("victory")
            return
        end

    elseif action == "reset" then
        self.levelStarting = true
    end
end

function Map:clear()
    self.removeWalls()
    coin.removeAll()
    spikes.removeAll()
    enemy.removeAll()
    especialCollider.removeAll()
    powerUp.removeAll()
    fireball.removeAll()
    MAP_MUSIC:stop()
end

function Map:checkLevelChange(dt)
    --this function will check for deaths to reset the map and game overs if the player run out of lives
    if player.victory or not player.alive then
        self.levelChangeTimer.current = self.levelChangeTimer.current + dt
        if self.levelChangeTimer.current > self.levelChangeTimer.max then
            self.levelChangeTimer.current = 0
            if player.victory then
                self:changeLevel("next_level")
            elseif not player.alive then
                if self:checkGameOver() then return end
                self:changeLevel("reset")
            end
        end
    end
end

function Map:checkGameOver()
    if player.noLives then
        self:sendtoMenu("gameOver")
        return true
    end
end

function Map:loadColliders()
    --create our physical colliders from the tiled map
    Walls = {}
    if self.level.layers["colliders"] then
        for _, obj in pairs(self.level.layers["colliders"].objects) do
            --because we don´t want the object collider to be visible
            obj.visible = false

            -- we have to multiply the object properties by 2, because remember the map from tiled is descalated by 2, so we fix that scalating problem here (that´s the same reason we are specifying those parameters in Map:draw)
            if obj.name == "wall" or obj.name == "ground" then
                local wall = {}
                if obj.shape == "rectangle" then
                    wall.collider = World:newRectangleCollider(obj.x * 2, obj.y * 2, obj.width * 2, obj.height * 2)
                    wall.collider:setType('static')
                    wall.collider:setCollisionClass('Wall')
                    wall.width = obj.width 
                    wall.height = obj.height

                    wall.fake = false
                    if obj.type == "fakeWall" then
                        wall.fake = true
                    end

                    table.insert(Walls, wall)
                end
            
            elseif obj.name == "spike" then
                spikes.new(obj.x * 2, obj.y * 2, obj.width * 2, obj.height * 2)

            elseif obj.name == "coin" then
                coin.new(obj.x * 2, obj.y * 2)

            elseif obj.name == "trampoline" then
                especialCollider.new(obj.x * 2, obj.y * 2, "trampoline")

            elseif obj.name == "flagpole" then
                especialCollider.new(obj.x * 2, obj.y * 2, "flagpole")

            elseif obj.name == "collectible" then
                especialCollider.new(obj.x * 2, obj.y * 2, "collectible")

            elseif obj.name == "switch" then
                especialCollider.new(obj.x * 2, obj.y * 2, "lever")

            elseif obj.name == "enemy" then
                enemy.new(obj.x * 2, obj.y * 2)

            elseif obj.name == "firePower" then
                powerUp.new(obj.x * 2, obj.y * 2, "fire")

            elseif obj.name == "heart" then
                powerUp.new(obj.x * 2, obj.y * 2, "heart")
            end
        end
    end
end

function Map:checkRemoveFakeWalls()
    if REMOVE_FAKE_WALLS and not self.fake_walls_removed then
        for i, wall in ipairs(Walls) do
            if wall.fake then
                wall.collider:destroy()
                table.remove(Walls, i)
            end
        end

        for i, layer in pairs(self.level.layers) do
            if layer.name == "deletable_walls" then
                self.level:removeLayer(i)
            end
        end

        sounds.lever:stop()
        sounds.lever:play()
        self.fake_walls_removed = true
    end
end

function Map:sendtoMenu(message)
    self.currentLevel = 1

    self:clear()
    GAME_STARTED = false

    if message == "victory" then
        END_SCREEN.victory = true
    elseif message == "gameOver" then
        END_SCREEN.gameOver = true
    end

    player.collider:destroy()
    player.lives = 5
    player.loaded = false
end

function Map.removeWalls()
    for _, wall in ipairs(Walls) do
        wall.collider:destroy()
    end

    Walls = {}
end

function Map:update(dt)
    self:checkLevelChange(dt)
    self:checkRemoveFakeWalls()
    self.level:update(dt)
    World:update(dt)
end

function Map:draw()
    love.graphics.draw(self.background, 0, 0, nil, self.bgScaleX, self.bgScaleY) 
    if self.clouds then
        love.graphics.draw(self.clouds, 0, 0, nil, self.bgScaleX, self.bgScaleY) 
    end

    self.level:draw(-camera.x * 0.5, -camera.y, 2)
end

return Map