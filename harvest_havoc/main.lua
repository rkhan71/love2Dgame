function love.load()
    ww = 960
    wh = 540
    love.window.setMode(ww, wh)

    world = love.physics.newWorld(0, 0, false)

    floor = {}
    floor.body = love.physics.newBody(world, ww / 2, wh - 1, 'static')
    floor.shape = love.physics.newRectangleShape(ww, 2)
    floor.fixture = love.physics.newFixture(floor.body, floor.shape)

    wallr = {}
    wallr.body = love.physics.newBody(world, ww + 100, wh / 2, 'static')
    wallr.shape = love.physics.newRectangleShape(2, wh)
    wallr.fixture = love.physics.newFixture(wallr.body, wallr.shape)

    walll = {}
    walll.body = love.physics.newBody(world, -100, wh / 2, 'static')
    walll.shape = love.physics.newRectangleShape(2, wh)
    walll.fixture = love.physics.newFixture(walll.body, walll.shape)

    function reset()
        basket = {}
        basket.body = love.physics.newBody(world, (ww / 2), wh - 50, 'kinematic')
        basket.shape = love.physics.newRectangleShape(100, 100)
        basket.fixture = love.physics.newFixture(basket.body, basket.shape)

        fruit = {}
        fruit.body = love.physics.newBody(world, love.math.random(25, ww - 25), 0, 'dynamic')
        fruit.shape = love.physics.newCircleShape(25)
        fruit.fixture = love.physics.newFixture(fruit.body, fruit.shape)
        fruit.body:setMass(0)

        score = 0
        lives = 3
    end

    play = false
end

function love.update(dt)
    if play then
        world:update(dt)

        local x, y = basket.body:getPosition()
        local fx, fy = fruit.body:getPosition()
        move = false
        speed = 200
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

        fspeed = 100
        fruit.body:setPosition(fx, fy + fspeed * dt)

        if basket.body:isTouching(fruit.body) and (fx >= x - 50) and (fx <= x + 50) then
            score = score + 1
            fruit.body:setPosition(love.math.random(25, ww - 25), 0)
        end
        if fruit.body:isTouching(floor.body) then
            lives = lives - 1
            fruit.body:setPosition(love.math.random(25, ww - 25), 0)
        end
        if lives == 0 then
            play = false
        end
    else
        function love.keypressed(key)
            if key == 'space' then
                play = true
                reset()
            end
        end
    end
end

function love.draw()
    if play then
        love.graphics.polygon('fill', basket.body:getWorldPoints(basket.shape:getPoints()))
        love.graphics.circle('fill', fruit.body:getX(), fruit.body:getY(), fruit.shape:getRadius())
        love.graphics.print('Score: '..score..'\nLives: '..lives, 15, 15)
    else
        love.graphics.print('Press Spacebar to Start\nHighscore: ', 15, 15)
    end
end
