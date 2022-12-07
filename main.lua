--======================================================================--
--== Coronium GS
--======================================================================--

local gs = require( 'CoroniumGS' ):new( 7173, 'abc' )
--local dm = require( 'DataManager' ):new()
--local gm = require( 'GameManager' ):new( dm )

local os = require( 'os' )
local math = require( 'math' )
local timer = require( 'timer' )
local table = require( 'table' )

--======================================================================--
--== Set Players Per Game and other constants
--======================================================================--

--playersNeeded = 2			 -- players needed per game
--totalTime =  20000			 -- 6 min = 360000 --4 min = 240000- - 2 min = 120000 -- goog short test 20000
--ballsPerTeamTotal = 1  		 -- not per PLAYER  - per TEAM
speedMinus =  0				 -- don't change this, change topBallSpeedDevisor
BGImage = 1    				 -- in the BG folder on client, determines the displayed file

--gs:setPlayersPerGame( playersNeeded )

--======================================================================--
--== Game Events
--======================================================================--

local function onGameStart( game, players )

	p( "--== New Game Started " .. game:getId() .. " ==--" )
	p( "Games", gs:getGameCount() )

	game.playerInfoTable = {}
	game.devTeamTable = {}
	game.supportTeamTable = {}
	game.goNumber = {}
	game.ghostTracker = {}


	game.totalDevEn = .001
	game.totalSupEn = .001
	game.devGreaterThan  = 1 -- the energy level that cannot be exceeded. Gets set dynamically by things like shields, but also by offesive spells
	game.suppGreaterThan = 1

	game.timerTable = {}
	game.devTimerTable = {}
	game.supTimerTable = {}
	game.devTimeTotal = 0
	game.supTimeTotal = 0
	game.leadChange	= 0
	game.leadChangeTemp = 0
	game.updateLead = nil

	--if game:getPlayersMax() >2 then game.wallHeight=2 else game.wallHeight=1 end
	game.wallHeight=2 

	game.globalVarsTable = {

	ghostBallSendVar = 15000, 		-- the frequency whith which Synch Orbs are created.
	stanSpinCost = .30, 			-- cost to attach a SPYNN to a standard ball
	userCreatedSpin  = .30,			-- cost to attach a SPYNN to a user created ball
	antiSpinAmount = .005, 			-- amount minused every second by an ANTI SPYNN Spynn
	regenSpinAmount = .0, 			-- amount of SPYNN regained every second (per player) up to 1.0
	newBallAmount = .10, 			-- Spynn cost to create a new ball
	shieldThreshold = .8,     		-- a team with a SHIELD up cannot have more than this SPYNN (costs .2 eery second if shieldTHreshold is .8)
	protectionTime = 2000,			-- amount of time per player PER PASS (at 2*#players+1 total passes required) allowed when creating a shiled
	invisiWidth = 12, 				-- width of the border on the invisible ball
	sideMinus = 3,					-- increase or decrease speed of balls coming from the side
	topBallSpeedDevisor = 7,		-- higher the number the slower the ball falls from the top
	energyCatchBonus = .08, 		-- amount of Spynn a team gets for catching a ball (if they choose Spynn vs Life)
	lifeCatchBonus = -4000, 		-- amount of life a team gets back for catching a ball (if they choose Life vs Spynn)
	wallHeight = game.wallHeight,	-- 1 = single ball height   2 = middle of the field   

	}

	game.devTeamSpinCost = game.globalVarsTable.stanSpinCost
	game.supportTeamSpinCost = game.globalVarsTable.stanSpinCost

	game:broadcast( { setGlobalVars = true, varTable = game.globalVarsTable} )
	--game:broadcast( { energyUpdate = true, devEn = .01, supEn = .01} )
	game:broadcast( { sendNames = true, img = BGImage..".png", catchEnabled = true } )
end


local function onGameCreate( game )
	p( "--== Game Created ==--" )
	p( game:getId() )
end

local function onGameJoin( game, player )
	p( "--== Game Joined ==--" )
	p( game:getId(), player:getId() )
end

function onGameLeave( game, player )
	p( "--== Game Leave ==--" )
	if game and game.masterTimer then 
		timer.clearTimer( game.masterTimer )
		game.masterTimer = nil
		game.supTimeTotal = nil
		game.devTimeTotal = nil
	end
	p( game:getId(), player:getId() )
	if game:getState() == "full" then 
		game:broadcast( { someoneBailed = true})
		--if game.gameEndTickTock then timer.clearTimer( game.gameEndTickTock ) p("game end timer cancelled") end
		game:close()
	end
end

local function onGameClose( game_id )
	p( "--== Game Closed ==--" )
	p( game_id )
end

--======================================================================--
--== Set Initial Game Data
--======================================================================--

local game_data = {
	player_turn = 1,
	msg = "Welcome to the GAME!"
}
--gs:setInitGameData( game_data ) --== Set initial game data for each player



--======================================================================--
--== Game Code
--======================================================================--

function makeTimersAndShit (team, client, addCancel, userCreatedBallName)
	-- if userCreatedBallName and userCreatedBallName ~= "null" then 
	-- 	for i=1, #team do 								
	-- 		if team[i]==userCreatedBallName then -- if user created ball is on opponenet's (user balls only count agains t the user team score)
	-- 			p("the trap loop")
	-- 		else
	-- 			p("the second trap loop loop "..userCreatedBallName)
	-- 			return
	-- 		end
	-- 	end
	-- end
	-- local game = gs:getPlayerGame( client )
	-- if team == game.devTeamTable and addCancel == "add" then 
	-- 	game.devTimerTable[#game.devTimerTable+1] = timer.setInterval( 500, function() 
	-- 		if game.devTimeTotal then
	-- 			game.devTimeTotal = game.devTimeTotal+500 
	-- 		else
	-- 			for i=#game.devTimerTable, 1, -1 do
	-- 				timer.clearTimer( game.devTimerTable[i] )
	-- 				game.devTimerTable[i] = nil
	-- 			end
	-- 		end
	-- 	end )
	-- elseif team == game.devTeamTable and addCancel == "cancel" then 
	-- 	if game.devTimerTable then 
	-- 		timer.clearTimer( game.devTimerTable[#game.devTimerTable] )
	-- 		game.devTimerTable[#game.devTimerTable] = nil
	-- 	end
	-- end
	-- if team == game.supportTeamTable and addCancel == "add" then 
	-- 	game.supTimerTable[#game.supTimerTable+1] = timer.setInterval( 500, function() 
	-- 		if game.supTimeTotal then
	-- 			game.supTimeTotal = game.supTimeTotal+500 
	-- 		else
	-- 			for i=#game.supTimerTable, 1, -1 do
	-- 				timer.clearTimer( game.supTimerTable[i] )
	-- 				game.supTimerTable[i] = nil
	-- 			end
	-- 		end
	-- 	end )
	-- elseif team == game.supportTeamTable and addCancel == "cancel" then 
	-- 	if game.supTimerTable then 
	-- 		timer.clearTimer( game.supTimerTable[#game.supTimerTable] )
	-- 		game.supTimerTable[#game.supTimerTable] = nil
	-- 	end
	-- end
end


function makeMainTimer (game)

	if game then 
		if game.supTimerTable then 
			for i=#game.supTimerTable, 1, -1 do
				timer.clearTimer( game.supTimerTable[i] )
				game.supTimerTable[i] = nil
			end
			--p("game.supTimerTable num = "..#game.supTimerTable)
		end 
		if game.devTimerTable then 
			for i=#game.devTimerTable, 1, -1 do
				timer.clearTimer( game.devTimerTable[i] )
				game.devTimerTable[i] = nil
			end
			--p(" game.devTimeTotal num = "..#game.devTimerTable) 
		end
		game.masterTimer = timer.setInterval( 500, function()
			if game then 
				if game.devTimeTotal and game.supTimeTotal then 
					if (game.devTimeTotal >= game.totalTime) or (game.supTimeTotal >= game.totalTime ) then 
						if game.devTimeTotal >= game.totalTime then 
							p("red loses!!")
							game:broadcast( { itIsOver = true, devTime = game.totalTime, supTime = game.supTimeTotal } )
						elseif game.supTimeTotal >= game.totalTime  then 
							p("blue loses!!")
							game:broadcast( { itIsOver = true, devTime = game.devTimeTotal, supTime = game.totalTime } )
						end
						timer.clearTimer( game.masterTimer )
						game.masterTimer = nil
						game:close()
						return
					end

					game:broadcast( { timerShit = 1, devTimeTotal = game.devTimeTotal, supTimeTotal = game.supTimeTotal, updateLead = game.updateLead} )
				else
					timer.clearTimer( game.masterTimer )
					game.masterTimer = nil
				end
			end
		end )
	else
		
	end
end


local function findThePassToPlayersTeam (client)
	local game = gs:getPlayerGame( client )
	if game then 
		for i=1, #game.devTeamTable do
			if client:getPlayerHandle() == game.devTeamTable[i] then
				return game.supportTeamTable, i, "supportTeamTable"
			end 
		end

		for i=1, #game.supportTeamTable do
			if client:getPlayerHandle() == game.supportTeamTable[i] then 
				return game.devTeamTable, i, "devTeamTable"
			end 
		end
	end
end


local function findTheClientsTeam (client)
	local game = gs:getPlayerGame( client )
	if game then 
		if game.devTeamTable and game.supportTeamTable then 
			for i=1, #game.devTeamTable do
				if client:getPlayerHandle() == game.devTeamTable[i] then
					--p("the team in findtheclientteam was the devTeamTable ")
					return game.devTeamTable, "devTeamTable"
				end 
			end
			for i=1, #game.supportTeamTable do
				if client:getPlayerHandle() == game.supportTeamTable[i] then 
					--p("the team in findtheclientteam was the supportTeamTable ")
					return game.supportTeamTable, "supportTeamTable"
				end 
			end
		else
			if game then 
				game:broadcast( { messedUp = true } )
			end
		end
	else
		return true
	end
end


local function findThePassToPlayerName (client, clientsTeam, direction)
	local game = gs:getPlayerGame( client )
	if not game then return end
	if clientsTeam == game.supportTeamTable then
		for i=1, #clientsTeam do
			if client:getPlayerHandle() == clientsTeam[i] then  -- when we find the clients position in the table
				if direction == "right" then 
					if i == #clientsTeam then 
						passToPlayerName = clientsTeam[1]
					else
						passToPlayerName = clientsTeam[i+1]
					end
					return passToPlayerName
				elseif direction == "left" then 
					if i == 1 then 
						passToPlayerName = clientsTeam[#clientsTeam]
					else
						passToPlayerName = clientsTeam[i-1]
					end
					return passToPlayerName
				end
			end 
		end
	elseif clientsTeam ==  game.devTeamTable then 
		for i=1, #clientsTeam do
			if client:getPlayerHandle() == clientsTeam[i] then  -- when we find the clients position in the table
				if direction == "left" then 
					if i == #clientsTeam then 
						passToPlayerName = clientsTeam[1]
					else
						passToPlayerName = clientsTeam[i+1]
					end
					return passToPlayerName
				elseif direction == "right" then 
					if i == 1 then 
						passToPlayerName = clientsTeam[#clientsTeam]
					else
						passToPlayerName = clientsTeam[i-1]
					end
					return passToPlayerName
				end
			end 
		end
	end
end


local function findNewOpponentsName (client, myTeam)
	local game = gs:getPlayerGame( client )	 
	local newNum = math.random( 1, #myTeam)
	local newOpponent = tostring (myTeam[newNum]) 
	return newOpponent
end


local function copyTable (table, client)
	local game = gs:getPlayerGame( client )

	if not table then 
		game:broadcast( { messedUp = true } )
		return 
	end
	if not game then 
		--game:broadcast( { messedUp = true } )
		return
	end

	game.newTable = {}
	

	for i=1, #table do
		p(table[i].." "..#game.newTable)
		game.newTable[i]=table[i]
	end
	return game.newTable
end
 

local function sendTheBalls (game, client, ballsPerTeam) 							 --also broadcasts the GAME END SCORE 

	game.circleID = 0
	game.masterDevList = {}
	game.masterSuppList = {}
	game.devDupeTable = copyTable( game.devTeamTable, client )  
	game.supportDupeTable =  copyTable( game.supportTeamTable, client ) 
	game.iterator = #game.supportTeamTable -- ballsPerTeam (sets one ball per player. can be adjusted)

	------ 	SETUP INITIAL BALLS FOR DEVELOPMENT TEAM ------------
	if not game.devDupeTable then p("Someone quit maybe?") return end
	for i=1, game.iterator do
		removeIt = math.random(1,#game.devDupeTable)
		table.insert( game.masterDevList, game.devDupeTable[removeIt] )
		table.remove( game.devDupeTable, removeIt )
		if #game.devDupeTable == 0 then game.devDupeTable = copyTable( game.devTeamTable, client ) end
	end
	for i=1, #game.masterDevList do 
		game.circleID = game.circleID+1
		local player = game:getPlayerByHandle (game.masterDevList[i])
		local randomOpponent = findNewOpponentsName (game.masterDevList[i], game.supportTeamTable )
		player:send( {velocity = 1, msg = 2500, passToPlayer = randomOpponent, msgs2 = 0, 
			circleData = {
				spin="start", 
				color= {196/255, 104/250, 60/255},
				circleName =  randomOpponent,
				ID = game.circleID,
				passed = false,
			}})
		--makeTimersAndShit (game.devTeamTable, client, "add", "null")
	end
	------ 	SETUP INITIAL BALLS FOR SUPPORT TEAM ------------
	for i=1, game.iterator do
		removeIt = math.random(1,#game.supportDupeTable)
		table.insert( game.masterSuppList, game.supportDupeTable[removeIt] )
		table.remove( game.supportDupeTable, removeIt )
		if #game.supportDupeTable == 0 then game.supportDupeTable = copyTable( game.supportTeamTable, client ) end
	end
	for i=1, #game.masterSuppList do 
		game.circleID = game.circleID+1
		local player = game:getPlayerByHandle (game.masterSuppList[i])
		local randomOpponent = findNewOpponentsName (game.masterDevList[i], game.devTeamTable )
		player:send( {velocity = 1, msg = 2500, passToPlayer = randomOpponent, msgs2 = 0, 
			circleData = {
				spin="start", 
				color= {196/255, 104/250, 60/255},
				circleName =  randomOpponent,
				ID = game.circleID,
				passed = false,
			}})
		--makeTimersAndShit (game.supportTeamTable, client, "add", "null")
	end
	---------------------------------------------------------
	gameEndTotal (client)
end


local function adjustTheScore (team, plusOrMinus, client, message)

	local game = gs:getPlayerGame( client )
	if game then 
		if team == game.devTeamTable then 
			--p("the dev team gets score adjusted")
			game.devTimeTotal = game.devTimeTotal+plusOrMinus
		elseif team == game.supportTeamTable then 
			--p("the support team gets score adjusted")
			game.supTimeTotal = game.supTimeTotal+plusOrMinus
		end
		if plusOrMinus>1 then 
			--p("and it was >1")
			client:send( { penalty = plusOrMinus, message=message } )
		elseif plusOrMinus < 1 then 
			--p("and it was < 1")
			client:send( { bonus = plusOrMinus } )
		end
	end
end


function gameEndTotal (client)
	local game = gs:getPlayerGame( client )
	if game then 
		game:broadcast( { trackTime = game.totalTime})
	end

	-- game.trackTimeLeft = game.totalTime

	-- game.gameEndTickTock = timer.setTimeout( game.totalTime, function() 
	-- 	game:broadcast( { itIsOver = true, devTime = game.devTimeTotal, supTime = game.supTimeTotal } )

	-- 	timer.clearTimer( game.masterTimer )
	-- 	game.masterTimer = nil

	-- 	timer.clearTimer(game.timeLeftTimer)
	-- 	game:close()

	-- 	end )

	-- game.timeLeftTimer = timer.setInterval(1000, function() 
	-- 	game.trackTimeLeft=game.trackTimeLeft-1000 
	-- 	game:broadcast( { trackTime = game.trackTimeLeft})
	-- 	end  )
end


local function energyShit (client, amount, game, greaterThanPara)

	local playerTeam = findTheClientsTeam(client)
	if not amount then amount = 0 end --p ("there was a problem with the energy amount") end
	if greaterThanPara then 
		if playerTeam == game.devTeamTable then 
			game.devGreaterThan = greaterThanPara
		elseif playerTeam == game.supportTeamTable then
			game.suppGreaterThan = greaterThanPara
		end
	end

	if playerTeam == game.devTeamTable then 
		game.totalDevEn=game.totalDevEn+amount
		if game.totalDevEn > game.devGreaterThan then game.totalDevEn = game.devGreaterThan end
		if game.totalDevEn < 0 then game.totalDevEn = .01 end
		
	elseif playerTeam== game.supportTeamTable then 
		game.totalSupEn=game.totalSupEn+amount
		if game.totalSupEn > game.suppGreaterThan then game.totalSupEn = game.suppGreaterThan end
		if game.totalSupEn < 0 then game.totalSupEn = .01 end
		
	end
	if game then 
		game:broadcast( { energyUpdate = true, devEn = game.totalDevEn, supEn = game.totalSupEn } )
	else
		p("THere was no GAME of energyShit on server... ")
	end
end


local function findAllClientsOnTeam (team, game)
	if game then 
		game.clientTeam = {}
		for i=1, #team do 
			local player = game:getPlayerByHandle (team[i])
			table.insert( game.clientTeam,  player)
		end
		return game.clientTeam
	end
end


local function increaseStanSpin (client, who) 

	local game = gs:getPlayerGame( client )

	if who and who == "opp" then 
		game.team, game.teamnum, game.tempTeam = findThePassToPlayersTeam(client)
	else
		game.team, game.tempTeam = findTheClientsTeam(client)
	end

	game.team1 = findAllClientsOnTeam(game.team, game)

	if game.tempTeam == "devTeamTable" then 
		p ("it was the devSpinTbale")
		game.stanSpinCost = (game.devTeamSpinCost/2)+game.devTeamSpinCost
		game.devTeamSpinCost = game.stanSpinCost
	elseif game.tempTeam == "supportTeamTable" then 
		p ("it was the supportSpinTbale")
		game.stanSpinCost = (game.supportTeamSpinCost/2)+game.supportTeamSpinCost
		game.supportTeamSpinCost = game.stanSpinCost
	end

	for i=1, #game.team1 do
		game.team1[i]:send ( { changeStanSpin = game.stanSpinCost } )
	end
end


local function reduceStanSpin (client)

	local game = gs:getPlayerGame( client )

	if who and who == "opp" then 
		game.team, game.teamnum, game.tempTeam = findThePassToPlayersTeam(client)
	else
		game.team, game.tempTeam = findTheClientsTeam(client)
	end

	game.team1 = findAllClientsOnTeam(game.team, game)

	if game.tempTeam == "devTeamTable" then 
		p ("it was the devSpinTbale")
		game.stanSpinCost = (game.devTeamSpinCost/3)+(game.devTeamSpinCost/3)
		game.devTeamSpinCost = game.stanSpinCost
	elseif game.tempTeam == "supportTeamTable" then 
		p ("it was the supportSpinTbale")
		game.stanSpinCost = (game.supportTeamSpinCost/3)+(game.supportTeamSpinCost/3)  -- well that's kind of silly
		game.supportTeamSpinCost = game.stanSpinCost
	end

	for i=1, #game.team1 do
		game.team1[i]:send ( { changeStanSpin = game.stanSpinCost } )
	end
end


--======================================================================--
--== Client Events
--======================================================================--


local function onClientData( client, data )
	local thisGame = gs:getPlayerGame( client )
	if thisGame then 
		if data.flameOver then 
			local game = gs:getPlayerGame( client )
			if game then 
				game:broadcast( { flameOver=true} )
			end
		end

		if data.playSpynnStatus then 
			local game = gs:getPlayerGame( client )
			if game then 
				local opponent = game:getPlayerByHandle (data.sendGhost)
				opponent:send( {castSpynn = data.castSpynn, status = data.status }) 
			end
		end
		if data.primumMagicisReturned then -- if a PRIMUM MAGICIS orb landed on a client, this tells the whole team YOU ARE FREE NOW!
			local game = gs:getPlayerGame( client )
			if game then 
				game.team, game.tempTeam = findTheClientsTeam(client)
				game.team1 = findAllClientsOnTeam(game.team, game)
				for i=1, #game.team1 do
					game.team1[i]:send ( { stopPrimumMagicis = true } )
				end
			end
		end
		if data.makePrimumMagicis then -- if a PRIMUM MAGICIS orb landed on a client, this tells the whole team CAST PRIMUM FIRST
			local game = gs:getPlayerGame( client )
			if game then 
				game.team, game.tempTeam = findTheClientsTeam(client)
				game.team1 = findAllClientsOnTeam(game.team, game)
				for i=1, #game.team1 do
					game.team1[i]:send ( { makePrimumMagicis = true } )
				end
			end
		end
		if data.pumpGhost then 
			local game = gs:getPlayerGame( client)
			if game then 
				local opponent = game:getPlayerByHandle (data.sendGhost)
				opponent:send( {pumpGhost = true, ghostID = data.ghostID }) 
			end
		end
		if data.showGhostSynch then 
			--p("sent the ghost synch !!!!  ")
			local game = gs:getPlayerGame( client)
			if game then 
				local opponent = game:getPlayerByHandle (data.sendGhost)
				opponent:send( {showGhostSynch = true, ghostID = data.ghostID }) 
			end
		end
		if data.moveTheGhost then 
			local game = gs:getPlayerGame( client)
			if game then 
				local opponent = game:getPlayerByHandle (data.sendGhost)
				opponent:send( {moveTheGhost = true, ghostID = data.ghostID, ghostX=data.ghostX, ghostY=data.ghostY }) 
			end
		end
		if data.deleteGhost then 
			local game = gs:getPlayerGame( client)
			if game then 
				local opponent = game:getPlayerByHandle (data.sendGhost)
				opponent:send( {deleteGhost = true, ghostID = data.ghostID}) 
			end
		end
		if data.lightItUp then 
			local game = gs:getPlayerGame( client)
			if game then 
				local opponent = game:getPlayerByHandle (data.sendGhost)
				opponent:send( {lightItUp = true, ghostID = data.ghostID}) 
			end
		end
		if data.ghostLock then 													-- determine who tapped the ghost ball first. first: data.ghost then this
			local game = gs:getPlayerGame( client)
			if game then 
				local opponent = game:getPlayerByHandle (data.sendGhost)
				for i=1, #game.ghostTracker do -- first look in the table
					if game.ghostTracker[i][1]== data.ghostLockPos.ghostID then -- find the sub table with the right ghostID
						for j=1, #game.ghostTracker[i] do
							if game.ghostTracker[i][j]==opponent then 			-- my opponenet's id is in there so DON'T pass back the ghostLock
								p("There WAS an opponent in the data.ghostLock so DELETE THE GHOST YOU CAUGHT")
								client:send( {deleteGhost = true, ghostID = data.ghostLockPos.ghostID}) 
								return true
							end
						end
						p("there was no opponenet so SEND GHOSTLOCK")
						table.insert( game.ghostTracker[i], client )  			-- my opponenet wasn't there, so put me there and DO pass back the ghostLock
						opponent:send( {ghostLock = true, ghostLockPos=data.ghostLockPos}) 
					end 
				end  
			end
		end
		if data.ghost then 										-- tells all team players to make a ghost.
			local game = gs:getPlayerGame( client)
			if game then 
				table.insert( game.ghostTracker, {data.ghostTable.ghostID} )
				game:broadcast( { makeAGhost=true, ghostTable=data.ghostTable} ) 
			end
		end
		if data.changeSpinCost then  										 -- change the cost of attaching spyn to a ball
			if data.what == "increase" then 
				increaseStanSpin (client, data.who)
			end
		end
		if data.howLong then  													-- sets game duration in seconds
			local game = gs:getPlayerGame( client )
			if game then 
				game.totalTime = data.howLong
				game.ballsPerTeam = data.ballsPerTeam
			end
		end
		if data.playerName then 															-- VERY FIRST EVENT all clients pass up when game start		
			local game = gs:getPlayerGame( client )
				if game then 
					table.insert ( game.playerInfoTable, client:getPlayerHandle()) 
					if data.playerTeam == "Dev" then 
						local game = gs:getPlayerGame( client )
						if not game.devTeamTable then  game.devTeamTable={} end
						table.insert ( game.devTeamTable, client:getPlayerHandle())
					elseif data.playerTeam == "Support" then 
						local game = gs:getPlayerGame( client )
						if not game.supportTeamTable then game.supportTeamTable={} end
						table.insert ( game.supportTeamTable, client:getPlayerHandle())
					end
					if #game.playerInfoTable == game:getPlayersMax() then 									-- once all the players are in, GOOOOOOO 
						game:broadcast( { devTeamTable=game.devTeamTable, supportTeamTable=game.supportTeamTable, makeTheMap=game.playerInfoTable} )		
					end
					if findTheClientsTeam (client) == game.devTeamTable then 
						client:send ( { myTeamTable = "devTeam"   } )
					elseif findTheClientsTeam (client) == game.supportTeamTable then 
						client:send ( { myTeamTable = "supportTeam"   } )
					end
			end
			--p("the player info table has "..#game.playerInfoTable)
		end
		if data.adjustScore then 
			adjustTheScore (findTheClientsTeam (client), data.adjustScore, client, data.message)
		end
		if data.adjustEnergy then
			local game = gs:getPlayerGame( client )
			if game then energyShit (client, data.amount, game, data.threshold) end
		end
		if data.adjustOpponentEnergy then
			local game = gs:getPlayerGame( client )
			if game then 
				local opponent = game:getPlayerByHandle (data.opp)
				energyShit (opponent, data.amount, game, data.threshold) 
			end
		end
		if data.Go then 																		-- update the Player Map page on the client
			local game = gs:getPlayerGame( client )
			table.insert(game.goNumber, data.playerName)
			for i=1, #game.goNumber do
				if game.goNumber[i] == data.opponent then
					game:broadcast({updateMap = data.playerName})
				end
			end
			if game:getPlayersMax() == #game.goNumber then 
				local t = timer.setTimeout ( 1000, function() game:broadcast( { andGO = 1} )  end )
				local m = timer.setTimeout ( 6000, function() makeMainTimer(game) end ) 
				local s = timer.setTimeout ( 6001, function() sendTheBalls(game, client, game.ballsPerTeam) end )
			end
		end
		if data.protectedFrom then 																-- PLACE a shield on very team member's screen
			local game = gs:getPlayerGame( client )
			local team = findTheClientsTeam(client)
			local team1 = findAllClientsOnTeam(team, game)
			for i=1, #team1 do
			 	team1[i]:send ( {protectedFrom = data.protectedFrom, caster = client:getPlayerHandle()} )
			 end
		end
		if data.dropProtection then 															-- REMOVE shields on very team member's screen
			local game = gs:getPlayerGame( client )
			local team = findTheClientsTeam(client)
			local team1 = findAllClientsOnTeam(team, game)
			for i=1, #team1 do
			 	team1[i]:send ( {shieldDown = true} )
			 end
		end

		if data.velocity then 	
			p("the server sees spin "..data.circleData.spin.." from here "..client:getPlayerHandle())									-- when balls head upwards to opponents team
			if data.circleData.spin2 then 
				p("And the server sees spin2 "..data.circleData.spin2)
			end
			if data.circleData.castingNum then 
				--p("the server ALSO sees castingNum "..data.circleData.castingNum)
			end   
			if data.circleData.bounceBallBack==true then 										 -- ball coming up when a PRIMUM MAGICIS is in play
				local m = "cast Primum Magicis first!" 
				if data.circleData.invisible == true then 
					data.circleData.circleName = "      " 
				else
					data.circleData.circleName = data.passToPlayer
				end
				client:send( {velocity = 1, msg = data.msg, passToPlayer = data.passToPlayer, message = m, wronge = true, circleData = data.circleData})
				return true
			end
			local team, number = findThePassToPlayersTeam(client)								-- to get pass to player for opponent
			if data.circleData.protection then 													-- get rid of PROTECTION ball, stop timer for that now non existant ball
				-- makeTimersAndShit (findTheClientsTeam (client) , client, "cancel")
				-- return true
			end
			if data.circleData.threshold and data.circleData.threshold == true then 			-- opponent shot THRESHOLD ball back to me -- increase my energy cost back to norm
				local game = gs:getPlayerGame( client )
				client:send ( { thresholdBallCameBack = true   } )
				--increaseStanSpin ( client, "opp" ) 							 -- this increases Spynn cost for the team OTHER THAN THE ONE WHO SHOT THE BALL UP - one who made ball first
			end
			if (data.passToPlayer ~= team[number] or data.circleData.passed == false ) and data.circleData.createdBall ~= "new" then  		-- if pass up to the WRONG OPPONENT	or HASN'T BEEN PASSED
				if data.circleData.passed == false then m = "Pass Penalty" end
				if data.passToPlayer ~= team[number] then m = "Player Penalty" end
				if data.circleData.invisible == true then 
					data.circleData.circleName = "      " 
					--p("there was an INVISIBLEITY on this wrong ball")
				else
					data.circleData.circleName = data.passToPlayer
				end
				client:send( {velocity = 1, msg = data.msg, passToPlayer = data.passToPlayer, message = m, wronge = true, circleData = data.circleData})
				
				--p("the SERVER SEES wrong ball")
				return true
			end
			if data.circleData.mirror == true then    										 -- this is a SPECIAL CASE. NO BALL comes back when it's a mirror
				client:send( {mirrorUp = 1} )
				return true
			end
			if data.circleData.spin then  -- plain ball sets all spin to nuetral. Downstream variouse dot.spin types get set, then the final orb is sent.	

				data.circleData.createdBall = "old"
				data.circleData.circleName = newOpponent
				data.circleData.invisible = false
				data.circleData.pestilence = false
				data.circleData.fog = false
				data.circleData.earthquake = false
				data.circleData.mirror = false
				data.circleData.passed = false
				data.circleData.adhesion = false
				data.circleData.threshold = false
				data.circleData.sling = false
				data.circleData.antiSpin = false
				data.circleData.sabotage = false
				data.circleData.trippedWire = false
				data.circleData.clarity = false
				data.circleData.secretPassage = false
				data.circleData.primumMagicis = false
				data.circleData.contactPoison = false
				data.circleData.spinPresent = false
			end

			if data.circleData.spin == "Invisibility" or data.circleData.spin2 == "Invisibility"  then 
				data.circleData.invisible = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Ghastly Fog" or data.circleData.spin2 == "Ghastly Fog" then 
				data.circleData.fog = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Anti Spynn" or data.circleData.spin2 == "Anti Spynn" then 
				data.circleData.antiSpin = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Deathly Pestilence" or data.circleData.spin2 == "Deathly Pestilence" then 
				data.circleData.pestilence = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Earthquake" or data.circleData.spin2 == "Earthquake" then 
				data.circleData.earthquake = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Adhesion" or data.circleData.spin2 == "Adhesion" then 
				data.circleData.adhesion = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Threshold" or data.circleData.spin2 == "Threshold" then 
				data.circleData.threshold = true
				data.circleData.spinPresent = true
				reduceStanSpin(client)
			end

			if data.circleData.spin == "Sling" or data.circleData.spin2 == "Sling" then 
				data.circleData.sling = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Sabotage" or data.circleData.spin2 == "Sabotage" then 
				data.circleData.sabotage = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Tripped Wire" or data.circleData.spin2 == "Tripped Wire" then 
				data.circleData.trippedWire = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Clarity" or data.circleData.spin2 == "Clarity" then 
				data.circleData.clarity = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Secret Passage" or data.circleData.spin2 == "Secret Passage" then 
				data.circleData.secretPassage = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Primum Magicis" or data.circleData.spin2 == "Primum Magicis" then 
				data.circleData.primumMagicis = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Contact Poison" or data.circleData.spin2 == "Contact Poison" then 
				data.circleData.contactPoison = true
				data.circleData.spinPresent = true
			end

			if data.circleData.spin == "Hall of Mirrors" or data.circleData.spin2 == "Hall of Mirrors" then 
				data.circleData.spinPresent = true
				-------------------------
				for i=1, data.circleData.mirrorCount do
					--print ("server mirror "..i)
					local oppTemp = tostring (team[number])
					local game = gs:getPlayerGame( client )	  
					local clientsTeam = findTheClientsTeam(client)
					local opponent = game:getPlayerByHandle (oppTemp) 								-- the current opponenet
					local newOpponent = findNewOpponentsName(client, clientsTeam) 					-- the new opponenet
					data.circleData.xSpot = nil
					data.circleData.ID = "mirror"
					data.circleData.createdBall = "old"
					data.circleData.passed = false
					timer.setTimeout ( i*75, function () 
							data.circleData.mirror = true; data.circleData.spinPresent = false;
							opponent:send( {velocity = 1, msg = data.msg+1000, msg2 = data.msg2-600, 
							passToPlayer =  newOpponent, mirror = true, circleData = data.circleData }) 
						end )
				end
			end
			if data.circleData.spin  == "start" or data.circleData.spin == "null" or data.circleData.spin == "Cancel" then
				data.circleData.castingNum = "null"
			end

			local oppTemp = tostring (team[number])
			local game = gs:getPlayerGame( client )	  
			local clientsTeam = findTheClientsTeam(client)
			local opponent = game:getPlayerByHandle (oppTemp) 								-- the current opponenet
			local newOpponent = findNewOpponentsName(client, clientsTeam) 					-- the new opponenet
			data.circleData.mirror = false
			data.circleData.spin = "null"
			data.circleData.spin2 = "null"
			data.circleData.circleName = newOpponent
			opponent:send( {velocity = 1, msg = data.msg, msg2 = data.msg2, passToPlayer =  newOpponent, circleData = data.circleData})
			p("orb down from the top")
		elseif data.offRight then 																-- when ball passed to the right  
			local game = gs:getPlayerGame( client )
			if game then 
				p("orb to the right")
				local clientsTeam = findTheClientsTeam(client)
				local nextPlayerName = findThePassToPlayerName(client, clientsTeam, "right")
		 		local nextPlayer = game:getPlayerByHandle (nextPlayerName)
		 		data.circleData.passed = true
				nextPlayer:send( {onLeft = 1, msg = data.msg, passToPlayer = data.passToPlayer, circleData = data.circleData})
			end

		elseif data.offLeft then 																-- when ball passed to the left 
			local game = gs:getPlayerGame( client )
			if game then 
				p("orb to the left")
				local clientsTeam = findTheClientsTeam(client)
				local nextPlayerName = findThePassToPlayerName(client, clientsTeam, "left")
				local nextPlayer = game:getPlayerByHandle (nextPlayerName)
				data.circleData.passed = true
				nextPlayer:send( {onRight = 1, msg = data.msg, passToPlayer = data.passToPlayer, circleData = data.circleData}) 
			end
		end
	end
end


local function onClientConnect( client )

	p( '--== Client Connected ==--' )
	p( "@ " .. os.date( "%X" ), client:getHost()  )
end

local function onClientClose( client )
	p( '--== Client Closed ==--' )
	p( "@ " .. os.date( "%X" ))

	local game = gs:getPlayerGame( client )

	if game and game.masterTimer then 
		timer.clearTimer( game.masterTimer )
		game.masterTimer = nil
		game.supTimeTotal = nil
		game.devTimeTotal = nil
	end

	-- local game = gs:getPlayerGame( client )

	-- timerTable = nil
	-- game.playerInfoTable = nil
	-- game.devTeamTable = nil
	-- game.supportTeamTable = nil
	-- game.goNumber = nil
	-- game.devTimeTotal = nil
	-- game.devTimeTotal = nil
	
	--gs:removePlayer( client )
end

local function onClientTimeout( client )
	p( '--== Client Timeout ==--' )
	p( "@ " .. os.date( "%X" ), client:getHost()  )
	if client then 
		--gs:removePlayer( client )
	end
end

local function onClientError( client, error )
	p( '--== Client Error ==--' )
	p( error )

	if error.code == "ECONNRESET" then
		client:destroy()
	end
	--gs:removePlayer( client )
end


--======================================================================--
--== Game Data Events
--======================================================================--

local function onGetGameData( player )
	local game = gs:getPlayerGame( player )
	game:publishGameData( player )
end

--======================================================================--
--== Game Handlers
--======================================================================--
--gs:on( "GetGameData", onGetGameData )

--======================================================================--
--== GameManager Handlers
--======================================================================--
gs:on( "GameStart", onGameStart )
gs:on( "GameCreate", onGameCreate )
gs:on( "GameJoin", onGameJoin )
gs:on( "GameLeave", onGameLeave )
gs:on( "GameClose", onGameClose )

--======================================================================--
--== Client Handlers
--======================================================================--
gs:on( "ClientConnect", onClientConnect )
gs:on( "ClientData", onClientData )
gs:on( "ClientError", onClientError )
gs:on( "ClientClose", onClientClose )
gs:on( "ClientTimeout", onClientTimeout )






















