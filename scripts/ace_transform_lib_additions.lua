local AceTransformLibAdditions = class()

function AceTransformLibAdditions:transform(entity, transformed_form, transform_source, options)
   local passive_transformer_component = entity:get_component('core_dani:passive_transformer')
   if passive_transformer_component then 
      local tracked_transformations = {}
      tracked_transformations = passive_transformer_component:get_tracked_transformations()

      if tracked_transformations and next(tracked_transformations) ~= nil then
         local transformed_form_component = transformed_form:get_component('core_dani:passive_transformer')
         if transformed_form_component then
            transformed_form_component:set_tracked_transformations(tracked_transformations)
         end
      end
   end
end

return AceTransformLibAdditions
