-- This script is copied from ACE with permission from Dani, who happens to be myself and can do so
-- since I wrote it anyway :P 

-- Adds a thought when the buff is added
local CoreDaniAddThoughtBuff = class()

function CoreDaniAddThoughtBuff:on_buff_added(entity, buff)
   local json = buff:get_json()
   if buff then
      radiant.entities.add_thought(entity, json.thought)
   end
end

return CoreDaniAddThoughtBuff
