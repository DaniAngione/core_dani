local FoodDecayService = require('stonehearth.services.server.food_decay.food_decay_service')

CoreDaniFoodDecayService = class()

CoreDaniFoodDecayService._core_dani_old_increment_decay = FoodDecayService.increment_decay
function CoreDaniFoodDecayService:increment_decay(food_decay_data)
   local entity = food_decay_data.entity
   local player_id = entity:get_player_id()
   if player_id and player_id ~= '' then
      local inventory = stonehearth.inventory:get_inventory(player_id)
      local storage = nil
      if inventory then
         storage = inventory:container_for(entity)
      end
      if storage then
         if radiant.entities.is_material(storage, 'no_decay') then
            return false
         end
      end
   end

   self:_core_dani_old_increment_decay(food_decay_data)
end

return CoreDaniFoodDecayService
