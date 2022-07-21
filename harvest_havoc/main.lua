function love.load()
    -- Set window size
    ww = 960
    wh = 540
    love.window.setMode(ww, wh)

    -- Create world and bodies so that love.physics can be used to take care of collisions and find out when bodies are touching
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

    -- Load in all the sounds
    loadscreen = love.audio.newSource('loadscreen.mp3', 'stream')
    playing = love.audio.newSource('play.mp3', 'stream')
    life = love.audio.newSource('life.mp3', 'static')
    gameover = love.audio.newSource('gameover.mp3', 'static')
    change = love.audio.newSource('change.mp3', 'static')
    gain = love.audio.newSource('gain.mp3', 'static')

    -- Reset function called whenever game ends so that when player restarts, the game is normal
    function reset()
        -- Positions of bodies
        circle.body:setPosition(love.math.random(25, ww - 25), -25)
        tri.body:setPosition(love.math.random(25, ww - 25), -10)
        basket.body:setPosition((ww / 2), wh - 50)

        -- In game variables
        score = 0
        count = 0
        lives = 3

        -- Get the highscore
        if love.filesystem.getInfo('highscore.txt') then
            highscore = love.filesystem.read('highscore.txt')
        else
            file = love.filesystem.newFile('highscore.txt')
            highscore = '0'
        end

        -- Set up fruits array which can be randomly indexed to show which "fruit" the player should catch
        fruits = {'circle', 'triangle'}
        fruit = fruits[love.math.random(2)]
        -- Random time interval at which the fruit to harvest is switched
        time = love.math.random(5, 10)

        -- Initial speeds of fruit falling down and players basket moving side to side
        fspeed = 100
        speed = 300

        -- Initial increase in points for catching correct fruit (increase grows if you catch fruit many times in a row)
        inc = 1

        -- variable to see when player scores points, and timer for how long to show gain in points
        point = false
        ptimer = 0
    end
    reset()

    -- variables to check whether the game is being played and if a player has just lost
    play = false
    loser = false
    help = false
end

function love.update(dt)
    if play then
        -- Play in-game music
        if not playing:isPlaying() then
            love.audio.play(playing)
        end

        -- make sure the world is updated so all the bodies act the way you want them to
        world:update(dt)

        -- Timer for change in fruit to harvest, once it reaches zero play sound, reselect fruit randomly, and reset timer
        time = time - dt
        if time <= 0 then
            love.audio.play(change)
            time = love.math.random(5, 10)
            fruit = fruits[love.math.random(2)]
        end

        -- Timer for how long to show gain in points
        ptimer = ptimer - dt
        if ptimer <= 0 then
            point = false
        end

        -- Increase speed of fruits and basket as time passes
        fspeed = fspeed + 3*dt
        speed = speed + 3*dt

        -- Get positions of bodies
        x, y = basket.body:getPosition()
        local cx, cy = circle.body:getPosition()
        local tx, ty = tri.body:getPosition()

        -- Variable to check if the player tries to move the basket, when it's true the position of the basket is reset
        move = false
        if love.keyboard.isDown('right') then
            -- Change position of basket with speed variable which is constantly updated
            x = x + speed * dt
            move = true
        elseif love.keyboard.isDown('left') then
            x = x - speed * dt
            move = true
        end
        -- Make sure basket doesn't go off the screen
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

        -- Making fruits come down the screen using fspeed variable
        circle.body:setPosition(cx, cy + fspeed * dt)
        tri.body:setPosition(tx, ty + fspeed * dt)

        -- Check if player has caught fruit (basket it touching fruit and fruit is in the right area), then either
        -- award points and reset count variable or decrease lives and reset increase to 0. Always reset position of fruit. 
        if basket.body:isTouching(circle.body) and (cx >= x - 50) and (cx <= x + 50) and (cy <= y) then
            if fruit == 'circle' then
                score = score + inc
                inc = inc + 1
                love.audio.play(gain)
                count = 0
                point = true
                ptimer = 0.5
            else
                inc = 1
                lives = lives - 1
                love.audio.play(life)
            end
            circle.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if basket.body:isTouching(tri.body) and (tx >= x - 50) and (tx <= x + 50) and (ty <= y) then
            if fruit == 'triangle' then
                score = score + inc
                inc = inc + 1
                love.audio.play(gain)
                count = 0
                point = true
                ptimer = 0.5
            else
                inc = 1
                lives = lives - 1
                love.audio.play(life)
            end
            tri.body:setPosition(love.math.random(25, ww - 25), -10)
        end

        -- Reset fruit positions when they reach the bottom of the screen, if fruit to harvest is missed increase count and reset increase
        if cy >= wh + 25 then
            if fruit == 'circle' then
                count = count + 1
                inc = 1
            end
            circle.body:setPosition(love.math.random(25, ww - 25), -10)
        end

        if ty >= wh + 25 then
            if fruit == 'triangle' then
                count = count + 1
                inc = 1
            end
            tri.body:setPosition(love.math.random(25, ww - 25), -10)
        end

        -- If player drops fruit they were supposed to catch 3 times in a row they lose a life, count resets to 0 
        if count == 3 then
            lives = lives - 1
            count = 0
            love.audio.play(life)
        end

        -- Once player loses all their lives end the game, reset the highscore if needed, and make loser variable true
        -- indicating that player has just lost
        if lives == 0 then
            if score > tonumber(highscore) then
                love.filesystem.write('highscore.txt', score)
            end
            play = false
            love.audio.stop(playing)
            loser = true
            reset()
        end
    elseif loser then
        -- Player has just lost so play game over sound once losing life sound is over. Wait a bit to let loss sink in.
        if not life:isPlaying() then
            love.audio.play(gameover)
            love.timer.sleep(5)
            loser = false
        end
    elseif help then
        -- Let user exit instructions screen
        function love.keypressed(key)
            if key == 'escape' then
                help = false
            end
        end
    else
        function love.keypressed(key)
            -- Here the game is not being played so we allow the player to start the game using spacebar
            if key == 'space' and loser == false then
                love.audio.stop(loadscreen)
                play = true
            end

            -- Let player see instructions on how to play the game
            if key == 'i' and loser == false then
                help = true
            end
        end

        -- Loadscreen music
        if not loadscreen:isPlaying() and not gameover:isPlaying() then
            love.audio.play(loadscreen)
        end
    end
