local SelectionService = require 'stonehearth.services.client.selection.selection_service'
local CoreDaniSelectionService = class()

CoreDaniSelectionService._core_dani_old_select_entity = SelectionService.select_entity
function CoreDaniSelectionService:select_entity(entity)
   local last_selected = self._selected

   self:_core_dani_old_select_entity(entity)

   -- Inform the server of the selection change
   if entity and entity:get_component('core_dani:entity_cutaway') or last_selected and last_selected:get_component('core_dani:entity_cutaway') then
      _radiant.call('core_dani:on_select_entity', entity, last_selected)
   end
end

return CoreDaniSelectionService
