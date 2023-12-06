local PowerUp= {}

PowerUp.__index = PowerUp

local player = require 'helpers.player'
local sounds = require 'helpers.sounds'

PowerUp.ActivePowerUp= {}

function PowerUp.new(x, y, Power)
    -- the instance will be the current PowerUp
    local instance = setmetatable({}, PowerUp)
    instance.x = x - 20
    instance.y = y - 30
    instance.toConsume = false
    instance.type = Power
    instance.randomTimeOffSet = math.random(1, 100)

    instance:createColliders()

    --insert the instance into the PowerUp.ActivePowerUptable
    table.insert(PowerUp.ActivePowerUp, instance)
end

function PowerUp.loadAssets()
    --fire
    PowerUp.fireAnim = {}

    PowerUp.fireAnim.frameWidth = 32
    PowerUp.fireAnim.frameHeight = 32
    PowerUp.fireAnim.scale = 1.5

    PowerUp.fireAnim.Sheet = love.graphics.newImage('Assets/Fireball/firepower_spritesheet.png')
    PowerUp.fireAnim.Grid = anim8.newGrid( PowerUp.fireAnim.frameWidth, PowerUp.fireAnim.frameHeight, PowerUp.fireAnim.Sheet:getWidth(), PowerUp.fireAnim.Sheet:getHeight() )

    PowerUp.animations = {}

    PowerUp.animations.fireAnim = anim8.newAnimation(PowerUp.fireAnim.Grid( '17-20', 9), 0.1)

    PowerUp.fireAnimation = PowerUp.animations.fireAnim

    --hearts
    PowerUp.heartAnim = {}
    for i = 1, 8 do
        PowerUp.heartAnim[i] = love.graphics.newImage("AsseTS/HearTile/Cuore"..i..".png")
    end

    PowerUp.heartWidth = PowerUp.heartAnim[1]:getWidth()
    PowerUp.heartHeight = PowerUp.heartAnim[1]:getHeight()
    PowerUp.heartAnim.scale = 2

    PowerUp.heartAnimation = {timer = 0, rate = 0.2, total = 8, current = 1, img = PowerUp.heartAnim}
    PowerUp.heartAnimation.draw = PowerUp.heartAnimation.img[1]
end

function PowerUp:createColliders()
    if self.type == "fire" then
        self.collider = World:newRectangleCollider(self.x, self.y, self.fireAnim.frameWidth * self.fireAnim.scale, self.fireAnim.frameHeight * self.fireAnim.scale)
    elseif self.type == "heart" then
        self.collider = World:newRectangleCollider(self.x, self.y, self.heartWidth * self.heartAnim.scale, self.heartHeight * self.heartAnim.scale)
    end

    self.collider:setType("static")
    self.collider.fixture:setSensor(true)
end

function PowerUp:update(dt)
    self:checkConsume()
    self:animate(dt)
end

function PowerUp.updateAll(dt)
    for _, instance in ipairs(PowerUp.ActivePowerUp) do
        instance:update(dt)
    end
end

function PowerUp:draw()
    if self.type == "fire" then
        self.fireAnimation:draw(self.fireAnim.Sheet, self.x, self.y, 0, self.fireAnim.scale)
    elseif self.type == "heart" then
        love.graphics.draw(self.heartAnimation.draw, self.x, self.y, 0, self.heartAnim.scale)
    end
end

function PowerUp.drawAll()
    for _, instance in ipairs(PowerUp.ActivePowerUp) do
        instance:draw()
    end
end

function PowerUp.removeAll()
    for _, instance in ipairs(PowerUp.ActivePowerUp) do
        instance.collider:destroy()
    end

    PowerUp.ActivePowerUp= {}
end

function PowerUp:checkConsume()
    for i, instance in ipairs(PowerUp.ActivePowerUp) do
        if instance.toConsume then
            if instance.type == "fire" then
                instance.collider:destroy()
                player.powerUps.fire = true
                sounds.powerUp:play()
                table.remove(PowerUp.ActivePowerUp, i)

            elseif instance.type == "heart" then
                instance.collider:destroy()
                if player.health.current < player.health.max then
                    player.health.current = player.health.current + 1
                else
                    player.health.current = player.health.max
                end
                sounds.powerUp:play()
                table.remove(PowerUp.ActivePowerUp, i)
            end
            player.statistics.powerUps_collected = player.statistics.powerUps_collected + 1
        end
    end
end

function PowerUp:animate(dt)
    if self.type == "fire" then
        self.fireAnimation:update(dt)

    elseif self.type == "heart" then
        self.heartAnimation.timer = self.heartAnimation.timer + dt
        if self.heartAnimation.timer > self.heartAnimation.rate then
            self.heartAnimation.timer = 0
            local anim = self.heartAnimation
            if anim.current < anim.total then
                anim.current = anim.current + 1
            else
                anim.current = 1
            end
            self.heartAnimation.draw = anim.img[anim.current]
        end
    end
end

function PowerUp:beginContact(a, b, collision)
    for i, instance in ipairs(PowerUp.ActivePowerUp) do
        if (a == instance.collider.fixture and b == player.collider.fixture) or (a == player.collider.fixture and b == instance.collider.fixture) then
            instance.toConsume = true
        end
    end
end

return PowerUp