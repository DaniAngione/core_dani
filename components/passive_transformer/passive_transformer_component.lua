local rng = _radiant.math.get_default_rng()
local log = radiant.log.create_logger('passive_transformer_component')
local sh_constants = require 'stonehearth.constants'
local constants = sh_constants.passive_transformer

-- Compatibility with ACE
local stonehearth_ace = require 'stonehearth_ace.stonehearth_ace_server'

local PassiveTransformerComponent = class()

function PassiveTransformerComponent:initialize()
   self._sv.tracked_transformations = {}
end

function PassiveTransformerComponent:activate()
   self._json = self:_load_json()
   self._interval = self:_update_interval()

   if not self._item_added_listener then
      self._item_added_listener = radiant.events.listen(self._entity, 'stonehearth:storage:item_added', self, self._on_item_added)
   end

   if not self._item_removed_listener then
      self._item_removed_listener = radiant.events.listen(self._entity, 'stonehearth:storage:item_removed', self, self._on_item_removed)
   end

   if not self._rate_multiplier then
      self._rate_multiplier = self:_define_rate_multiplier()
   end

   if not self._processing_interval then
      self._processing_interval = self:_create_interval_timer(self._interval)
   end
end

function PassiveTransformerComponent:post_activate()
   if stonehearth_ace and not self._tick_setting_changed_listener then
      self._tick_setting_changed_listener = radiant.events.listen(radiant, 'passive_transformer_tick_setting_changed', self, self._update_interval)
   end
end

function PassiveTransformerComponent:_load_json()
   local json = radiant.entities.get_json(self)
   
   self._processes = {}
   self._transformer_type = json.type
   self._paused = json.paused
   if self._transformer_type then
      for _, obj in ipairs(constants.TRANSFORMERS) do
         if obj[self._transformer_type] then
            self._processes = obj[self._transformer_type]
            log:debug('Setting up processor %s with rate of %s that can perform the following processes: %s', self._entity, self._rate, radiant.util.table_tostring(self._processes))
            break
         end
      end
   end
end

function PassiveTransformerComponent:_update_interval(setting_change)
   local interval = '30m'
   if setting_change then
      interval = tostring(setting_change)
      self._interval = interval

      self._rate_multiplier = self:_define_rate_multiplier()
      self:_create_interval_timer(interval)
      return
   else
      interval = tostring(radiant.util.get_config('passive_transformer_tick', '30m'))
   end

   return interval
end

function PassiveTransformerComponent:_create_interval_timer(interval)
   if self._paused then
      return false
   end

   if self._processing_interval then
      self._processing_interval:destroy()
      self._processing_interval = nil
   end

   return stonehearth.calendar:set_persistent_interval("Passive Transformer Component", interval, function()
      self:_on_processing_interval_tick()
   end)
end

function PassiveTransformerComponent:_define_rate_multiplier()
   return constants.RATE_MULTIPLIERS[self._interval] or 0.5
end

function PassiveTransformerComponent:_on_item_added(args)
   if not args then
      log:debug('Item added to passive transformer (%s) has no \'args\' (how is that even possible?!)', self._entity)
      return
   end

   local item = args.item
   local id = tostring(item)
   if self._sv.tracked_transformations[item] then
      log:debug('Item (%s) added to passive transformer (%s) is already being tracked', item, self._entity)
      return
   end

   local item_data = nil
   local rate, item_type, processor_data, process_type, process_data, result, visual_steps_data

   if item then
      item_data = radiant.entities.get_entity_data(item, 'core_dani:passive_transform', false)
      log:debug('Getting entity data for %s in %s', item, self._entity)
   end

   if item_data and item_data.processes then 
      item_type = item_data.type
      log:debug('Acquired item type (%s) for %s in %s', item_type, item, self._entity)
      for process, _ in pairs(self._processes) do
         if item_data.processes[process] then
            processor_data = self._processes[process]
            process_type = process
            process_data = item_data.processes[process]
            result = item_data.processes[process].result
            visual_steps_data = process_data.visual_steps or {}
            log:debug('Found a viable process for %s! Rate is %s, type is %s and it will turn into %s inside %s', item, processor_data.rate, process_type, result, self._entity)
            break
         end
      end

      if processor_data and processor_data.rate and process_type and result then
         local progress_required = nil
         local progress_required_data = process_data.progress_required
         if type(progress_required_data) == 'number' then
            progress_required = progress_required_data
         elseif progress_required_data.min and progress_required_data.max then
            progress_required = rng:get_int(progress_required_data.min, progress_required_data.max)
         end
         log:debug('%s: Starting process...%s, %s, %s', self._entity, item, process_type, result)
         local entry = { 
            item = item,
            process_type = process_type, 
            rate = processor_data.rate,
            quality = processor_data.quality,
            sunlight_based = processor_data.sunlight_based,
            progress_required = progress_required, 
            result = result,
            visual_steps = visual_steps_data
        }
        self._sv.tracked_transformations[id] = entry     
        self.__saved_variables:mark_changed()
      else
         log:debug('Could not start process for %s in %s because a viable process couldn\' be found', item, self._entity)
         return
      end
   else
      log:debug('Item added to passive transformer (%s) has no \'core_dani:passive_transform\' data!', self._entity)
      return
   end
