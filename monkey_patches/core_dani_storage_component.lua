-- Original Monkey Patch created for the ACE mod by myself and PaulTheGreat
-- Used here with permission from ACE

local StorageComponent = require 'stonehearth.components.storage.storage_component'
CoreDaniStorageComponent = class()

CoreDaniStorageComponent._core_dani_old_create = StorageComponent.create
function CoreDaniStorageComponent:create()
	
	self._is_create = true
	self:_core_dani_old_create()

end

CoreDaniStorageComponent._core_dani_old_activate = StorageComponent.activate
function CoreDaniStorageComponent:activate()
	
	self:_core_dani_old_activate()
	
	local json = radiant.entities.get_json(self) or {}
   if self._is_create then		
		if json.default_filter then
			self:set_filter(json.default_filter)
		end
	end
	
	-- communicate this setting to the renderer
   self._sv.reposition_items = json.reposition_items
   self.__saved_variables:mark_changed()
end

return CoreDaniStorageComponent