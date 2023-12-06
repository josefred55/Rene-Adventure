local Player = {}

local fireball = require 'helpers.fireball'
local sounds = require 'helpers.sounds'

function Player:load()
    self.loaded = true
    self.x = 200
    self.y = 300
    self.startX = self.x
    self.startY = self.y
    self.width = 30
    self.height = 70
    self.speed = 350
    self.acceleration = 800
    self.friction = 400
    self.doubleJump = true
    self.coins = 0
    self.alive = true
    self.lives = 5
    self.noLives = false
    self.xVel = 0
    self.yVel = 0
    self.victory = false

    self.statistics = {enemies_killed = 0, coins_grabbed = 0, powerUps_collected = 0, collectibles_momentarily_found = 0, collectibles_found = 0}

    self.canSlideWall = false
    self.canWallJump = {right = false, left = false}

    self.colliding = {}

    self.respawnTimer = 0

    --this will determine if the player can move, useful for when they die, they wont be able to move
    self.movable = true

    self.powerUps = {fire = false, fireballTimer = 1.5, anim = "none", animTimer = 0, animTimerMax = 0.4}

    --When the player takes damage, in the grace time the player will be inmortal for a few seconds, when it ends, the player will be able of taking damage again
    self.graceTimer = {current = 0, max = 2.5}
    self.inmortality = false

    self.color = {
        red = 1,
        green = 1,
        blue = 1,
        speed = 3
    }

    --to keep track of the user´s current health and their maximum healt
    self.health = {current = 3, max = 3}

    -- this is to check the direction of the frame the player is currently looking at, it will be set to look to the right by default when loading the game
    self.direction = "right"

    -- this variable will helps us checking if the player is touching ground
    self.grounded = false

    self.collider = World:newRectangleCollider(self.x, self.y, self.width, self.height)
    self.collider:setFixedRotation(true)
end

function Player.loadAssets()
    Player.sprites = {}
    --my sprites are separated in different images so i have no choice but to do this for every image. Running:
    Player.sprites.runSheet = love.graphics.newImage('Assets/Characters/Fighter/Run.png')
    Player.sprites.runGrid = anim8.newGrid( 128, 128, Player.sprites.runSheet:getWidth(), Player.sprites.runSheet:getHeight() )

    --jumping:

    Player.sprites.jumpSheet = love.graphics.newImage('Assets/Characters/Fighter/Jump.png')
    Player.sprites.jumpGrid = anim8.newGrid( 128, 128, Player.sprites.jumpSheet:getWidth(), Player.sprites.jumpSheet:getHeight() )

    --idle:
    Player.sprites.idleSheet = love.graphics.newImage('Assets/Characters/Fighter/Idle.png')
    Player.sprites.idleGrid = anim8.newGrid( 128, 128, Player.sprites.idleSheet:getWidth(), Player.sprites.idleSheet:getHeight() )

    --death:
    Player.sprites.deathSheet = love.graphics.newImage('Assets/Characters/Fighter/Dead.png')
    Player.sprites.deathGrid = anim8.newGrid( 128, 128, Player.sprites.deathSheet:getWidth(), Player.sprites.deathSheet:getHeight() )

    --shooting fireballs:
    Player.sprites.shootSheet = love.graphics.newImage('Assets/Characters/Fighter/Attack_1.png')
    Player.sprites.shootGrid = anim8.newGrid( 128, 128, Player.sprites.shootSheet:getWidth(), Player.sprites.shootSheet:getHeight() )

    --storing the animations

    Player.sprites.animations = {}

    Player.sprites.animations.run = anim8.newAnimation(Player.sprites.runGrid( '1-8', 1), 0.1)
    Player.sprites.animations.jump = anim8.newAnimation(Player.sprites.jumpGrid( '3-6', 1), 0.2, 'pauseAtEnd')
    Player.sprites.animations.fall = anim8.newAnimation(Player.sprites.jumpGrid( '7-8', 1), 0.3, 'pauseAtEnd')
    Player.sprites.animations.idle = anim8.newAnimation(Player.sprites.idleGrid( '1-6', 1), 0.1)
    Player.sprites.animations.death = anim8.newAnimation(Player.sprites.deathGrid( '1-3', 1), 0.25, 'pauseAtEnd')
    Player.sprites.animations.shoot = anim8.newAnimation(Player.sprites.shootGrid( '1-3', 1), 0.05, 'pauseAtEnd')

    --an extra improvised animation extracted from the jump frames for when the player is gliding in a wall
    Player.sprites.animations.Slide = anim8.newAnimation(Player.sprites.jumpGrid( '5-7', 1), 0.2)

    --to check the current player animation when updating the frames
    Player.animation = Player.sprites.animations.idle
