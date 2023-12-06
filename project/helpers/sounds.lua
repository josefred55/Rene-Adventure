local Sounds = {}

function Sounds.load()
    Sounds.jump = love.audio.newSource("Assets/sounds/jumping.mp3", "static")
    Sounds.coin = love.audio.newSource("Assets/sounds/coin.mp3", "static")
    Sounds.hurt = love.audio.newSource("Assets/sounds/hurt.mp3", "static")
    Sounds.bones = love.audio.newSource("Assets/sounds/bones.mp3", "static")
    Sounds.fireball = love.audio.newSource("Assets/sounds/fireball2.wav", "static")
    Sounds.powerUp = love.audio.newSource("Assets/sounds/powerUp.wav", "static")
    Sounds.lever = love.audio.newSource("Assets/sounds/lever.mp3", "static")
    Sounds.good = love.audio.newSource("Assets/sounds/victory.mp3", "static")
    Sounds.wallJump = love.audio.newSource("Assets/sounds/wallJump.wav", "static")

    Sounds.overworldMusic = love.audio.newSource("Assets/sounds/overworld.mp3", "stream")
    Sounds.overworldMusic:setLooping(true)

    Sounds.undergroundMusic = love.audio.newSource("Assets/sounds/underground.mp3", "stream")
    Sounds.undergroundMusic:setLooping(true)

    Sounds.jump:setVolume(0.5)
    Sounds.coin:setVolume(0.5)
    Sounds.hurt:setVolume(0.5)
    Sounds.bones:setVolume(0.5)
    Sounds.powerUp:setVolume(0.5)
    Sounds.overworldMusic:setVolume(0.25)
end

return Sounds