function love.load()
    ww = 960
    wh = 540
    love.window.setMode(ww, wh)

    world = love.physics.newWorld(0, 0, false)

    function reset()
        basket = {}
        basket.body = love.physics.newBody(world, (ww / 2), wh - 50, 'kinematic')
        basket.shape = love.physics.newRectangleShape(100, 100)
        basket.fixture = love.physics.newFixture(basket.body, basket.shape)

        circle = {}
        circle.body = love.physics.newBody(world, love.math.random(25, ww - 25), -25, 'dynamic')
        circle.shape = love.physics.newCircleShape(25)
        circle.fixture = love.physics.newFixture(circle.body, circle.shape)

        tri = {}
        tri.body = love.physics.newBody(world, love.math.random(25, ww - 25), -10, 'dynamic')
        tri.shape = love.physics.newPolygonShape(0, -25, 25, 10, -25, 10)
        tri.fixture = love.physics.newFixture(tri.body, tri.shape)

        score = 0
        lives = 3

        if love.filesystem.getInfo('highscore.txt') then
            highscore = love.filesystem.read('highscore.txt')
        else
            file = love.filesystem.newFile('highscore.txt')
            highscore = '0'
        end
        fruits = {'circle', 'triangle'}
        fruit = fruits[love.math.random(2)]
        time = love.math.random(3, 6)
    end
    reset()

    play = false
end

function love.update(dt)
    if play then
        world:update(dt)

        time = time - dt

        local x, y = basket.body:getPosition()
        local cx, cy = circle.body:getPosition()
        local tx, ty = tri.body:getPosition()

        move = false
        speed = 500
        if love.keyboard.isDown('right') then
            x = x + speed * dt
            move = true
        elseif love.keyboard.isDown('left') then
            x = x - speed * dt
            move = true
        end
        if x >= ww + 50 then
            x = x - speed * dt
            move = true
        elseif x <= -50 then
            x = x + speed * dt
            move = true
        end
        if move then
            basket.body:setPosition(x, y)
        end

        fspeed = 300
        circle.body:setPosition(cx, cy + fspeed * dt)
        tri.body:setPosition(tx, ty + fspeed * dt)

        if basket.body:isTouching(circle.body) and (cx >= x - 50) and (cx <= x + 50) then
            if fruit == 'circle' then
                score = score + 1
                circle.body:setPosition(love.math.random(25, ww - 25), 0)
            else
                lives = lives - 1
                circle.body:setPosition(love.math.random(25, ww - 25), 0)
            end
        end

        if basket.body:isTouching(tri.body) and (tx >= x - 50) and (tx <= x + 50) then
            if fruit == 'triangle' then
                score = score + 1
                tri.body:setPosition(love.math.random(25, ww - 25), 0)
            else
                lives = lives - 1
                tri.body:setPosition(love.math.random(25, ww - 25), 0)
            end
        end

        if cy >= wh + 25 then
            circle.body:setPosition(love.math.random(25, ww - 25), 0)
        end

        if ty >= wh + 25 then
            tri.body:setPosition(love.math.random(25, ww - 25), 0)
        end

        if lives == 0 then
            if score > tonumber(highscore) then
                love.filesystem.write('highscore.txt', score)
            end
            play = false
            reset()
        end

        if time <= 0 then
            time = love.math.random(3,6)
            fruit = fruits[love.math.random(2)]
        end
    else
        function love.keypressed(key)
            if key == 'space' then
                play = true
            end
        end
    end
end

function love.draw()
    if play then
        love.graphics.polygon('fill', basket.body:getWorldPoints(basket.shape:getPoints()))
        love.graphics.polygon('fill', tri.body:getWorldPoints(tri.shape:getPoints()))
        love.graphics.circle('fill', circle.body:getX(), circle.body:getY(), circle.shape:getRadius())
        love.graphics.print('Score: '..score..'\nLives: '..lives..'\nHarvest: '..fruit, 15, 15)
    else
        love.graphics.print('Press Spacebar to Start\nHighscore: '..highscore, 15, 15)
    end
end