end

function Player:update(dt)
    if not self.loaded then return end

    self:checkPowerUps(dt)
    self:checkInmortality(dt)
    self:movement(dt)
    self:checkSlideWall()
    self:animate(dt)
    self:unTint(dt)
    self:checkDeath(dt)
end

function Player:draw()
    love.graphics.setColor(self.color.red, self.color.green, self.color.blue)

    local direction
    if self.xVel > 0 then
        direction = "right"
    elseif self.xVel < 0 then
        direction = "left"
    else
        direction = self.direction
    end

    if direction == "right" then
        if self.animation == self.sprites.animations.run then
            self.animation:draw(self.sprites.runSheet, self.x, self.y)

        elseif self.animation == self.sprites.animations.jump then
            self.animation:draw(self.sprites.jumpSheet, self.x, self.y)

        elseif self.animation == self.sprites.animations.idle then
            self.animation:draw(self.sprites.idleSheet, self.x, self.y)

        elseif self.animation == self.sprites.animations.death then
            self.animation:draw(self.sprites.deathSheet, self.x, self.y)

        elseif self.animation == self.sprites.animations.shoot then
            self.animation:draw(self.sprites.shootSheet, self.x, self.y)

        elseif self.animation == self.sprites.animations.fall then
            self.animation:draw(self.sprites.jumpSheet, self.x, self.y)

        --the Slide animations will be inversed, if the player is looking to the right, the sprite will look at the left, and viceversa, to make a better visual effect when wall jumping
        elseif self.animation == self.sprites.animations.Slide then
            self.animation:draw(self.sprites.jumpSheet, self.x + 130, self.y, 0, -1, 1)
        end

    elseif direction == "left" then
        local scaleX = -1
        self.x = self.collider:getX() + 60

        if self.animation == self.sprites.animations.run then
            self.animation:draw(self.sprites.runSheet, self.x, self.y, 0, scaleX, 1)
    
        elseif self.animation == self.sprites.animations.jump then
            self.animation:draw(self.sprites.jumpSheet, self.x, self.y, 0, scaleX, 1)
    
        elseif self.animation == self.sprites.animations.idle then
            self.animation:draw(self.sprites.idleSheet, self.x, self.y, 0, scaleX , 1)
    
        elseif self.animation == self.sprites.animations.death then
            self.animation:draw(self.sprites.deathSheet, self.x, self.y, 0, scaleX, 1)

        elseif self.animation == self.sprites.animations.shoot then
            self.animation:draw(self.sprites.shootSheet, self.x, self.y, 0, scaleX, 1)

        elseif self.animation == self.sprites.animations.fall then
            self.animation:draw(self.sprites.jumpSheet, self.x, self.y, 0, scaleX, 1)

        elseif self.animation == self.sprites.animations.Slide then
            self.animation:draw(self.sprites.jumpSheet, self.x - 130, self.y)
        end
    end
    love.graphics.setColor(1, 1 , 1 ,1)
end

function Player:checkPowerUps(dt)
    if not self.powerUps.fire then return end

    self:firePowerUp(dt)
end

function Player:firePowerUp(dt)
    self.powerUps.fireballTimer = self.powerUps.fireballTimer + dt
    if self.powerUps.fireballTimer > 1.5 then
        if love.keyboard.isDown('z') and not self.canSlideWall then
            self.powerUps.anim = "shooting"
            if self.direction == "right" then
                fireball.new(self.collider:getX() + 30, self.collider:getY(), "right")
                self.powerUps.fireballTimer = 0
            else
                fireball.new(self.collider:getX() - 30, self.collider:getY(), "left")
                self.powerUps.fireballTimer = 0
            end
            sounds.fireball:stop()
            sounds.fireball:play()
        end
    end
