function love.load()
    love.window.setMode(960, 540)
    basket = {}
    basket.x = 430
    basket.y = 440
    basket.ht = 100
    basket.wd = 100
end

function love.update()
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
end
