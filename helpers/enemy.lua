local Enemy = {}

local player = require 'helpers.player'
local fireball = require 'helpers.fireball'
local sounds = require 'helpers.sounds'

Enemy.__index = Enemy

Enemy.activeEnemies = {}

function Enemy.new(x, y)
    local instance = setmetatable({}, Enemy)
    instance.x = x
    instance.y = y
    instance.width = 32
    instance.height = 64
    instance.scale = 2
    instance.damage = 1
    instance.xVel = 200
    instance.counter = 0
    instance.rageCounter = 0
    instance.rage = false
    instance.direction = "right"
    instance.alive = true
    instance.deathTimer = 0
    instance.sensor = false

    instance.collider = World:newRectangleCollider(instance.x, instance.y, instance.width, instance.height)
    instance.collider:setFixedRotation(true)

    instance:loadAnimations()

    table.insert(Enemy.activeEnemies, instance)
end

--the dot instead of the colon is because we will load the assets in the parent table, not for each instance

function Enemy.loadAssets()
    Enemy.runAnim = {}

    Enemy.runAnim.Sheet = love.graphics.newImage('Assets/Characters/Enemy/Skeleton Crew/Skeleton - Warrior/Run/Run-Sheet.png')
    Enemy.runAnim.Grid = anim8.newGrid( 64, 64, Enemy.runAnim.Sheet:getWidth(), Enemy.runAnim.Sheet:getHeight() )

    Enemy.deathAnim = {}

    Enemy.deathAnim.Sheet = love.graphics.newImage('Assets/Characters/Enemy/Skeleton Crew/Skeleton - Warrior/Death/Death-Sheet.png')
    Enemy.deathAnim.Grid = anim8.newGrid( 64, 48, Enemy.deathAnim.Sheet:getWidth(), Enemy.deathAnim.Sheet:getHeight() )
end

--[[ the animations have to be created for each enemy because if they don´t the same anim8 animation will be used for every enemy (which is technically true)
 the problem is that in that case because the animation is meant to be paused at end, after the first enemy dies, when another enemy dies after that,
 the animation won´t loop for the it and for the next enemies because it already played for the first enemy, so it´s basically to avoid problems with looping it]]--
function Enemy:loadAnimations()
    self.animations = {}

    self.animations.run = anim8.newAnimation(self.runAnim.Grid( '1-6', 1), 0.2)

    --pauseAtEnd means that once the death animation is completed, the animation won´t loop, because we only want to play the death animation once
    self.animations.death = anim8.newAnimation(self.deathAnim.Grid( '1-6', 1), 0.1, 'pauseAtEnd') 
    
    self.animation = self.animations.run
end

function Enemy:update(dt)
    self:move(dt)
    self:checkAlive(dt)
    self:borderDetection()
    self.animation:update(dt)
end

function Enemy:draw()
    local scaleX = - self.scale
    if self.animation == self.animations.run then
        if self.direction == "right" then
            self.animation:draw(self.runAnim.Sheet, self.x, self.y, 0, self.scale, self.scale, self.width, self.height / 1.3)

        elseif self.direction == "left" then
            self.animation:draw(self.runAnim.Sheet, self.x, self.y, 0, scaleX, self.scale, self.width, self.height / 1.3)
        end

    elseif self.animation == self.animations.death then
        if self.direction == "right" then
            self.animation:draw(self.deathAnim.Sheet, self.x, self.y, 0, self.scale, self.scale, self.width, self.height / 1.3)

        elseif self.direction == "left" then
            self.animation:draw(self.deathAnim.Sheet, self.x, self.y, 0, scaleX, self.scale, self.width, self.height / 1.3)
        end
    end
end

function Enemy.updateAll(dt)
    for _, instance in ipairs(Enemy.activeEnemies) do
        instance:update(dt)
    end
end

function Enemy.drawAll()
    for _, instance in ipairs(Enemy.activeEnemies) do
        instance:draw()
    end
end

function Enemy.removeAll()
    for _, instance in ipairs(Enemy.activeEnemies) do
        instance.collider:destroy()
    end

    Enemy.activeEnemies = {}
end

function Enemy:move(dt)
    if not self.alive then
        self.x = self.deathPos.x
        self.y = self.deathPos.y + 35
        return 
    end

    self.x = self.collider:getX()
    self.y = self.collider:getY()

    if self.xVel > 0 then
        self.direction = "right"
    else
        self.direction = "left"
    end

    --check collision every 0.1 seconds to avoid getting stuck colliding with itself
    self.counter = self.counter + dt
    if self.counter > 0.1 then
        self:checkCollision()
        self.counter = 0
    end
    self.collider:setLinearVelocity(self.xVel, 300)
end

function Enemy:checkCollision()
    if not self.alive then return end

    if player.collider:isTouching(self.collider.body) then
        if not player.inmortality and player.health.current > 0 then
            player:takeDamage(self.damage)
            self:flipDirection("noRage")
        end
    end

    --this is to avoid the enemy from getting stuck walking to a wall or two enemies that are walking in different directions get stuck when collide
    for _, instance in ipairs(Enemy.activeEnemies) do
        if instance.collider ~= self.collider and instance.alive then
            if self.collider:isTouching(instance.collider.body) then
                self:flipDirection("noRage")
            end
        end
    end

    for _, wall in ipairs(Walls) do
        if self.collider:isTouching(wall.collider.body) then
            --only change direction if the wall is above or more or less at the enemy´s height the enemy, this will avoid the enemy from fliping if colliding with
            --the ground or a platform
            if self.collider:getY() > wall.collider:getY() then
                self:flipDirection("rage")
            end
        end
    end