end

function Player:checkInmortality(dt)
    if not self.inmortality then return end

    self:blink()
    self.graceTimer.current = self.graceTimer.current + dt
    if self.graceTimer.current > self.graceTimer.max then
        self.inmortality = false
        self.graceTimer.current = 0
    end
end

function Player:movement(dt)
    if self.health.current <= 0 then 
        self:fixPosition()
        return
    end

    self.xVel, self.yVel = self.collider:getLinearVelocity()

    --limit the player falling velocity
    if self.yVel > 500 then
        self.yVel = 500
    end

    if self.movable then
        --movements (left and right)
        if love.keyboard.isDown('d', 'right') and self.xVel < self.speed then
            self:move(dt, "right")
        elseif love.keyboard.isDown('a', 'left') and self.xVel > -(self.speed) then
            self:move(dt, "left")
        end
    end

    --jumping
    function love.keypressed(key)
        if key == 'up' or key == "w" then
            if self.movable then
                --if the player can wall jump, he will, else he will do a normal jumo
                if self.canWallJump.right or self.canWallJump.left then
                    self:wallJump()
                elseif self.grounded or self.doubleJump and (not self.wallGliding) then
                    self:jump()
                end
            end
        elseif key == "escape" then
            if not GAME_PAUSED then
                GAME_PAUSED = true
                if MAP_MUSIC:isPlaying() then
                    MAP_MUSIC:pause()
                end
            else
                GAME_PAUSED = false
                if not MAP_MUSIC:isPlaying() then
                    MAP_MUSIC:play()
                end
            end
        end
    end

    --apply friction
    if self.xVel < 0 then
        self.xVel = math.min(self.xVel + self.friction * dt, 0)
    elseif self.xVel > 0 then
        self.xVel = math.max(self.xVel - self.friction * dt, 0)
    end

    --avoid the player from going past the left corner of the screen
    if self.collider:getX() < 10 then
        self.collider:setPosition(11, self.collider:getY())
    end

    self.collider:setLinearVelocity(self.xVel, self.yVel)
    self:fixPosition()
end

function Player:fixPosition()
    --move the player coordinates along their collider (the sprite is a bit offset because of the scale so i have to change the coordinates a little)
    self.x = self.collider:getX() - 60
    self.y = self.collider:getY() - 93
end

function Player:move(dt, direction)
    if direction == "right" then
        self.xVel = math.min(self.xVel + self.acceleration * dt, self.speed)
        self.direction = "right"
    elseif direction == "left" then
        self.xVel = math.max(self.xVel - self.acceleration * dt, -self.speed)
        self.direction = "left"
    end
end

function Player:animate(dt)
    --if the player is not alive, play the death animation and ignore every other animation
    if self.health.current == 0 then
        self.animation = self.sprites.animations.death
    --or shooting a fireball
    elseif self.powerUps.anim == "shooting" then
        self.movable = false
        self.powerUps.animTimer = self.powerUps.animTimer + dt
        if self.powerUps.animTimer > self.powerUps.animTimerMax then
            self.powerUps.animTimer = 0
            self.powerUps.anim = "none"
            self.movable = true
            self.sprites.animations.shoot:resume()
            self.sprites.animations.shoot:gotoFrame(1)
        end
        self.animation = self.sprites.animations.shoot
    --or gliding in a wall (we know that the player is doing that if he can wall jump)
    elseif self.canWallJump.right or self.canWallJump.left then
        self.animation = self.sprites.animations.Slide
    --having a positive y velocity means the player is currently falling
    elseif self.yVel > 0 and not self.grounded then
        self.animation = self.sprites.animations.fall
    else
        if self.grounded then
            --if the player has no x velocity it means they aren´t moving, so apply the idle aniamation, if it´s not 0, then they are moving
            if self.xVel == 0 then
                self.animation = self.sprites.animations.idle
            else
                self.animation = self.sprites.animations.run
            end
    --update the player jumping animation, we know when they are jumping thanks to the grounded variable
        elseif not self.grounded then
            self.animation = self.sprites.animations.jump
        end
    end
    self.animation:update(dt)
