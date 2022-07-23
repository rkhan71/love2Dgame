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

    -- Reset function called whenever game ends so that when player restarts, the game is normal
    function reset()
        -- Positions of bodies
        red.body:setPosition(love.math.random(25, ww - 25), -25)
        green.body:setPosition(love.math.random(25, ww - 25), -25)
        blue.body:setPosition(love.math.random(25, ww - 25), -10)
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

        -- boolean variables to help with counting missed fruits and checking when sound of fruit change has been played
        countedr = false
        countedg = false
        countedb = false
        changed = false
    end
    reset()

    -- boolean variables to check the state of the game
    play = false
    loser = false
    help = false
    pause = false
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
        if basket.body:isTouching(red.body) and (rx >= x - 50) and (rx <= x + 50) and (ry <= y) then
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
                love.audio.play(life)
            end
            red.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if basket.body:isTouching(blue.body) and (bx >= x - 50) and (bx <= x + 50) and (by <= y) then
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
                love.audio.play(life)
            end
            blue.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if basket.body:isTouching(green.body) and (gx >= x - 50) and (gx <= x + 50) and (gy <= y) then
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
                love.audio.play(life)
            end
            green.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        -- If fruit to harvest is missed increase count and reset increase
        if ry >= y - 50 and ry <= y - 40 and fruit == 'red' and not countedr then
            countedr = true
            count = count + 1
            inc = 1
            love.audio.play(splat)
        end

        if gy >= y - 50 and gy <= y - 40 and fruit == 'green' and not countedg then
            countedg = true
            count = count + 1
            inc = 1
            love.audio.play(splat)
        end

        if by >= y - 50 and by <= y - 40 and fruit == 'blue' and not countedb then
            countedb = true
            count = count + 1
            inc = 1
            love.audio.play(splat)
        end

        -- Reset fruit positions when they reach the bottom of the screen, if fruit to harvest is missed increase count and reset increase
        if ry >= wh + 25 then
            countedr = false
            red.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if by >= wh + 25 then
            countedb = false
            blue.body:setPosition(love.math.random(25, ww - 25), -25)
        end

        if gy >= wh + 25 then
            countedg = false
            green.body:setPosition(love.math.random(25, ww - 25), -25)
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

        -- Loadscreen music
        if not loadscreen:isPlaying() and not gameover:isPlaying() then
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
    if play or pause then
        -- Draw all the bodies
        love.graphics.setColor(love.math.colorFromBytes(160, 82, 45))
        love.graphics.polygon('fill', basket.body:getWorldPoints(basket.shape:getPoints()))
        love.graphics.setColor(0, 0, 1)
        love.graphics.circle('fill', blue.body:getX(), blue.body:getY(), blue.shape:getRadius())
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle('fill', green.body:getX(), green.body:getY(), green.shape:getRadius())
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle('fill', red.body:getX(), red.body:getY(), red.shape:getRadius())

        -- Pause screen
        if pause then
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.rectangle('fill', 0, 0, ww, wh)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("GAME PAUSED\n\nPress 'p' to resume\nPress 'r' to restart\nPress 'q' to quit", (ww / 2) - 50, (wh / 2) - 50)
        else
            -- Show all the in game variables in the top left corner of the screen unless game is paused
            love.graphics.setColor(1, 1, 1)
            love.graphics.print('Score: '..score..'\nLives: '..lives..'\nCount: '..count..'\nHarvest: ', 15, 15)
            if fruit == 'red' then
                love.graphics.setColor(1, 0, 0)
            elseif fruit == 'green' then
                love.graphics.setColor(0, 1, 0)
            else
                love.graphics.setColor(0, 0, 1)
            end
            love.graphics.circle('fill', 77, 65, 8)
        end

        -- Show a gain in points when player catches correct fruit
        if point then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print('+'..inc - 1, ww / 2, wh / 2)
        end
    elseif loser then
        -- Game Over screen
        love.graphics.setColor(1, 1, 1)
        love.graphics.print('GAME OVER', (ww / 2) - 75, wh / 2)
    elseif help then
        -- Instructions screen
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Instructions\n(press 'esc' to exit)\n\nThis year's harvest has caused great havoc! We need your help to harvest all the fruits you can. Fruits are falling all over the place from the sky. Harvest them by catching them in your basket which is controlled using the left and right arrow keys.\n\nBut beware! The fruit that you need to harvest will change periodically. The fruit to harvest is displayed in the top left corner of your screen. When the fruit to harvest changes, a clown will alert you by honking his horn. However, this mischievous clown also attempts to throw you off by blowing his horn at times when the fruit to harvest has not changed!\n\nYou will be rewarded with points for harvesting the correct fruit. If you continuously harvest the correct fruit without dropping any or harvesting fruits you were not supposed to, your reward increases. However, if you harvest the wrong fruit or drop the fruit you were supposed to harvest 3 times in a row then you will lose a life. You only have 3 lives so be careful! Your score, lives, and count of how many fruits to harvest you have dropped in a row, are also displayed in the top left corner of your screen.\n\nPress 'p' to pause the game. Good Luck!", 15, 15, 930)
    else
        -- Loadscreen
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("HARVEST HAVOC\n\nPress Spacebar to Start\nPress 'i' for Instructions\nHighscore: "..highscore, 15, 15)
    end
end
