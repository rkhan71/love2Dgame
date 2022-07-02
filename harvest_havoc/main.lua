function love.load()
    ww = 960
    wh = 540
    love.window.setMode(ww, wh)

    basket = {
        x = (ww / 2) - 50,
        y = wh - 100,
        ht = 100,
        wd = 100
    }

    fruit = {
        rad = 25,
        x = love.math.random(25, ww - 25),
        y = 0,
        vel = 100
    }

    world = love.physics.newWorld(0, 9.81, false)
    bodyb = love.physics.newBody(world, basket.x, basket.y, 'kinematic')
    bodyf = love.physics.newBody(world, fruit.x, fruit.y, 'dynamic')
    shapeb = love.physics.newRectangleShape(basket.wd, basket.ht)
    shapef = love.physics.newCircleShape(fruit.rad)
    fixtureb = love.physics.newFixture(bodyb, shapeb)
    fixturef = love.physics.newFixture(bodyf, shapef)

    score = 0
end

function love.update(dt)
    world:update(dt)
    
    fruit.x, fruit.y = bodyf:getWorldPoints(shapef:getPoint())
    if love.keyboard.isDown('left') then
        basket.x = basket.x - 3
    end
    if love.keyboard.isDown('right') then
        basket.x = basket.x + 3
    end
    if basket.x <= 0 then
        basket.x = basket.x + 3
    elseif basket.x >= 860 then
        basket.x = basket.x - 3
    end
end

function love.draw()
    love.graphics.rectangle('fill', basket.x, basket.y, basket.wd, basket.ht)
    love.graphics.circle('fill', fruit.x, fruit.y, fruit.rad)
    love.graphics.print('Score: '..score, 15, 15)
end