end

function Player:takeDamage(amount)
    --the player can only take damage is they are alive
    if self.health.current <= 0 then return end

    self.powerUps.fire = false
    --if the player doesn´t die when taking the amount of damage, just substract the it from their current health, else we kill the player. and also tint the player red when taking damage
    self:tintRed()
    if self.health.current - amount > 0 then
        self.health.current = self.health.current - amount
        self.inmortality = true
    else
        self.health.current = 0
    end
    sounds.hurt:play()
end

function Player:tintRed()
    self.color.green = 0
    self.color.blue = 0
end

function Player:blink()
    if self.color.red == 1 then
        self.color.red = 0
        self.color.green = 0
        self.color.blue = 0
    elseif self.color.red == 0 then
        self.color.red = 1
        self.color.green = 1
        self.color.blue =  1
    end
end

function Player:unTint(dt)
    self.color.red = math.min(self.color.red + self.color.speed * dt, 1)
    self.color.green = math.min(self.color.green + self.color.speed * dt, 1)
    self.color.blue = math.min(self.color.blue + self.color.speed * dt, 1)
end

function Player:checkDeath(dt)
    --this little timer is for when the player dies the game waits one second while the death animation is playing and then the player and the world is restarted
    if not self.alive then return end

    if self.health.current == 0 then
        sounds.overworldMusic:stop()
        sounds.undergroundMusic:stop()

        --in that second the player won´t be able to move
        self.movable = false
        self.collider:setLinearVelocity(0, 800)

        --if the player found collectibles but dies, he loses them, the only way they are saved is by collecting them and passing the level without dying
        self.statistics.collectibles_momentarily_found = self.statistics.collectibles_found

        self.respawnTimer = self.respawnTimer + dt
        if self.respawnTimer > 1.5 then
            --death of the player
            self.alive = false
            if self.lives - 1 == 0 then
                self.noLives = true
            else
                self.lives = self.lives - 1
            end
        end
    --the player will die too if they fall to a pit
    elseif self.y > 650 then
        self.health.current = 0
        sounds.hurt:play()
    end
end

function Player:respawn()
    self:resetPosition()
    self.collider:setLinearVelocity(0, 0)
    self.health.current = self.health.max
    self.alive = true
    self.movable = true
    self.grounded = false
    self.respawnTimer = 0
    self.victory = false

    --resume the animation because if the player already dies the animation is paused at the end and won´t loop until it gets unpaused
    self.sprites.animations.death:resume()
    self.sprites.animations.death:gotoFrame(1)
end

function Player:resetPosition()
    self.collider:setPosition(self.startX, self.startY)
end

function Player:incrementCoins()
    if self.coins + 1 == 100 then
        self.lives = self.lives + 1
        self.coins = 0
        sounds.good:play()
    else
        self.coins = self.coins + 1
    end
    self.statistics.coins_grabbed = self.statistics.coins_grabbed + 1
end

