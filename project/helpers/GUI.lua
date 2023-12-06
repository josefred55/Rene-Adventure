local Player = require 'helpers.player'

local GUI = {}

function GUI:load()
    self.coins = {}
    self.coins.img = love.graphics.newImage('Assets/coin_1.png')
    self.coins.width = self.coins.img:getWidth()
    self.coins.height = self.coins.img:getHeight()
    self.coins.scale = 2
    self.coins.x = love.graphics.getWidth() - 200
    self.coins.y = love.graphics.getHeight() - 100

    self.hearts = {}
    self.hearts.img = love.graphics.newImage('Assets/heart.png')
    self.hearts.width = self.hearts.img:getWidth()
    self.hearts.height = self.hearts.img:getHeight()
    self.hearts.x = 0
    self.hearts.y = 50
    self.hearts.scale = 1
    self.hearts.spacing = self.hearts.width * self.hearts.scale + 30

    self.lives = {}
    self.lives.img = love.graphics.newImage('Assets/Characters/Fighter/characterHead.png')
    self.lives.width = self.lives.img:getWidth()
    self.lives.height = self.lives.img:getHeight()
    self.lives.x = love.graphics.getWidth() - 200
    self.lives.y = 50
    self.lives.scale = 2

    self.powerUps = {}
    self.powerUps.fireImg = love.graphics.newImage('Assets/Fireball/fireball_gui.png')
    self.powerUps.fireWidth = self.powerUps.fireImg:getWidth()
    self.powerUps.fireHeight = self.powerUps.fireImg:getHeight()
    self.powerUps.x = 200
    self.powerUps.y = love.graphics.getHeight() - 100
    self.powerUps.scale = 1.5

    self.font = love.graphics.newFont('Assets/gamefont.ttf', 32)
end

function GUI:draw()
    self:displayCoins()
    self:displayHearts()
    self:displayPowerUpIcon()
    self:displayLives()
    self:displayText()
end

function GUI:displayCoins()
    --draw the coin icon and the amount of coins
    --this is so the text have a bit of shade
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.draw(self.coins.img, self.coins.x + 2, self.coins.y + 2, 0, self.coins.scale)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.coins.img, self.coins.x, self.coins.y, 0, self.coins.scale)

    love.graphics.setFont(self.font)
end

function GUI:displayHearts()
    for i = 1, Player.health.current do
        local x = self.hearts.x + self.hearts.spacing * i
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.draw(self.hearts.img, x + 2, self.hearts.y + 2, 0, self.hearts.scale)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.hearts.img, x, self.hearts.y, 0, self.hearts.scale)

        love.graphics.setFont(self.font)
    end
end

function GUI:displayPowerUpIcon()
    if Player.powerUps.fire then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.draw(self.powerUps.fireImg, self.powerUps.x + 2, self.powerUps.y + 2, 0, self.powerUps.scale)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.powerUps.fireImg, self.powerUps.x, self.powerUps.y, 0, self.powerUps.scale)

        love.graphics.setFont(self.font)
        self.powerUps.active = true
    else
        --no powerUp active
        self.powerUps.active = false
    end
end

function GUI:displayLives()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.draw(self.lives.img, self.lives.x + 2, self.lives.y + 2, 0, self.lives.scale)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.lives.img, self.lives.x, self.lives.y, 0, self.lives.scale)
end

function GUI:displayText()
    --fix the position of the text
    local coinX = self.coins.x + self.coins.width * self.coins.scale
    local coinY = self.coins.y + self.coins.height / 2 * self.coins.scale - self.font:getHeight() / 2

    local liveX = self.lives.x + self.lives.width * self.lives.scale
    local liveY = self.lives.y + self.lives.height / 2 * self.lives.scale - self.font:getHeight() / 2

    local powerX = self.powerUps.fireWidth * self.powerUps.scale
    local powerY = self.powerUps.y + self.powerUps.fireHeight / 2 * self.powerUps.scale - self.font:getHeight() / 2

    love.graphics.setColor(0, 0, 0, 0.5)
    --the player coins
    love.graphics.print(" : " .. Player.coins, coinX + 2, coinY + 2)

    -- the player powerUps
    love.graphics.print("PowerUp : ", powerX + 2, powerY + 2)

    --the player lives
    love.graphics.print(" : " .. Player.lives, liveX + 2, liveY + 2)

    --if the player has no active powerups
    if not self.powerUps.active then
        love.graphics.print("none", powerX + 152, powerY + 2)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(" : " .. Player.coins, coinX, coinY)
    love.graphics.print(" : " .. Player.lives, liveX, liveY)
    love.graphics.print("PowerUp : ", powerX, powerY)

    if not self.powerUps.active then
        love.graphics.print("none", powerX + 150, powerY)
    end
end

return GUI
