function love.load()
    ww = 960
    wh = 540
    love.window.setMode(ww, wh)

    world = love.physics.newWorld(0, 9.81, false)

    basket = {}
    basket.body = love.physics.newBody(world, (ww / 2), wh - 50, 'kinematic')
    basket.shape = love.physics.newRectangleShape(100, 100)
    basket.fixture = love.physics.newFixture(basket.body, basket.shape)

    fruit = {}
    fruit.body = love.physics.newBody(world, love.math.random(25, ww - 25), 0, 'dynamic')
    fruit.shape = love.physics.newCircleShape(25)
    fruit.fixture = love.physics.newFixture(fruit.body, fruit.shape)

    score = 0
    lives = 3
end

function love.update(dt)
    world:update(dt)

    local x, y = basket.body:getPosition()
    local fx, fy = fruit.body:getPosition()
    move = false
    speed = 100
    if love.keyboard.isDown('right') then
        x = x + speed * dt
        move = true
    elseif love.keyboard.isDown('left') then
        x = x - speed * dt
        move = true
    end
    if move then
        basket.body:setPosition(x, y)
    end

    if basket.body:isTouching(fruit.body) and (fx >= x - 50) and (fx <= x + 50) then
        score = score + 1
        fruit.body:setPosition(love.math.random(25, ww - 25), 0)
    end
    if fy >= wh then
        lives = lives - 1
        fruit.body:setPosition(love.math.random(25, ww - 25), 0)
    end
end

function love.draw()
    love.graphics.polygon('fill', basket.body:getWorldPoints(basket.shape:getPoints()))
    love.graphics.circle('fill', fruit.body:getX(), fruit.body:getY(), fruit.shape:getRadius())
    love.graphics.print('Score: '..score..'\nLives: '..lives, 15, 15)
end
