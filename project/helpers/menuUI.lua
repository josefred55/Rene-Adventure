local Menu = {}

local player = require 'helpers.player'
local map = require 'helpers.map'
local GUI = require 'helpers.GUI'

BUTTON_HEIGHT = 64
BUTTON_FONT = love.graphics.newFont('Assets/gamefont.ttf', 32)

END_SCREEN = {instructions = false, victory = false, gameOver = false, statistics = false}

local fileInfo = love.filesystem.getInfo("Assets/instructions.txt")
if fileInfo then
    Menu.instructions, _ = love.filesystem.read( "Assets/instructions.txt", 512)
end

local function newButton(text, fn)
    return {
        text = text,
        fn = fn,

        now = false,
        last = false
    }
end

local buttons = {menuScreen = {}, victory_screen = {}, gameOver_screen = {}, statistics_screen = {}, instructions_screen = {}, paused_screen = {}}

function Menu.load()
    --Menu screen buttons
    table.insert(buttons.menuScreen, newButton(
        "Start Game",
        function()
            GAME_STARTED = true
            love.loadOtherStuff("map")
        end))

    table.insert(buttons.menuScreen, newButton(
        "Instructions",
        function()
            --the instructions are not part of the end scrren ui but it is easier to just include them in that table
            END_SCREEN.instructions = true
        end))

    table.insert(buttons.menuScreen, newButton(
        "Exit",
        function()
            love.event.quit(0)
        end))

    --victory screen buttons
    table.insert(buttons.victory_screen, newButton(
        "Play again",
        function()
            GAME_STARTED = true
            love.loadOtherStuff("map")
            END_SCREEN.victory = false
        end))

    table.insert(buttons.victory_screen, newButton(
        "Statistics",
        function()
            END_SCREEN.victory = false
            END_SCREEN.statistics = true
        end))

    table.insert(buttons.victory_screen, newButton(
        "Go to Menu",
        function()
            END_SCREEN.victory = false
        end))

    table.insert(buttons.victory_screen, newButton(
        "Exit",
        function()
            love.event.quit(0)
        end))

    --gameOver screen buttons
    table.insert(buttons.gameOver_screen, newButton(
        "Play again",
        function()
            GAME_STARTED = true
            love.loadOtherStuff("map")
            END_SCREEN.gameOver = false
        end))

    table.insert(buttons.gameOver_screen, newButton(
        "Go to Menu",
        function()
            END_SCREEN.gameOver = false
        end))

    table.insert(buttons.gameOver_screen, newButton(
        "Exit",
        function()
            love.event.quit(0)
        end))

    --statistics screen
    table.insert(buttons.statistics_screen, newButton(
        "Go back",
        function()
            END_SCREEN.victory = true
            END_SCREEN.statistics = false
        end))

    --instructions screen
    table.insert(buttons.instructions_screen, newButton(
        "Go back",
        function()
            END_SCREEN.instructions = false
        end))

    -- paused screen

    table.insert(buttons.paused_screen, newButton(
    "Resume game",
        function()
            GAME_PAUSED = false
            MAP_MUSIC:play()
        end))

    table.insert(buttons.paused_screen, newButton(
    "Go to menu",
        function()
            map:sendtoMenu()
            GAME_PAUSED = false
        end))

    table.insert(buttons.paused_screen, newButton(
        "Exit",
        function()
            love.event.quit()
        end))
end

function Menu.update(dt)
end

function Menu.drawLoadingScreen(level_number, lives_number)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(BUTTON_FONT)

    local level_text = "level "
    local level_text_width = BUTTON_FONT:getWidth(level_text)

    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight() - 50
    local lives = lives_number or 5

    love.graphics.print(level_text .. level_number, (window_width * 0.5) - (level_text_width * 0.5), (window_height * 0.5) - 30)

    love.graphics.draw(GUI.lives.img, (window_width * 0.5) - (GUI.lives.width * 0.5) - 30, (window_height * 0.5) + 30)
    love.graphics.print( "x  " .. lives, (window_width * 0.5), (window_height * 0.5) + 30)
end

