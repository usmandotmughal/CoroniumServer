--======================================================================--
--== Coronium GS
--======================================================================--
local gs = require( 'CoroniumGS' ):new( 7173, 'abc' )
local dm = require( 'DataManager' ):new()
local gm = require( 'GameManager' ):new( dm )

local os = require( 'os' )
--======================================================================--
--== Set Players Per Game
--======================================================================--
gm:setPlayersPerGame( 1 )
--======================================================================--
--== Set Initial Game Data
--======================================================================--
local game_data = {
	player_turn = 1
}
gm:setInitGameData( game_data ) --== Set initial game data for each player
--======================================================================--
--== Game Code
--======================================================================--

--== Game Code Goes Here

--======================================================================--
--== GameManager Events
--======================================================================--
local function onGameStart( game, players )
	p( "--== New Game Started " .. game:getId() .. " ==--" )
	p( "Games", gm:getGameCount() )

end
--======================================================================--
--== Client Events
--======================================================================--
local function onClientData( client, data )
	p( data )
end

local function onClientConnect( client )
	p( '--== Client Connected ==--' )
	p( "@ " .. os.date( "%X" ), client:getHost() )

	gm:addPlayer( client )
end

local function onClientClose( client )
	p( '--== Client Closed ==--' )
	p( "@ " .. os.date( "%X" ))

	gm:removePlayer( client )
end

local function onClientTimeout( client )
	p( '--== Client Timeout ==--' )
	p( "@ " .. os.date( "%X" ), client:getHost()  )

	gm:removePlayer( client )
end

local function onClientError( client, error )
	p( '--== Client Error ==--' )
	p( error )

	gm:removePlayer( client )
end

local function onGetGameData( player )
	local game = gm:getPlayerGame( player )
	game:publishGameData( player )
end
--======================================================================--
--== GameManager Handlers
--======================================================================--
gm:on( "GameStart", onGameStart )
--======================================================================--
--== Client Handlers
--======================================================================--
gs:on( "GetGameData", onGetGameData )
gs:on( "ClientConnect", onClientConnect )
gs:on( "ClientData", onClientData )
gs:on( "ClientError", onClientError )
gs:on( "ClientClose", onClientClose )
gs:on( "ClientTimeout", onClientTimeout )
