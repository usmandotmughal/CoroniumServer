
#Coronium Game Server (GS)#

##Development Setup##

###Download source###

[Download](https://bitbucket.org/develephant/coronium-gs/get/default.zip) the latest Server/Client code bundle from the bitbucket repo.

###Start Coding###

Code your Server project using the __Server/main.lua__ file.  You should not need to edit the other files under normal circumstances.

##Pretty Printing##

You can pretty print almost any data using the __p( data )__ global method.
    --== Pretty print the data

    p( data )

##Events/Emitters##

###Event listeners###

####Add event listener####

    :on( "EventName", onEventCallback )

####Single use event listener####

    :once( "EventName", onEventCallback )

###Creating custom events###

####Create 'emitting' module####

    local Emitter = require( 'core' ).Emitter
    local my_mod = Emitter:extend()

    function my_mod:doSomething()
      -- Emit event
      self:emit( "SomeEventName", someEventData )
    end

    return my_mod

####Create listener####

    local mod = require( 'my_mod' )
    
    mod:on( "SomeEventName", function( someEventData )
      --Do something with the event data
      p( someEventData )
    end)

    mod:doSomething()

## Community Support ##

Please visit the [community forums](http://forums.coronium.io/categories/coronium-gs) for tips and helpful topics.
