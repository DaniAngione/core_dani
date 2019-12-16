core_dani = {}

local service_creation_order = {
   'cooling'
}

local monkey_patches = {
   core_dani_storage_component = 'stonehearth.components.storage.storage_component'
}

local function monkey_patching()
   for from, into in pairs(monkey_patches) do
      local monkey_see = require('monkey_patches.' .. from)
      local monkey_do = radiant.mods.require(into)
      radiant.log.write_('core_dani', 0, 'Dani Core Mod server monkey-patching sources \'' .. from .. '\' => \'' .. into .. '\'')
      radiant.mixin(monkey_do, monkey_see)
   end
end

local function create_service(name)
   local path = string.format('services.server.%s.%s_service', name, name)
   local service = require(path)()
	
   local saved_variables = core_dani._sv[name]
   if not saved_variables then
      saved_variables = radiant.create_datastore()
      core_dani._sv[name] = saved_variables
   end

   service.__saved_variables = saved_variables
   service._sv = saved_variables:get_data()
   saved_variables:set_controller(service)
   saved_variables:set_controller_name('core_dani:' .. name)
   service:initialize()
   core_dani[name] = service
end

function core_dani:_on_init()
   core_dani._sv = core_dani.__saved_variables:get_data()

   for _, name in ipairs(service_creation_order) do
      create_service(name)
   end

   radiant.events.trigger_async(radiant, 'core_dani:server:init')
   radiant.log.write_('core_dani', 0, 'Dani Core Mod server initialized')
end

function core_dani:_on_required_loaded()
	monkey_patching()
   
   radiant.events.trigger_async(radiant, 'core_dani:server:required_loaded')
end

radiant.events.listen(core_dani, 'radiant:init', core_dani, core_dani._on_init)
radiant.events.listen(radiant, 'radiant:required_loaded', core_dani, core_dani._on_required_loaded)

return core_dani