end

function Enemy:borderDetection()
    if not self.alive then return end

    for _, wall in ipairs(Walls) do
        if not self.collider:isTouching(wall.collider.body) or not (wall.width and wall.height) then goto continue end

        local wall_x, wall_y = wall.collider:getPosition()

        wall_x = wall_x - wall.width
        wall_y = wall_y - wall.height

        --check if the enemy is on top of the platform
        if self.y < wall_y then
            --check if the enemy is going beyond the left border
            if self.x < wall_x + 10 then
                self.collider:setPosition(wall_x + 15, self.y)
                self:flipDirection("noRage")
            --check the right border
            elseif self.x > (wall_x + wall.width * 2) - 10 then
                self.collider:setPosition((wall_x + wall.width * 2) - 15, self.y)
                self:flipDirection("noRage")
            end
        end
        ::continue::
    end
end

function Enemy:flipDirection(rage)
    self.xVel = - self.xVel
    self.flipped = true
    if rage == "rage" then
        self:updateRage()
    end
end

function Enemy:updateRage()
    --rage will be an enemy state where it moves much faster, every time it collides with a wall it will increase the counter and when the coutner gets to 3,
    --it will enter in rage mode. When the enemy is in rage state and collides with a wall again, it will go back to his normal phase.
    if self.rage then
        self.rage = false
        self.rageCounter = 0
        self:changeSpeed(200)
    end

    self.rageCounter = self.rageCounter + 1

    if self.rageCounter == 3 then
        self.rage = true
        self:changeSpeed(500)
    end
end

function Enemy:changeSpeed(speed)
    if self.xVel > 0 then
        self.xVel = speed
    elseif self.xVel < 0 then
        self.xVel =  - speed
    end
end

function Enemy:checkAlive(dt)
    for _, instance in ipairs(Enemy.activeEnemies) do
        if instance.alive then goto continue end

        --these actions for the enemy death are in this conditional because they are meant to be executed once, and of course before the enemy actually dies
        if not instance.sensor then
            instance.collider:setType("static")
            instance.animation = instance.animations.death
            instance.collider.fixture:setSensor(true)
            instance.sensor = true
        end

        instance.deathTimer = instance.deathTimer + dt
        if instance.deathTimer > 20 then
            instance.readytoDie = true
            instance:die()
        end
        ::continue::
    end
end

function Enemy:die()
    --the final death
    for i, enemy in ipairs(Enemy.activeEnemies) do
        if enemy.readytoDie then
            self.collider:destroy()
            table.remove(Enemy.activeEnemies, i)
            player.statistics.enemies_killed = player.statistics.enemies_killed + 1
        end
    end
end

function Enemy:beginContact(a, b, collision)
    for _, instance in ipairs(Enemy.activeEnemies) do
        if not instance.alive then goto continue end
        --check if one of the colliders is the enemy, if it is, if the other collider is the player, make the player take damage.
        --if the enemy collided with the player or a a wall, make it flip its direction
        if a == instance.collider.fixture or b == instance.collider.fixture then
            if (a == player.collider.fixture or b == player.collider.fixture) and not player.inmortality and player.health.current > 0 then
                player:takeDamage(instance.damage)
                instance:flipDirection("noRage")
            end

            for _, wall in ipairs(Walls) do
                if a == wall.collider.fixture or b == wall.collider.fixture then
                    instance:flipDirection("rage")
                end
            end

            --if the enemy collided with a fireball, kill the enenmy
            for _, fireball in ipairs(fireball.ActiveFireballs) do
                if a == fireball.collider.fixture or b == fireball.collider.fixture then
                    instance.deathPos = {x = instance.collider:getX(), y = instance.collider:getY()}
                    instance.alive = false
                    fireball.toVanish = true
                    sounds.bones:play()
                end
            end

            --finally, check if the object enemy with another enemy, but that enemy won´t be the original enemy itself of course
            for _, instance_2 in ipairs(Enemy.activeEnemies) do
                if (a == instance_2.collider.fixture and a ~= instance.collider.fixture) or (b == instance_2.collider.fixture and b ~= instance.collider.fixture) then
                    if instance_2.alive then
                        instance:flipDirection("noRage")
                    end
                end
            end
        end
        ::continue::
    end
end

function Enemy:setPresolve(a, b, collision)
    for _, instance in ipairs(Enemy.activeEnemies) do
        if instance.alive then
            --the reason of this is that if the player is inmortal (just took damage) he will pass trought enemies like a ghost
            if a == instance.collider.fixture or b == instance.collider.fixture then
                if a == player.collider.fixture or b == player.collider.fixture then
                    if player.inmortality and player.alive then
                        collision:setEnabled(false)
                    else
                        collision:setEnabled(true)
                    end
                end
            end
        end
    end
end

return Enemy