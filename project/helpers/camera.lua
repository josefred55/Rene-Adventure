local camera = {
    x = 0,
    y = 0,
    scale = 1,
}

function camera:apply()
    love.graphics.push()
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-self.x, -self.y)
end

function camera:clear()
    love.graphics.pop()
end

function camera:setPosition(x, y)
    --this will take the passed in x coordinate to make the self.x be in the center of the window and the player looks centered
    self.x = x - love.graphics.getWidth() / 2 / self.scale
    self.y = y

    --bound the corners of the screens

    local rightSide = self.x + love.graphics.getWidth() / 2

    if self.x < 0 then
        self.x = 0
    elseif rightSide > MapWidth - love.graphics.getWidth() / 2 then
        self.x = MapWidth - love.graphics.getWidth()
    end
end

return camera