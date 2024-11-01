local log = radiant.log.create_logger('entity_cutaway_component')

-- ACE Compatibility (Support for gameplay settings)
local stonehearth_ace = require('stonehearth_ace.stonehearth_ace_server')

local EntityCutawayComponent = class()

function EntityCutawayComponent:activate()
   local json = radiant.entities.get_json(self)

   self._sv._unselected_model = json.unselected_model or 'default'
   self._selected_model = json.selected_model or 'selected'
   self._camera_rotations = json.camera_rotations
   if self._camera_rotations then
      self._selected_0_90 = json.selected_0_90 or 'selected_0_90'
      self._selected_90_180 = json.selected_90_180 or 'selected_90_180'
      self._selected_180_270 = json.selected_180_270 or 'selected_180_270'
      self._selected_270_360 = json.selected_270_360 or 'selected_270_360'
   end
end

function EntityCutawayComponent:restore()
   local render_info = self._entity:add_component('render_info')
   render_info:set_model_variant(self._sv._unselected_model)
end

function EntityCutawayComponent:_on_selection_changed(is_last_selected)
   log:debug('Selection changed triggered for %s', self._entity)
   if stonehearth_ace and not stonehearth.client_state:get_client_gameplay_setting(self._entity:get_player_id(), 'core_dani', 'entity_cutaway', true) then
      return
   end

   local render_info = self._entity:add_component('render_info')
   if is_last_selected then
      render_info:set_model_variant(self._sv._unselected_model)
   else
      render_info:set_model_variant(self._selected_model)
   end
end

function EntityCutawayComponent:get_unselected_model()
   return self._sv._unselected_model
end

return EntityCutawayComponent
