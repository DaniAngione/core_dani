local OpeningContainerComponent = class()

local OC_FILTERS = {}

local ALWAYS_FALSE_FRC = nil

local get_always_false_filter = function()
   if not ALWAYS_FALSE_FRC then
      local filter_fn = function(entity)
         return false
      end

      ALWAYS_FALSE_FRC = stonehearth.ai:create_filter_result_cache(filter_fn, ' always false opening_container frc')
   end
   return ALWAYS_FALSE_FRC
end

local get_opening_container_filter = function(opening_container_entity)
   local player_id = radiant.entities.get_player_id(opening_container_entity)
   local filter = OC_FILTERS[player_id]
   if not filter then
      local filter_fn = function(entity)
         local entity_player_id = radiant.entities.get_player_id(entity)
         local is_not_hostile = stonehearth.player:are_player_ids_not_hostile(player_id, entity_player_id)
         return is_not_hostile
      end

      local frc = stonehearth.ai:create_filter_result_cache(filter_fn, player_id .. ' opening_container frc')
      local amenity_changed_listener = radiant.events.listen(radiant, 'stonehearth:amenity:sync_changed', function(e)
            local faction_a = e.faction_a
            local faction_b = e.faction_b
            if player_id == faction_a or player_id == faction_b then
               if frc and frc.cache then
                  frc.cache:clear()
               end
            end
         end)
      filter = {
         frc = frc,
         listener = amenity_changed_listener
      }
      OC_FILTERS[player_id] = filter
   end
   return filter
end

function OpeningContainerComponent:initialize()
   local json = radiant.entities.get_json(self)
   self._sensor_name = json.sensor
   self._tracked_entities = {}
end

function OpeningContainerComponent:activate(entity, json)
   if self._sensor_name then
      self:_trace_sensor()
      self._player_id_trace = self._entity:trace_player_id('opening_container component')
                                       :push_object_state()
   end
end

function OpeningContainerComponent:destroy()
   if self._sensor_trace then
      self._sensor_trace:destroy()
      self._sensor_trace = nil
   end

   if self._open_effect then
      self._open_effect:stop()
      self._open_effect = nil
   end

   if self._close_effect then
      self._close_effect:stop()
      self._close_effect = nil
   end

   if self._player_id_trace then
      self._player_id_trace:destroy()
      self._player_id_trace = nil
   end

   if self._lockable_filter then
      self._lockable_filter:destroy()
      self._lockable_filter = nil
   end
end

function OpeningContainerComponent:_get_filter_cache()
   local player_id = radiant.entities.get_player_id(self._entity)
   if player_id then
   return get_opening_container_filter(self._entity).frc.cache
   end
end

function OpeningContainerComponent:_trace_sensor()
   local sensor_list = self._entity:get_component('sensor_list')
   local sensor = sensor_list:get_sensor(self._sensor_name)
   if sensor then
      self._sensor_trace = sensor:trace_contents('opening_container')
                                       :on_added(function (id, entity)
                                             self:_on_added_to_sensor(id, entity)
                                          end)
                                       :on_removed(function (id)
                                             self:_on_removed_to_sensor(id)
                                          end)
                                       :push_object_state()
   end
end

function OpeningContainerComponent:_on_added_to_sensor(id, entity)
   if self:_valid_entity(entity) then
      if not next(self._tracked_entities) then
         -- if this is in our faction, open the opening_container
         self:_open_opening_container();
      end
      self._tracked_entities[id] = entity
   end
end

function OpeningContainerComponent:_on_removed_to_sensor(id)
   self._tracked_entities[id] = nil
   if not next(self._tracked_entities) then
      self:_close_opening_container()
   end
end

function OpeningContainerComponent:_open_opening_container()
   if self._close_effect then
      self._close_effect:stop()
      self._close_effect = nil
   end
   if not self._open_effect then
      self._open_effect = radiant.effects.run_effect(self._entity, 'open')
         :set_cleanup_on_finish(false)
   end
end

function OpeningContainerComponent:_close_opening_container()
   if self._open_effect then
      self._open_effect:stop()
      self._open_effect = nil
   end
   if not self._close_effect then
      self._close_effect = radiant.effects.run_effect(self._entity, 'close')
   end
end

function OpeningContainerComponent:_valid_entity(entity)
   if not entity then
      return false
   end

   if not radiant.entities.has_free_will(entity) then
      -- entity can't open opening_containers
      return false
   end

   if entity:get_id() == self._entity:get_id() then
      return false
   end

   if stonehearth.player:are_player_ids_hostile(radiant.entities.get_player_id(entity), radiant.entities.get_player_id(self._entity)) then
      return false
   end

   --[[
   if not mob_component or not mob_component:get_moving() then
      return false
   end
   ]]

   return true
end

return OpeningContainerComponent
