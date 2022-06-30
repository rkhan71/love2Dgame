function love.load()
    -- loop through array of suits and ranks 1-13 to create a deck of cards. ipairs makes for loop call function which iterates through 
    -- array of suits. It returns an index and the actual value so two values need to be initialized. 
    deck = {}
    for suitInd, suit in ipairs({'club', 'spade', 'diamond', 'heart'}) do
        for rank = 1, 13 do
            table.insert(deck, {suit = suit, rank = rank})
        end
    end

    -- create function that lets the player or dealer take random cards out of the deck and add them to a table 
    -- which will represent their hands. Use function to deal inital cards to player and dealer.
    function hit(person)
        table.insert(person, table.remove(deck, love.math.random(#deck)))
    end
    player = {}
    hit(player)
    hit(player)

    dealer = {}
    hit(dealer)
    hit(dealer)

    -- create round variable which will determine when round is over
    round = false
end

function love.keypressed(key)
    if not round then
        -- let player use 'h' key to hit
        if key == 'h' then
            hit(player)
            if calctotal(player) > 21 then
                round = true
            end
        end

        -- let player use 's' key to stand and therefore end round
        if key == 's' then
            round = true
        end
    else
        if key == 'r' then
            love.load()
        end
    end
end

function love.draw()
    -- create table which will be printed to show game results
    local output = {}

    -- function to find totals for player and dealer hands
    function calctotal(person)
        local total = 0
        local ace = false
        for cardInd, card in ipairs(person) do 
            if card.rank > 10 then
                total = total + 10
            else
                total = total + card.rank
            end
            if card.rank == 1 then
                ace = true
            end
        end
        if ace and total <= 11 then
            total = total + 10
        end
        return total
    end

    -- find winner when round over and add winner message to output table
    if round then
        -- give dealer more cards if he needs
        while calctotal(dealer) < 17 do
            hit(dealer)
        end

        -- function to find winner by returning value if first input wins
        local function winner(person1, person2)
            p1 = calctotal(person1)
            p2 = calctotal(person2)
            return p1 <= 21 and (p2 > 21 or p1 > p2)
        end

        if winner(player, dealer) then
            table.insert(output, 'Player wins!')
        elseif winner(dealer, player) then
            table.insert(output, 'Dealer wins.')
        else
            table.insert(output, 'Draw.')
        end

        table.insert(output, '')
    end

    -- add player and dealer hands and totals to output table to show them when they need to be shown
    table.insert(output, 'Player hand:')
    for cardInd, card in ipairs(player) do
        table.insert(output, card.suit..' '..card.rank)
    end
    table.insert(output, 'Total: '..calctotal(player))

    table.insert(output, '')

    table.insert(output, 'Dealer hand: ')
    for cardInd, card in ipairs(dealer) do
        if not round and cardInd == 1 then
            table.insert(output, '(Card hidden)')
        else
            table.insert(output, card.suit..' '..card.rank)
        end
    end
    if not round then
        table.insert(output, 'Total: ?')
    else
        table.insert(output, 'Total: '..calctotal(dealer))
    end

    love.graphics.print(table.concat(output, '\n'), 15, 15)
end