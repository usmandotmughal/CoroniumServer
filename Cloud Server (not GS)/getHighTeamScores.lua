



local answer = coronium.mongo:getObjects( "teamsAndScores", {}, 15, "score", "DESC" )
local user_records = answer.result
local out_data = { answer.result}

coronium.output( coronium.answer( out_data ) )







