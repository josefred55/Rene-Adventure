local Fireballs = {}

local sounds = require 'helpers.sounds'

Fireballs.__index = Fireballs

Fireballs.ActiveFireballs = {}

function Fireballs.new(x, y, direction)
    -- the instance will be the current Fireballs
    local instance = setmetatable({}, Fireballs)
    instance.x = x
    instance.y = y
    instance.radius = 10
    instance.scale = 1.5
    instance.speed = 500
    instance.direction = direction
    instance.toVanish = false

    --the fireball will exist for 2 seconds and then it will vanish
    instance.duration = {current = 0, max = 2}

    instance.animation = {timer = 0, rate = 0.1, total = 5, current = 1, img = Fireballs.anim}
    instance.animation.draw = instance.animation.img[1]

    instance.collider = World:newCircleCollider(instance.x, instance.y, instance.radius)
    instance.collider:setGravityScale(0)

    --insert the instance into the Fireballs.ActiveFireballs table
    table.insert(Fireballs.ActiveFireballs, instance)
end

function Fireballs.loadAssets()
    --store each animation image in a table to index it when animating
    Fireballs.anim = {}
    for i = 1, 5 do
        Fireballs.anim[i] = love.graphics.newImage("Assets/Fireball/FB00"..i..".png")
    end

    Fireballs.width = Fireballs.anim[1]:getWidth()
    Fireballs.height = Fireballs.anim[1]:getHeight()
end

function Fireballs:update(dt)
    self:move()
    self:checkDuration(dt)
    self:checkVanish()
    self:animate(dt)
end

function Fireballs.updateAll(dt)
    for _, instance in ipairs(Fireballs.ActiveFireballs) do
        instance:update(dt)
    end
end

function Fireballs:draw()
    if self.direction == "right" then
        love.graphics.draw(self.animation.draw, self.x, self.y, 0, self.scale, self.scale, self.width / 2, self.height / 2)
    else
        local scaleX = - self.scale
        love.graphics.draw(self.animation.draw, self.x, self.y, 0, scaleX, self.scale, self.width / 2, self.height / 2)
    end
end

function Fireballs.drawAll()
    for _, instance in ipairs(Fireballs.ActiveFireballs) do
        instance:draw()
    end
end

function Fireballs.removeAll()
    for _, instance in ipairs(Fireballs.ActiveFireballs) do
        instance.collider:destroy()
    end

    Fireballs.ActiveFireballs = {}
end

function Fireballs:move()
     --set the speed of the fireball
     if self.direction == "right" then
        self.collider:setLinearVelocity(self.speed, 0)
    else
        self.collider:setLinearVelocity(-self.speed, 0)
    end

    self.x = self.collider:getX() 
    self.y = self.collider:getY() 
end

function Fireballs:checkDuration(dt)
    self.duration.current = self.duration.current + dt
    if self.duration.current >= self.duration.max then
        self.toVanish = true
    end
end

function Fireballs:animate(dt)
    self.animation.timer = self.animation.timer + dt
    if self.animation.timer > self.animation.rate then
        self.animation.timer = 0
        self:setNewFrame()
    end
end

function Fireballs:setNewFrame(dt)
    local anim = self.animation
    if anim.current < anim.total then
        anim.current = anim.current + 1
    else
        anim.current = 1
    end
    self.animation.draw = anim.img[anim.current]
end

function Fireballs:checkVanish()
    for i, instance in ipairs(Fireballs.ActiveFireballs) do
        if instance.toVanish then
            instance.collider:destroy()
            table.remove(Fireballs.ActiveFireballs, i)
        end
    end
end

function Fireballs:beginContact(a, b, collision)
    for i, instance in ipairs(Fireballs.ActiveFireballs) do
        if a == instance.collider.fixture or b == instance.collider.fixture then
            for _, wall in ipairs(Walls) do
                if a == wall.collider.fixture or b == wall.collider.fixture then
                    --if the fireball collided with a wall ( not a spike or a coin ) then destroy the fireball
                    instance.toVanish = true
                end
            end
        end
    end
end

return Fireballs