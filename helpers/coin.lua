--since every coin will have the same image and the same width and height, we can declare them here, and every enw instance will inherit those attributes
local Coin = {img = love.graphics.newImage('Assets/coin_1.png')}

local Player = require 'helpers.player'
local sounds = require 'helpers.sounds'

Coin.__index = Coin

Coin.width = Coin.img:getWidth()
Coin.height = Coin.img:getHeight()

--this will contain the coins that we are currently showing on the screen
Coin.ActiveCoins = {}

function Coin.new(x, y)
    -- the instance will be the current coin
    local instance = setmetatable({}, Coin)
    instance.x = x
    instance.y = y
    instance.scaleX = 1
    instance.randomTimeOffSet = math.random(1, 100)

    -- a coin will be removed when touched
    instance.toBeRemoved = false

    --the instance colldier will make the player able to collect coins
    instance.collider = World:newCircleCollider(instance.x, instance.y, 10)
    instance.collider:setType("static")

    --setting a sensor for our collider fixture will make it trigger the begincontact callback when touched
    -- and it never causes a physical collision, meaning the player can pass trought it but the game will still know when the coin is touched thanks to the sensor
    instance.collider.fixture:setSensor(true)

    --insert the instance into the Coin.activecoins table
    table.insert(Coin.ActiveCoins, instance)
end

function Coin:update(dt)
    self:spin(dt)
    self:checkRemove()
end

function Coin:checkRemove()
    --loop trought the instances table and check which coin needs to be removed and remove it from the metatable with the index, also destroy its physical collider
    --and update the player amount of coins
    for i, instance in ipairs(Coin.ActiveCoins) do
        if instance.toBeRemoved then
            sounds.coin:stop()
            sounds.coin:play()
            Player:incrementCoins()
            instance.collider:destroy()
            table.remove(Coin.ActiveCoins, i)
        end
    end
end

function Coin:spin(dt)
    --[[we can use an animation to "spin" the coin, but we can recreate the effect messing with the scale
    passing the love timer to math.sin will make it go from -1 to 1 and from 1 to -1 in a loop
    so basically we are growing or shrinking the scaleX value at every frame, giving the spin illusion when being drawn.
    also we add the random value to the time so that evry coin spin asynchronously, and the * 2 to spin faster]]--
    self.scaleX = math.sin(love.timer.getTime() * 2 + self.randomTimeOffSet)
end

function Coin:draw()
    love.graphics.draw(self.img, self.x, self.y, 0, self.scaleX, 1, self.width / 2, self.height / 2)
end

function Coin.updateAll(dt)
    --to update all the coins automatically, loop trought the active coins table and call the update function for each instance in it
    for _, instance in ipairs(Coin.ActiveCoins) do
        instance:update(dt)
    end
end

function Coin.drawAll()
    for _, instance in ipairs(Coin.ActiveCoins) do
        instance:draw()
    end
end

function Coin.removeAll()
    --remove every coin from the map and empty the Coin.activeCoins table
    for _, instance in ipairs(Coin.ActiveCoins) do
        instance.collider:destroy()
    end

    Coin.ActiveCoins = {}
end

function Coin:beginContact(a, b, collision)
    for _, instance in ipairs(Coin.ActiveCoins) do
        --a coin will be removed if the player collides with it
        if (a == instance.collider.fixture and b == Player.collider.fixture) or (a == Player.collider.fixture and b == instance.collider.fixture) then
            if Player.health.current > 0 then
                instance.toBeRemoved = true
                return true
            end
        end
    end
end

return Coin