end

function love.draw()
    if play then
        -- Draw all the bodies 
        love.graphics.polygon('fill', basket.body:getWorldPoints(basket.shape:getPoints()))
        love.graphics.polygon('fill', tri.body:getWorldPoints(tri.shape:getPoints()))
        love.graphics.circle('fill', circle.body:getX(), circle.body:getY(), circle.shape:getRadius())

        -- Show all the in game variables in the top left corner of the screen
        love.graphics.print('Score: '..score..'\nLives: '..lives..'\nCount: '..count..'\nHarvest: '..fruit, 15, 15)

        -- Show a gain in points when player catches correct fruit
        if point then
            love.graphics.print('+'..inc - 1, ww / 2, wh / 2)
        end
    elseif loser then
        -- Game Over screen
        love.graphics.print('GAME OVER', ww / 2, wh / 2)
    elseif help then
        -- Instructions screen
        love.graphics.printf("Instructions\n(press 'esc' to exit)\n\nThe aim of the game is to harvest as many 'fruits' as you can. The fruits fall from the top of the screen and you can harvest them by putting your basket underneath them before they hit the floor. You can move your basket using the left and right arrow keys.\n\nHowever, the fruit that you need to harvest will change periodically. The fruit to harvest is displayed in the top left corner of the screen. When the fruit to harvest changes, a clown will alert you by honking his horn. But the clown also attempts to throw you off by blowing his horn at times when the fruit to harvest has not changed!\n\nYou gain points for harvesting the correct fruit. If you keep harvesting the correct fruit without dropping any or harvesting fruits you were not supposed to, the number of points you gain increases. However, if you harvest the wrong fruit or drop the fruit you were supposed to harvest 3 times in a row then you will lose a life. You only have 3 lives so be careful! Your score, lives, and count of how many fruits to harvest you have dropped in a row, are also displayed in the top left corner of the screen.\n\nThat's all you need to know. Enjoy!", 15, 15, 930)
    else
        -- Loadscreen
        love.graphics.print("Press Spacebar to Start\nPress 'i' for Instructions\nHighscore: "..highscore, 15, 15)
    end
end
