function love.load()
    -- Set window size
    ww = 960
    wh = 540
    love.window.setMode(ww, wh)

    -- Create world and bodies so that love.physics can be used to take care of collisions and find out when bodies are touching
    world = love.physics.newWorld(0, 0, false)

    basket = {}
    basket.body = love.physics.newBody(world, (ww / 2), wh - 70, 'kinematic')
    basket.shape = love.physics.newRectangleShape(100, 100)
    basket.fixture = love.physics.newFixture(basket.body, basket.shape)

    red = {}
    red.body = love.physics.newBody(world, love.math.random(25, ww - 25), -25, 'dynamic')
    red.shape = love.physics.newCircleShape(25)
    red.fixture = love.physics.newFixture(red.body, red.shape)

    green = {}
    green.body = love.physics.newBody(world, love.math.random(25, ww - 25), -25, 'dynamic')
    green.shape = love.physics.newCircleShape(25)
    green.fixture = love.physics.newFixture(green.body, green.shape)

    blue = {}
    blue.body = love.physics.newBody(world, love.math.random(25, ww - 25), -25, 'dynamic')
    blue.shape = love.physics.newCircleShape(25)
    blue.fixture = love.physics.newFixture(blue.body, blue.shape)

    -- Load in all the sounds
    loadscreen = love.audio.newSource('loadscreen.mp3', 'stream')
    playing = love.audio.newSource('play.mp3', 'stream')
    life = love.audio.newSource('life.mp3', 'static')
    gameover = love.audio.newSource('gameover.mp3', 'static')
    change = love.audio.newSource('change.mp3', 'static')
    gain = love.audio.newSource('gain.mp3', 'static')
    splat = love.audio.newSource('splat.mp3', 'static')

    -- Load in images of clouds and their widths
    cloud1 = love.graphics.newImage('cloud1.png')
    cloud2 = love.graphics.newImage('cloud2.png')
    cloud3 = love.graphics.newImage('cloud3.png')
    cwid = {}
    cwid[1] = cloud1:getWidth()
    cwid[2] = cloud2:getWidth()
    cwid[3] = cloud3:getWidth()

    -- Reset function called whenever game ends so that when player restarts, the game is normal
    function reset()
        -- Positions of bodies
        red.body:setPosition(love.math.random(25, ww - 25), -25)
        green.body:setPosition(love.math.random(25, ww - 25), -25)
        blue.body:setPosition(love.math.random(25, ww - 25), -10)
        basket.body:setPosition((ww / 2), wh - 70)

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
        fruits = {'red', 'blue', 'green'}
        fruit = fruits[love.math.random(3)]
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

        -- boolean variables to check when fruit change and gameover sounds have been played
        changed = false
        goplayed = false

        -- Timers to help with showing and hiding fruits that have hit the ground
        stimers = {}
        stimers.red = 0
        stimers.green = 0
        stimers.blue = 0

        -- timer for gameover screen
        gotimer = 5

        -- positions of clouds
        cpos = {}
        cpos[1] = 0
        cpos[2] = 700
        cpos[3] = 400
    end
    reset()

    -- boolean variables to check the state of the game
    play = false
    loser = false
    help = false
    pause = false
end