end

function PassiveTransformerComponent:_on_processing_interval_tick()
   if self._paused then
      return false
   end

   log:debug('It\'s processing time for %s!', self._entity)
   for id, data in pairs(self._sv.tracked_transformations) do
      local rate_multiplier = self._rate_multiplier
      if data.sunlight_based then
         local location = radiant.entities.get_world_grid_location(self._entity)
         location.y = location.y + 4
         if stonehearth.terrain:is_sheltered(location) or not stonehearth.calendar:is_daytime() then
            return false
         elseif stonehearth_ace then
            local biome = stonehearth.world_generation:get_biome()
            local biome_sunlight = biome.sunlight or 1
            local weather = stonehearth.weather:get_current_weather()
            local weather_sunlight = weather:get_sunlight() or 1
            rate_multiplier = rate_multiplier * (biome_sunlight * weather_sunlight)
         end
      end
      local current_progress = data.progress_required - (data.rate * rate_multiplier)

      if current_progress <= 0 then
         self:_transform(data.item)
      else
         if data.visual_steps then
            for _, visual_step in pairs(data.visual_steps) do
               if current_progress <= visual_step.progress_trigger and current_progress > (visual_step.progress_trigger - (data.rate * rate_multiplier)) then
                  if visual_step.description then
                     radiant.entities.set_description(data.item, visual_step.description)
                  end
                  if visual_step.model_variant then
                     data.item:get_component('render_info'):set_model_variant(visual_step.model_variant)
                  end
               end
            end
         end
         self._sv.tracked_transformations[id].progress_required = current_progress

         self.__saved_variables:mark_changed()
      end
   end
end

function PassiveTransformerComponent:_transform(item)
   local id = tostring(item)
   local item_data = self._sv.tracked_transformations[id]
   local player_id = self._entity:get_player_id()
   local inventory = stonehearth.inventory:get_inventory(player_id)
   local storage = self._entity:get_component('stonehearth:storage')

   if item_data and inventory and storage then
      local transformed_entity = radiant.entities.create_entity(item_data.result, { owner = player_id })
      if item_data.quality then
         local item_quality = radiant.entities.get_item_quality(item) or 1
         local max_quality = 3
         local town = stonehearth.town:get_town(self._entity:get_player_id())
         if town then
            for _, bonus in pairs(town:get_active_town_bonuses()) do
               if bonus.get_adjusted_item_quality_chances then
                  max_quality = 4
                  break
               end
            end
         end
         transformed_entity:add_component('stonehearth:item_quality'):initialize_quality(math.max(1, math.min(max_quality, item_quality + item_data.quality)))
      end
      inventory:add_item(transformed_entity)

      self._sv.tracked_transformations[id] = nil
      inventory:remove_item(item)
      radiant.entities.destroy_entity(item)

      storage:add_item(transformed_entity, true)

      self.__saved_variables:mark_changed()
   else
      log:error('Could not transform, data missing!')
      return
   end
end

function PassiveTransformerComponent:get_tracked_transformations()
   return self._sv.tracked_transformations
end

function PassiveTransformerComponent:set_tracked_transformations(table)
   self._sv.tracked_transformations = table
   self.__saved_variables:mark_changed()
end

function PassiveTransformerComponent:_on_item_removed(args)
   local id = tostring(args.item)
   if self._sv.tracked_transformations[id] then
      self._sv.tracked_transformations[id] = nil
   end
end

function PassiveTransformerComponent:destroy()
   if self._item_removed_listener then
      self._item_removed_listener:destroy()
      self._item_removed_listener = nil
   end

   if self._item_added_listener then
      self._item_added_listener:destroy()
      self._item_added_listener = nil
   end

   if self._processing_interval then
      self._processing_interval:destroy()
      self._processing_interval = nil
   end

   if self._tick_setting_changed_listener then
      self._tick_setting_changed_listener:destroy()
      self._tick_setting_changed_listener = nil
   end
end

return PassiveTransformerComponent