-- Service that ticks once per hour to cool hot glass. Created by DaniAngione and based upon Team Radiant's "FoodDecayService"
-- Special thanks to Max, BrunoSupremo and Relyss for the amazing help with the script! IT'S WORKING!!
-- This script is probably not as clean and sleek as it could be due to my noobiness in coding; feel free to improve upon it if you so wish and contact me - any positive changes are appreciated :)

local rng = _radiant.math.get_default_rng()

CoolingService = class()
local COOLING_PER_HOUR = 1

local VERSIONS = {
   ZERO = 0,
   TRACK_COOLING_MANUALLY = 1,
   FIX_LOST_COOL_ITEMS = 2,
}

function CoolingService:get_version()
   return VERSIONS.FIX_LOST_COOL_ITEMS
end

function CoolingService:initialize()
   self.cooling_types = {"molten_glass", "hot_glass", "hot_glassware"}
   self.enable_cooling = true
   self._sv = self.__saved_variables:get_data()
   if not self._sv.initialized then
      self._sv.initialized = true
      self._sv._cooling_glass = {}
      self._sv.cooling_listener = stonehearth.calendar:set_persistent_interval("CoolingService on_cooling", '1h', function()
            self:_on_cooling()
         end)
      self._sv.cooling_type_counts = {}
      self._sv.version = self:get_version()
   else
      -- fix up cooling have no values (came from food rotting, guess I should leave the same fix? - dani)
      self._sv.version = self._sv.version or VERSIONS.ZERO
      if self._sv.version ~= self:get_version() then
         self:fixup_post_load()
      end

      self._sv.cooling_listener:bind(function()
         self:_on_cooling()
      end)
   end

   local entity_container = radiant.events.listen(radiant, 'radiant:entity:post_create', function(e)
            local entity = e.entity
            self:_on_entity_added_to_world(entity)
         end)
		 

   radiant.events.listen(radiant, 'radiant:entity:post_destroy', function(e)
         local entity_id = e.entity_id
         self:_on_entity_destroyed(entity_id)
      end)

      self._post_create_listener = radiant.events.listen(radiant, 'radiant:entity:post_create', function(e)
            local entity = e.entity
            self:_on_entity_added_to_world(entity)
         end)
		 
   self._game_loaded_listener = radiant.events.listen_once(radiant, 'radiant:game_loaded', function()
         if self._post_create_listener then
            self._post_create_listener:destroy()
            self._post_create_listener = nil
         end
         if not stonehearth.calendar:is_tracking_timer(self._sv.cooling_listener) then
            radiant.log.write('cooling', 0, 'glass cooling does not have a listener tracked by the calendar. Recreating a listener')
            if self._sv.cooling_listener then
               self._sv.cooling_listener:destroy()
            end
            -- omg there was a save file where this listener was lost too? I am le sad. -yshan
            self._sv.cooling_listener = stonehearth.calendar:set_persistent_interval("CoolingService on_cooling", '1h', function()
                  self:_on_cooling()
               end)
         end
         self._game_loaded_listener = nil
      end)
end

function CoolingService:fixup_post_load()
   if self._sv.version < VERSIONS.TRACK_COOLING_MANUALLY then
      for _, cooling_data in pairs(self._sv._cooling_glass) do
         local cooling_glass = cooling_data.entity
         if cooling_glass and cooling_glass:is_valid() then
            cooling_data.cooling = radiant.entities.get_attribute(cooling_glass, 'cooling') or 10
         end
      end

      if self._sv._cool_glass then
         for id, entity in pairs(self._sv._cool_glass) do
            if entity and entity:is_valid() then
               self:_on_entity_added_to_world(entity)
            end
         end
      end

      self._sv._cool_glass = nil
   end

   if self._sv.version < VERSIONS.FIX_LOST_COOL_ITEMS then
      self._listen_for_cool_glass = true
   end

   self._sv.version = self:get_version()
end

function CoolingService:get_molten_glass_count()
   return self._sv.cooling_type_counts[self.cooling_types[1]] or 0
end

function CoolingService:get_hot_glass_count()
   return self._sv.cooling_type_counts[self.cooling_types[2]] or 0
end

function CoolingService:get_hot_glassware_count()
   return self._sv.cooling_type_counts[self.cooling_types[3]] or 0
end

function CoolingService:_on_cooling()
   if not self.enable_cooling then
      return
   end
   local cooling_glass = self._sv._cooling_glass
   local ids = {} -- table can be added to while iterating TODO(yshan) how expensive is this?
   for id, _ in pairs(cooling_glass) do
      table.insert(ids, id)
   end

   for _, id in ipairs(ids) do
      self:increment_cooling(cooling_glass[id])
   end
end