function love.update(dt)
    -- Clouds moving unless game paused or player just lost
    if not loser and not pause then
        for i = 1, 3 do
            if cpos[i] > ww then
                cpos[i] = -cwid[i]
            end
            cpos[i] = cpos[i] + 1
        end
    end

    if play then
        -- Play in-game music
        if not playing:isPlaying() then
            love.audio.play(playing)
        end

        -- make sure the world is updated so all the bodies act the way you want them to
        world:update(dt)

        -- Timer for change in fruit to harvest, once it reaches zero play sound, reselect fruit randomly, and reset timer
        time = time - dt
        if time <= 1 and not changed then
            love.audio.play(change)
            changed = true
        end
        if time <= 0 then
            time = love.math.random(5, 10)
            fruit = fruits[love.math.random(3)]
            changed = false
        end

        -- Timer for how long to show gain in points
        ptimer = ptimer - dt
        if ptimer <= 0 then
            point = false
        end

        -- Timers for splats
        for key, stimer in pairs(stimers) do
            if stimers[key] > 0 then
                stimers[key] = stimers[key] - dt
            end
        end

        -- Increase speed of fruits and basket as time passes
        fspeed = fspeed + 3*dt
        speed = speed + 3*dt

        -- Get positions of bodies
        x, y = basket.body:getPosition()
        local rx, ry = red.body:getPosition()
        local bx, by = blue.body:getPosition()
        local gx, gy = green.body:getPosition()

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
        red.body:setPosition(rx, ry + fspeed * dt)
        blue.body:setPosition(bx, by + fspeed * dt)
        green.body:setPosition(gx, gy + fspeed * dt)

        -- Check if player has caught fruit (basket it touching fruit and fruit is in the right area), then either
        -- award points and reset count variable or decrease lives and reset increase to 0. Always reset position of fruit. 
        if basket.body:isTouching(red.body) and (rx >= x - 50) and (rx <= x + 50) then
            if fruit == 'red' then
                score = score + inc
                inc = inc + 1
                love.audio.play(gain)
                count = 0
                point = true
                ptimer = 0.5
            else
                inc = 1
                lives = lives - 1
                love.audio.stop(life)
                love.audio.play(life)
            end
            red.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if basket.body:isTouching(blue.body) and (bx >= x - 50) and (bx <= x + 50) then
            if fruit == 'blue' then
                score = score + inc
                inc = inc + 1
                love.audio.play(gain)
                count = 0
                point = true
                ptimer = 0.5
            else
                inc = 1
                lives = lives - 1
                love.audio.stop(life)
                love.audio.play(life)
            end
            blue.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if basket.body:isTouching(green.body) and (gx >= x - 50) and (gx <= x + 50) then
            if fruit == 'green' then
                score = score + inc
                inc = inc + 1
                love.audio.play(gain)
                count = 0
                point = true
                ptimer = 0.5
            else
                inc = 1
                lives = lives - 1
                love.audio.stop(life)
                love.audio.play(life)
            end
            green.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        -- Reset fruit positions when they reach the bottom of the screen, if fruit to harvest is missed increase count and reset increase
        if ry >= wh - 45 then
            if fruit == 'red' then
                count = count + 1
                inc = 1
                love.audio.play(splat)
            end
            rsx = red.body:getX()
            stimers.red = 3
            red.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if gy >= wh - 45 then
            if fruit == 'green' then
                count = count + 1
                inc = 1
                love.audio.play(splat)
            end
            gsx = green.body:getX()
            stimers.green = 3
            green.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if by >= wh - 45 then
            if fruit == 'blue' then
                count = count + 1
                inc = 1
                love.audio.play(splat)
            end
            bsx = blue.body:getX()
            stimers.blue = 3
            blue.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        -- If player drops fruit they were supposed to catch 3 times in a row they lose a life, count resets to 0 
        if count == 3 then
            lives = lives - 1
            count = 0
            love.audio.stop(life)
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
        end

        -- Pause game
        function love.keypressed(key)
            if key == 'p' then
                play = false
                pause = true
                love.audio.pause(playing)
            end
        end
    elseif pause then
        function love.keypressed(key)
            if key == 'p' then
                pause = false
                play = true
            elseif key == 'r' then
                love.audio.stop(playing)
                reset()
                pause = false
                play = true
            elseif key == 'q' then
                love.audio.stop(playing)
                reset()
                pause = false
            end
        end
    elseif loser then
        -- Player has just lost so play game over sound once losing life sound is over.
        gotimer = gotimer - dt
        if not life:isPlaying() and not goplayed then
            love.audio.play(gameover)
            goplayed = true
        end
        if gotimer <= 0 then
            function love.keypressed(key)
                if key == 'r' then
                    love.audio.stop(gameover)
                    reset()
                    loser = false
                    play = true
                elseif key == 'q' then
                    love.audio.stop(gameover)
                    reset()
                    loser = false
                end
            end
        end
    elseif help then
        -- Let user exit instructions screen
        function love.keypressed(key)
            if key == 'escape' then
                help = false
            end
        end

        -- Loadscreen music
        if not loadscreen:isPlaying() then
            love.audio.play(loadscreen)
        end
    else
        function love.keypressed(key)
            if key == 'space' and loser == false then
                -- Here the game is not being played so we allow the player to start the game using spacebar
                love.audio.stop(loadscreen)
                play = true
            elseif key == 'i' and loser == false then
                -- Let player see instructions on how to play the game
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
    function background()
        -- Draw background
        love.graphics.setColor(love.math.colorFromBytes(135, 206, 235))
        love.graphics.rectangle('fill', 0, 0, ww, wh - 90)
        love.graphics.setColor(love.math.colorFromBytes(34, 139, 34))
        love.graphics.rectangle('fill', 0, wh - 90, ww, 90)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(cloud1, cpos[1], 50)
        love.graphics.draw(cloud2, cpos[2], 100)
        love.graphics.draw(cloud3, cpos[3], 20)
    end

    function statics()
        -- Draw static basket and fruits in random positions
        love.graphics.setColor(love.math.colorFromBytes(102, 51, 0))
        love.graphics.rectangle('fill', ww / 2, wh - 120, 100, 100)
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle('fill', ww / 6, wh - 400, 25)
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle('fill', ww / 2, wh - 200, 25)
        love.graphics.setColor(0, 0, 1)
        love.graphics.circle('fill', ww - 200, wh - 300, 25)
    end

    if play or pause or loser then
        background()

        -- Draw fruits in actual positions
        love.graphics.setColor(0, 0, 1)
        love.graphics.circle('fill', blue.body:getX(), blue.body:getY(), blue.shape:getRadius())
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle('fill', green.body:getX(), green.body:getY(), green.shape:getRadius())
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle('fill', red.body:getX(), red.body:getY(), red.shape:getRadius())

        -- Show a gain in points when player catches correct fruit
        if point and inc > 1 then
            love.graphics.setColor(0, 0, 0)
            love.graphics.print('+'..inc - 1, ww / 2, wh / 2)
        end

        -- Show fallen fruit
        if stimers.red > 0 then
            love.graphics.setColor(1, 0, 0)
            love.graphics.ellipse('fill', rsx, wh - 20, red.shape:getRadius(), 5)
        end

        if stimers.green > 0 then
            love.graphics.setColor(1, 1, 0)
            love.graphics.ellipse('fill', gsx, wh - 20, green.shape:getRadius(), 5)
        end

        if stimers.blue > 0 then
            love.graphics.setColor(0, 0, 1)
            love.graphics.ellipse('fill', bsx, wh - 20, blue.shape:getRadius(), 5)
        end

        -- Draw basket in actual position
        love.graphics.setColor(love.math.colorFromBytes(102, 51, 0))
        love.graphics.polygon('fill', basket.body:getWorldPoints(basket.shape:getPoints()))

        -- Pause screen
        if pause then
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.rectangle('fill', 0, 0, ww, wh)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf("GAME PAUSED\n\nPress 'p' to resume\nPress 'r' to restart\nPress 'q' to quit", 0, (wh / 2) - 50, ww, 'center')
        else
            -- Show all the in game variables in the top left corner of the screen unless game is paused
            love.graphics.setColor(0, 0, 0)
            love.graphics.print('Score: '..score..'\nLives: '..lives..'\nCount: '..count..'\nHarvest: ', 15, 15)
            if fruit == 'red' then
                love.graphics.setColor(1, 0, 0)
            elseif fruit == 'green' then
                love.graphics.setColor(1, 1, 0)
            else
                love.graphics.setColor(0, 0, 1)
            end
            love.graphics.circle('fill', 77, 65, 8)
        end

        -- Game over screen
        if loser then
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.rectangle('fill', 0, 0, ww, wh)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf('GAME OVER\n\n', 0, (wh / 2) - 20, ww, 'center')
            if gotimer <= 0 then
                love.graphics.printf("Press 'r' to restart\nPress 'q' to go back to main menu", 0, wh / 2, ww, 'center')
            end
        end
    elseif help then
        -- Instructions screen
        background()
        statics()
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Instructions\n(press 'esc' to exit)\n\nScore points by catching the fruit to harvest in your basket. Move the basket along the bottom of the screen using the left and right arrow keys. The points you gain from harvesting fruit increase if you continuously harvest the correct fruit without dropping any.\n\nThe fruit to harvest changes every so often. A clown will tell you when the fruit to harvest is about to change by blowing his horn. However, he will also blow his horn at random times to try and throw you off. You will see what fruit to harvest in the top left corner of your screen.\n\nBut be careful! Harvesting the wrong fruit, or dropping the fruit to harvest 3 times in a row will lead to the loss of 1 of your 3 lives. Your score, remaining lives, and count of fruits to harvest you have dropped in a row, will also be shown in the top left corner of your screen.\n\nPress 'p' to pause the game at any time. Good luck!", 250, 20, 460, 'center')
    else
        -- Loadscreen
        background()
        statics()
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("HARVEST HAVOC\n\nPress Spacebar to Start\nPress 'i' for Instructions\nHighscore: "..highscore, 0, 20, ww, 'center')
    end
end
