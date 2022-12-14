--[[ Lua code. See documentation: http://berserk-games.com/knowledgebase/scripting/ --]]

--[[ The onLoad event is called after the game save finishes loading. --]]

local player

local deck
local deckGUID = "b835b9"

local dropActionPosition = {-12.76, 0.94, 0.05}
local discardPosition = {-4.68, 0.94, 15.70}
local discardOffset = 0

local princessPlacePosition = {8.11, 0.94, -14.83}
local princessRetinuePositions = {
	{8.11, 1, -9.83},
	{8.11, 1, -4.83},
	{8.11, 1, 0.17},
	{8.11, 1, 5.17},
	{8.11, 1, 10.17},
	{8.11, 1, 15.17}
}

local cards = {
	['Princesa'] = {
		value = 8,
	},
	['Padre'] = {
		value = 2
	},
	['Guarda'] = {
		value = 1
	},
	['Príncipe'] = {
		value = 8,
	},
	['Aia'] = {
		value = 4
	},
	['Barão'] = {
		value = 3
	},
	['Rei'] = {
		value = 6
	},
	['Condessa'] = {
		value = 7
	}
}

local princessRetinue = {}

local princessGUID = "cbbf5f"
local princessCard

local secretAgentPosition = {-5.85, 0.94, -15.13}
local secretAgentCard

local setupFinished = false

local turn = 'player'

local chooseCards = {}
local chooseCardFor = '';
local selectedPrincessRetinue

local currentActionCard -- the current card the player is playing
local currentOpponentActionCard -- the current card the opponent is playing

local lockOpponentLoop = false

local choosedCardMenu -- The card choosed from the user for guarda, principe, etc so the code can detect it
local lastChoosedCardMenu -- The choosed card after the event has detected it 

local chooseReiFor

function onLoad()
	player = Player.getPlayers()[1]
    deck = getObjectFromGUID(deckGUID)
    player.changeColor('Blue')
end

function chooseCardMenuPadre()
	choosedCardMenu = 'Padre'
	hideChooseCardMenu()
end
function chooseCardMenuBarao()
	choosedCardMenu = 'Barão'
	hideChooseCardMenu()
end
function chooseCardMenuAia()
	choosedCardMenu = 'Aia'
	hideChooseCardMenu()
end
function chooseCardMenuPrincipe()
	choosedCardMenu = 'Príncipe'
	hideChooseCardMenu()
end
function chooseCardMenuRei()
	choosedCardMenu = 'Rei'
	hideChooseCardMenu()
end
function chooseCardMenuCondessa()
	choosedCardMenu = 'Condessa'
	hideChooseCardMenu()
end
function hideChooseCardMenu()
	UI.setAttribute('ChooseCardMenu', 'active', 'false')
end	

function handleChoosedCardMenu(a)

    -- this code I think was repeated, keep it here just in case

    selectedPrincessRetinue.highlightOff('Blue')

	if selectedPrincessRetinue.getName() == lastChoosedCardMenu then
		discardCard(selectedPrincessRetinue)

		for i = #princessRetinue,1,-1 
		do 
			if princessRetinue[i] != 'done' and princessRetinue[i].guid == selectedPrincessRetinue.guid then
				princessRetinue[i] = 'done'
			end
		end

		Wait.time(
			function()
				discardCard(currentActionCard)
				switchTurn()
			end,
			1
		)
	else
		discardCard(currentActionCard)
		switchTurn()
    end
end

function disableSecretAgentActions()
	UI.setAttribute('ChooseReiForSecretAgent', 'active', 'false')
	UI.setAttribute('ChooseBaraoVersusSecretAgent', 'active', 'false')
	UI.setAttribute('ChoosePrincipeForSecretAgent', 'active', 'false')
	UI.setAttribute('drawSecretAgent', 'active', 'false')
end

-- Helper functions start

function discardCard(card)
	card.setPositionSmooth(Vector(discardPosition) + Vector(0, 1, discardOffset))
	discardOffset = discardOffset - 2
end

function drawFromSecretAgent()
	if secretAgentCard.is_face_down then
		secretAgentCard.flip()
	end
	
	Wait.time(
		function()
			secretAgentCard.setPositionSmooth(dropActionPosition)
			UI.setAttribute('DrawMenu', 'active', 'false')
			disableSecretAgentActions()
		end,
		1
	)
end

function drawFromDeck()
	drawToPlayer()
end

function drawToPlayer()
	deck.deal(1)
end

-- Helper functions end

function onObjectDrop(colorName, obj)
	-- print('obj')
	-- print(obj.getPosition())
	-- print('dropActionPosition')
	-- print(dropActionPosition)
	-- if obj.getPosition() == dropActionPosition then
	-- 	print("Action")
	-- end
end

function collisionOnTable(params)
	local info = params[1]
	local obj = info.collision_object

	if math.floor(obj.getPosition()[1]) == math.floor(dropActionPosition[1]) and math.floor(obj.getPosition()[3]) == math.floor(dropActionPosition[3]) then
		if #player.getHandObjects() < 1 then
			broadcastToAll("Você deve comprar uma carta antes")
			obj.deal(1)
		else
			currentActionCard = obj
			currentActionCard.interactable = false

			local name = currentActionCard.getName()
			broadcastToAll("Você jogou " .. name)

			handleCardAction(name)
		end
	end
end	

function handleCardAction(name)
	if name == 'Guarda' then
		handleGuardaAction()
	elseif name == 'Príncipe' then
		handlePrincipeAction()
	elseif name == 'Rei' then
		handleReiAction()
	elseif name == 'Padre' then
		handlePadreAction()
	end
end

function handleOpponentCardAction(name)
	print(name)

	if name == 'Barão' then
		handleOpponentBaraoAction()
	elseif name == 'Guarda' then
		handleOpponentGuardaAction()
	end
end

function handleGuardaAction()
    -- This function is called if the user discard a Guarda

	broadcastToAll("Escolha uma carta para revelar")

	-- place the buttons above princess retinue so the user can choose a card to reveal
    placeChooseButtonsForPrincessRetinue("chooseCardForGuarda")

end

function handlePrincipeAction()
    UI.setAttribute('ChoosePrincipeFor', 'active', 'true')
end

function handleReiAction()
	UI.setAttribute('ChooseReiFor', 'active', 'true')
end

function handlePadreAction()
	broadcastToAll("Escolha uma carta para revelar")

	placeChooseButtonsForPrincessRetinue("handleCardForPadre")
end

function handleOpponentBaraoAction()
	UI.setAttribute('ChooseBaraoVersus', 'active', 'true')
end

function handleOpponentGuardaAction()
	if secretAgentCard.is_face_down == false then
		gameover()
		return
	end

	Wait.time(
		function()
			secretAgentCard.flip()
		end,
		1
	)

	Wait.time(
		function()
			discardCard(currentOpponentActionCard)
		end,
		2
	)

	Wait.time(
		function()
			switchTurn()
		end,
		3
	)
end

function handleCardForPadre(obj, player_clicker_color, alt_click)
	-- Destroy all buttons and replace the card with a new one

	for i = #chooseCards,1,-1 
	do 
		destroyObject(chooseCards[i].buttonObj)

		if chooseCards[i].buttonObj.guid == obj.guid then
			chooseCards[i].buttonObj.clearButtons()
			
            selectedPrincessRetinue = chooseCards[i].princessRetinue

			selectedPrincessRetinue.flip()
		end
	end

	Wait.time(
		function()
			discardCard(currentActionCard)
		end,
		1
	)

	Wait.time(
		function()
			switchTurn()
		end,
		2
	)
end

-- ChoosePrincipeFor start --

function choosePrincipeForMe()
    -- disable ChoosePrincipeFor UI
    UI.setAttribute('ChoosePrincipeFor', 'active', 'false')

    -- discard current card
    discardCard(currentActionCard)

    -- discard player hand card
    Wait.time(
        function()
            playerHandCard = player.getHandObjects()[1]
    
            playerHandCardVector = playerHandCard.getPosition()
            playerHandCard.setPosition(playerHandCardVector + Vector(playerHandCardVector[3] + 10, 0, 0))

            discardCard(playerHandCard)
        end,
        0.5
    )

    -- draw a new card
    Wait.time(
        function()
            drawFromDeck()
			switchTurn()
        end,
        1
    )
end

function choosePrincipeForEnemy()
    UI.setAttribute('ChoosePrincipeFor', 'active', 'false')

    -- This function is called if the user discard a Principe
    broadcastToAll("Escolha uma carta para descartar e trocar por uma nova do baralho")

    placeChooseButtonsForPrincessRetinue("chooseCardForPrincipe")
end

function choosePrincipeForSecretAgent()
    -- disable ChoosePrincipeFor UI
    UI.setAttribute('ChoosePrincipeFor', 'active', 'false')

    -- discard current card
    discardCard(currentActionCard)

    -- discard secret agent
    Wait.time(
        function()
            if secretAgentCard.is_face_down then secretAgentCard.flip() end
            discardCard(secretAgentCard)
        end,
        0.5
    )

    -- draw a new secret agent
    Wait.time(
        function()
            drawSecretAgent()
			switchTurn()
        end,
        1
    )

end

-- ChoosePrincipeFor end --

-- ChooseBaraoVersus start --

function ChooseBaraoVersusHand()
	ChooseBaraoVersusResolver('hand')
end

function ChooseBaraoVersusSecretAgent()
	waitTime = 0
	if secretAgentCard.is_face_down then 
		secretAgentCard.flip() 
		waitTime = 1
	end

	Wait.time(
		function()
			ChooseBaraoVersusResolver('secretAgent')
		end,
		waitTime
	)
end

function ChooseBaraoVersusResolver(target)
	UI.setAttribute('ChooseBaraoVersus', 'active', 'false')

	-- get and flip next opponent card value
	referenceCard = nil

	for i = #princessRetinue,1,-1 do
		if princessRetinue[i] != 'done' and princessRetinue[i].guid == currentOpponentActionCard.guid then
			-- find the index for the opponent card, so we can get the next card in the retinue for the reference
			referenceCardIndex = i - 1
			if referenceCardIndex < 1 then
				-- if the reference card index is bellow zero, it means the reference card is the princess
				-- the player loses
				gameover()
				return
			end
			
			referenceCard = princessRetinue[referenceCardIndex]

			break
		end
	end

	if referenceCard.is_face_down then referenceCard.flip() end

	Wait.time(
		function()
			-- compare values
			opponentValue = cards[referenceCard.getName()].value

			playerValue = nil

			if target == 'hand' then
				playerValue = cards[player.getHandObjects()[1].getName()].value
			elseif target == 'secretAgent' then
				playerValue = cards[secretAgentCard.getName()].value
			end

			if opponentValue > playerValue then
				-- if opponent wins, game over
				gameover()
				return
			end

			-- if player wins, discard opponent card
			discardCard(currentOpponentActionCard)

			for i = #princessRetinue,1,-1 do
				if princessRetinue[i] != 'done' and princessRetinue[i].guid == currentOpponentActionCard.guid then
					princessRetinue[i] = 'done'
					break;
				end
			end

			currentActionCard = nil

			Wait.time(
				function()
					switchTurn()
				end,
				1
			)
		end,
		1
	)
end

-- ChooseBaraoVersus end --

-- ChooseReiFor start --

function ChooseReiForHand()
	UI.setAttribute('ChooseReiFor', 'active', 'false');

	chooseReiFor = 'hand';
	placeChooseButtonsForPrincessRetinue('handleChooseReiFor');
end

function ChooseReiForSecretAgent()
	UI.setAttribute('ChooseReiFor', 'active', 'false');

	chooseReiFor = 'secretAgent';
	placeChooseButtonsForPrincessRetinue('handleChooseReiFor');
end

function handleChooseReiFor(obj, player_clicker_color, alt_click)
	-- Destroy all buttons and replace the card with a new one

	for i = #chooseCards,1,-1 
	do 
		destroyObject(chooseCards[i].buttonObj)

		if chooseCards[i].buttonObj.guid == obj.guid then
			chooseCards[i].buttonObj.clearButtons()
			
            selectedPrincessRetinue = chooseCards[i].princessRetinue
			playerHandCard = player.getHandObjects()[1]

			princessRetinueIndex = nil
			for j = #princessRetinue,1,-1
			do
				if princessRetinue[j] != 'done' and princessRetinue[j].guid == selectedPrincessRetinue.guid then
					princessRetinueIndex = j
				end
			end

			if chooseReiFor == 'hand' then
				selectedPrincessRetinue.interactable = true
				selectedPrincessRetinue.deal(1)
				
				playerHandCard.interactable = false

				princessRetinue[princessRetinueIndex] = playerHandCard

				playerHandCardVector = playerHandCard.getPosition()
				playerHandCard.setPosition(playerHandCardVector + Vector(playerHandCardVector[3] + 10, 0, 0))

				playerHandCard.setPositionSmooth(princessRetinuePositions[princessRetinueIndex])
			elseif chooseReiFor == 'secretAgent' then
				selectedPrincessRetinue.setPositionSmooth(secretAgentPosition)

				princessRetinue[princessRetinueIndex] = secretAgentCard

				secretAgentCard.setPositionSmooth(princessRetinuePositions[princessRetinueIndex])
			end
		end
	end

	chooseReiFor = nil

	Wait.time(
		function()
			switchTurn()
		end,
		1
	)
end

-- ChooseReiFor end

function placeChooseButtonsForPrincessRetinue(callbackFunction)
    -- Place a button on every princess retinue card so the user can select one
    -- When choosing a callback function is called
	chooseCards = {}

    for i = #princessRetinue,1,-1 
	do 
		if princessRetinue[i] != 'done' then
			-- Dont place button on flipped cards if current action card is Padre
			shouldPlaceButtonsOnFlippeds = currentActionCard.getName() != 'Padre';

			if princessRetinue[i].is_face_down or (shouldPlaceButtonsOnFlippeds and princessRetinue[i].is_face_down == false) then
				local obj = spawnObject({
					type = "reversi_chip",
					position = Vector(princessRetinue[i].getPosition()) + Vector(0,1,0),
					scale = {.5, .5, .5},
					sound = false
				})

				table.insert(chooseCards, {
					princessRetinue = princessRetinue[i],
					buttonObj = obj
				})

				obj.interactable = false

				obj.createButton({
					click_function = callbackFunction,
					function_owner = Global,
					label          = "Selecionar",
					tooltip        = "Selecionar esta carta",
					position       = {0, .2, 0},
					rotation       = {0, 270, 0},
					width          = 4000,
					height         = 6000,
					font_size      = 600,
					color          = {0.3, 0.8, 0.3},
					font_color     = {1, 1, 1}
				})
			end
		end
	end

	if currentActionCard.getName() == 'Padre' and #chooseCards == 0 then
		discardCard(currentActionCard)
		Wait.time(
			function()
				switchTurn()
			end,
			1
		)
	end
end

function chooseCardForGuarda(obj, player_clicker_color, alt_click)
    -- Destroy all buttons and show a blue highlight around the selected card so the user knows which one he selected
    -- Also enable the ChooseCardMenu that shows the user a list of card's name for him to guess

	for i = #chooseCards,1,-1 
	do 
		destroyObject(chooseCards[i].buttonObj)

		if chooseCards[i].buttonObj.guid == obj.guid then
			chooseCards[i].buttonObj.clearButtons()

			selectedPrincessRetinue = chooseCards[i].princessRetinue

			if selectedPrincessRetinue.is_face_down then
				UI.setAttribute('ChooseCardMenu', 'active', 'true')
				selectedPrincessRetinue.highlightOn('Blue')
			else
				discardCard(selectedPrincessRetinue)
				
				for i = #princessRetinue,1,-1 
				do 
					if princessRetinue[i] != 'done' and princessRetinue[i].guid == selectedPrincessRetinue.guid then
						princessRetinue[i] = 'done'
					end
				end

				Wait.time(
					function()
						switchTurn()
					end,
					1.5
				)
			end
		end
	end
end

function chooseCardForPrincipe(obj, player_clicker_color, alt_click)
    -- Destroy all buttons and replace the card with a new one

	for i = #chooseCards,1,-1 
	do 
		destroyObject(chooseCards[i].buttonObj)

		if chooseCards[i].buttonObj.guid == obj.guid then
			chooseCards[i].buttonObj.clearButtons()

            selectedPrincessRetinue = chooseCards[i].princessRetinue

            -- flip and discard selected card
            selectedPrincessRetinue.flip()
            discardCard(selectedPrincessRetinue)

            Wait.time(
                function() 
                    discardCard(currentActionCard)
                end, 
                0.5
            )

            Wait.time(
                function() 
                    for i = #princessRetinue,1,-1
                    do
                        if princessRetinue[i] != 'done' and princessRetinue[i].guid == selectedPrincessRetinue.guid then
                            -- draw a new card to the opponent
                            local princessRetinueCard = deck.takeObject({
                                flip     = false,
                                position = princessRetinuePositions[i]
                            })
                        
                            princessRetinueCard.interactable = false
                        
                            princessRetinue[i] = princessRetinueCard

							switchTurn()
                        end
                    end
                end, 
                1
            )
            
		end
	end
end

function inputSelectedCardHandler(obj, player_clicker_color, alt_click)
end

function switchTurn()
	if turn == 'player' then
		turn = 'opponent'
		broadcastToAll("Turno do oponente")

		Wait.time(
			function()
				handleOpponentTurn()
			end,
        	1
		)
	elseif turn  == 'opponent' then
		turn = 'player'
		broadcastToAll("Seu turno")
		UI.setAttribute('DrawMenu', 'active', 'true')
	end
end

function gameover()
	broadcastToAll("Você perdeu")
end

function toggleStartGameMenu()
	if UI.getAttribute('StartGameMenu', 'active') == 'true' then
		UI.setAttribute('StartGameMenu', 'active', 'false')
	elseif UI.getAttribute('StartGameMenu', 'active') == 'false' then
		UI.setAttribute('StartGameMenu', 'active', 'true')
	end
end

function toggleDrawMenu()
	if UI.getAttribute('DrawMenu', 'active') == 'true' then
		UI.setAttribute('DrawMenu', 'active', 'false')
	elseif UI.getAttribute('DrawMenu', 'active') == 'false' then
		UI.setAttribute('DrawMenu', 'active', 'true')
	end
end

function setup()
	broadcastToAll("Preparando...")
	toggleStartGameMenu()

	-- deck.randomize()
	
	drawPrincess()
    drawPrincessRetinueCardWrapper()

    drawSecretAgent()

    drawToPlayer()
end

function drawSecretAgent()
	secretAgentCard = deck.takeObject({
		flip     = false,
    	position = secretAgentPosition
    })

    secretAgentCard.interactable = false
end

function drawPrincess()
	princessCard = deck.takeObject({
		flip     = true,
    	position = princessPlacePosition,
    	guid     = princessGUID
    })

    princessCard.interactable = false
end

function drawPrincessRetinueCardWrapper()
	Timer.create({
		identifier = "DrawPrincessRetinueCards",
		function_name = "drawPrincessRetinueCard",
		delay = 0.3,
		repetitions = #princessRetinuePositions
    })
end

function drawPrincessRetinueCard()
	local index = #princessRetinue + 1

	local princessRetinueCard = deck.takeObject({
		flip     = false,
    	position = princessRetinuePositions[index]
    })

    princessRetinueCard.interactable = false

    table.insert(princessRetinue, princessRetinueCard)
end

function identifyOpponentCard()
	-- identify first retinue card
	for i = #princessRetinue,1,-1 do
		if princessRetinue[i] != 'done' then
			currentOpponentActionCard = princessRetinue[i]
			break
		end
	end

	if currentOpponentActionCard.is_face_down == true then
		currentOpponentActionCard.flip()
	end
end

function handleOpponentTurn()
	identifyOpponentCard()
	handleOpponentCardAction(currentOpponentActionCard.getName())

	-- handle opponent card
	-- pass the turn

	-- currentOpponentActionCard = nil
end

--[[ The onUpdate event is called once per frame. --]]
function onUpdate ()
    if princessCard ~= nil and secretAgentCard ~= nil and #princessRetinue == 6 and setupFinished == false then
        -- Shows to the user that everything is ready, princess and shes retinue and secret agent has been draw
    	broadcastToAll("Tudo pronto")
    	setupFinished = true
    	UI.setAttribute('DrawMenu', 'active', 'true')
    end

    if player ~= nil then
        -- if player has more than one card in hand and the draw menu is active, disable it
	    if #player.getHandObjects() > 1 and UI.getAttribute('DrawMenu', 'active') == 'true' then
	    	UI.setAttribute('DrawMenu', 'active', 'false')
	    end
    end

    -- if turn == 'player' and setupFinished == true and UI.getAttribute('DrawMenu', 'active') == 'false' then
    -- 	UI.setAttribute('DrawMenu', 'active', 'true')
    -- end

    -- if turn == 'oponent' and UI.getAttribute('DrawMenu', 'active') == 'true' then
    -- 	UI.setAttribute('DrawMenu', 'active', 'false')
    -- end

    -- Listen for select Choose Card Menu
    if choosedCardMenu ~= nil then
        -- Rotate previous selected card
		selectedPrincessRetinue.flip()

        -- store the selected card and empty the current one so in the next frame onUpdate event doesn't enter here again
		lastChoosedCardMenu = choosedCardMenu
		choosedCardMenu = nil

        -- calls HandleChoosedCardMenu function once after 1 second
		Timer.create({
			identifier = "HandleChoosedCardMenu",
			function_name = "handleChoosedCardMenu",
			delay = 1,
			repetitions = 1
	    })
    end
end