#Server-Side Development#

##Getting Started##

###Spin Up An Instance###

You can currently run __Coronium GS__ via an Amazon AMI, or Ubuntu 14.04 64bit based install.  [DigitalOcean](https://www.digitalocean.com/?refcode=cddeeddbbdb8) is the recommended cloud provider for Ubuntu based instances.

The most current installation options can be found at the [Coronium GS](http://coronium.gs) site.

*See also: [Client side development](http://coronium.gs/client/topics/development.md.html)*

###Download the source###

Visit the bitbucket repo to [download the latest client and server files](https://bitbucket.org/develephant/coronium-gs) for __Coronium GS__.

##Overview: main.lua##

The __main.lua__ file that is included in the download (Server/main.lua) is the main development template (see also: `main-tpl.lua`).  The file is where you build the foundation for your server game, so study it well. 

For a full listing of server-side events you can listen for see: [Server-side Events](http://coronium.gs/server/modules/CoroniumGS.html#Events).

##Securing##

You can set a custom key on the server-side that you must match with the client when it connects.  By default the key is 'abc', to change it, at the top of the __main.lua__:

     local gs = require( 'CoroniumGS' ):new( 7173, 'ENTER-YOUR-KEY-HERE' )

__*You will also need to make sure you pass the same key up with the client [connect](http://coronium.gs/client/modules/CoroniumGSClient.html#connect) method.*__

##Event Usage##

__Coronium GS__ is an event driven system.  You listen for specific events and then perform some action depending on the data passed into these events.

For a full listing of __Coronium GS__ server events see [Coronium GS Events](http://coronium.gs/server/modules/CoroniumGS.html#Events).

The __GameStart__ event is part of the `GameManager`.

###GameStart###

To listen for events, we need an event handler, and the listener.  For example, to set up listening for a [GameStart](http://coronium.gs/server/modules/GameManager.html#GameStart) event, we can do the following:

	local function onGameStart( game, players )
		p( "new game id: " .. game:getId() )
	end
	gs:on( "GameStart", onGameStart )

###ClientData###

The 'work horse' of __Coronium GS__, the [ClientData](http://coronium.gs/server/modules/CoroniumGS.html#ClientData) event is called when the server has recieved data from the client.  You can capture and process this data to make your game do stuff.

    local function onClientData( client, data )
      if data.place_marker then
      	--Place a game marker
      end
    end
    gs:on( "ClientData", onClientData )

##Custom Modules/Events##

In many cases you will want to create seperate modules for your game.  You store these modules in the __modules__ folder and require them in your code:

    local my_mod = require( 'my_module' )

###Libraries###

On the server-side, __Coronium GS__ requires that you include the Lua libraries specifically.  Table, String, Math, OS in particular.  Not all Lua libraries are available.  For example, to use table functionalty in your file:

    local table = require( 'table' )

    table.insert( t, value )

If you're getting errors when using any of the Lua libs, double check that they have been imported.

###Custom Events###

You can use the built it event dispatcher in your module as well by extending the 'Emitter' class:

    local Emitter = require( 'core' ).Emitter
    local my_mod = Emitter:extend()

    my_mod:doSomething()
    	self:emit( "DidIt", { msg = "I did it!" } )
    end

    return my_mod

Then in some other area or module, you can set up a listener:

    local my_mod = require( 'my_module' )

    --Listen
    my_mod:on( "DidIt", function( e )
      p( e.msg )
    end)

    my_mod:doSomething()


###Timers###

You can use timers on the __Coronium GS__ server.  But you must be very cautious on when and where you implement them.

__*Timers can take up precious computing resources, so you never want too many running at the same time.  A good practice is to use one global timer and process your events there.*__

To include __timer__ functionality in your file, you must import the __timer__ library:

    local timer = require( 'timer' )

There 2 different timer methods that you can use.

The __setInterval__ timer will run continuously at the millisecond interval you set:

    local t = timer.setInterval( 5000, function()
    	p( "I'm a continuous timer!" )
    end )

The __setTimeout__ is a one-shot timer.  After the timer expires it will not run again and is cleared from memory:

    local t = timer.setTimeout( 10000, function()
    	p( "Has it already been 10 seconds!?" )
    end )

####Clearing Timers####

As long as you store a handle to the timer you create, you can clear it at any time:

    timer.clearTimer( t )

### File IO ###

*Coming soon.  You cannot use the standard Lua file IO library because it is not asynchronous, and will halt your program if you do so.  The asynchronous file IO will be coming soon.*

##Games##

When a client first connects, they are put in a 'waiting' area until the correct amount of clients are available to start a game.  You can set this number using the [setPlayersPerGame](http://coronium.gs/server/modules/GameManager.html#setPlayersPerGame) method of the `GameManager` class.

###Starting###

Once enough players are available for a game, a new game instance will be created, and the clients become 'players' and enter the game.  At this point the [GameStart](http://coronium.gs/server/modules/GameManager.html#GameStart) event will be emitted:

    gs:on( "GameStart", function( game, players ) 
      game:broadcast( { greeting = "Hello Players!" } )
    end )

###Game References###

To do any work on a game, you need to pull the `Game` instance using the `GameManager`.  As long as you have either a `Client`/Player belonging to the game, or a game id, you can easily get a handle to a game:

    local function onClientData( client, data )
      --get the game using the game manager
      local game = gm:getPlayerGame( client )
      --print the game id
      p( game:getId() )
      -- broadcast to all game players
      game:broadcast( { msg = "Hello all!" } )
    end
    gs:on( "ClientData", onClientData )

To get a handle to a game using a game id:

    local game = gm:getGame( 'the-game-id' )

For a full listing of game methods see the `Game` docs.

###Ending###

It's your responsibility to end a game.  You can do this by broadcasting a 'game_done' event to all the game players:

    local function onClientData( client, data )
      --do work here, client wins
      local game = gm:getPlayerGame( client )
      game:broadcast( { game_done = 1 } )
    end
    gs:on( "ClientData", onClientData )

##Game Data##

Your game data is stored in a presistent memory storage space while the game is running.  You can write on this data, as well as, access it and make decisions based on its content.

Working with persistent data storage is event driven as well, so careful consideration should be taken when accessing and storing it.  To work with data you need an event handler and listener.

__Important:__ When working with GameData events, you must use the `gs:once` listener.  This will run the event handler within the correct context.  DO NOT use `gs:on`, or you will run into trouble.

###Get Game Data###

    local function onClientData( client, data )
    	if data.get_my_data then
    	  local game = gm:getPlayerGame( client )
    	  game:once( "GameData", function( game_data )
    	    p( game_data )
    	  end)
    	  game:getData()
    	end
    end
    gs:on( "ClientData", onClientData )

###Save Game Data###

    local function onClientData( client, data )
      if date.save_data then
        local game = gm:getPlayerGame( client )
        game:once( "GameDataSaved", function( err )
        	if not err then
        	  p( "saved" )
        	end
        end)
        game:saveData( { username = "Chris", color = "Green" } )
      end
    end)
    gs:on( "ClientData", onClientData )

When modifiying the game data, you need to operate on the whole object and then resave it:

###Modify game data###

	local function onClientData( client, data )
		if data.update then
			local game = gm:getPlayerGame( client )
			game:once( "GameData", function( gd )
				gd.username = data.username
				gd.score = gd.score + data.score
				game:once( "DataSaved", function( err )
					print( "saved" )
				end)
				game:saveData( gd )
			end)
			game:getData()
		end
	end
	gs:on( "ClientData", onClientData )

###Sending Game Data###

The server includes a built-in event called __GetGameData__, that can be triggered by the client.  But if you need to send the data object to the client(s) in other places, you can use the __publishGameData__ `Game` method, or send it using any of the messaging methods.

    local onClientData( client, data )
      if data.give_me_data then
        local game = game:getPlayerGame( client )
        --== Send down the current game 
        --== data object to all players
        game:publishGameData()

        --== Or to a single player
        game:publishGameData( client )
      end
    end

##Messaging##

The __Coronium GS__ server works by sending messages with state and other data for the client to interpet.

###Client/Player###

When you have a handle on a `Client`/Player you can use the [send](http://coronium.gs/server/modules/Client.html#send) method to send a message to that particular client:

    local function onClientData( client, data )
    	if data.new_message then
    		client:send( { msg = "You have a new messsage" } )
    	end
    end

###Game###

If you have a handle on a `Game` you can broadcast to all players in that game.  You can also pull the `Client`/Players and message via a loop:

####broadcast to all####

    local function onGameStart( game, players )
    	game:broadcast( { greeting = "Hello everyone!" } )
    end
    gm:on( "GameStart", onGameStart )

####game players loop####

	local function onClientData( client, data )
		if data.send_to_all then
			local game = gm:getPlayerGame( client )
			local players = game:getPlayers()
			for p=1, #players do
				players[ p ]:send( "My name is " .. player:getPlayerName() )
			end
		end
	end
	gs:on( "ClientData", onClientData )

##SSH Commands##

While logged in via SSH, you can issue the following commands to control the __Coronium GS__ instance:

###Start###

    sudo service gs start

###Stop###

    sudo service gs stop

###Restart###

    sudo service gs restart

##Log File##

You can view the __Coronium GS__ log file for debugging by opening an SSH connection to your instance and entering the following in terminal:

    sudo tail -f ~/gs.log

## Demos ##

You can find a handful of demos in the [source download](https://bitbucket.org/develephant/coronium-gs), in the __demos__ folder.  By studying those files, you can see more clearly how Coronium GS works in practice.

##Server Docs##

For a full listing of all available server methods and events, please see the [Server Side Documentation](http://coronium.gs/server/index.html).

##Support##

For support, tips, and community involvement, please visit the [Coronium Cloud Community](http://forums.coronium.io/categories/coronium-gs).

[Coronium GS](http://coronium.io/gs) &copy;2014 Chris Byerley [@develephant](http://twitter.com/develephant) | [develephant.net](http://develephant.net)