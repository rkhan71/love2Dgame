function love.load()
    ww = 960
    wh = 540
    love.window.setMode(ww, wh)

    world = love.physics.newWorld(0, 0, false)

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
    tri.body:setFixedRotation(true)

    loadscreen = love.audio.newSource('loadscreen.mp3', 'stream')
    playing = love.audio.newSource('play.mp3', 'stream')
    life = love.audio.newSource('life.mp3', 'static')
    gameover = love.audio.newSource('gameover.mp3', 'static')
    change = love.audio.newSource('change.mp3', 'static')
    gain = love.audio.newSource('gain.mp3', 'static')

    function reset()
        circle.body:setPosition(love.math.random(25, ww - 25), -25)
        tri.body:setPosition(love.math.random(25, ww - 25), -10)
        basket.body:setPosition((ww / 2), wh - 50)

        score = 0
        count = 0
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
        fspeed = 100
        speed = 300
    end
    reset()

    play = false
    loser = false
end

function love.update(dt)
    if play then
        love.audio.stop(loadscreen)

        if not playing:isPlaying() then
            love.audio.play(playing)
        end

        world:update(dt)

        time = time - dt
        fspeed = fspeed + 3*dt
        speed = speed + 3*dt

        local x, y = basket.body:getPosition()
        local cx, cy = circle.body:getPosition()
        local tx, ty = tri.body:getPosition()

        move = false

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

        circle.body:setPosition(cx, cy + fspeed * dt)
        tri.body:setPosition(tx, ty + fspeed * dt)

        if basket.body:isTouching(circle.body) and (cx >= x - 50) and (cx <= x + 50) then
            if fruit == 'circle' then
                score = score + 1
                love.audio.play(gain)
                count = 0
            else
                lives = lives - 1
                love.audio.play(life)
            end
            circle.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if basket.body:isTouching(tri.body) and (tx >= x - 50) and (tx <= x + 50) then
            if fruit == 'triangle' then
                score = score + 1
                love.audio.play(gain)
                count = 0
            else
                lives = lives - 1
                love.audio.play(life)
            end
            tri.body:setPosition(love.math.random(25, ww - 25), -10)
        end

        if cy >= wh + 25 then
            if fruit == 'circle' then
                count = count + 1
            end
            circle.body:setPosition(love.math.random(25, ww - 25), -10)
        end

        if ty >= wh + 25 then
            if fruit == 'triangle' then
                count = count + 1
            end
            tri.body:setPosition(love.math.random(25, ww - 25), -10)
        end

        if count == 3 then
            lives = lives - 1
            love.audio.play(life)
        end

        if lives == 0 then
            if score > tonumber(highscore) then
                love.filesystem.write('highscore.txt', score)
            end
            play = false
            love.audio.stop(playing)
            loser = true
            reset()
        end

        if time <= 0 then
            love.audio.play(change)
            time = love.math.random(3,6)
            fruit = fruits[love.math.random(2)]
        end
    elseif loser then
        if not life:isPlaying() then
            love.audio.play(gameover)
            love.timer.sleep(5)
            loser = false
        end
    else
        function love.keypressed(key)
            if key == 'space' and loser == false then
                play = true
            end
        end
        if not loadscreen:isPlaying() and not gameover:isPlaying() then
            love.audio.play(loadscreen)
        end
    end
end

function love.draw()
    if play then
        love.graphics.polygon('fill', basket.body:getWorldPoints(basket.shape:getPoints()))
        love.graphics.polygon('fill', tri.body:getWorldPoints(tri.shape:getPoints()))
        love.graphics.circle('fill', circle.body:getX(), circle.body:getY(), circle.shape:getRadius())
        love.graphics.print('Score: '..score..'\nLives: '..lives..'\nCount: '..count..'\nHarvest: '..fruit, 15, 15)
    elseif loser then
        love.graphics.print('GAME OVER', ww / 2, wh / 2)
    else
        love.graphics.print('Press Spacebar to Start\nHighscore: '..highscore, 15, 15)
    end
end