-- callback function to be executed when the collision between object a and body b begins
function Player:beginContact(a, b, collision)
    local wall_collision = false

    --first make sure that the collision occured with a wall
    for _, wall in ipairs(Walls) do
        if a == wall.collider.fixture or b == wall.collider.fixture then
            wall_collision = true
        end
    end

    if self.grounded then return end

    -- getNormal returns the coordinates of a unit vector that points from the first colliding object (a) to the second one (b) if the second object is below the first...
    -- then the y normal vector (my) will be positive, and viceversa. this is useful to know which object is below and which object is above 
    local mx, my = collision:getNormal()
    --the object that was created first will be a and the other will be b, we need to know which one is a and which one is b
    if a == self.collider.fixture and wall_collision then
        --make sure that the player isn´t colliding with another wall before acting
        if self.colliding.this then
            self:endContact(self.colliding.player, self.colliding.wall, self.colliding.collision)
        end

        self.colliding = {this = true, player = a, wall = b, collision = collision}

        -- if a is the player then the normal vector will tell us the direction towards b
        if my > 0 then
            -- if the y vector is positive, that means the b object is below a, because if we are pointing from a to b, and that trajectory is positive, then the pointer is going down
            -- so basically it means the player has landed
            self:land(collision)
        --check if the player is touching the wall from the right or the left, not on top of it
        --another condition for the player to slide in a wall, is that the wall has a minimum height, so that the player can´t slide in short walls, we pass the wall to 
        --the function to check it there
        elseif mx < 0 then
            self:WallSideCollision(collision, b,  "left")
        elseif mx > 0 then
            self:WallSideCollision(collision, b, "right")
        end
    --if b is the player then we do the opposite
    elseif b == self.collider.fixture and wall_collision then
        if self.colliding.this then
            self:endContact(self.colliding.player, self.colliding.wall, self.colliding.collision)
        end

        self.colliding = {this = true, player = b, wall = a, collision = collision}

        if my < 0 then
            self:land(collision)
        elseif mx > 0 then
            self:WallSideCollision(collision, a, "left")
        elseif mx < 0 then
            self:WallSideCollision(collision, a, "right")
        end
    end
end

function Player:land(collision)
    self.currentGroundCollision = collision
    self.grounded = true
    self.doubleJump = true
end

function Player:jump()
    -- we will know when he is using the second by checking if they are not at the ground (they are already perfoming a jump)
    self.sprites.animations.jump:resume()
    self.sprites.animations.fall:resume()
    if not self.grounded and self.doubleJump then --double jump
        -- if the player is falling, anulate the gravity to not cancel automatically the second jump impulse
        if self.yVel > -200 then
            self.collider:setLinearVelocity(self.xVel, 0)
            self.collider:applyLinearImpulse(0, -1200)
        else
            --if the player is still going up, perform the doubleJump but will less impulse
            self.collider:applyLinearImpulse(0, -600)
        end

        self.doubleJump = false
        self.sprites.animations.jump:gotoFrame(2)
    else --normal jump
        self.collider:applyLinearImpulse(0, -1200)
        self.sprites.animations.jump:gotoFrame(1)
    end
    sounds.jump:stop()
    sounds.jump:play()
    self.sprites.animations.fall:gotoFrame(1)
    self.grounded = false
end

function Player:WallSideCollision(collision, wall_fixture, direction)
    self.currentGroundCollision = collision
    self.canSlideWall = true
    self.WallSideDirection = direction
end

function Player:checkSlideWall()
    --reset sliding if the player is not falling to avoid bugs
    if not self.canSlideWall then return end

    if love.keyboard.isDown('d', 'right') and self.WallSideDirection == "right" then
        self:SlideWall()
        self.canWallJump.right = true
    elseif love.keyboard.isDown('a', 'left') and self.WallSideDirection == "left" then
        self:SlideWall()
        self.canWallJump.left = true
    end
end

function Player:SlideWall()
    --apply vertical friction (30)
    self.yVel = 30
    self.collider:setLinearVelocity(self.xVel, self.yVel)
end

function Player:wallJump()
    if self.canWallJump.right then
        self.collider:applyLinearImpulse(-1500, -1200)
        self.canWallJump.right = false
    elseif self.canWallJump.left then
        self.collider:applyLinearImpulse(1500, -1200)
        self.canWallJump.left = false
    end
    self.sprites.animations.jump:resume()
    self.sprites.animations.jump:gotoFrame(2)

    self.sprites.animations.fall:resume()
    self.sprites.animations.fall:gotoFrame(1)

    sounds.wallJump:stop()
    sounds.wallJump:play()

    self.canSlideWall = false
end

-- callback function to be executed when the collision between object a and body b ends

function Player:endContact(a, b, collision)
    if a == self.collider.fixture or b == self.collider.fixture then
        if self.currentGroundCollision == collision then
            self.colliding.this = false
            self.grounded = false
            self.canSlideWall = false
            self.canWallJump.right = false
            self.canWallJump.left = false
        end
    end
end

return Player