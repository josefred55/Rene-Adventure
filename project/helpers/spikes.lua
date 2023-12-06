Spikes = {}

local Player = require 'helpers.player'

Spikes.__index = Spikes

--this will contain thSpikes.ActiveSpikes that we are currently showing on the screen
Spikes.ActiveSpikes = {}

function Spikes.new(x, y, width, height)
    -- the instance will be the current Spikes
    local instance = setmetatable({}, Spikes)
    instance.x = x
    instance.y = y
    instance.width = width
    instance.height = height
    instance.damage = 1
    instance.graceTimer = 0

    instance.collider = World:newRectangleCollider(instance.x, instance.y, instance.width, instance.height)
    instance.collider:setType("static")

    instance.collider.fixture:setSensor(true)
    
    --insert the instance into theSpikes.ActiveSpikes table
    table.insert(Spikes.ActiveSpikes, instance)
end

function Spikes:update(dt)
    self:checkPlayerCollision()
end

function Spikes.updateAll(dt)
    for _, instance in ipairs(Spikes.ActiveSpikes) do
        instance:update(dt)
    end
end
--we don´t need to draw the spikes, since they are drawed directly with the tiled map

function Spikes.removeAll()
    for _, instance in ipairs(Spikes.ActiveSpikes) do
        instance.collider:destroy()
    end

    Spikes.ActiveSpikes = {}
end

function Spikes:checkPlayerCollision()
    if not Player.inmortality then
        if Player.collider:isTouching(self.collider.body) then
            Player:takeDamage(self.damage)
        end
    end
end
function Spikes:beginContact(a, b, collision)
    --the player will take damage when colliding with a spike
    for _, instance in ipairs(Spikes.ActiveSpikes) do
        if (a == instance.collider.fixture and b == Player.collider.fixture) or (a == Player.collider.fixture and b == instance.collider.fixture) then
            if not Player.inmortality then
                Player:takeDamage(instance.damage)
            end
            return true
        end
    end
end

return Spikes