function CoolingService:increment_cooling(cooling_data)
   local entity = cooling_data.entity
   local inventory = nil
   local location = nil
   local player_id = radiant.entities.get_player_id(entity)

   local cooling_tuning = radiant.entities.get_entity_data(entity, 'core_dani:cooling')
   if not cooling_tuning then
      return false
   end
   local initial_cooling = cooling_data.cooling
   local cooling = initial_cooling - COOLING_PER_HOUR;
   cooling_data.cooling = cooling
   if cooling <= 0 then
	  -- Here starts the part where it decides whether the glass was properly cooled (storage) or left outside. I couldn't fit it in the "convert_to_cool_form" function and only made it work
	  -- here, so part of the code necessary is repeated (like some variables)... could probably be somehow optimized on the function below OR in two new functions instead of a single
	  -- transformation function... I think. - Dani
		inventory = stonehearth.inventory:get_inventory(player_id)
      location = radiant.entities.get_world_grid_location(entity)
         if not location and inventory then
            local storage = inventory:container_for(entity)
            if storage then
					if cooling_tuning.proper_cooler_alias ~= nil then
						local storage_alias = storage:get_uri()
						-- Check if this is the proper container to cool the entity; otherwise it will cool down to the not proper alias;
						if cooling_tuning.proper_cooler_alias == storage_alias or cooling_tuning.proper_cooler_alias_2 == storage_alias or cooling_tuning.proper_cooler_alias_3 == storage_alias then
							self:_convert_to_cool_form(entity, cooling_tuning.proper_cool_entity_alias)
						elseif cooling_tuning.alternative_cooler_alias and cooling_tuning.alternative_cooler_alias == storage_alias then
							self:_convert_to_cool_form(entity, cooling_tuning.alternative_cool_entity_alias)
						elseif cooling_tuning.cool_entity_alias then
							self:_convert_to_cool_form(entity, cooling_tuning.cool_entity_alias)
						else
							cooling_data.cooling = cooling_tuning.initial_cooling.max
						end
					else
						self:_convert_to_cool_form(entity, cooling_tuning.proper_cool_entity_alias)
					end
				end
			elseif cooling_tuning.cool_entity_alias then
				self:_convert_to_cool_form(entity, cooling_tuning.cool_entity_alias)
			else
				cooling_data.cooling = cooling_tuning.initial_cooling.max
			end
		end
   return true
end

function CoolingService:_convert_to_cool_form(entity, cool_alias)
   local inventory = nil
   local storage_component = nil
   local location = nil
   local storage = nil
   local cool_entity
   if cool_alias then
      -- Replace glass with a cool form
      local player_id = radiant.entities.get_player_id(entity)
      if player_id then
         inventory = stonehearth.inventory:get_inventory(player_id)
         location = radiant.entities.get_world_grid_location(entity)
		 cool_entity = radiant.entities.create_entity(cool_alias, { owner = player_id })
		 local entity_forms = cool_entity:get_component('stonehearth:entity_forms')
		 if entity_forms ~= nil then
			cool_entity = entity_forms:get_iconic_entity()
		 end
         if not location then
			storage = inventory:container_for(entity)
            -- if no location, is it in storage?
            if storage then
               storage_component = storage:get_component('stonehearth:storage')
            end
         end
      end
   end
   if inventory then
      inventory:remove_item(entity:get_id())
   end
   -- Glass is cooled, destroy hot glass
   radiant.entities.destroy_entity(entity)
   if cool_entity then
      if location then
         radiant.terrain.place_entity(cool_entity, location)
      elseif not storage_component or not storage_component:add_item(cool_entity, true) then
         if inventory then
            inventory:add_item(cool_entity, storage, true)
			storage_component:add_item(cool_entity, true) 
         end
      end
      self:_on_entity_added_to_world(cool_entity)
   end
end

function CoolingService:_get_cooling_type(entity)
   for _, cooling_type in ipairs(self.cooling_types) do
      if radiant.entities.is_material(entity, cooling_type) then
         return cooling_type
      end
   end
   return 'unknown'
end

function CoolingService:_on_entity_added_to_world(entity)
   local id = entity:get_id()
   if self._sv._cooling_glass[id] then
      return
   end

   local cooling_tuning = radiant.entities.get_entity_data(entity, 'core_dani:cooling', false) -- do not throw error
   if cooling_tuning then

      local cooling_type = self:_get_cooling_type(entity)
      local initial_cooling = 10
      if cooling_tuning.initial_cooling then
         initial_cooling = rng:get_int(cooling_tuning.initial_cooling.min, cooling_tuning.initial_cooling.max)
      end
      self._sv._cooling_glass[id] = { entity = entity, cooling_type = cooling_type, cooling = initial_cooling }

      local count = self._sv.cooling_type_counts[cooling_type] or 0
      count = count + 1
      self._sv.cooling_type_counts[cooling_type] = count
   end
end

function CoolingService:_on_entity_destroyed(entity_id)
   local cooling_data = self._sv._cooling_glass[entity_id]
   if cooling_data then -- If what's being destroyed is hot glass
      local cooling_type = cooling_data.cooling_type
      local count = self._sv.cooling_type_counts[cooling_type]
      if count then
         count = count - 1
         self._sv.cooling_type_counts[cooling_type] = count
      end
      self._sv._cooling_glass[entity_id] = nil
   end
end

return CoolingService
