local log = radiant.log.create_logger('consumption')

local CoreDaniConsumptionComponent = class()

function CoreDaniConsumptionComponent:_get_quality(food)
   local food_data = radiant.entities.get_entity_data(food, 'stonehearth:food', false)

   if not food_data then
      radiant.assert(false, 'Trying to eat a piece of food that has no entity data.')
      return -1
   end

   -- apply buffs (Core Dani)
   if food_data.applied_buffs then
      for _, applied_buff in ipairs(food_data.applied_buffs) do
         radiant.entities.add_buff(self._entity, applied_buff)
      end
   end

   if not food_data.quality then
      log:error('Food %s has no quality entry, defaulting quality to raw & bland.', food)
   end

   if self:_has_food_preferences() then
      if not radiant.entities.is_material(food, self._sv._food_preferences) then
         return stonehearth.constants.food_qualities.UNPALATABLE
      end
   end
   return food_data.quality or stonehearth.constants.food_qualities.RAW_BLAND
end

return CoreDaniConsumptionComponent