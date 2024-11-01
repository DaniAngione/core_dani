core_dani = {}

local stonehearth_ace = require('stonehearth_ace.stonehearth_ace_client')

local monkey_patches = {
   core_dani_storage_renderer = 'stonehearth.renderers.storage.storage_renderer',
   core_dani_selection_service = 'stonehearth.services.client.selection.selection_service'
}

if stonehearth_ace then
   monkey_patches = {
      core_dani_selection_service = 'stonehearth.services.client.selection.selection_service'
   }
end

local function monkey_patching()
   for from, into in pairs(monkey_patches) do
      local monkey_see = require('monkey_patches.' .. from)
      local monkey_do = radiant.mods.require(into)
      radiant.log.write_('core_dani', 0, 'Dani Core Mod client monkey-patching \'' .. from .. '\' => \'' .. into .. '\'')
      if monkey_see.ACE_USE_MERGE_INTO_TABLE then
         radiant.util.merge_into_table(monkey_do, monkey_see)
      else
         radiant.mixin(monkey_do, monkey_see)
      end
   end

   radiant.events.trigger(radiant, 'core_dani:client:monkey_patched', monkey_patches)
end

local player_service_trace = nil

function core_dani:_on_init()
   core_dani._sv = core_dani.__saved_variables:get_data()

   radiant.events.trigger_async(radiant, 'core_dani:client:init')
   radiant.log.write_('core_dani', 0, 'Dani Core Mod client initialized')
end

function core_dani:_on_required_loaded()
   monkey_patching()
   
   radiant.events.trigger_async(radiant, 'core_dani:client:required_loaded')
end

radiant.events.listen(core_dani, 'radiant:init', core_dani, core_dani._on_init)
radiant.events.listen(radiant, 'radiant:required_loaded', core_dani, core_dani._on_required_loaded)

return core_dani
