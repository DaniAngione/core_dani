local validator = radiant.validator
local CoreDaniClientCallHandler = class()

local log = radiant.log.create_logger('Dani\'s Core Mod client_call_handler')

function CoreDaniClientCallHandler:on_select_entity(session, response, entity, last_selected)
   if entity and entity:get_component('core_dani:entity_cutaway') and session.player_id == entity:get_player_id() then
      entity:get_component('core_dani:entity_cutaway'):_on_selection_changed(false)
   end

   if last_selected and last_selected:get_component('core_dani:entity_cutaway') and session.player_id == last_selected:get_player_id() then
      last_selected:get_component('core_dani:entity_cutaway'):_on_selection_changed(true)
   end
end

return CoreDaniClientCallHandler