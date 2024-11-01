local validator = radiant.validator
local CoreDaniSettingsCallHandler = class()

local log = radiant.log.create_logger('Dani\'s Core Mod settings_call_handler')

function CoreDaniSettingsCallHandler:passive_transformer_tick_setting_changed(session, response, value)
   if session.player_id == _radiant.sim.get_host_player_id() then
      radiant.events.trigger(radiant, 'passive_transformer_tick_setting_changed', value)
   end
end

return CoreDaniSettingsCallHandler