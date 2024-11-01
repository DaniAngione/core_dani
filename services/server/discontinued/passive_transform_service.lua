-- THIS SERVICE IS NO LONGER IN USE AND HAS BEEN REPLACED BY THE "PASSIVE TRANSFORMER COMPONENT"
-- It's only being left here as historical data of how bad I was! :D

------------------------------------------------------------------------------------------------------

-- Service for handling passive, over-time transformations within stations, originally created to cool hot glass for Glassworks. Created by DaniAngione and based upon Team Radiant's "PassiveTransformService"
-- Special thanks to Max, BrunoSupremo and Relyss for the amazing help with the first version of the script! IT'S WORKING!!
-- Also a lot of thanks to PaulTheGreat for the experience/learning over the years, allowing me to make this new version!

local rng = _radiant.math.get_default_rng()
local log = radiant.log.create_logger('core_dani.passive_transform')
local constants = stonehearth.constants.passive_transform
-- ACE Compatibility
local AcePresent = require 'stonehearth_ace.stonehearth_ace_server'

PassiveTransformService = class()

function PassiveTransformService:initialize()
   self.item_types = constants.types or {}
   self.enable_processing = true
   self._interval = self:_update_interval(radiant.util.get_config('passive_transform_tick', '1h'))
   self._sv = self.__saved_variables:get_data()
   if not self._sv.initialized then
      self._sv.initialized = true
      self._sv._ongoing_processes = {}
      self._sv.processing_tick_listener = self:_create_processing_tick_listener()
      self._sv.item_type_counts = {}
   else
      self._sv.processing_tick_listener:bind(function()
         self:_on_processing_tick()
      end)
   end

   radiant.events.listen(radiant, 'radiant:entity:post_destroy', function(e)
         local entity_id = e.entity_id
         self:_on_entity_destroyed(entity_id)
      end)

   self._post_create_listener = radiant.events.listen(radiant, 'radiant:entity:post_create', function(e)
         local entity = e.entity
         self:_on_entity_added_to_world(entity)
      end)

   self._game_loaded_listener = radiant.events.listen_once(radiant, 'radiant:game_loaded', function()
         if not stonehearth.calendar:is_tracking_timer(self._sv.processing_tick_listener) then
            log:debug('There is no listener tracked by the calendar. Recreating a listener')
            if self._sv.processing_tick_listener then
               self._sv.processing_tick_listener:destroy()
            end
            self._sv.processing_tick_listener = self:_create_processing_tick_listener()
         end
         self._game_loaded_listener = nil
      end)
end

function PassiveTransformService:_update_interval(value)
   local interval = tostring(constants.PROCESSING_TICK_DEFAULT_INTERVAL)
   if value then
      interval = tostring(value)
   end

   self._progress_per_processing_tick = constants.PROGRESS_PER_PROCESSING_TICK[interval]
   self._sv.interval = interval
end

function PassiveTransformService:_create_processing_tick_listener()
   local interval = self._interval or '1h'
   if not self._progress_per_processing_tick then
      self:_update_interval(radiant.util.get_config('passive_transform_tick_setting', '1h'))
   end

   if self._sv.processing_tick_listener then
      self._sv.processing_tick_listener:destroy()
   end

   log:debug('Creating listener with the interval: %s', interval)
   return stonehearth.calendar:set_persistent_interval("PassiveTransformService processing tick", interval, function()
      self:_on_processing_tick()
   end)
end

function PassiveTransformService:get_item_type_count(item_type)
   return self._sv.item_type_counts[self.item_types[item_type]] or 0
end

function PassiveTransformService:_on_entity_added_to_world(entity)
   local id = entity:get_id()
   if self._sv._ongoing_processes[id] then
      return
   end

   local passive_transform_tuning = radiant.entities.get_entity_data(entity, 'core_dani:passive_transform', false)
   if passive_transform_tuning then
      local progress_required = 4

      local item_type= passive_transform_tuning.type
      if type(passive_transform_tuning.progress_required) == 'number' then
         progress_required = passive_transform_tuning.progress_required
      elseif passive_transform_tuning.progress_required.min and passive_transform_tuning.progress_required.max then
         progress_required = rng:get_int(passive_transform_tuning.progress_required.min, passive_transform_tuning.progress_required.max)
      end
      self._sv._ongoing_processes[id] = { entity = entity, item_type = item_type, progress_required = progress_required, passive_transform_tuning = passive_transform_tuning.tuning }

      local count = self._sv.item_type_counts[item_type] or 0
      count = count + 1
      self._sv.item_type_counts[item_type] = count
   end
end

function PassiveTransformService:_on_processing_tick()
   if not self.enable_processing then
      return
   end

   local ongoing_processes = self._sv._ongoing_processes
   local ids = {}
   for id, _ in pairs(ongoing_processes) do
      table.insert(ids, id)
   end

   for _, id in ipairs(ids) do
      self:increment_progress(ongoing_processes[id])
   end
end

