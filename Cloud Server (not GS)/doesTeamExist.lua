

-- looks through all users to discover team names and membership number, then passes those team names
-- to client to make sure New Team being added by client does not already exist

local answer = coronium.user.getUsers( {}, { team=1 } )
local user_records = answer.result
local out_data = { answer.result}

coronium.output( coronium.answer( out_data ) )