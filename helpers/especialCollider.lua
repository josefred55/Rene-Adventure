local player = require "helpers.player"
local sounds = require 'helpers.sounds'

local especialCollider = {trampoline = {}, flagpole = {}, lever = {}, collectible = {}}
especialCollider.__index = especialCollider

especialCollider.trampoline.img = love.graphics.newImage('Assets/trampoline.png')
especialCollider.trampoline.width = especialCollider.trampoline.img:getWidth()
especialCollider.trampoline.height = especialCollider.trampoline.img:getHeight()
especialCollider.trampoline.scale = 0.1

especialCollider.lever.img = love.graphics.newImage('Assets/palanca.png')
especialCollider.lever.width = especialCollider.lever.img:getWidth()
especialCollider.lever.height = especialCollider.lever.img:getHeight()
especialCollider.lever.scale = 0.1

especialCollider.flagpole.sheet = love.graphics.newImage('Assets/flag animation.png')
especialCollider.flagpole.grid = anim8.newGrid( 60, 60, especialCollider.flagpole.sheet:getWidth(), especialCollider.flagpole.sheet:getHeight() )
especialCollider.flagpole.width = 35
especialCollider.flagpole.height = 50
especialCollider.flagpole.anim = anim8.newAnimation(especialCollider.flagpole.grid( '1-5', 1), 0.2)
especialCollider.flagpole.scale = 1

especialCollider.collectible.sheet = love.graphics.newImage('Assets/collectibles.png')
especialCollider.collectible.grid = anim8.newGrid( 32, 32, especialCollider.collectible.sheet:getWidth(), especialCollider.collectible.sheet:getHeight() )
especialCollider.collectible.width = 32
especialCollider.collectible.height = 32
especialCollider.collectible.anim = anim8.newAnimation(especialCollider.collectible.grid( '1-8', 8), 0.1)
especialCollider.collectible.scale = 1

especialCollider.activeEspColliders = {}

function especialCollider.new(x, y, type)
    local instance = setmetatable({}, especialCollider)
    instance.x = x
    instance.y = y
    instance.type = type
    instance.scale = 1.5

    instance:createCollider()

    table.insert(especialCollider.activeEspColliders, instance)
end

function especialCollider:createCollider()
    if self.type == "trampoline" then
        self.width = self.trampoline.width
        self.height = self.trampoline.height
        self.scale = self.trampoline.scale
        self.offsetX, self.offsetY = (self.width * self.scale) / 2, (self.height * self.scale) / 2

        self.collider = World:newRectangleCollider(self.x - self.offsetX, self.y - self.offsetY, self.width * self.scale, self.height * self.scale)
        self.collider:setType("static")

        --the trampolines are inserted into the walls table because they are physical colliders and the others are sensors or a single entity
        table.insert(Walls, self)

    elseif self.type == "flagpole" then
        self.width = self.flagpole.width
        self.height = self.flagpole.height
        self.scale = self.flagpole.scale
        self.offsetX, self.offsetY = (self.width * self.scale) / 2, (self.height * self.scale) / 2

        self.collider = World:newRectangleCollider(self.x - self.offsetX * self.scale, (self.y + 10) - self.offsetY, self.width * self.scale, self.height * self.scale)
        self.collider:setType("static")
        self.collider.fixture:setSensor(true)

        self.anim = self.flagpole.anim

    elseif self.type == "lever" then
        self.width = self.lever.width
        self.height = self.lever.height
        self.scale = self.lever.scale
        self.offsetX, self.offsetY = (self.width * self.scale) / 2, (self.height * self.scale) / 2

        self.collider = World:newRectangleCollider(self.x - self.offsetX, self.y - self.offsetY, self.width * self.scale, self.height * self.scale)
        self.collider:setType("static")
        self.collider.fixture:setSensor(true)

    elseif self.type == "collectible" then
        self.width = self.collectible.width
        self.height = self.collectible.height
        self.scale = self.collectible.scale
        self.offsetX, self.offsetY = (self.width * self.scale) / 2, (self.height * self.scale) / 2

        self.collider = World:newRectangleCollider(self.x - self.offsetX, self.y - self.offsetY, self.width * self.scale, self.height * self.scale)
        self.collider:setType("static")
        self.collider.fixture:setSensor(true)

        self.anim = self.collectible.anim
        self.toBeRemoved = false
    end
end

function especialCollider:update(dt)
    if self.anim then
        self.anim:update(dt)
    end

    self:checkRemove()
end

function especialCollider.updateAll(dt)
    for _, instance in ipairs(especialCollider.activeEspColliders) do
        instance:update(dt)
    end
end

function especialCollider:draw()
    if self.type == "trampoline" then
        love.graphics.draw(self.trampoline.img, self.x, self.y, 0, self.scale, self.scale, self.width / 2, self.height / 2)
    elseif self.type == "lever" then
        love.graphics.draw(self.lever.img, self.x, self.y, 0, self.scale, self.scale, self.width / 2, self.height / 2)
    elseif self.type == "flagpole" then
        self.anim:draw(self.flagpole.sheet, self.x, self.y, 0, self.scale, self.scale, self.width / 2, self.height / 2)
    elseif self.type == "collectible" then
        self.anim:draw(self.collectible.sheet, self.x, self.y, 0, self.scale, self.scale, self.width / 2, self.height / 2)
    end
end

function especialCollider.drawAll()
    for _, instance in ipairs(especialCollider.activeEspColliders) do
        instance:draw()
    end
end

function especialCollider:checkRemove()
    for i, instance in ipairs(especialCollider.activeEspColliders) do
        if instance.type == "collectible" and instance.toBeRemoved then
            instance.collider:destroy()
            table.remove(especialCollider.activeEspColliders, i)
            player.statistics.collectibles_momentarily_found = player.statistics.collectibles_momentarily_found + 1
        end
    end
end

function especialCollider.removeAll()
    for _, instance in ipairs(especialCollider.activeEspColliders) do
        if instance.type ~= "trampoline" then --not the trampolines since they are destroyed with the walls
            instance.collider:destroy()
        end
    end

    especialCollider.activeEspColliders = {}
end

function especialCollider:beginContact(a, b, collision)
    for _, instance in ipairs(especialCollider.activeEspColliders) do
        if a == instance.collider.fixture or b == instance.collider.fixture then
            if not (a == player.collider.fixture or b == player.collider.fixture) or player.health.current <= 0 then goto continue end

            if instance.type == "trampoline" then --the player will be impulsed when he touches a trampoline
                --the player can only bounce on the trampoline if they landed on it
                local mx, my = collision:getNormal()
                if a == player.collider.fixture then
                    if my > 0 then
                        player.collider:applyLinearImpulse(0, -3500)
                    end
                elseif b == player.collider.fixture then
                    if my < 0 then
                        player.collider:applyLinearImpulse(0, -3500)
                    end
                    sounds.jump:stop()
                    sounds.jump:play()
                end
            elseif instance.type == "flagpole" then --the player will win if he touchs the flagpole
                sounds.good:play()
                player.victory = true
                player.collider:setLinearVelocity(0, 500)
                player.movable = false
            elseif instance.type == "lever" then --touching the lever of the second level will remove that big fake wall
                REMOVE_FAKE_WALLS = true
            elseif instance.type == "collectible" then 
                instance.toBeRemoved = true
                sounds.good:play()
            end
        end
        ::continue::
    end
end

return especialCollider