function PassiveTransformService:increment_progress(passive_transform_data)
   local entity = passive_transform_data.entity

   local passive_transform_tuning = passive_transform_data.passive_transform_tuning
   local progress_required = passive_transform_data.progress_required
   if not passive_transform_tuning or not progress_required then
      return
   end

   local processing_rate, processing_method = self:_get_processing_rate_and_method(entity, passive_transform_data, self._progress_per_processing_tick)

   if not processing_rate or not processing_method then
      log:error('No rate(%s) or method(%s) found for %s', processing_rate or 'nil', processing_method or 'nil', entity)
      return
   elseif processing_rate == 0 then
      log:debug('Found rate to be zero for the following item: %s (%s)', entity, passive_transform_data.item_type)
      return
   end

   log:debug('Found rate (%s) and method (%s) for the following item: %s (%s)', processing_rate, processing_method, entity, passive_transform_data.item_type)
   local current_progress = progress_required - processing_rate
   passive_transform_data.progress_required = current_progress
   passive_transform_data.processing_method = processing_method

   if current_progress <= 0 then
      self:_transform(entity, passive_transform_tuning.processes[method].result or passive_transform_tuning.processes[method])
   elseif passive_transform_tuning.progress_stages then
      local new_progress_stage = nil
      local lowest_trigger_value = progress_required + 1
      local effect = nil
      for _, progress_stage in pairs(passive_transform_tuning.progress_stages) do
         if current_progress <= progress_stage.progress_stage_value and progress_stage.progress_stage_value < lowest_trigger_value then
            lowest_trigger_value = progress_stage.progress_stage_value
            new_progress_stage = progress_stage
         end
      end

      if new_progress_stage then
         if new_progress_stage.description then
            radiant.entities.set_description(entity, new_progress_stage.description)
         end
         if new_progress_stage.model_variant then
            entity:get_component('render_info'):set_model_variant(new_progress_stage.model_variant)
         end
      end
   end
   return true
end

function PassiveTransformService:_get_processing_rate_and_method(entity, tuning, rate)
   local player_id = entity:get_player_id()
   local item_type = tuning.type
   local method = nil
   local processes = {}
   local acceptable_tags = {}

   if item_type and constants.TYPES[item_type] then
      processes = constants.TYPES[item_type]
   end

   if processes == {} then
      log:error('This item does not have registered TYPES in the constants :( (%s)', entity)
      return
   end
   log:debug('Possible processes found for %s: %s', entity, radiant.util.table_tostring(processes))
   
   if player_id and player_id ~= '' then
      local inventory = stonehearth.inventory:get_inventory(player_id)
      local storage = nil
      local best_rate = 0
      if inventory then
         storage = inventory:container_for(entity)
      end

      if storage then
         for _, process in ipairs(processes) do
            local process_table = constants.PROCESSES[process]
            if process_table then
               for key, data in pairs(process_table) do
                  table.insert(acceptable_tags, { key, data })
               end
            end
         end
         log:debug('Possible acceptable processors found for %s: %s', entity, radiant.util.table_tostring(acceptable_tags))

         for tag, data in pairs(acceptable_tags) do
            log:debug('Testing %s as a processor for %s; Currently checking if % (%)', storage, entity, tag, data)
            if radiant.entities.is_material(storage, tag) then
               best_rate = data.rate
               method = tag
               log:debug('%s is in a processor! Method: %s, Rate: %s (Processor: %s)', entity, method, best_rate, storage)
               break
            end
         end

         rate = rate * best_rate
      end
   end      

   return rate, method or 'none'
end

function PassiveTransformService:_transform(entity, transform_alias)
   local inventory = nil
   local storage_component = nil
   local location = nil
   local transformed_entity
   if transform_alias then
      local player_id = entity:get_player_id()
      if player_id and player_id ~= '' then
         inventory = stonehearth.inventory:get_inventory(player_id)
         location = radiant.entities.get_world_grid_location(entity)
         transformed_entity = radiant.entities.create_entity(transform_alias, { owner = player_id })
         if not location then
            local storage = inventory and inventory:container_for(entity)
            if storage then
               storage_component = storage:get_component('stonehearth:storage')
            end
         end
      end
   end
   if inventory then
      inventory:remove_item(entity:get_id())
   end
   radiant.entities.destroy_entity(entity)
   if transformed_entity then
      if location then
         radiant.terrain.place_entity(transformed_entity, location)
      elseif not storage_component or not storage_component:add_item(transformed_entity, true) then
         if inventory then
            inventory:add_item(transformed_entity)
         end
      end
      self:_on_entity_added_to_world(transformed_entity)
   end
end

function PassiveTransformService:_on_entity_destroyed(entity_id)
   local ongoing_process_data = self._sv._ongoing_processes[entity_id]
   if ongoing_process_data then
      local item_type = ongoing_process_data.type
      local count = self._sv.item_type_counts[item_type]
      if count then
         count = count - 1
         self._sv.item_type_counts[item_type] = count
      end
      self._sv._ongoing_processes[entity_id] = nil
   end
end

return PassiveTransformService