function Menu.draw(screen)
    local screentoDraw
    if screen == "menu" then
        screentoDraw = buttons.menuScreen
    elseif screen == "instructions" then
        screentoDraw = buttons.instructions_screen
    elseif screen == "victory" then
        screentoDraw = buttons.victory_screen
    elseif screen == "gameOver" then
        screentoDraw = buttons.gameOver_screen
    elseif screen == "statistics" then
        screentoDraw = buttons.statistics_screen
    elseif screen == "pause" then
        screentoDraw = buttons.paused_screen
    end

    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()

    --the button width will be a third of the window width, so if the window gets scaled the button does too
    local button_width = window_width * (1/3)

    --to display all the buttons.menuScreen evenly with a margin, we need the total height of every button combined
    local margin = 32
    local total_height = (BUTTON_HEIGHT + margin) * #screentoDraw

    --this variable will represnt the current location of the current button or text as we iterate the buttons.menuScreen table right below, so it will change every time we finish with one button
    local cursor_y = 100

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(BUTTON_FONT)

    if screentoDraw == buttons.instructions_screen then
        local instruct_text = Menu.instructions
        local text_width = BUTTON_FONT:getWidth(instruct_text)

        love.graphics.push()
        love.graphics.scale(0.8, 0.8)

        love.graphics.print(instruct_text, 100, 100)

        love.graphics.pop()

    elseif screentoDraw == buttons.victory_screen then
        local congrats_text = "Congratulations, You Win!"
        local text_width = BUTTON_FONT:getWidth(congrats_text)

        love.graphics.print(congrats_text, (window_width * 0.5) - (text_width * 0.5), 100)

    elseif screentoDraw == buttons.gameOver_screen then
        local sorry_text = "Game Over :("
        local text_width = BUTTON_FONT:getWidth(sorry_text)

        love.graphics.print(sorry_text, (window_width * 0.5) - (text_width * 0.5), 100)

    elseif screentoDraw == buttons.statistics_screen then
        for statistic, number in pairs(player.statistics) do
            local statistic_text = tostring(statistic)

            if statistic_text == "collectibles_momentarily_found" then goto continue end

            statistic_text = statistic_text:gsub("_", " ")
            local text_width = BUTTON_FONT:getWidth(statistic_text)

            love.graphics.print(statistic_text .. ": " .. number, (window_width * 0.5) - (text_width * 0.5) - 10, cursor_y)

            cursor_y = cursor_y + margin

            ::continue::
        end
    end

    --draw the buttons
    cursor_y = 0
    for i, button in ipairs(screentoDraw) do
        if screentoDraw == buttons.instructions_screen then
            cursor_y = 200
        end
        --the reason of button.last is basically because we don´t want to keep checking if the button is clicked, ony check it the first time
        button.last = button.now

        local button_x = (window_width * 0.5) - (button_width * 0.5)
        local button_y = (window_height * 0.5) - (total_height * 0.5) + cursor_y

        --get the position of the mouse
        local mx, my = love.mouse.getPosition()

        local color = {0.4, 0.4, 0.5, 1.0}

        --if a button is hot, it means the mouse cursor is right on top of that button, basically a button if hot if the user can click it at that exact moment
        local hot = mx > button_x and mx < button_x + button_width and
                    my > button_y and my < button_y + BUTTON_HEIGHT

        if hot then
            color = {0.8, 0.8, 0.9, 1.0}
        end

        --this will check if the left click of the mouse is down
        button.now = love.mouse.isDown(1)

        --if the button is clicked, call the button function
        if button.now and not button.last and hot then
            button.fn()
        end

---@diagnostic disable-next-line: deprecated
        love.graphics.setColor(unpack(color))

        --the calculations for the buttons.menuScreen x and y position exist so they are drawed at the center of the screen
        love.graphics.rectangle(
            "fill",
            button_x,
            button_y,
            button_width,
            BUTTON_HEIGHT
        )

        --move the cursor so that the next button is positioned right below the last one
        cursor_y = cursor_y + (BUTTON_HEIGHT + margin)

        --draw the text
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(BUTTON_FONT)

        --we want to use these values to center the text
        local text_width = BUTTON_FONT:getWidth(button.text)
        local text_height = BUTTON_FONT:getHeight(button.text)

        love.graphics.print(
            button.text,
            (window_width * 0.5) - (text_width * 0.5),
            button_y + (text_height * 0.5)
        )
    end
end

return Menu